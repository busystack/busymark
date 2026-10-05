#include "gtk_accent_host.h"
#include "gtk_accent.h"

#include <cstring>
#include <memory>

struct BusyMarkGtkAccentHost {
  std::unique_ptr<busymark::GtkAccentObserver> observer;
  FlMethodChannel* methods = nullptr;
  FlEventChannel* events = nullptr;
  GtkWidget* window = nullptr;
  GtkWidget* view = nullptr;
  gulong window_destroy = 0;
  gulong view_destroy = 0;
};

static FlValue* accent_payload(const busymark::GtkAccent& accent) {
  FlValue* result = fl_value_new_map();
  fl_value_set_string_take(result, "available",
                           fl_value_new_bool(accent.available));
  if (accent.available) {
    FlValue* rgb = fl_value_new_list();
    fl_value_append_take(rgb, fl_value_new_float(accent.rgba.red));
    fl_value_append_take(rgb, fl_value_new_float(accent.rgba.green));
    fl_value_append_take(rgb, fl_value_new_float(accent.rgba.blue));
    fl_value_set_string_take(result, "rgb", rgb);
  }
  return result;
}

static void accent_method(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* host = static_cast<BusyMarkGtkAccentHost*>(data);
  if (std::strcmp(fl_method_call_get_name(call), "getAccent") != 0) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  g_autoptr(FlValue) payload = accent_payload(host->observer->Read());
  fl_method_call_respond_success(call, payload, nullptr);
}

static FlMethodErrorResponse* accent_listen(FlEventChannel*, FlValue*,
                                            gpointer data) {
  auto* host = static_cast<BusyMarkGtkAccentHost*>(data);
  host->observer->Listen([host](const busymark::GtkAccent& accent) {
    g_autoptr(FlValue) payload = accent_payload(accent);
    fl_event_channel_send(host->events, payload, nullptr, nullptr);
  });
  return nullptr;
}

static FlMethodErrorResponse* accent_cancel(FlEventChannel*, FlValue*,
                                            gpointer data) {
  static_cast<BusyMarkGtkAccentHost*>(data)->observer->Cancel();
  return nullptr;
}

static void shutdown_accent_host(BusyMarkGtkAccentHost* host) {
  // Stop queued GTK work before either the window or Flutter engine disappears.
  host->observer.reset();
  if (host->methods != nullptr) {
    fl_method_channel_set_method_call_handler(host->methods, nullptr, nullptr,
                                               nullptr);
  }
  if (host->events != nullptr) {
    fl_event_channel_set_stream_handlers(host->events, nullptr, nullptr, nullptr,
                                          nullptr);
  }
  g_clear_object(&host->methods);
  g_clear_object(&host->events);
  if (host->window != nullptr) {
    g_signal_handler_disconnect(host->window, host->window_destroy);
    host->window = nullptr;
  }
  if (host->view != nullptr) {
    g_signal_handler_disconnect(host->view, host->view_destroy);
    host->view = nullptr;
  }
}

static void widget_destroyed(GtkWidget*, gpointer data) {
  shutdown_accent_host(static_cast<BusyMarkGtkAccentHost*>(data));
}

BusyMarkGtkAccentHost* busymark_gtk_accent_host_new(FlView* view,
                                                  GtkWidget* window) {
  auto* host = new BusyMarkGtkAccentHost();
  host->observer = std::make_unique<busymark::GtkAccentObserver>(window);
  host->window = window;
  host->view = GTK_WIDGET(view);
  host->window_destroy = g_signal_connect(window, "destroy",
                                         G_CALLBACK(widget_destroyed), host);
  host->view_destroy = g_signal_connect(view, "destroy",
                                       G_CALLBACK(widget_destroyed), host);
  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  host->methods = fl_method_channel_new(messenger, "com.busymark.app/gtk_accent",
                                        FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(host->methods, accent_method, host,
                                             nullptr);
  host->events = fl_event_channel_new(
      messenger, "com.busymark.app/gtk_accent/events", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(host->events, accent_listen, accent_cancel,
                                        host, nullptr);
  return host;
}

void busymark_gtk_accent_host_free(BusyMarkGtkAccentHost* host) {
  if (host == nullptr) return;
  shutdown_accent_host(host);
  delete host;
}
