// Exercise the pinned plugin implementation with a controlled registrar view.
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <initializer_list>

static GtkWidget* current_view;
static const char* current_method = "state";
static FlValue* current_args;
static FlMethodResponse* last_response;
static int sent_events;

static FlView* test_get_view(FlPluginRegistrar*) {
  return reinterpret_cast<FlView*>(current_view);
}
static const gchar* test_get_name(FlMethodCall*) { return current_method; }
static FlValue* test_get_args(FlMethodCall*) { return current_args; }
static gboolean test_respond(FlMethodCall*, FlMethodResponse* response, GError**) {
  g_set_object(&last_response, response);
  return TRUE;
}
static gboolean test_send(FlEventChannel*, FlValue*, GCancellable*, GError**) {
  ++sent_events;
  return TRUE;
}

#define fl_plugin_registrar_get_view test_get_view
#define fl_method_call_get_name test_get_name
#define fl_method_call_get_args test_get_args
#define fl_method_call_respond test_respond
#define fl_event_channel_send test_send
#include "yaru_window.cc"
#include "yaru_window_linux_plugin.cc"

static YaruWindowLinuxPlugin* make_plugin() {
  return YARU_WINDOW_LINUX_PLUGIN(
      g_object_new(yaru_window_linux_plugin_get_type(), nullptr));
}

static void request(YaruWindowLinuxPlugin* plugin, const char* method) {
  current_method = method;
  yaru_window_linux_plugin_handle_method_call(plugin, nullptr);
}

static void assert_unavailable() {
  g_assert_true(FL_IS_METHOD_ERROR_RESPONSE(last_response));
  g_assert_cmpstr(fl_method_error_response_get_code(
                      FL_METHOD_ERROR_RESPONSE(last_response)),
                  ==, "window-unavailable");
}

static void absent_view() {
  g_autoptr(YaruWindowLinuxPlugin) plugin = make_plugin();
  current_view = nullptr;
  for (const char* method : {"state", "init", "close", "show", "hide"}) {
    request(plugin, method);
    assert_unavailable();
  }
  g_autoptr(FlMethodErrorResponse) error = listen_state_cb(nullptr, nullptr, plugin);
  g_assert_nonnull(error);
  g_assert_cmpstr(fl_method_error_response_get_code(error), ==, "window-unavailable");
  g_hash_table_insert(plugin->signals, GINT_TO_POINTER(0), nullptr);
  g_assert_null(cancel_state_cb(nullptr, nullptr, plugin));
  g_assert_cmpuint(g_hash_table_size(plugin->signals), ==, 0);
  g_assert_null(cancel_state_cb(nullptr, nullptr, plugin));
}

static void surface_lifecycle() {
  g_autoptr(YaruWindowLinuxPlugin) plugin = make_plugin();
  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_object_ref_sink(window);
  GtkWidget* child = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  g_object_ref_sink(child);
  current_view = child;
  request(plugin, "state");  // Detached view has no GtkWindow ancestor.
  assert_unavailable();
  gtk_container_add(GTK_CONTAINER(window), child);
  request(plugin, "state");  // Window exists, but GDK is not realized.
  assert_unavailable();
  gtk_widget_show_all(window);
  request(plugin, "state");
  g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(last_response));
  gtk_widget_unrealize(window);
  request(plugin, "state");
  assert_unavailable();
  g_signal_connect(window, "destroy", G_CALLBACK(+[](GtkWidget*, gpointer data) {
                     request(YARU_WINDOW_LINUX_PLUGIN(data), "state");
                     assert_unavailable();
                   }), plugin);
  gtk_widget_destroy(window);
  request(plugin, "state");
  assert_unavailable();
  current_view = nullptr;
  g_object_unref(child);
  g_object_unref(window);
}

static void notification_retirement() {
  g_autoptr(YaruWindowLinuxPlugin) plugin = make_plugin();
  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_object_ref_sink(window);
  GtkWidget* child = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  g_object_ref_sink(child);
  gtk_container_add(GTK_CONTAINER(window), child);
  current_view = child;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlEventChannel) channel = fl_event_channel_new(
      fl_engine_get_binary_messenger(engine), "test/yaru", FL_METHOD_CODEC(codec));
  plugin->event_channel = FL_EVENT_CHANNEL(g_object_ref(channel));
  sent_events = 0;
  window_property_cb(GTK_WINDOW(window), nullptr, channel);
  g_assert_cmpint(sent_events, ==, 0);
  gtk_widget_show_all(window);
  g_assert_null(listen_state_cb(nullptr, nullptr, plugin));
  g_assert_cmpuint(g_hash_table_size(plugin->signals), ==, 1);
  window_property_cb(GTK_WINDOW(window), nullptr, channel);
  g_assert_cmpint(sent_events, ==, 1);
  gtk_widget_destroy(window);
  current_view = nullptr;
  g_assert_null(cancel_state_cb(nullptr, nullptr, plugin));
  g_assert_cmpuint(g_hash_table_size(plugin->signals), ==, 0);
  window_state_cb(window, nullptr, channel);
  g_assert_cmpint(sent_events, ==, 1);
  g_object_unref(window);
  g_object_unref(child);
  g_assert_null(yaru_window_get_state(nullptr));
}

int main(int argc, char** argv) {
  gtk_test_init(&argc, &argv, nullptr);
  current_args = fl_value_new_list();
  fl_value_append_take(current_args, fl_value_new_int(0));
  g_test_add_func("/yaru/absent-view", absent_view);
  g_test_add_func("/yaru/surface-lifecycle", surface_lifecycle);
  g_test_add_func("/yaru/notification-retirement", notification_retirement);
  int result = g_test_run();
  g_clear_object(&last_response);
  fl_value_unref(current_args);
  return result;
}
