#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <handy.h>
#include <window_manager/window_manager_plugin.h>

// Test control only: drain outstanding GTK completions without retaining the
// engine, view, renderer or window. Completion is an observed weak notification.
static GThread* gtk_thread;
static bool finalized = false;
static bool wrong_thread = false;
static guint deadline_source = 0;
static gboolean finish(gpointer data) {
  if (deadline_source) {
    g_source_remove(deadline_source);
    deadline_source = 0;
  }
  g_application_release(G_APPLICATION(data));
  return G_SOURCE_REMOVE;
}
static void engine_finalized(gpointer data, GObject*) {
  finalized = true;
  wrong_thread = g_thread_self() != gtk_thread;
  g_printerr("ENGINE_FINALIZED gtk=%d\n", !wrong_thread);
  if (wrong_thread) {
    g_main_context_invoke(nullptr, finish, data);
  } else {
    finish(data);
  }
}
static gboolean deadline(gpointer data) {
  deadline_source = 0;
  g_printerr("ENGINE_FINALIZATION_DEADLINE\n");
  g_application_release(G_APPLICATION(data));
  return G_SOURCE_REMOVE;
}
static void first_frame(GtkWidget* view) {
  gtk_widget_show(gtk_widget_get_toplevel(view));
}
static void activate(GtkApplication* app) {
  hdy_init();
  GtkWidget* window = hdy_application_window_new();
  gtk_application_add_window(app, GTK_WINDOW(window));
  gtk_window_set_title(GTK_WINDOW(window), "Pinned engine complete retirement");
  gtk_window_set_default_size(GTK_WINDOW(window), 1280, 720);
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  auto* view = fl_view_new(project);
  auto* overlay = gtk_overlay_new();
  gtk_container_add(GTK_CONTAINER(overlay), GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), overlay);
  g_application_hold(G_APPLICATION(app));
  g_object_weak_ref(G_OBJECT(fl_view_get_engine(view)), engine_finalized, app);
  deadline_source = g_timeout_add_seconds(20, deadline, app);
  gtk_widget_show(overlay);
  gtk_widget_show(GTK_WIDGET(view));
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame), view);
  gtk_widget_realize(GTK_WIDGET(view));
  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                "WindowManagerPlugin");
  window_manager_plugin_register_with_registrar(registrar);
}
int main(int argc, char** argv) {
  gtk_thread = g_thread_self();
  g_autoptr(GtkApplication) app = gtk_application_new(
      "io.busystack.EngineCompleteRetirement", G_APPLICATION_NON_UNIQUE);
  g_signal_connect(app, "activate", G_CALLBACK(activate), nullptr);
  int result = g_application_run(G_APPLICATION(app), argc, argv);
  return finalized && !wrong_thread ? result : 1;
}
