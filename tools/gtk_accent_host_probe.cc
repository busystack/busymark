// Executes the production host, GTK observer, Flutter channels and codecs.
// Only the engine's binary transport is injected; a real FlView/FlEngine owns
// the widget lifecycle. The view is never realized, so no Dart app is launched.
#include "gtk_accent_host.h"

#include <cmath>
#include <string>

constexpr char kMethods[] = "com.busymark.app/gtk_accent";
constexpr char kEvents[] = "com.busymark.app/gtk_accent/events";

struct Handler {
  FlBinaryMessengerMessageHandler callback;
  gpointer data;
  GDestroyNotify destroy;
};

struct TestMessenger {
  GObject parent;
  GHashTable* handlers;
  GPtrArray* events;
};
struct TestMessengerClass { GObjectClass parent; };
static void messenger_interface_init(FlBinaryMessengerInterface* iface);
G_DEFINE_TYPE_WITH_CODE(TestMessenger, test_messenger, G_TYPE_OBJECT,
                       G_IMPLEMENT_INTERFACE(fl_binary_messenger_get_type(),
                                             messenger_interface_init))

struct TestResponse {
  FlBinaryMessengerResponseHandle parent;
  GBytes* bytes;
  bool responded;
};
struct TestResponseClass { FlBinaryMessengerResponseHandleClass parent; };
G_DEFINE_TYPE(TestResponse, test_response,
              fl_binary_messenger_response_handle_get_type())

static void test_response_finalize(GObject* object) {
  g_clear_pointer(&reinterpret_cast<TestResponse*>(object)->bytes, g_bytes_unref);
  G_OBJECT_CLASS(test_response_parent_class)->finalize(object);
}
static void test_response_class_init(TestResponseClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = test_response_finalize;
}
static void test_response_init(TestResponse*) {}

static void free_handler(gpointer data) {
  auto* handler = static_cast<Handler*>(data);
  if (handler->destroy != nullptr) handler->destroy(handler->data);
  delete handler;
}
static void set_handler(FlBinaryMessenger* messenger, const gchar* channel,
                        FlBinaryMessengerMessageHandler callback, gpointer data,
                        GDestroyNotify destroy) {
  auto* self = reinterpret_cast<TestMessenger*>(messenger);
  g_hash_table_remove(self->handlers, channel);
  if (callback != nullptr) {
    g_hash_table_insert(self->handlers, g_strdup(channel),
                        new Handler{callback, data, destroy});
  } else if (destroy != nullptr) {
    destroy(data);
  }
}
static gboolean send_response(FlBinaryMessenger*,
                              FlBinaryMessengerResponseHandle* handle,
                              GBytes* bytes, GError**) {
  auto* response = reinterpret_cast<TestResponse*>(handle);
  g_assert_false(response->responded);
  response->responded = true;
  response->bytes = bytes != nullptr ? g_bytes_ref(bytes) : g_bytes_new(nullptr, 0);
  return TRUE;
}
static void send_event(FlBinaryMessenger* messenger, const gchar* channel,
                       GBytes* message, GCancellable*, GAsyncReadyCallback callback,
                       gpointer) {
  g_assert_cmpstr(channel, ==, kEvents);
  g_assert_null(callback);  // FlEventChannel sends unacknowledged envelopes.
  g_assert_nonnull(message);
  g_ptr_array_add(reinterpret_cast<TestMessenger*>(messenger)->events,
                  g_bytes_ref(message));
}
static void shutdown_messenger(FlBinaryMessenger* messenger) {
  g_hash_table_remove_all(reinterpret_cast<TestMessenger*>(messenger)->handlers);
}
static void messenger_interface_init(FlBinaryMessengerInterface* iface) {
  iface->set_message_handler_on_channel = set_handler;
  iface->send_response = send_response;
  iface->send_on_channel = send_event;
  iface->shutdown = shutdown_messenger;
}
static void test_messenger_finalize(GObject* object) {
  auto* self = reinterpret_cast<TestMessenger*>(object);
  g_hash_table_unref(self->handlers);
  g_ptr_array_unref(self->events);
  G_OBJECT_CLASS(test_messenger_parent_class)->finalize(object);
}
static void test_messenger_class_init(TestMessengerClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = test_messenger_finalize;
}
static void test_messenger_init(TestMessenger* self) {
  self->handlers = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, free_handler);
  self->events = g_ptr_array_new_with_free_func(
      reinterpret_cast<GDestroyNotify>(g_bytes_unref));
}

static TestMessenger* active_messenger = nullptr;
// --wrap affects the production host's call, not calls inside Flutter's shared
// library. This is the sole injected I/O boundary; channel handlers are real.
extern "C" FlBinaryMessenger* __wrap_fl_engine_get_binary_messenger(FlEngine* engine) {
  g_assert_true(FL_IS_ENGINE(engine));
  g_assert_nonnull(active_messenger);
  return FL_BINARY_MESSENGER(active_messenger);
}

static void drain() {
  int iterations = 0;
  while (g_main_context_pending(nullptr)) {
    g_main_context_iteration(nullptr, FALSE);
    g_assert_cmpint(++iterations, <, 10000);
  }
}
static void theme(const char* root, const char* name, const char* css,
                   const char* dark = nullptr) {
  const std::string directory = std::string(root) + "/themes/" + name + "/gtk-3.0";
  g_assert_cmpint(g_mkdir_with_parents(directory.c_str(), 0700), ==, 0);
  g_assert_true(g_file_set_contents((directory + "/gtk.css").c_str(), css, -1, nullptr));
  if (dark != nullptr) {
    g_assert_true(g_file_set_contents((directory + "/gtk-dark.css").c_str(),
                                      dark, -1, nullptr));
  }
}
static FlMethodResponse* decode(FlMethodCodec* codec, GBytes* bytes) {
  if (g_bytes_get_size(bytes) == 0) {
    return FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  // The codec's public virtual interface avoids Flutter-private test headers.
  auto* response = FL_METHOD_CODEC_GET_CLASS(codec)->decode_response(codec, bytes, &error);
  g_assert_no_error(error);
  g_assert_nonnull(response);
  return response;
}
static void payload(FlMethodResponse* response, bool available,
                     double r = 0, double g = 0, double b = 0) {
  g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  FlValue* value = fl_method_success_response_get_result(FL_METHOD_SUCCESS_RESPONSE(response));
  g_assert_cmpint(fl_value_get_type(value), ==, FL_VALUE_TYPE_MAP);
  auto* flag = fl_value_lookup_string(value, "available");
  g_assert_nonnull(flag);
  g_assert_cmpint(fl_value_get_type(flag), ==, FL_VALUE_TYPE_BOOL);
  g_assert_cmpint(fl_value_get_bool(flag), ==, available);
  auto* rgb = fl_value_lookup_string(value, "rgb");
  if (!available) {
    g_assert_null(rgb);
    g_assert_cmpuint(fl_value_get_length(value), ==, 1);
    return;
  }
  g_assert_cmpuint(fl_value_get_length(value), ==, 2);
  g_assert_nonnull(rgb);
  g_assert_cmpint(fl_value_get_type(rgb), ==, FL_VALUE_TYPE_LIST);
  g_assert_cmpuint(fl_value_get_length(rgb), ==, 3);
  const double expected[] = {r, g, b};
  for (size_t i = 0; i < 3; ++i) {
    auto* channel = fl_value_get_list_value(rgb, i);
    g_assert_cmpint(fl_value_get_type(channel), ==, FL_VALUE_TYPE_FLOAT);
    g_assert_cmpfloat(std::abs(fl_value_get_float(channel) - expected[i]), <, 0.000001);
  }
}

struct Harness {
  TestMessenger* messenger;
  FlStandardMethodCodec* codec;
  GtkWidget* window;
  FlView* view;
  BusyMarkGtkAccentHost* host;
  guint disposed_channels = 0;

  Harness() {
    messenger = static_cast<TestMessenger*>(g_object_new(test_messenger_get_type(), nullptr));
    active_messenger = messenger;
    codec = fl_standard_method_codec_new();
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_object_ref_sink(window);
    gtk_widget_realize(window);
    g_autoptr(FlDartProject) project = fl_dart_project_new();
    view = fl_view_new(project);
    g_object_ref_sink(view);
    host = busymark_gtk_accent_host_new(view, window);
    g_assert_cmpuint(g_hash_table_size(messenger->handlers), ==, 2);
    for (const auto* name : {kMethods, kEvents}) {
      auto* handler = static_cast<Handler*>(g_hash_table_lookup(messenger->handlers, name));
      g_object_weak_ref(G_OBJECT(handler->data), [](gpointer data, GObject*) {
        ++*static_cast<guint*>(data);
      }, &disposed_channels);
    }
  }
  ~Harness() {
    stop();
    // Flutter channels are messenger-owned until channel/engine shutdown. Their
    // host callbacks must already be detached, and shutdown releases both refs.
    shutdown_messenger(FL_BINARY_MESSENGER(messenger));
    g_assert_cmpuint(g_hash_table_size(messenger->handlers), ==, 0);
    g_assert_cmpuint(disposed_channels, ==, 2);
    gtk_widget_destroy(GTK_WIDGET(view));
    gtk_widget_destroy(window);
    g_object_unref(view);
    g_object_unref(window);
    g_object_unref(codec);
    g_object_unref(messenger);
    active_messenger = nullptr;
    drain();
  }
  void stop() {
    busymark_gtk_accent_host_free(host);
    host = nullptr;
  }
  FlMethodResponse* call(const char* channel, const char* method,
                         bool require_response = true) {
    auto* handler = static_cast<Handler*>(g_hash_table_lookup(messenger->handlers, channel));
    g_assert_nonnull(handler);
    g_autoptr(GError) error = nullptr;
    auto* method_codec = FL_METHOD_CODEC(codec);
    g_autoptr(GBytes) bytes = FL_METHOD_CODEC_GET_CLASS(method_codec)->encode_method_call(
        method_codec, method, nullptr, &error);
    g_assert_no_error(error);
    auto* response = static_cast<TestResponse*>(g_object_new(test_response_get_type(), nullptr));
    handler->callback(FL_BINARY_MESSENGER(messenger), channel, bytes,
                       FL_BINARY_MESSENGER_RESPONSE_HANDLE(response), handler->data);
    if (!require_response) {
      g_assert_false(response->responded);
      g_object_unref(response);
      return nullptr;
    }
    g_assert_true(response->responded);
    auto* result = decode(method_codec, response->bytes);
    g_object_unref(response);
    return result;
  }
  void event(bool available, double r = 0, double g = 0, double b = 0) {
    g_assert_cmpuint(messenger->events->len, >, 0);
    auto* bytes = static_cast<GBytes*>(g_ptr_array_index(
        messenger->events, messenger->events->len - 1));
    g_autoptr(FlMethodResponse) response = decode(FL_METHOD_CODEC(codec), bytes);
    payload(response, available, r, g, b);
  }
  void listen() {
    g_autoptr(FlMethodResponse) response = call(kEvents, "listen");
    g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  }
  void cancel() {
    g_autoptr(FlMethodResponse) response = call(kEvents, "cancel");
    g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  }
  void detached() {
    // Exercise the real channel after host destruction: no dangling host data.
    g_autoptr(FlMethodResponse) method = call(kMethods, "getAccent", false);
    g_assert_null(method);  // Flutter drops messages when the method handler is cleared.
    g_autoptr(FlMethodResponse) listen = call(kEvents, "listen");
    g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(listen)); // No handler, no replay.
  }
};

int main(int argc, char** argv) {
  g_assert_cmpint(argc, ==, 2);
  theme(argv[1], "BusyMarkHostOld", "@define-color theme_selected_bg_color #336699;",
        "@define-color theme_selected_bg_color #7764d8;");
  theme(argv[1], "BusyMarkHostModern", "@define-color accent_bg_color #006600;"
        "@define-color theme_selected_bg_color #336699;");
  theme(argv[1], "BusyMarkHostMissing", "window { color: #abcdef; }");
  g_setenv("XDG_DATA_HOME", argv[1], TRUE);
  g_setenv("GTK_THEME", "BusyMarkHostOld", TRUE);
  g_unsetenv("NO_AT_BRIDGE");
  g_setenv("GTK_MODULES", "gail:atk-bridge", TRUE);
  gtk_init(&argc, &argv);
  g_unsetenv("GTK_THEME");
  auto* settings = gtk_settings_get_default();
  g_object_set(settings, "gtk-theme-name", "BusyMarkHostOld",
                "gtk-application-prefer-dark-theme", FALSE, nullptr);
  {
    Harness test;
    g_autoptr(FlMethodResponse) snapshot = test.call(kMethods, "getAccent");
    payload(snapshot, true, 0.2, 0.4, 0.6);
    g_autoptr(FlMethodResponse) unknown = test.call(kMethods, "unknown");
    g_assert_true(FL_IS_METHOD_NOT_IMPLEMENTED_RESPONSE(unknown));
    g_print("PASS production getAccent method and exact standard-codec payload\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkHostModern", nullptr);
    drain();
    test.listen();
    test.event(true, 0, 0.4, 0);
    g_assert_cmpuint(test.messenger->events->len, ==, 1);
    g_object_set(settings, "gtk-theme-name", "BusyMarkHostOld", nullptr);
    drain();
    test.event(true, 0.2, 0.4, 0.6);
    g_object_set(settings, "gtk-application-prefer-dark-theme", TRUE, nullptr);
    drain();
    test.event(true, 119.0 / 255, 100.0 / 255, 216.0 / 255);
    g_assert_cmpuint(test.messenger->events->len, ==, 3);
    g_object_set(settings, "gtk-application-prefer-dark-theme", TRUE, nullptr);
    drain();
    g_assert_cmpuint(test.messenger->events->len, ==, 3);
    g_object_set(settings, "gtk-theme-name", "BusyMarkHostMissing", nullptr);
    drain();
    test.event(false);
    g_autoptr(FlMethodResponse) unavailable = test.call(kMethods, "getAccent");
    payload(unavailable, false);
    g_assert_cmpuint(test.messenger->events->len, ==, 4);
    g_print("PASS actual event channel replay, live GTK/dark changes and unavailability\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkHostModern", nullptr);
    test.cancel();  // A refresh is queued but must not reach the channel.
    drain();
    g_assert_cmpuint(test.messenger->events->len, ==, 4);
    test.listen();
    test.event(true, 0, 0.4, 0);
    g_assert_cmpuint(test.messenger->events->len, ==, 5);
    g_print("PASS channel cancellation and current-state reattachment\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkHostOld", nullptr);
    test.stop();
    drain();
    test.detached();
    g_assert_cmpuint(test.messenger->events->len, ==, 5);
    g_print("PASS host free cancels queued refresh and detaches channel callbacks\n");
  }
  for (bool window_first : {true, false}) {
    g_object_set(settings, "gtk-theme-name", "BusyMarkHostOld", nullptr);
    Harness test;
    test.listen();
    g_object_set(settings, "gtk-theme-name", "BusyMarkHostModern", nullptr);
    gtk_widget_destroy(window_first ? test.window : GTK_WIDGET(test.view));
    drain();
    test.detached();
    g_assert_cmpuint(test.messenger->events->len, ==, 1);
    gtk_widget_destroy(window_first ? GTK_WIDGET(test.view) : test.window);
    test.stop();  // Cleanup after both widget destroy signals is safe.
    drain();
    g_assert_cmpuint(test.messenger->events->len, ==, 1);
    g_print("PASS %s destruction, subsequent cleanup and no events after shutdown\n",
            window_first ? "window-first" : "view-first");
  }
  busymark_gtk_accent_host_free(nullptr);
  g_print("PASS Flutter messenger shutdown releases both channel objects\n");
  return 0;
}
