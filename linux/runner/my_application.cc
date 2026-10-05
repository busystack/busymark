#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <handy.h>
#include <pango/pango.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>

#include "flutter/generated_plugin_registrant.h"
#include "gtk_accent_host.h"
#include "linux_chrome_host.h"
#include "rich_clipboard_host.h"
#include "secure_credential_host.h"
#include "video_player_host.h"
#include "web_render_host.h"
#include "writerside_dialog_host.h"

constexpr char kApplicationDisplayName[] = "BusyMark";
constexpr char kNativeMenuChannel[] = "busymark/native_menus";
constexpr char kGitBranchMenuIcon[] = "busymark-git-branch-symbolic";
constexpr char kAssetInputChannel[] = "com.busymark.app/asset_input";
constexpr char kMenuAccelAttribute[] = "accel";
constexpr char kNativeMenuActionNamespace[] = "busymark-native-menu";
constexpr char kNativeMenuActionIndexKey[] = "busymark-native-menu-index";
constexpr char kLegacyYaruWindowShadowCompatibilityCss[] =
    "window#busymark-window:not(.solid-csd):not(.maximized):"
    "not(.fullscreen):not(.tiled):not(.tiled-top):not(.tiled-right):"
    "not(.tiled-bottom):not(.tiled-left) > decoration {"
    "box-shadow: 0 3px 9px 1px rgba(0,0,0,0.5);"
    "}"
    "window#busymark-window:not(.solid-csd):not(.maximized):"
    "not(.fullscreen):not(.tiled):not(.tiled-top):not(.tiled-right):"
    "not(.tiled-bottom):not(.tiled-left) > decoration:backdrop {"
    "box-shadow: 0 3px 9px 1px transparent,"
    "0 2px 6px 2px rgba(0,0,0,0.2);"
    "}"
    "window#busymark-window.tiled:not(.solid-csd):not(.maximized):"
    "not(.fullscreen) > decoration,"
    "window#busymark-window.tiled-top:not(.solid-csd):not(.maximized):"
    "not(.fullscreen) > decoration,"
    "window#busymark-window.tiled-right:not(.solid-csd):not(.maximized):"
    "not(.fullscreen) > decoration,"
    "window#busymark-window.tiled-bottom:not(.solid-csd):not(.maximized):"
    "not(.fullscreen) > decoration,"
    "window#busymark-window.tiled-left:not(.solid-csd):not(.maximized):"
    "not(.fullscreen) > decoration {"
    "box-shadow: 0 0 0 20px transparent;"
    "}";

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  BusyMarkGtkAccentHost* gtk_accent_host;
  BusyMarkLinuxChromeHost* chrome_host;
  FlMethodChannel* native_menu_channel;
  FlMethodChannel* writerside_dialog_channel;
  FlMethodChannel* asset_input_channel;
  FlMethodChannel* secure_credential_channel;
  FlMethodChannel* rich_clipboard_channel;
  BusyMarkWebRenderHost* visualization_host;
  BusyMarkVideoPlayerHost* video_player_host;
  GtkCssProvider* native_surface_css_provider;
  GtkWindow* main_window;
  GtkWidget* flutter_view;
  GtkWidget* flutter_overlay;
};
G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static gchar* gtk_accelerator_from_shortcut_label(const gchar* shortcut) {
  if (shortcut == nullptr || shortcut[0] == '\0') {
    return nullptr;
  }

  guint key = 0;
  GdkModifierType modifiers = static_cast<GdkModifierType>(0);
  gtk_accelerator_parse(shortcut, &key, &modifiers);
  if (key != 0) {
    return g_strdup(shortcut);
  }

  gchar** parts = g_strsplit(shortcut, "+", -1);
  const gsize part_count = g_strv_length(parts);
  GString* accelerator = g_string_new(nullptr);
  gboolean valid = part_count > 0;
  for (gsize index = 0; valid && index + 1 < part_count; index++) {
    const gchar* part = g_strstrip(parts[index]);
    if (g_strcmp0(part, "Ctrl") == 0 ||
        g_strcmp0(part, "Control") == 0) {
      g_string_append(accelerator, "<Control>");
    } else if (g_strcmp0(part, "Alt") == 0) {
      g_string_append(accelerator, "<Alt>");
    } else if (g_strcmp0(part, "Shift") == 0) {
      g_string_append(accelerator, "<Shift>");
    } else if (g_strcmp0(part, "Super") == 0) {
      g_string_append(accelerator, "<Super>");
    } else if (g_strcmp0(part, "Meta") == 0) {
      g_string_append(accelerator, "<Meta>");
    } else {
      valid = FALSE;
    }
  }
  if (valid) {
    const gchar* key_label = g_strstrip(parts[part_count - 1]);
    g_string_append(accelerator,
                    g_strcmp0(key_label, "Esc") == 0 ? "Escape" : key_label);
    key = 0;
    modifiers = static_cast<GdkModifierType>(0);
    gtk_accelerator_parse(accelerator->str, &key, &modifiers);
    valid = key != 0;
  }

  g_strfreev(parts);
  return g_string_free(accelerator, !valid);
}

static void set_menu_item_accelerator(GMenuItem* item,
                                      const gchar* shortcut) {
  g_autofree gchar* accelerator =
      gtk_accelerator_from_shortcut_label(shortcut);
  if (accelerator != nullptr) {
    g_menu_item_set_attribute(item, kMenuAccelAttribute, "s", accelerator);
  }
}

static GdkPixbuf* load_application_icon_at_size(gint size) {
  g_autofree gchar* executable_path =
      g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) {
    return nullptr;
  }

  g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
  g_autofree gchar* icon_path =
      g_build_filename(executable_dir, "data", "flutter_assets", "assets",
                       "branding", "busymark_logo.svg", nullptr);

  g_autoptr(GError) error = nullptr;
  GdkPixbuf* icon =
      gdk_pixbuf_new_from_file_at_size(icon_path, size, size, &error);
  if (icon == nullptr) {
    const gchar* message = error != nullptr ? error->message : "unknown error";
    g_warning("Failed to load application icon: %s", message);
  }
  return icon;
}

static GdkPixbuf* load_application_icon() {
  return load_application_icon_at_size(256);
}

static gboolean gtk_theme_exists_in_data_dir(const gchar* data_dir,
                                             const gchar* theme_name) {
  if (data_dir == nullptr || theme_name == nullptr || theme_name[0] == '\0') {
    return FALSE;
  }
  g_autofree gchar* css_path =
      g_build_filename(data_dir, "themes", theme_name, "gtk-3.0", "gtk.css",
                       nullptr);
  return g_file_test(css_path, G_FILE_TEST_IS_REGULAR);
}

static gboolean gtk_theme_exists(const gchar* theme_name) {
  if (gtk_theme_exists_in_data_dir(g_get_user_data_dir(), theme_name)) {
    return TRUE;
  }
  const gchar* const* data_dirs = g_get_system_data_dirs();
  for (gint i = 0; data_dirs != nullptr && data_dirs[i] != nullptr; ++i) {
    if (gtk_theme_exists_in_data_dir(data_dirs[i], theme_name)) {
      return TRUE;
    }
  }
  return FALSE;
}

static gboolean icon_theme_exists_in_data_dir(const gchar* data_dir,
                                              const gchar* theme_name) {
  if (data_dir == nullptr || theme_name == nullptr || theme_name[0] == '\0') {
    return FALSE;
  }
  g_autofree gchar* index_path =
      g_build_filename(data_dir, "icons", theme_name, "index.theme", nullptr);
  return g_file_test(index_path, G_FILE_TEST_IS_REGULAR);
}

static gboolean icon_theme_exists(const gchar* theme_name) {
  if (icon_theme_exists_in_data_dir(g_get_user_data_dir(), theme_name)) {
    return TRUE;
  }
  const gchar* const* data_dirs = g_get_system_data_dirs();
  for (gint i = 0; data_dirs != nullptr && data_dirs[i] != nullptr; ++i) {
    if (icon_theme_exists_in_data_dir(data_dirs[i], theme_name)) {
      return TRUE;
    }
  }
  return FALSE;
}

static const gchar* available_gtk_theme_fallback(gboolean prefer_dark) {
  const gchar* primary = prefer_dark ? "Yaru-dark" : "Yaru";
  if (gtk_theme_exists(primary)) {
    return primary;
  }
  const gchar* secondary = prefer_dark ? "Adwaita-dark" : "Adwaita";
  return gtk_theme_exists(secondary) ? secondary : nullptr;
}

static const gchar* available_icon_theme_fallback(gboolean prefer_dark) {
  const gchar* primary = prefer_dark ? "Yaru-dark" : "Yaru";
  if (icon_theme_exists(primary)) {
    return primary;
  }
  return icon_theme_exists("Adwaita") ? "Adwaita" : nullptr;
}

static void set_gtk_theme_preference(gboolean prefer_dark) {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    g_object_set(settings, "gtk-application-prefer-dark-theme", prefer_dark,
                 nullptr);

    g_autofree gchar* theme_name = nullptr;
    g_object_get(settings, "gtk-theme-name", &theme_name, nullptr);
    const gchar* fallback = available_gtk_theme_fallback(prefer_dark);
    if (fallback != nullptr && !gtk_theme_exists(theme_name)) {
      g_object_set(settings, "gtk-theme-name", fallback, nullptr);
    }

    g_autofree gchar* icon_theme_name = nullptr;
    g_object_get(settings, "gtk-icon-theme-name", &icon_theme_name, nullptr);
    const gchar* icon_fallback = available_icon_theme_fallback(prefer_dark);
    if (icon_fallback != nullptr && !icon_theme_exists(icon_theme_name)) {
      g_object_set(settings, "gtk-icon-theme-name", icon_fallback, nullptr);
    }
  }
}

static gboolean uses_legacy_yaru_window_shadow() {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings == nullptr) {
    return FALSE;
  }

  g_autofree gchar* theme_name = nullptr;
  g_object_get(settings, "gtk-theme-name", &theme_name, nullptr);
  if (theme_name == nullptr) {
    return FALSE;
  }

  g_autofree gchar* normalized_theme = g_ascii_strdown(theme_name, -1);
  const gboolean is_yaru =
      g_strcmp0(normalized_theme, "yaru") == 0 ||
      g_str_has_prefix(normalized_theme, "yaru-");
  return is_yaru && strstr(normalized_theme, "highcontrast") == nullptr &&
         strstr(normalized_theme, "high-contrast") == nullptr;
}

static void respond_bool(FlMethodCall* method_call, gboolean value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  fl_method_call_respond_success(method_call, result, nullptr);
}

static const gchar* fl_lookup_string_arg(FlValue* args, const gchar* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return fl_value_get_string(value);
}

static gboolean fl_lookup_int64_arg(FlValue* args,
                                    const gchar* key,
                                    gint64* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_INT) {
    return FALSE;
  }
  *value_out = fl_value_get_int(value);
  return TRUE;
}

static gboolean fl_lookup_double_arg(FlValue* args,
                                     const gchar* key,
                                     gdouble* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) {
    return FALSE;
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) {
    *value_out = fl_value_get_float(value);
    return TRUE;
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) {
    *value_out = static_cast<gdouble>(fl_value_get_int(value));
    return TRUE;
  }
  return FALSE;
}

static FlValue* fl_lookup_map_arg(FlValue* args, const gchar* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_MAP
             ? value
             : nullptr;
}
struct NativeMenuHandlerData;

struct NativeMenuSession {
  NativeMenuHandlerData* owner;
  gint64 id;
  GtkWidget* menu;
  GMenu* model;
  GSimpleActionGroup* action_group;
  FlMethodCall* method_call;
  gulong deactivate_signal_id;
  guint cleanup_source_id;
  gint pending_selected_index;
};

struct NativeMenuHandlerData {
  GtkWidget* view;
  NativeMenuSession* active;
  GdkEvent* trigger_event;
  gulong event_signal_id;
};

static gboolean native_menu_capture_trigger_event(GtkWidget*,
                                                  GdkEvent* event,
                                                  gpointer user_data) {
  auto* data = static_cast<NativeMenuHandlerData*>(user_data);
  if (event == nullptr ||
      (event->type != GDK_BUTTON_PRESS && event->type != GDK_KEY_PRESS &&
       event->type != GDK_TOUCH_BEGIN)) {
    return GDK_EVENT_PROPAGATE;
  }
  g_clear_pointer(&data->trigger_event, gdk_event_free);
  data->trigger_event = gdk_event_copy(event);
  return GDK_EVENT_PROPAGATE;
}

static void native_menu_session_respond(NativeMenuSession* session,
                                        gint selected_index) {
  if (session->method_call == nullptr) {
    return;
  }
  g_autoptr(FlValue) result = selected_index < 0
                                  ? fl_value_new_null()
                                  : fl_value_new_int(selected_index);
  fl_method_call_respond_success(session->method_call, result, nullptr);
  g_clear_object(&session->method_call);
}

static void native_menu_session_dispose(NativeMenuSession* session) {
  if (session == nullptr) {
    return;
  }
  NativeMenuHandlerData* owner = session->owner;
  if (owner != nullptr && owner->active == session) {
    owner->active = nullptr;
  }
  if (session->cleanup_source_id != 0) {
    g_source_remove(session->cleanup_source_id);
    session->cleanup_source_id = 0;
  }
  if (session->menu != nullptr) {
    if (session->deactivate_signal_id != 0) {
      g_signal_handler_disconnect(session->menu,
                                  session->deactivate_signal_id);
      session->deactivate_signal_id = 0;
    }
    if (gtk_widget_get_visible(session->menu)) {
      gtk_menu_shell_deactivate(GTK_MENU_SHELL(session->menu));
    }
  }
  if (owner != nullptr && owner->view != nullptr) {
    gtk_widget_insert_action_group(owner->view,
                                   kNativeMenuActionNamespace, nullptr);
  }
  if (session->menu != nullptr && GTK_IS_MENU(session->menu) &&
      gtk_menu_get_attach_widget(GTK_MENU(session->menu)) != nullptr) {
    gtk_menu_detach(GTK_MENU(session->menu));
  }
  g_clear_object(&session->menu);

  if (owner != nullptr && owner->view != nullptr) {
    if (gtk_widget_get_realized(owner->view)) {
      gtk_widget_grab_focus(owner->view);
    }
  }
  g_clear_object(&session->model);
  g_clear_object(&session->action_group);
  native_menu_session_respond(session, session->pending_selected_index);
  g_free(session);
}

static gboolean native_menu_cleanup_idle_cb(gpointer user_data) {
  auto* session = static_cast<NativeMenuSession*>(user_data);
  session->cleanup_source_id = 0;
  native_menu_session_dispose(session);
  return G_SOURCE_REMOVE;
}

static void native_menu_deactivate_cb(GtkMenuShell*, gpointer user_data) {
  auto* session = static_cast<NativeMenuSession*>(user_data);
  if (session->cleanup_source_id == 0) {
    // GtkMenu deactivates before invoking the selected GAction. Let the
    // action run before resolving and freeing the native session.
    session->cleanup_source_id = g_idle_add_full(
        G_PRIORITY_DEFAULT_IDLE, native_menu_cleanup_idle_cb, session,
        nullptr);
  }
}

static void native_menu_action_activated_cb(GSimpleAction* action,
                                            GVariant*,
                                            gpointer user_data) {
  auto* session = static_cast<NativeMenuSession*>(user_data);
  session->pending_selected_index =
      GPOINTER_TO_INT(
          g_object_get_data(G_OBJECT(action), kNativeMenuActionIndexKey)) -
      1;
}

static void native_menu_check_activated_cb(GSimpleAction* action,
                                           GVariant*,
                                           gpointer user_data) {
  g_autoptr(GVariant) state = g_action_get_state(G_ACTION(action));
  if (state == nullptr ||
      !g_variant_is_of_type(state, G_VARIANT_TYPE_BOOLEAN)) {
    return;
  }
  g_simple_action_set_state(
      action, g_variant_new_boolean(!g_variant_get_boolean(state)));
  native_menu_action_activated_cb(action, nullptr, user_data);
}

static gboolean native_menu_dismiss_active(NativeMenuHandlerData* data,
                                           gint64 session_id) {
  NativeMenuSession* session = data->active;
  if (session == nullptr || session->id != session_id) {
    return FALSE;
  }
  if (session->menu != nullptr && gtk_widget_get_visible(session->menu)) {
    gtk_menu_shell_deactivate(GTK_MENU_SHELL(session->menu));
  } else {
    native_menu_session_dispose(session);
  }
  return TRUE;
}

static gboolean fl_lookup_optional_bool_with_default(
    FlValue* args,
    const gchar* key,
    gboolean fallback,
    gboolean* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) {
    *value_out = fallback;
    return TRUE;
  }
  if (fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return FALSE;
  }
  *value_out = fl_value_get_bool(value);
  return TRUE;
}

static gboolean fl_lookup_positive_int64_arg(FlValue* args,
                                             const gchar* key,
                                             gint64* value_out) {
  if (!fl_lookup_int64_arg(args, key, value_out) || *value_out <= 0) {
    return FALSE;
  }
  return TRUE;
}

static void respond_native_menu_argument_error(FlMethodCall* method_call,
                                               const gchar* message) {
  fl_method_call_respond_error(method_call, "invalid-arguments", message,
                               nullptr, nullptr);
}

static gboolean parse_native_menu_anchor(FlValue* args,
                                         GdkRectangle* rectangle_out) {
  FlValue* anchor = fl_lookup_map_arg(args, "anchor");
  if (anchor == nullptr) {
    return FALSE;
  }
  gdouble x = 0;
  gdouble y = 0;
  gdouble width = 0;
  gdouble height = 0;
  if (!fl_lookup_double_arg(anchor, "x", &x) ||
      !fl_lookup_double_arg(anchor, "y", &y) ||
      !fl_lookup_double_arg(anchor, "width", &width) ||
      !fl_lookup_double_arg(anchor, "height", &height) ||
      !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) ||
      !std::isfinite(height) || !std::isfinite(x + width) ||
      !std::isfinite(y + height) || width < 0 || height < 0) {
    return FALSE;
  }

  const gdouble left = std::floor(x);
  const gdouble top = std::floor(y);
  const gdouble right = std::ceil(x + width);
  const gdouble bottom = std::ceil(y + height);
  const gdouble pixel_width = std::max(1.0, right - left);
  const gdouble pixel_height = std::max(1.0, bottom - top);
  if (left < G_MININT || left > G_MAXINT || top < G_MININT ||
      top > G_MAXINT || right < G_MININT || right > G_MAXINT ||
      bottom < G_MININT || bottom > G_MAXINT || pixel_width > G_MAXINT ||
      pixel_height > G_MAXINT) {
    return FALSE;
  }

  rectangle_out->x = static_cast<gint>(left);
  rectangle_out->y = static_cast<gint>(top);
  rectangle_out->width = static_cast<gint>(pixel_width);
  rectangle_out->height = static_cast<gint>(pixel_height);
  return TRUE;
}

static GIcon* create_native_menu_icon(const gchar* icon_name, FlValue* entry) {
  if (icon_name == nullptr || icon_name[0] == '\0') {
    return nullptr;
  }

  FlValue* packed_color = fl_value_lookup_string(entry, "iconColor");
  GdkRGBA foreground = {0.5, 0.5, 0.5, 1.0};
  if (packed_color != nullptr &&
      fl_value_get_type(packed_color) == FL_VALUE_TYPE_INT) {
    const guint32 argb = static_cast<guint32>(fl_value_get_int(packed_color));
    foreground = {
        static_cast<gdouble>((argb >> 16) & 0xff) / 255.0,
        static_cast<gdouble>((argb >> 8) & 0xff) / 255.0,
        static_cast<gdouble>(argb & 0xff) / 255.0,
        static_cast<gdouble>((argb >> 24) & 0xff) / 255.0,
    };
  }

  if (g_strcmp0(icon_name, kGitBranchMenuIcon) == 0) {
    constexpr gint kIconSize = 16;
    cairo_surface_t* surface =
        cairo_image_surface_create(CAIRO_FORMAT_ARGB32, kIconSize, kIconSize);
    cairo_t* cr = cairo_create(surface);
    cairo_set_source_rgba(cr, foreground.red, foreground.green,
                          foreground.blue, foreground.alpha);
    cairo_set_line_width(cr, 1.5);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);

    cairo_move_to(cr, 4.0, 4.5);
    cairo_line_to(cr, 4.0, 11.5);
    cairo_stroke(cr);
    cairo_move_to(cr, 4.0, 7.0);
    cairo_curve_to(cr, 4.0, 5.0, 6.0, 3.0, 10.0, 3.0);
    cairo_stroke(cr);

    constexpr gdouble kFullCircle = 6.283185307179586;
    constexpr gdouble kNodes[][2] = {
        {4.0, 3.0}, {11.5, 3.0}, {4.0, 13.0}};
    for (const auto& point : kNodes) {
      cairo_arc(cr, point[0], point[1], 1.5, 0.0, kFullCircle);
      cairo_fill(cr);
    }

    cairo_destroy(cr);
    cairo_surface_flush(surface);
    GdkPixbuf* pixbuf =
        gdk_pixbuf_get_from_surface(surface, 0, 0, kIconSize, kIconSize);
    cairo_surface_destroy(surface);
    return pixbuf == nullptr ? nullptr : G_ICON(pixbuf);
  }

  if (packed_color != nullptr &&
      fl_value_get_type(packed_color) == FL_VALUE_TYPE_INT) {
    GtkIconInfo* icon_info = gtk_icon_theme_lookup_icon(
        gtk_icon_theme_get_default(), icon_name, 16,
        static_cast<GtkIconLookupFlags>(GTK_ICON_LOOKUP_FORCE_SIZE |
                                        GTK_ICON_LOOKUP_FORCE_SYMBOLIC));
    if (icon_info != nullptr) {
      gboolean was_symbolic = FALSE;
      g_autoptr(GError) error = nullptr;
      GdkPixbuf* pixbuf = gtk_icon_info_load_symbolic(
          icon_info, &foreground, nullptr, nullptr, nullptr, &was_symbolic,
          &error);
      g_object_unref(icon_info);
      if (pixbuf != nullptr) {
        return G_ICON(pixbuf);
      }
    }
  }

  return g_themed_icon_new(icon_name);
}

static gboolean validate_native_menu_entries(FlValue* entries,
                                              FlMethodCall* method_call,
                                              guint depth,
                                              size_t* entry_count) {
  if (depth > 8 || entries == nullptr ||
      fl_value_get_type(entries) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(entries) == 0 ||
      fl_value_get_length(entries) > 4096 - *entry_count) {
    respond_native_menu_argument_error(method_call, "Invalid or excessive submenu entries.");
    return FALSE;
  }
  *entry_count += fl_value_get_length(entries);
  size_t command_count = 0;
  size_t checkable_run_selected_count = 0;
  gboolean checkable_run_has_disabled_entry = FALSE;
  gboolean in_checkable_run = FALSE;
  for (size_t index = 0; index < fl_value_get_length(entries); index++) {
    FlValue* entry = fl_value_get_list_value(entries, index);
    if (entry == nullptr || fl_value_get_type(entry) != FL_VALUE_TYPE_MAP) {
      respond_native_menu_argument_error(method_call, "Menu entries must be maps.");
      return FALSE;
    }
    FlValue* children = fl_value_lookup_string(entry, "children");
    FlValue* icon_color = entry == nullptr
                              ? nullptr
                              : fl_value_lookup_string(entry, "iconColor");
    gboolean separator = FALSE;
    gboolean enabled = TRUE;
    gboolean checkable = FALSE;
    gboolean selected = FALSE;
    gboolean mutually_exclusive = FALSE;
    if (entry == nullptr || fl_value_get_type(entry) != FL_VALUE_TYPE_MAP ||
        !fl_lookup_optional_bool_with_default(entry, "separator", FALSE,
                                              &separator) ||
        !fl_lookup_optional_bool_with_default(entry, "enabled", TRUE,
                                              &enabled) ||
        !fl_lookup_optional_bool_with_default(entry, "checkable", FALSE,
                                              &checkable) ||
        !fl_lookup_optional_bool_with_default(entry, "selected", FALSE,
                                              &selected) ||
        !fl_lookup_optional_bool_with_default(entry, "mutuallyExclusive",
                                              FALSE,
                                              &mutually_exclusive) ||
        (!separator && fl_lookup_string_arg(entry, "label") == nullptr) ||
        (fl_value_lookup_string(entry, "icon") != nullptr &&
         fl_value_get_type(fl_value_lookup_string(entry, "icon")) !=
             FL_VALUE_TYPE_STRING) ||
        (icon_color != nullptr &&
         (fl_value_get_type(icon_color) != FL_VALUE_TYPE_INT ||
          fl_value_get_int(icon_color) < 0 ||
          fl_value_get_int(icon_color) >
              static_cast<gint64>(G_MAXUINT32))) ||
        (selected && !checkable) ||
        (children != nullptr && (separator || checkable)) ||
        (fl_value_lookup_string(entry, "shortcut") != nullptr &&
         fl_lookup_string_arg(entry, "shortcut") == nullptr)) {
      respond_native_menu_argument_error(
          method_call,
          "entries must contain valid command or separator presentation.");
      return FALSE;
    }
    if (children != nullptr &&
        !validate_native_menu_entries(children, method_call, depth + 1, entry_count)) {
      return FALSE;
    }
    if (!separator) {
      command_count++;
    }
    if (!separator && checkable && mutually_exclusive) {
      if (!in_checkable_run) {
        checkable_run_selected_count = 0;
        checkable_run_has_disabled_entry = FALSE;
        in_checkable_run = TRUE;
      }
      checkable_run_selected_count += selected ? 1 : 0;
      checkable_run_has_disabled_entry =
          checkable_run_has_disabled_entry || !enabled;
      continue;
    }
    if (in_checkable_run &&
        (checkable_run_selected_count > 1 ||
         checkable_run_has_disabled_entry)) {
      respond_native_menu_argument_error(
          method_call,
          "single-choice groups allow at most one selected entry and require "
          "enabled entries.");
      return FALSE;
    }
    in_checkable_run = FALSE;
  }
  if (in_checkable_run &&
      (checkable_run_selected_count > 1 ||
       checkable_run_has_disabled_entry)) {
    respond_native_menu_argument_error(
        method_call,
        "single-choice groups allow at most one selected entry and require "
        "enabled entries.");
    return FALSE;
  }
  if (command_count == 0) {
    respond_native_menu_argument_error(method_call,
                                       "entries must contain a command.");
    return FALSE;
  }

  return TRUE;
}

static gchar* escape_native_menu_label(const gchar* label) {
  GString* literal = g_string_new(nullptr);
  for (const gchar* cursor = label; *cursor != '\0'; cursor++) {
    if (*cursor == '_') {
      g_string_append_c(literal, '_');
    }
    g_string_append_c(literal, *cursor);
  }
  return g_string_free(literal, FALSE);
}

static void build_native_menu_model(FlValue* entries,
                                     NativeMenuSession* session,
                                     GMenu* model,
                                     size_t* next_index,
                                     gboolean ancestors_enabled) {
  GMenu* section = g_menu_new();
  guint section_length = 0;
  auto flush_section = [&]() {
    if (section_length > 0) {
      g_menu_append_section(model, nullptr, G_MENU_MODEL(section));
    }
    g_object_unref(section);
    section = g_menu_new();
    section_length = 0;
  };

  for (size_t index = 0; index < fl_value_get_length(entries); index++) {
    FlValue* entry = fl_value_get_list_value(entries, index);
    gboolean separator = FALSE;
    fl_lookup_optional_bool_with_default(entry, "separator", FALSE,
                                         &separator);
    if (separator) {
      flush_section();
      (*next_index)++;
      continue;
    }

    const size_t entry_index = (*next_index)++;
    const gchar* label = fl_lookup_string_arg(entry, "label");
    // GMenu's GtkMenu adapter treats underscores as mnemonic markers. Flutter
    // labels are literal presentation text, so double every underscore only at
    // this native boundary; action indexes and clipboard payloads stay intact.
    g_autofree gchar* literal_label = escape_native_menu_label(label);
    const gchar* icon_name = fl_lookup_string_arg(entry, "icon");
    const gchar* shortcut = fl_lookup_string_arg(entry, "shortcut");
    gboolean enabled = TRUE;
    gboolean checkable = FALSE;
    gboolean selected = FALSE;
    fl_lookup_optional_bool_with_default(entry, "enabled", TRUE, &enabled);
    fl_lookup_optional_bool_with_default(entry, "checkable", FALSE,
                                         &checkable);
    fl_lookup_optional_bool_with_default(entry, "selected", FALSE,
                                         &selected);

    FlValue* children = fl_value_lookup_string(entry, "children");
    if (children != nullptr) {
      g_autoptr(GMenu) submenu = g_menu_new();
      build_native_menu_model(children, session, submenu, next_index,
                              ancestors_enabled && enabled);
      g_autoptr(GMenuItem) item =
          g_menu_item_new_submenu(literal_label, G_MENU_MODEL(submenu));
      g_menu_append_item(section, item);
      section_length++;
      continue;
    }
    g_autofree gchar* action_name = g_strdup_printf("select-%zu", entry_index);
    GSimpleAction* action = checkable
                                ? g_simple_action_new_stateful(
                                      action_name, nullptr,
                                      g_variant_new_boolean(selected))
                                : g_simple_action_new(action_name, nullptr);
    g_simple_action_set_enabled(action, ancestors_enabled && enabled);
    g_object_set_data(G_OBJECT(action), kNativeMenuActionIndexKey,
                      GINT_TO_POINTER(static_cast<gint>(entry_index) + 1));
    g_signal_connect(
        action, "activate",
        G_CALLBACK(checkable ? native_menu_check_activated_cb
                             : native_menu_action_activated_cb),
        session);
    g_action_map_add_action(G_ACTION_MAP(session->action_group),
                            G_ACTION(action));

    g_autofree gchar* detailed_action =
        g_strdup_printf("%s.%s", kNativeMenuActionNamespace, action_name);
    g_autoptr(GMenuItem) item =
        g_menu_item_new(literal_label, detailed_action);
    if (icon_name != nullptr && icon_name[0] != '\0') {
      g_autoptr(GIcon) icon = create_native_menu_icon(icon_name, entry);
      g_menu_item_set_icon(item, icon);
    }
    if (shortcut != nullptr && shortcut[0] != '\0') {
      set_menu_item_accelerator(item, shortcut);
    }
    g_menu_append_item(section, item);
    g_object_unref(action);
    section_length++;
  }
  flush_section();
  g_object_unref(section);

}


// GtkMenu's model adapter does not bind submenu-heading sensitivity to an
// action. Apply availability to those actual GTK widgets, in model order.
// Sections can coalesce separators, so separators never consume a command row.
static gboolean set_native_submenu_availability(GtkWidget* menu,
                                                FlValue* entries,
                                                gboolean ancestors_enabled) {
  GList* rows = gtk_container_get_children(GTK_CONTAINER(menu));
  GList* row = rows;
  gboolean valid = TRUE;
  for (size_t index = 0; index < fl_value_get_length(entries); index++) {
    FlValue* entry = fl_value_get_list_value(entries, index);
    gboolean separator = FALSE;
    gboolean enabled = TRUE;
    fl_lookup_optional_bool_with_default(entry, "separator", FALSE, &separator);
    if (separator) continue;
    while (row != nullptr && GTK_IS_SEPARATOR_MENU_ITEM(row->data)) row = row->next;
    if (row == nullptr || !GTK_IS_MENU_ITEM(row->data)) {
      valid = FALSE;
      break;
    }
    fl_lookup_optional_bool_with_default(entry, "enabled", TRUE, &enabled);
    FlValue* children = fl_value_lookup_string(entry, "children");
    if (children != nullptr) {
      GtkWidget* submenu = gtk_menu_item_get_submenu(GTK_MENU_ITEM(row->data));
      gtk_widget_set_sensitive(GTK_WIDGET(row->data), ancestors_enabled && enabled);
      if (submenu == nullptr || !GTK_IS_MENU(submenu) ||
          !set_native_submenu_availability(submenu, children, ancestors_enabled && enabled)) {
        valid = FALSE;
        break;
      }
    }
    row = row->next;
  }
  g_list_free(rows);
  return valid;
}

static void set_native_menu_direction(GtkWidget* widget, gpointer data) {
  gtk_widget_set_direction(widget, static_cast<GtkTextDirection>(GPOINTER_TO_INT(data)));
  if (GTK_IS_MENU_ITEM(widget)) {
    GtkWidget* submenu = gtk_menu_item_get_submenu(GTK_MENU_ITEM(widget));
    if (submenu != nullptr) set_native_menu_direction(submenu, data);
  }
  if (GTK_IS_CONTAINER(widget)) {
    gtk_container_foreach(GTK_CONTAINER(widget), set_native_menu_direction, data);
  }
}

static void show_native_menu(NativeMenuHandlerData* data,
                             FlMethodCall* method_call,
                             FlValue* args) {
  if (data->view == nullptr || !gtk_widget_get_realized(data->view) ||
      gtk_widget_get_window(data->view) == nullptr) {
    fl_method_call_respond_error(method_call, "unavailable",
                                 "The native menu host is unavailable.",
                                 nullptr, nullptr);
    return;
  }
  GdkRectangle anchor = {};
  gint64 session_id = 0;
  if (!fl_lookup_positive_int64_arg(args, "sessionId", &session_id) ||
      !parse_native_menu_anchor(args, &anchor)) {
    respond_native_menu_argument_error(
        method_call,
        "sessionId must be positive and anchor must contain finite geometry.");
    return;
  }

  GtkWidget* toplevel = gtk_widget_get_toplevel(data->view);
  GdkWindow* rect_window =
      GTK_IS_WINDOW(toplevel) ? gtk_widget_get_window(toplevel) : nullptr;
  GdkRectangle window_anchor = anchor;
  if (rect_window == nullptr ||
      !gtk_widget_translate_coordinates(
          data->view, toplevel, anchor.x, anchor.y, &window_anchor.x,
          &window_anchor.y)) {
    fl_method_call_respond_error(
        method_call, "unavailable",
        "GTK could not translate the menu anchor into window coordinates.",
        nullptr, nullptr);
    return;
  }

  FlValue* entries = fl_value_lookup_string(args, "entries");
  const gchar* direction_arg = fl_lookup_string_arg(args, "textDirection");
  if (fl_value_lookup_string(args, "textDirection") != nullptr &&
      g_strcmp0(direction_arg, "ltr") != 0 &&
      g_strcmp0(direction_arg, "rtl") != 0) {
    respond_native_menu_argument_error(method_call, "textDirection must be ltr or rtl.");
    return;
  }
  const GtkTextDirection direction = direction_arg == nullptr
      ? gtk_widget_get_direction(data->view)
      : (g_strcmp0(direction_arg, "rtl") == 0 ? GTK_TEXT_DIR_RTL : GTK_TEXT_DIR_LTR);
  gboolean focus_first = FALSE;
  const gchar* preferred_position_arg =
      fl_lookup_string_arg(args, "preferredPosition");
  GtkPositionType preferred_position = GTK_POS_BOTTOM;
  if (g_strcmp0(preferred_position_arg, "top") == 0) {
    preferred_position = GTK_POS_TOP;
  } else if (preferred_position_arg != nullptr &&
             g_strcmp0(preferred_position_arg, "bottom") != 0) {
    respond_native_menu_argument_error(
        method_call, "preferredPosition must be top or bottom.");
    return;
  }
  if (entries == nullptr ||
      fl_value_get_type(entries) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(entries) == 0 ||
      fl_value_get_length(entries) > static_cast<size_t>(G_MAXINT) ||
      !fl_lookup_optional_bool_with_default(args, "focusFirst", FALSE,
                                            &focus_first)) {
    respond_native_menu_argument_error(
        method_call,
        "entries must be non-empty and focusFirst must be boolean.");
    return;
  }

  size_t entry_count = 0;
  if (!validate_native_menu_entries(entries, method_call, 0, &entry_count)) return;
  if (data->active != nullptr) {
    native_menu_session_dispose(data->active);
  }

  auto* session = g_new0(NativeMenuSession, 1);
  session->owner = data;
  session->id = session_id;
  session->pending_selected_index = -1;
  session->method_call =
      FL_METHOD_CALL(g_object_ref(G_OBJECT(method_call)));
  session->action_group = g_simple_action_group_new();
  session->model = g_menu_new();
  data->active = session;

  size_t next_index = 0;
  build_native_menu_model(entries, session, session->model, &next_index, TRUE);
  // GtkPopover maps as a Wayland subsurface whose frame callback can stall
  // while Flutter's parent surface is idle. GtkMenu maps as an independent
  // native xdg_popup instead.
  gtk_widget_insert_action_group(
      data->view, kNativeMenuActionNamespace,
      G_ACTION_GROUP(session->action_group));
  session->menu = gtk_menu_new_from_model(G_MENU_MODEL(session->model));
  if (session->menu == nullptr || !GTK_IS_MENU(session->menu)) {
    fl_method_call_respond_error(method_call, "unavailable",
                                 "GTK could not create the native menu.",
                                 nullptr, nullptr);
    g_clear_object(&session->method_call);
    native_menu_session_dispose(session);
    return;
  }
  g_object_ref_sink(session->menu);
  gtk_menu_attach_to_widget(GTK_MENU(session->menu), data->view, nullptr);
  set_native_menu_direction(session->menu, GINT_TO_POINTER(direction));
  gtk_widget_show_all(session->menu);
  if (!set_native_submenu_availability(session->menu, entries, TRUE)) {
    fl_method_call_respond_error(method_call, "invalid-menu",
                                 "GTK menu rows do not match the menu model.",
                                 nullptr, nullptr);
    g_clear_object(&session->method_call);
    native_menu_session_dispose(session);
    return;
  }
  session->deactivate_signal_id = g_signal_connect(
      session->menu, "deactivate", G_CALLBACK(native_menu_deactivate_cb),
      session);

  const gboolean open_above = preferred_position == GTK_POS_TOP;
  const gboolean rtl = direction == GTK_TEXT_DIR_RTL;
  g_object_set(session->menu, "anchor-hints",
               GDK_ANCHOR_FLIP_Y | GDK_ANCHOR_SLIDE | GDK_ANCHOR_RESIZE,
               nullptr);
  if (!open_above) {
    g_object_set(session->menu, "menu-type-hint",
                 GDK_WINDOW_TYPE_HINT_DROPDOWN_MENU, nullptr);
  }
  // Flutter reports view-local coordinates, while FlView is a no-window
  // widget below the native titlebar. Use the translated toplevel rectangle
  // directly instead of a hidden proxy whose GTK allocation is deferred.
  gtk_menu_popup_at_rect(
      GTK_MENU(session->menu), rect_window, &window_anchor,
      open_above ? (rtl ? GDK_GRAVITY_NORTH_EAST : GDK_GRAVITY_NORTH_WEST)
                 : (rtl ? GDK_GRAVITY_SOUTH_EAST : GDK_GRAVITY_SOUTH_WEST),
      open_above ? (rtl ? GDK_GRAVITY_SOUTH_EAST : GDK_GRAVITY_SOUTH_WEST)
                 : (rtl ? GDK_GRAVITY_NORTH_EAST : GDK_GRAVITY_NORTH_WEST),
      data->trigger_event);
  if (focus_first) {
    gtk_menu_shell_select_first(GTK_MENU_SHELL(session->menu), TRUE);
  } else {
    gtk_menu_shell_deselect(GTK_MENU_SHELL(session->menu));
  }
}

static void native_menu_handler_data_free(gpointer user_data) {
  auto* data = static_cast<NativeMenuHandlerData*>(user_data);
  if (data->active != nullptr) {
    native_menu_session_dispose(data->active);
  }
  if (data->view != nullptr) {
    if (data->event_signal_id != 0) {
      g_signal_handler_disconnect(data->view, data->event_signal_id);
    }
    g_object_remove_weak_pointer(
        G_OBJECT(data->view),
        reinterpret_cast<gpointer*>(&data->view));
  }
  g_clear_pointer(&data->trigger_event, gdk_event_free);
  g_free(data);
}

static void native_menu_method_call_cb(FlMethodChannel*,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  auto* data = static_cast<NativeMenuHandlerData*>(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "show") == 0) {
    show_native_menu(data, method_call, fl_method_call_get_args(method_call));
  } else if (strcmp(method, "dismiss") == 0) {
    gint64 session_id = 0;
    if (!fl_lookup_positive_int64_arg(fl_method_call_get_args(method_call),
                                      "sessionId", &session_id)) {
      respond_native_menu_argument_error(
          method_call, "sessionId must be a positive integer.");
      return;
    }
    respond_bool(method_call,
                 native_menu_dismiss_active(data, session_id));
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void register_native_menu_channel(MyApplication* self, FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->native_menu_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kNativeMenuChannel, FL_METHOD_CODEC(codec));
  auto* data = g_new0(NativeMenuHandlerData, 1);
  data->view = GTK_WIDGET(view);
  g_object_add_weak_pointer(G_OBJECT(data->view),
                            reinterpret_cast<gpointer*>(&data->view));
  data->event_signal_id =
      g_signal_connect(data->view, "event",
                       G_CALLBACK(native_menu_capture_trigger_event), data);
  fl_method_channel_set_method_call_handler(
      self->native_menu_channel, native_menu_method_call_cb, data,
      native_menu_handler_data_free);
}

static FlValue* local_paths_from_uris(gchar** uris) {
  FlValue* paths = fl_value_new_list();
  if (uris == nullptr) {
    return paths;
  }
  for (gchar** current = uris; *current != nullptr; current++) {
    g_autoptr(GError) error = nullptr;
    g_autofree gchar* path = g_filename_from_uri(*current, nullptr, &error);
    if (path != nullptr) {
      fl_value_append_take(paths, fl_value_new_string(path));
    }
  }
  return paths;
}

static void asset_input_method_call_cb(FlMethodChannel*,
                                       FlMethodCall* method_call,
                                       gpointer) {
  const gchar* method = fl_method_call_get_name(method_call);
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  if (strcmp(method, "readClipboardImageFiles") == 0) {
    g_auto(GStrv) uris = gtk_clipboard_wait_for_uris(clipboard);
    g_autoptr(FlValue) paths = local_paths_from_uris(uris);
    fl_method_call_respond_success(method_call, paths, nullptr);
    return;
  }
  if (strcmp(method, "readClipboardImagePng") == 0) {
    g_autoptr(GdkPixbuf) pixbuf = gtk_clipboard_wait_for_image(clipboard);
    if (pixbuf == nullptr) {
      g_autoptr(FlValue) result = fl_value_new_null();
      fl_method_call_respond_success(method_call, result, nullptr);
      return;
    }
    gchar* buffer = nullptr;
    gsize length = 0;
    g_autoptr(GError) error = nullptr;
    if (!gdk_pixbuf_save_to_buffer(pixbuf, &buffer, &length, "png", &error,
                                   nullptr)) {
      g_autoptr(FlValue) details = fl_value_new_null();
      fl_method_call_respond_error(
          method_call, "asset.clipboard-encode-failed",
          error != nullptr ? error->message : "Could not encode clipboard image.",
          details, nullptr);
      return;
    }
    g_autoptr(GBytes) bytes = g_bytes_new_take(buffer, length);
    g_autoptr(FlValue) result = fl_value_new_uint8_list_from_bytes(bytes);
    fl_method_call_respond_success(method_call, result, nullptr);
    return;
  }
  fl_method_call_respond_not_implemented(method_call, nullptr);
}

static void asset_drag_data_received_cb(GtkWidget*,
                                        GdkDragContext* context,
                                        gint,
                                        gint,
                                        GtkSelectionData* selection,
                                        guint,
                                        guint time,
                                        gpointer user_data) {
  auto* self = MY_APPLICATION(user_data);
  g_auto(GStrv) uris = gtk_selection_data_get_uris(selection);
  g_autoptr(FlValue) paths = local_paths_from_uris(uris);
  const gboolean accepted = fl_value_get_length(paths) > 0;
  if (accepted && self->asset_input_channel != nullptr) {
    fl_method_channel_invoke_method(self->asset_input_channel,
                                    "assetFilesDropped", paths, nullptr,
                                    nullptr, nullptr);
  }
  gtk_drag_finish(context, accepted, FALSE, time);
}

static void register_asset_input_channel(MyApplication* self, FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->asset_input_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kAssetInputChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->asset_input_channel, asset_input_method_call_cb, self, nullptr);
  GtkTargetEntry targets[] = {
      {const_cast<gchar*>("text/uri-list"), 0, 0},
  };
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, targets, 1,
                    GDK_ACTION_COPY);
  g_signal_connect(view, "drag-data-received",
                   G_CALLBACK(asset_drag_data_received_cb), self);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication*, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window = GTK_WINDOW(hdy_application_window_new());
  gtk_application_add_window(GTK_APPLICATION(application), window);
  self->main_window = window;
  gtk_window_set_title(window, kApplicationDisplayName);
  gtk_widget_set_name(GTK_WIDGET(window), "busymark-window");
  g_autoptr(GdkPixbuf) application_icon = load_application_icon();
  if (application_icon != nullptr) {
    gtk_window_set_default_icon(application_icon);
    gtk_window_set_icon(window, application_icon);
  }
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  gtk_window_set_wmclass(window, APPLICATION_ID, APPLICATION_ID);
  G_GNUC_END_IGNORE_DEPRECATIONS
  if (application_icon == nullptr) {
    gtk_window_set_icon_name(window, APPLICATION_ID);
  }

  gtk_window_set_default_size(window, 1280, 720);
  if (uses_legacy_yaru_window_shadow()) {
    self->native_surface_css_provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(self->native_surface_css_provider,
        kLegacyYaruWindowShadowCompatibilityCss, -1, nullptr);
    gtk_style_context_add_provider_for_screen(gtk_widget_get_screen(GTK_WIDGET(window)),
        GTK_STYLE_PROVIDER(self->native_surface_css_provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  self->flutter_view = GTK_WIDGET(view);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));

  self->flutter_overlay = gtk_overlay_new();
  gtk_widget_set_hexpand(self->flutter_overlay, TRUE);
  gtk_widget_set_vexpand(self->flutter_overlay, TRUE);
  gtk_container_add(GTK_CONTAINER(self->flutter_overlay), GTK_WIDGET(view));
  gtk_widget_show(self->flutter_overlay);
  gtk_container_add(GTK_CONTAINER(window), self->flutter_overlay);

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  // Register before realizing the view starts Dart execution.
  self->gtk_accent_host = busymark_gtk_accent_host_new(view, GTK_WIDGET(window));
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  self->chrome_host = busymark_linux_chrome_host_new(view, window, set_gtk_theme_preference);
  register_native_menu_channel(self, view);
  self->writerside_dialog_channel =
      busymark_writerside_dialog_channel_new(view, window);
  register_asset_input_channel(self, view);
  self->rich_clipboard_channel = busymark_rich_clipboard_channel_new(view);
  self->secure_credential_channel =
      busymark_secure_credential_channel_new(view);
  self->visualization_host =
      busymark_web_render_host_new(GTK_APPLICATION(self), window);
  busymark_web_render_host_register_channel(self->visualization_host, view);
  self->video_player_host =
      busymark_video_player_host_new(self->flutter_overlay);
  busymark_video_player_host_register_channel(self->video_player_host, view);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
  hdy_init();

}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  busymark_linux_chrome_host_free(self->chrome_host);
  self->chrome_host = nullptr;
  busymark_gtk_accent_host_free(self->gtk_accent_host);
  self->gtk_accent_host = nullptr;
  if (self->native_surface_css_provider != nullptr) {
    GdkScreen* screen = gdk_screen_get_default();
    if (screen != nullptr) gtk_style_context_remove_provider_for_screen(screen, GTK_STYLE_PROVIDER(self->native_surface_css_provider));
  }
  g_clear_object(&self->native_surface_css_provider);
  g_clear_object(&self->native_menu_channel);
  g_clear_object(&self->writerside_dialog_channel);
  g_clear_object(&self->asset_input_channel);
  g_clear_object(&self->rich_clipboard_channel);
  g_clear_object(&self->secure_credential_channel);
  if (self->visualization_host != nullptr) busymark_web_render_host_shutdown(self->visualization_host);
  g_clear_object(&self->visualization_host);
  if (self->video_player_host != nullptr) busymark_video_player_host_shutdown(self->video_player_host);
  g_clear_object(&self->video_player_host);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}
static void my_application_init(MyApplication*) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  g_set_application_name(kApplicationDisplayName);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
