#include "linux_chrome_host.h"

#include "gtk_header_icons.h"
#include "gtk_window_preferences.h"

#include <cstring>

struct BusyMarkLinuxChromeHost {
  GtkWindow* window;
  GtkSettings* settings;
  void (*set_theme)(gboolean);
  FlMethodChannel* settings_channel;
  FlMethodChannel* icons_channel;
  FlEventChannel* preferences_channel;
  FlEventChannel* animations_channel;
  FlEventChannel* icons_changed_channel;
  BusyMarkGtkWindowPreferencesWatcher* preferences;
  BusyMarkGtkHeaderIcons* icons;
  gulong animation_signal = 0;
  bool preferences_listening = false;
  bool animations_listening = false;
  bool icons_listening = false;
  gint64 icons_revision = 0;
};

static FlValue* preferences_value(BusyMarkLinuxChromeHost* host) {
  const auto preferences = host->preferences->Read();
  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(value, "decorationLayout",
      fl_value_new_string(preferences.decoration_layout.c_str()));
  fl_value_set_string_take(value, "doubleClick",
      fl_value_new_string(preferences.double_click.c_str()));
  fl_value_set_string_take(value, "middleClick",
      fl_value_new_string(preferences.middle_click.c_str()));
  fl_value_set_string_take(value, "rightClick",
      fl_value_new_string(preferences.right_click.c_str()));
  return value;
}

static FlValue* animations_value(BusyMarkLinuxChromeHost* host) {
  gboolean enabled = TRUE;
  if (host->settings != nullptr) {
    g_object_get(host->settings, "gtk-enable-animations", &enabled, nullptr);
  }
  return fl_value_new_bool(enabled);
}

static void send_preferences(BusyMarkLinuxChromeHost* host) {
  if (!host->preferences_listening) return;
  g_autoptr(FlValue) value = preferences_value(host);
  fl_event_channel_send(host->preferences_channel, value, nullptr, nullptr);
}

static void send_animations(BusyMarkLinuxChromeHost* host) {
  if (!host->animations_listening) return;
  g_autoptr(FlValue) value = animations_value(host);
  fl_event_channel_send(host->animations_channel, value, nullptr, nullptr);
}

static void animation_changed(GObject*, GParamSpec*, gpointer data) {
  send_animations(static_cast<BusyMarkLinuxChromeHost*>(data));
}

static FlMethodErrorResponse* preferences_listen(FlEventChannel*, FlValue*, gpointer data) {
  auto* host = static_cast<BusyMarkLinuxChromeHost*>(data);
  host->preferences_listening = true;
  send_preferences(host);
  return nullptr;
}
static FlMethodErrorResponse* preferences_cancel(FlEventChannel*, FlValue*, gpointer data) {
  static_cast<BusyMarkLinuxChromeHost*>(data)->preferences_listening = false;
  return nullptr;
}
static FlMethodErrorResponse* animations_listen(FlEventChannel*, FlValue*, gpointer data) {
  auto* host = static_cast<BusyMarkLinuxChromeHost*>(data);
  host->animations_listening = true;
  send_animations(host);
  return nullptr;
}
static FlMethodErrorResponse* animations_cancel(FlEventChannel*, FlValue*, gpointer data) {
  static_cast<BusyMarkLinuxChromeHost*>(data)->animations_listening = false;
  return nullptr;
}

static void settings_call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* host = static_cast<BusyMarkLinuxChromeHost*>(data);
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlValue) result = nullptr;
  if (strcmp(method, "getGtkWindowPreferences") == 0) {
    result = preferences_value(host);
  } else if (strcmp(method, "getGtkAnimationsEnabled") == 0) {
    result = animations_value(host);
  } else if (strcmp(method, "lowerWindow") == 0) {
    GdkWindow* window = gtk_widget_get_window(GTK_WIDGET(host->window));
    if (window != nullptr) gdk_window_lower(window);
  } else if (strcmp(method, "setPreferDark") == 0) {
    FlValue* value = fl_method_call_get_args(call);
    if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
      fl_method_call_respond_error(call, "invalid-arguments", "Expected a boolean theme preference.", nullptr, nullptr);
      return;
    }
    host->set_theme(fl_value_get_bool(value));
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  fl_method_call_respond_success(call, result, nullptr);
}

// The icon method/event handlers below resolve native artwork; they never
// receive application-header or sidebar layout coordinates.
static void send_icons_changed_event(BusyMarkLinuxChromeHost* self) {
  if (!self->icons_listening ||
      self->icons_changed_channel == nullptr ||
      self->icons == nullptr) {
    return;
  }
  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(
      event, "revision",
      fl_value_new_int(self->icons_revision));
  fl_value_set_string_take(event, "scale",
                           fl_value_new_int(self->icons->scale()));
  g_autoptr(GError) error = nullptr;
  if (!fl_event_channel_send(self->icons_changed_channel,
                             event, nullptr, &error)) {
    const gchar* message = error != nullptr ? error->message : "unknown error";
    g_warning("Failed to send GTK header-icon invalidation: %s", message);
  }
}

static FlMethodErrorResponse* icons_listen_cb(
    FlEventChannel*, FlValue*, gpointer user_data) {
  auto* self = static_cast<BusyMarkLinuxChromeHost*>(user_data);
  self->icons_listening = TRUE;
  if (self->icons_revision > 0) {
    send_icons_changed_event(self);
  }
  return nullptr;
}

static FlMethodErrorResponse* icons_cancel_cb(
    FlEventChannel*, FlValue*, gpointer user_data) {
  auto* self = static_cast<BusyMarkLinuxChromeHost*>(user_data);
  self->icons_listening = FALSE;
  return nullptr;
}

static gboolean parse_gtk_header_icon_request(
    FlValue* request,
    const gchar** key_out,
    std::vector<std::string>* names_out,
    BusyMarkGtkIconDirection* direction_out,
    gboolean* allow_missing_out) {
  if (request == nullptr || fl_value_get_type(request) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* key = fl_value_lookup_string(request, "key");
  FlValue* names = fl_value_lookup_string(request, "names");
  FlValue* direction = fl_value_lookup_string(request, "direction");
  FlValue* allow_missing = fl_value_lookup_string(request, "allowMissing");
  if (key == nullptr || fl_value_get_type(key) != FL_VALUE_TYPE_STRING ||
      names == nullptr || fl_value_get_type(names) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(names) == 0 || direction == nullptr ||
      fl_value_get_type(direction) != FL_VALUE_TYPE_STRING ||
      (allow_missing != nullptr &&
       fl_value_get_type(allow_missing) != FL_VALUE_TYPE_BOOL)) {
    return FALSE;
  }
  names_out->clear();
  for (size_t index = 0; index < fl_value_get_length(names); index++) {
    FlValue* name = fl_value_get_list_value(names, index);
    if (name == nullptr || fl_value_get_type(name) != FL_VALUE_TYPE_STRING) {
      return FALSE;
    }
    names_out->emplace_back(fl_value_get_string(name));
  }
  const gchar* direction_value = fl_value_get_string(direction);
  if (g_strcmp0(direction_value, "ltr") == 0) {
    *direction_out = BusyMarkGtkIconDirection::kLtr;
  } else if (g_strcmp0(direction_value, "rtl") == 0) {
    *direction_out = BusyMarkGtkIconDirection::kRtl;
  } else {
    return FALSE;
  }
  *allow_missing_out =
      allow_missing == nullptr ? FALSE : fl_value_get_bool(allow_missing);
  *key_out = fl_value_get_string(key);
  return TRUE;
}

static FlValue* gtk_header_icon_asset_to_fl_value(
    const BusyMarkGtkHeaderIconAsset& asset) {
  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(
      value, "bytes",
      fl_value_new_uint8_list(asset.png_bytes.data(), asset.png_bytes.size()));
  fl_value_set_string_take(
      value, "resolvedName",
      fl_value_new_string(asset.resolved_name.c_str()));
  fl_value_set_string_take(value, "scale", fl_value_new_int(asset.scale));
  fl_value_set_string_take(value, "pixelWidth",
                           fl_value_new_int(asset.pixel_width));
  fl_value_set_string_take(value, "pixelHeight",
                           fl_value_new_int(asset.pixel_height));
  return value;
}

static void icons_method_call_cb(FlMethodChannel*,
                                            FlMethodCall* method_call,
                                            gpointer user_data) {
  auto* self = static_cast<BusyMarkLinuxChromeHost*>(user_data);
  if (g_strcmp0(fl_method_call_get_name(method_call), "loadIcons") != 0) {
    fl_method_call_respond_not_implemented(method_call, nullptr);
    return;
  }
  FlValue* requests = fl_method_call_get_args(method_call);
  if (requests == nullptr ||
      fl_value_get_type(requests) != FL_VALUE_TYPE_LIST) {
    fl_method_call_respond_error(
        method_call, "invalid-arguments",
        "loadIcons requires a list of keyed icon requests.", nullptr,
        nullptr);
    return;
  }

  g_autoptr(FlValue) result = fl_value_new_map();
  for (size_t index = 0; index < fl_value_get_length(requests); index++) {
    const gchar* key = nullptr;
    std::vector<std::string> names;
    BusyMarkGtkIconDirection direction = BusyMarkGtkIconDirection::kLtr;
    gboolean allow_missing = FALSE;
    if (!parse_gtk_header_icon_request(
            fl_value_get_list_value(requests, index), &key, &names,
            &direction, &allow_missing)) {
      fl_method_call_respond_error(
          method_call, "invalid-arguments",
          "Each icon request requires key, non-empty names, ltr/rtl "
          "direction, and an optional boolean allowMissing.",
          nullptr, nullptr);
      return;
    }
    const auto asset = self->icons->Load(
        names, direction, 0, allow_missing);
    if (asset) {
      fl_value_set_string_take(
          result, key, gtk_header_icon_asset_to_fl_value(*asset));
    } else {
      fl_value_set_string_take(result, key, fl_value_new_null());
    }
  }
  fl_method_call_respond_success(method_call, result, nullptr);
}


BusyMarkLinuxChromeHost* busymark_linux_chrome_host_new(
    FlView* view, GtkWindow* window, void (*set_theme)(gboolean)) {
  auto* host = new BusyMarkLinuxChromeHost{};
  host->window = window;
  host->settings = gtk_settings_get_default();
  host->set_theme = set_theme;
  host->preferences = new BusyMarkGtkWindowPreferencesWatcher(host->settings);
  host->icons = new BusyMarkGtkHeaderIcons(GTK_WIDGET(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(fl_view_get_engine(view));
  host->settings_channel = fl_method_channel_new(messenger, "com.busymark.app/linux_chrome", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(host->settings_channel, settings_call, host, nullptr);
  host->icons_channel = fl_method_channel_new(messenger, "com.busymark.app/gtk_header_icons", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(host->icons_channel, icons_method_call_cb, host, nullptr);
  host->preferences_channel = fl_event_channel_new(messenger, "com.busymark.app/gtk_window_preferences", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(host->preferences_channel, preferences_listen, preferences_cancel, host, nullptr);
  host->animations_channel = fl_event_channel_new(messenger, "com.busymark.app/gtk_animation_settings", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(host->animations_channel, animations_listen, animations_cancel, host, nullptr);
  host->icons_changed_channel = fl_event_channel_new(messenger, "com.busymark.app/gtk_header_icons_changed", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(host->icons_changed_channel, icons_listen_cb, icons_cancel_cb, host, nullptr);
  host->preferences->Start([host](const auto&) { send_preferences(host); });
  host->icons->Start([host]() {
    host->icons_revision++;
    send_icons_changed_event(host);
  });
  if (host->settings != nullptr) {
    host->animation_signal = g_signal_connect(host->settings, "notify::gtk-enable-animations", G_CALLBACK(animation_changed), host);
  }
  return host;
}

void busymark_linux_chrome_host_free(BusyMarkLinuxChromeHost* host) {
  if (host == nullptr) return;
  if (host->animation_signal != 0 && host->settings != nullptr) {
    g_signal_handler_disconnect(host->settings, host->animation_signal);
  }
  delete host->preferences;
  delete host->icons;
  g_clear_object(&host->settings_channel);
  g_clear_object(&host->icons_channel);
  g_clear_object(&host->preferences_channel);
  g_clear_object(&host->animations_channel);
  g_clear_object(&host->icons_changed_channel);
  delete host;
}
