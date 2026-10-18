// Isolated engine regression: compile the actual pinned renderer translation
// unit with a controlled compositor. No timing delay, real application input,
// backend switch, or production test hook is required.
#include <gtk/gtk.h>
#include <atomic>
#include <condition_variable>
#include <cstdio>
#include <mutex>
#include <string>
#include <thread>
#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

static std::mutex control;
static std::condition_variable changed;
static bool entered, release_presentation, retirement_gate_seen;
static std::atomic<bool> presenting{false}, retirement_requested{false};
static GThread* gtk_thread;
static int shutdowns, finalizations, redraws;

static GMutexLocker* observed_mutex_locker_new(GMutex* mutex) {
  if (g_thread_self() == gtk_thread && retirement_requested && presenting) {
    std::lock_guard<std::mutex> lock(control);
    retirement_gate_seen = true;
    changed.notify_all();
  }
  return g_mutex_locker_new(mutex);
}
static void observed_queue_draw(GtkWidget*) { ++redraws; }

// Only calls compiled from this exact renderer file are instrumented. GTK and
// the compositor retain their real locks. B has no renderer retirement lock;
// its resource destruction assertion fails while presentation is blocked.
#define g_mutex_locker_new observed_mutex_locker_new
#define gtk_widget_queue_draw observed_queue_draw
#include BM2_RENDERER_SOURCE
#undef gtk_widget_queue_draw
#undef g_mutex_locker_new

struct _FlEngine { GObject parent_instance; };
G_DEFINE_TYPE(FlEngine, fl_engine, G_TYPE_OBJECT)
static void fl_engine_class_init(FlEngineClass*) {}
static void fl_engine_init(FlEngine*) {}
FlutterRendererType fl_engine_get_renderer_type(FlEngine*) { return kSoftware; }
FlTaskRunner* fl_engine_get_task_runner(FlEngine*) { return nullptr; }
FlOpenGLManager* fl_engine_get_opengl_manager(FlEngine*) { return nullptr; }

typedef struct _TestCompositor { FlCompositor parent; bool retired; } TestCompositor;
typedef struct _TestCompositorClass { FlCompositorClass parent; } TestCompositorClass;
G_DEFINE_TYPE(TestCompositor, test_compositor, fl_compositor_get_type())
static void release_resources(FlCompositor* compositor) {
  auto* self = reinterpret_cast<TestCompositor*>(compositor);
  g_assert_false(presenting.load());
  if (!self->retired) { self->retired = true; ++shutdowns; }
}
static gboolean present(FlCompositor*, const FlutterLayer**, size_t) {
  std::unique_lock<std::mutex> lock(control);
  presenting = true;
  entered = true;
  changed.notify_all();
  changed.wait(lock, [] { return release_presentation; });
  presenting = false;
  return TRUE;
}
static void dimensions(FlCompositor*, size_t* width, size_t* height) {
  *width = *height = 100;
}
static gboolean draw(FlCompositor*, cairo_t*, GdkWindow*, gboolean) { return TRUE; }
static void dispose(GObject* object) {
  // Deliberately fail B at the unsafe release, without returning into freed
  // renderer memory. C must first finish the blocked presentation.
  release_resources(FL_COMPOSITOR(object));
  G_OBJECT_CLASS(test_compositor_parent_class)->dispose(object);
}
template<class C> static auto install_shutdown(C* klass, int)
    -> decltype(klass->shutdown = release_resources, void()) {
  klass->shutdown = release_resources;
}
template<class C> static void install_shutdown(C*, long) {}
static void test_compositor_class_init(TestCompositorClass* klass) {
  auto* compositor = FL_COMPOSITOR_CLASS(klass);
  compositor->present_layers = present;
  compositor->get_frame_size = dimensions;
  compositor->render = draw;
  install_shutdown(compositor, 0);
  G_OBJECT_CLASS(klass)->dispose = dispose;
}
static void test_compositor_init(TestCompositor* self) { self->retired = false; }
FlCompositorOpenGL* fl_compositor_opengl_new(FlTaskRunner*, FlOpenGLManager*, gboolean) {
  return reinterpret_cast<FlCompositorOpenGL*>(g_object_new(test_compositor_get_type(), nullptr));
}
FlCompositorSoftware* fl_compositor_software_new(FlTaskRunner*) {
  return reinterpret_cast<FlCompositorSoftware*>(g_object_new(test_compositor_get_type(), nullptr));
}
void fl_engine_shutdown_compositor(FlEngine*, FlCompositor* compositor) {
  // Unit double for the render-thread task. The separately built live engine
  // validates the real PostRenderThreadTask implementation and GPU cleanup.
  std::thread cleanup([&] { release_resources(compositor); });
  cleanup.join();
}
static void finalized(gpointer, GObject*) {
  g_assert_true(g_thread_self() == gtk_thread);
  ++finalizations;
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  gtk_thread = g_thread_self();
  const bool pending = argc > 1 && std::string(argv[1]) == "pending-redraw";
  const bool partial = argc > 1 && std::string(argv[1]) == "partial";
  const bool first_frame = argc > 1 && std::string(argv[1]) == "first-frame";
  for (int cycle = 0; cycle < 50; ++cycle) {
    entered = release_presentation = retirement_gate_seen = false;
    retirement_requested = false;
    presenting = false;
    shutdowns = finalizations = redraws = 0;
    g_autoptr(FlEngine) engine = FL_ENGINE(g_object_new(fl_engine_get_type(), nullptr));
    GtkWidget* parent = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    g_object_ref_sink(parent);
    FlViewRenderer* renderer = fl_view_renderer_new(engine, FALSE);
    if (!partial) renderer->compositor = FL_COMPOSITOR(g_object_new(test_compositor_get_type(), nullptr));
    g_object_weak_ref(G_OBJECT(renderer), finalized, nullptr);
    gtk_container_add(GTK_CONTAINER(parent), GTK_WIDGET(renderer));
    if (partial) g_object_ref(renderer);
    if (first_frame) {
      g_signal_connect_swapped(renderer, "first-frame", G_CALLBACK(gtk_widget_destroy), parent);
    }
    std::thread raster;
    std::thread coordinator;
    if (!partial) {
      raster = std::thread([&] { fl_view_renderer_present_layers(renderer, nullptr, 0); });
      std::unique_lock<std::mutex> lock(control);
      changed.wait(lock, [] { return entered; });
      if (pending || first_frame) {
        release_presentation = true;
        changed.notify_all();
        lock.unlock();
        raster.join();
      } else {
        lock.unlock();
        coordinator = std::thread([] {
          std::unique_lock<std::mutex> lock(control);
          changed.wait(lock, [] { return retirement_gate_seen; });
          g_assert_true(presenting.load());
          release_presentation = true;
          changed.notify_all();
        });
      }
    }
    retirement_requested = true;
    if (first_frame) {
      while (g_main_context_iteration(nullptr, FALSE)) {}
    } else {
      gtk_widget_destroy(parent);
    }
    if (partial) {
      g_object_run_dispose(G_OBJECT(renderer));
      g_object_run_dispose(G_OBJECT(renderer));
      g_object_unref(renderer);
    }
    g_object_run_dispose(G_OBJECT(parent));
    g_object_unref(parent);
    if (raster.joinable()) raster.join();
    if (coordinator.joinable()) coordinator.join();
    while (g_main_context_iteration(nullptr, FALSE)) {}
    g_assert_cmpint(finalizations, ==, 1);
    g_assert_cmpint(shutdowns, ==, partial ? 0 : 1);
    g_assert_cmpint(redraws, ==, 0);
    g_assert_false(presenting.load());
  }
  std::printf("PASS %s: 50 retirements; resources released once, GTK finalization, no continuing redraw\n", partial ? "partial" : first_frame ? "first-frame" : pending ? "pending-redraw" : "active-presentation");
  return 0;
}
