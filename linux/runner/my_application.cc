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

constexpr char kApplicationDisplayName[] = "BusyMark";
constexpr char kHeaderBarChannel[] = "com.busymark.app/headerbar";
constexpr gint kHeaderButtonHeight = 32;
constexpr gint kHeaderButtonSpacing = 8;
constexpr gint kHeaderSidebarInset = 8;
constexpr gdouble kHeaderBackdropForegroundOpacity = 0.50;
constexpr char kDefaultHeaderbarBackground[] = "#272727";
constexpr char kDefaultSidebarBackground[] = "#393939";
constexpr char kDefaultSidebarBorder[] = "rgba(16,16,16,0.35)";
constexpr char kDefaultForeground[] = "#F7F7F7";
constexpr char kDefaultModalBarrierColor[] = "rgba(0,0,0,0.25)";
// Yaru GTK 3 adds a zero-blur 23%/75% black ring around CSD windows. Current
// Ubuntu apps retain the diffuse shadow without that legacy hard edge. Reuse
// Yaru's geometry here; Handy continues to own clipping, radii, and states.
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
constexpr char kLtrIsolateStart[] = "\xE2\x81\xA6";
constexpr char kBidiIsolateEnd[] = "\xE2\x81\xA9";

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* header_bar_channel;
  GtkCssProvider* header_bar_css_provider;
  GtkWindow* main_window;
  GtkWidget* flutter_view;
  GtkWidget* titlebar_handle;
  GtkWidget* titlebar_overlay;
  GtkWidget* modal_scrim;
  GtkWidget* titlebar_box;
  GtkHeaderBar* header_bar;
  GtkWidget* sidebar_header_box;
  GtkWidget* sidebar_search_button;
  GtkWidget* sidebar_title_label;
  GtkWidget* sidebar_menu_button;
  GtkWidget* sidebar_menu;
  GMenu* main_menu_model;
  GtkWidget* header_start_box;
  GtkWidget* back_button;
  GtkWidget* sidebar_toggle_button;
  GtkWidget* title_stack;
  GtkWidget* title_label;
  GtkWidget* search_entry;
  gboolean document_controls_visible;
  gboolean search_visible;
  GtkWidget* view_mode_box;
  GtkWidget* view_mode_button;
  GtkWidget* view_mode_icon;
  GtkWidget* view_mode_menu;
  GMenu* view_mode_menu_model;
  GtkWidget* refresh_button;
  GtkWidget* adaptive_search_button;
  GtkWidget* adaptive_menu_button;
  GtkWidget* adaptive_menu;
  GSimpleActionGroup* header_action_group;
  GSimpleAction* view_mode_action;
  gchar* view_mode;
  gchar* search_query;
  gchar* background_color;
  gchar* sidebar_background_color;
  gchar* foreground_color;
  gchar* sidebar_border_color;
  gchar* modal_barrier_color;
  gint sidebar_width;
  gboolean sidebar_visible;
  gboolean text_direction_rtl;
  gboolean back_visible;
  gboolean search_active;
  gboolean modal_barrier_visible;
  gint modal_barrier_depth;
  gboolean suppress_header_actions;
  gchar* header_configuration_session_id;
  gint64 header_configuration_revision;
};

struct HeaderBarConfiguration {
  const gchar* session_id;
  gint64 revision;
  const gchar* title;
  const gchar* view_mode;
  gboolean can_refresh;
  gboolean document_controls_visible;
  gboolean search_active;
  gboolean search_visible;
  gboolean sidebar_visible;
  gboolean sidebar_toggle_visible;
  gboolean back_visible;
  gboolean modal_barrier_visible;
  gint64 modal_barrier_depth;
  const gchar* search_query;
  const gchar* text_direction;
  gdouble sidebar_width;
  FlValue* labels;
  FlValue* theme;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

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

static void respond_success(FlMethodCall* method_call) {
  g_autoptr(FlValue) result = fl_value_new_null();
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void respond_bool(FlMethodCall* method_call, gboolean value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void respond_int64(FlMethodCall* method_call, gint64 value) {
  g_autoptr(FlValue) result = fl_value_new_int(value);
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void respond_invalid_configuration(FlMethodCall* method_call,
                                          const gchar* message) {
  fl_method_call_respond_error(method_call, "invalid-header-configuration",
                               message, nullptr, nullptr);
}

static const gchar* fl_method_string_arg(FlValue* args) {
  return args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(args)
             : nullptr;
}

static gboolean fl_method_bool_arg(FlValue* args) {
  return args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_BOOL
             ? fl_value_get_bool(args)
             : FALSE;
}

static gint64 fl_method_int_arg(FlValue* args, gint64 fallback) {
  return args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_INT
             ? fl_value_get_int(args)
             : fallback;
}

static gdouble fl_method_double_arg(FlValue* args, gdouble fallback) {
  if (args == nullptr) {
    return fallback;
  }
  switch (fl_value_get_type(args)) {
    case FL_VALUE_TYPE_FLOAT:
      return fl_value_get_float(args);
    case FL_VALUE_TYPE_INT:
      return static_cast<gdouble>(fl_value_get_int(args));
    default:
      return fallback;
  }
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

static gboolean fl_lookup_optional_bool_arg(FlValue* args,
                                            const gchar* key,
                                            gboolean* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return FALSE;
  }
  *value_out = fl_value_get_bool(value);
  return TRUE;
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

static gboolean has_header_bar(MyApplication* self) {
  return self->header_bar != nullptr && GTK_IS_HEADER_BAR(self->header_bar);
}

static gboolean is_css_hex_color(const gchar* value) {
  if (value == nullptr || strlen(value) != 7 || value[0] != '#') {
    return FALSE;
  }
  for (int i = 1; i < 7; i++) {
    if (!g_ascii_isxdigit(value[i])) {
      return FALSE;
    }
  }
  return TRUE;
}

static gboolean is_css_rgba_color(const gchar* value) {
  if (value == nullptr || !g_str_has_prefix(value, "rgba(")) {
    return FALSE;
  }
  gint red = -1;
  gint green = -1;
  gint blue = -1;
  gdouble alpha = -1;
  gchar extra = 0;
  if (sscanf(value, "rgba(%d,%d,%d,%lf)%c", &red, &green, &blue, &alpha,
             &extra) != 4) {
    return FALSE;
  }
  return red >= 0 && red <= 255 && green >= 0 && green <= 255 && blue >= 0 &&
         blue <= 255 && alpha >= 0 && alpha <= 1;
}

static gboolean is_css_color_token(const gchar* value) {
  return is_css_hex_color(value) || is_css_rgba_color(value);
}

static const gchar* css_color_or(const gchar* value, const gchar* fallback) {
  return is_css_color_token(value) ? value : fallback;
}

static gchar* modal_barrier_color_for_depth(const gchar* color, gint depth) {
  GdkRGBA barrier;
  if (!gdk_rgba_parse(&barrier, color)) {
    return g_strdup(color);
  }
  const gint effective_depth = std::max(0, depth);
  barrier.alpha =
      1.0 - std::pow(1.0 - barrier.alpha, effective_depth);
  return gdk_rgba_to_string(&barrier);
}

static void replace_css_color_field(gchar** target, const gchar* value) {
  g_free(*target);
  *target = is_css_color_token(value) ? g_strdup(value) : nullptr;
}

static void set_widget_visible(GtkWidget* widget, gboolean visible) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_no_show_all(widget, !visible);
    if (visible) {
      // Some header controls are nested in containers that start hidden.
      // Showing only the container leaves children skipped by the initial
      // gtk_widget_show_all() invisible, producing an empty header slot.
      gtk_widget_show_all(widget);
    } else {
      gtk_widget_hide(widget);
    }
  }
}

static void set_widget_sensitive(GtkWidget* widget, gboolean sensitive) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_sensitive(widget, sensitive);
  }
}

static gboolean stop_modal_scrim_event(GtkWidget*, GdkEvent*, gpointer) {
  return GDK_EVENT_STOP;
}

static void close_header_menu_button(GtkWidget* menu_button) {
  if (menu_button == nullptr || !GTK_IS_MENU_BUTTON(menu_button)) {
    return;
  }
  GtkPopover* popover =
      gtk_menu_button_get_popover(GTK_MENU_BUTTON(menu_button));
  if (popover != nullptr && GTK_IS_POPOVER(popover)) {
    gtk_popover_popdown(popover);
  }
  if (GTK_IS_TOGGLE_BUTTON(menu_button)) {
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(menu_button), FALSE);
  }
}

static GtkTextDirection app_text_direction(MyApplication* self) {
  return self->text_direction_rtl ? GTK_TEXT_DIR_RTL : GTK_TEXT_DIR_LTR;
}

static void set_widget_direction(GtkWidget* widget, GtkTextDirection direction) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_direction(widget, direction);
  }
}

static void set_widget_horizontal_margins(GtkWidget* widget,
                                          gint margin_start,
                                          gint margin_end) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_margin_start(widget, margin_start);
    gtk_widget_set_margin_end(widget, margin_end);
  }
}

static void set_toggle_button_active(MyApplication* self,
                                     GtkWidget* widget,
                                     gboolean active) {
  if (widget == nullptr || !GTK_IS_TOGGLE_BUTTON(widget)) {
    return;
  }
  const gboolean previous = self->suppress_header_actions;
  self->suppress_header_actions = TRUE;
  gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(widget), active);
  self->suppress_header_actions = previous;
}

static void update_adaptive_header_actions(MyApplication* self) {
  const gboolean use_main_header = !self->sidebar_visible;
  set_widget_visible(self->adaptive_search_button,
                     use_main_header && self->search_visible);
  set_widget_visible(self->adaptive_menu_button, use_main_header);
}

static void update_sidebar_header_geometry(MyApplication* self) {
  if (self->sidebar_header_box == nullptr ||
      !GTK_IS_WIDGET(self->sidebar_header_box)) {
    return;
  }
  const gint width = self->sidebar_visible ? self->sidebar_width : 0;
  gtk_widget_set_size_request(self->sidebar_header_box, width, -1);
  set_widget_visible(self->sidebar_header_box, width > 0);
  update_adaptive_header_actions(self);
}

static void update_titlebar_direction(MyApplication* self) {
  const GtkTextDirection direction = app_text_direction(self);
  if (self->titlebar_box != nullptr && GTK_IS_BOX(self->titlebar_box) &&
      has_header_bar(self) && self->sidebar_header_box != nullptr &&
      GTK_IS_WIDGET(self->sidebar_header_box)) {
    gtk_widget_set_direction(self->titlebar_box, GTK_TEXT_DIR_LTR);
    if (self->text_direction_rtl) {
      gtk_box_reorder_child(GTK_BOX(self->titlebar_box),
                            GTK_WIDGET(self->header_bar), 0);
      gtk_box_reorder_child(GTK_BOX(self->titlebar_box),
                            self->sidebar_header_box, 1);
    } else {
      gtk_box_reorder_child(GTK_BOX(self->titlebar_box),
                            self->sidebar_header_box, 0);
      gtk_box_reorder_child(GTK_BOX(self->titlebar_box),
                            GTK_WIDGET(self->header_bar), 1);
    }
  }

  set_widget_direction(self->sidebar_header_box, direction);
  set_widget_direction(GTK_WIDGET(self->header_bar), direction);
  set_widget_direction(self->header_start_box, direction);
  set_widget_direction(self->sidebar_toggle_button, direction);
  set_widget_direction(self->back_button, direction);
  set_widget_direction(self->title_stack, direction);
  set_widget_direction(self->title_label, direction);
  set_widget_direction(self->search_entry, direction);
  set_widget_direction(self->view_mode_box, direction);
  set_widget_direction(self->view_mode_button, direction);
  set_widget_direction(self->view_mode_icon, direction);
  set_widget_direction(self->refresh_button, direction);
  set_widget_direction(self->adaptive_search_button, direction);
  set_widget_direction(self->adaptive_menu_button, direction);
  set_widget_direction(self->adaptive_menu, direction);
  set_widget_direction(self->sidebar_search_button, direction);
  set_widget_direction(self->sidebar_menu_button, direction);
  set_widget_direction(self->sidebar_menu, direction);
  set_widget_direction(self->view_mode_menu, direction);

  // GTK 3 resolves logical margins against the widget direction at setter
  // time, so reapply both sides after a live LTR/RTL direction change.
  set_widget_horizontal_margins(self->sidebar_search_button,
                                kHeaderSidebarInset, 0);
  set_widget_horizontal_margins(self->sidebar_menu_button, 0,
                                kHeaderSidebarInset);
  set_widget_horizontal_margins(self->header_start_box, kHeaderSidebarInset,
                                0);
}

static void refresh_header_bar_css(MyApplication* self) {
  if (!has_header_bar(self)) {
    return;
  }

  const gchar* background =
      css_color_or(self->background_color, kDefaultHeaderbarBackground);
  const gchar* sidebar_background =
      css_color_or(self->sidebar_background_color, kDefaultSidebarBackground);
  const gchar* foreground =
      css_color_or(self->foreground_color, kDefaultForeground);
  const gchar* sidebar_border =
      css_color_or(self->sidebar_border_color, kDefaultSidebarBorder);
  g_autofree gchar* modal = modal_barrier_color_for_depth(
      css_color_or(self->modal_barrier_color, kDefaultModalBarrierColor),
      self->modal_barrier_depth);
  const gchar* window_shadow_css = uses_legacy_yaru_window_shadow()
                                       ? kLegacyYaruWindowShadowCompatibilityCss
                                       : "";

  gtk_style_context_add_class(gtk_widget_get_style_context(self->titlebar_box),
                              "busymark-titlebar");
  gtk_style_context_add_class(
      gtk_widget_get_style_context(GTK_WIDGET(self->header_bar)),
      "busymark-headerbar");

  g_autofree gchar* css = g_strdup_printf(
      "window#busymark-window,"
      "window#busymark-window:backdrop {"
      "background-color: %s;"
      "background-image: none;"
      "}"
      "%s"
      ".busymark-titlebar,"
      ".busymark-titlebar:backdrop {"
      "background-color: %s;"
      "background-image: none;"
      "color: %s;"
      "border: none;"
      "box-shadow: none;"
      "}"
      "headerbar.busymark-headerbar,"
      "headerbar.busymark-headerbar:backdrop {"
      "background-color: %s;"
      "background-image: none;"
      "color: %s;"
      "border: none;"
      "box-shadow: none;"
      "}"
      "headerbar.busymark-headerbar:dir(ltr) {"
      "padding-left: 0;"
      "}"
      "headerbar.busymark-headerbar:dir(rtl) {"
      "padding-right: 0;"
      "}"
      ".busymark-sidebar-header {"
      "background-color: %s;"
      "background-image: none;"
      "color: %s;"
      "border: none;"
      "box-shadow: none;"
      "}"
      ".busymark-sidebar-header label {"
      "color: %s;"
      "font-weight: 800;"
      "}"
      ".busymark-sidebar-header label:backdrop {"
      "color: alpha(%s, %.2f);"
      "}"
      ".busymark-sidebar-header:dir(ltr) {"
      "border-right: 1px solid %s;"
      "}"
      ".busymark-sidebar-header:dir(rtl) {"
      "border-left: 1px solid %s;"
      "}"
      // Legacy Yaru GTK 3 uses an absolute near-black image for active and
      // checked buttons. BusyMark-owned controls use neutral current-color
      // layers while GTK continues to own geometry, focus, and motion.
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):not(:disabled) {"
      "background-color: transparent;"
      "background-image: none;"
      "border-color: transparent;"
      "box-shadow: none;"
      "}"
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):not(:disabled):hover {"
      "background-color: alpha(currentColor, 0.07);"
      "background-image: none;"
      "}"
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):not(:disabled):active {"
      "background-color: alpha(currentColor, 0.16);"
      "background-image: none;"
      "}"
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):not(:disabled):checked {"
      "background-color: alpha(currentColor, 0.10);"
      "background-image: none;"
      "}"
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):"
      "not(:disabled):checked:hover {"
      "background-color: alpha(currentColor, 0.13);"
      "background-image: none;"
      "}"
      ".busymark-titlebar "
      ".busymark-header-control:not(.suggested-action):"
      "not(:disabled):checked:active {"
      "background-color: alpha(currentColor, 0.19);"
      "background-image: none;"
      "}"
      // Keep native controls visually enabled beneath the modal tint while
      // removing transient hover and checked surfaces. The overlay below owns
      // interaction blocking.
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control,"
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control:hover,"
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control:active,"
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control:checked,"
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control:checked:hover,"
      ".busymark-titlebar.busymark-modal-open "
      ".busymark-header-control:checked:active {"
      "background-color: transparent;"
      "background-image: none;"
      "border-color: transparent;"
      "box-shadow: none;"
      "}"
      ".busymark-modal-scrim {"
      "background-color: %s;"
      "background-image: none;"
      "}",
      background, window_shadow_css, background, foreground, background,
      foreground, sidebar_background, foreground, foreground, foreground,
      kHeaderBackdropForegroundOpacity, sidebar_border, sidebar_border, modal);

  g_autoptr(GError) error = nullptr;
  GtkCssProvider* provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(provider, css, -1, &error);
  if (error != nullptr) {
    g_warning("Failed to load BusyMark headerbar CSS: %s", error->message);
    g_object_unref(provider);
    return;
  }

  GdkScreen* screen = gtk_widget_get_screen(GTK_WIDGET(self->header_bar));
  if (self->header_bar_css_provider != nullptr) {
    gtk_style_context_remove_provider_for_screen(
        screen, GTK_STYLE_PROVIDER(self->header_bar_css_provider));
    g_clear_object(&self->header_bar_css_provider);
  }
  self->header_bar_css_provider = provider;
  gtk_style_context_add_provider_for_screen(
      screen, GTK_STYLE_PROVIDER(self->header_bar_css_provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

static void gtk_theme_name_changed_cb(GtkSettings*,
                                      GParamSpec*,
                                      gpointer user_data) {
  refresh_header_bar_css(MY_APPLICATION(user_data));
}

static void set_header_bar_theme(MyApplication* self, FlValue* args) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return;
  }
  gboolean prefer_dark = FALSE;
  if (fl_lookup_optional_bool_arg(args, "preferDark", &prefer_dark)) {
    set_gtk_theme_preference(prefer_dark);
  }
  replace_css_color_field(&self->background_color,
                          fl_lookup_string_arg(args, "backgroundColor"));
  replace_css_color_field(
      &self->sidebar_background_color,
      fl_lookup_string_arg(args, "sidebarBackgroundColor"));
  replace_css_color_field(&self->foreground_color,
                          fl_lookup_string_arg(args, "foregroundColor"));
  replace_css_color_field(
      &self->sidebar_border_color,
      fl_lookup_string_arg(args, "sidebarBorderColor"));
  replace_css_color_field(&self->modal_barrier_color,
                          fl_lookup_string_arg(args, "modalBarrierColor"));
  refresh_header_bar_css(self);
}

static void focus_flutter_view(MyApplication* self) {
  if (self->flutter_view != nullptr && GTK_IS_WIDGET(self->flutter_view)) {
    gtk_widget_grab_focus(self->flutter_view);
  }
}

static void invoke_header_bar_action(MyApplication* self,
                                     const gchar* action) {
  if (self->modal_barrier_visible ||
      self->header_bar_channel == nullptr || action == nullptr) {
    return;
  }
  fl_method_channel_invoke_method(self->header_bar_channel, action, nullptr,
                                  nullptr, nullptr, nullptr);
}

static void invoke_header_bar_string_action(MyApplication* self,
                                            const gchar* action,
                                            const gchar* value) {
  if (self->modal_barrier_visible ||
      self->header_bar_channel == nullptr || action == nullptr) {
    return;
  }
  g_autoptr(FlValue) args = fl_value_new_string(value == nullptr ? "" : value);
  fl_method_channel_invoke_method(self->header_bar_channel, action, args,
                                  nullptr, nullptr, nullptr);
}

static void invoke_header_bar_bool_action(MyApplication* self,
                                          const gchar* action,
                                          gboolean value) {
  if (self->modal_barrier_visible ||
      self->header_bar_channel == nullptr || action == nullptr) {
    return;
  }
  g_autoptr(FlValue) args = fl_value_new_bool(value);
  fl_method_channel_invoke_method(self->header_bar_channel, action, args,
                                  nullptr, nullptr, nullptr);
}

enum class SearchQueryUpdateDisposition {
  kAlreadyCurrent,
  kPreserveNativeText,
  kApplyDartSnapshot,
};

constexpr SearchQueryUpdateDisposition resolve_search_query_update(
    bool queries_match,
    bool native_entry_has_authority) {
  if (queries_match) {
    return SearchQueryUpdateDisposition::kAlreadyCurrent;
  }
  return native_entry_has_authority
             ? SearchQueryUpdateDisposition::kPreserveNativeText
             : SearchQueryUpdateDisposition::kApplyDartSnapshot;
}

static_assert(
    resolve_search_query_update(false, true) ==
        SearchQueryUpdateDisposition::kPreserveNativeText,
    "A newer focused native edit must survive a delayed Dart snapshot");
static_assert(
    resolve_search_query_update(false, false) ==
        SearchQueryUpdateDisposition::kApplyDartSnapshot,
    "Dart owns search text while the native entry is not being edited");

static void cache_search_query(MyApplication* self, const gchar* query) {
  const gchar* normalized_query = query == nullptr ? "" : query;
  if (g_strcmp0(self->search_query, normalized_query) == 0) {
    return;
  }
  g_free(self->search_query);
  self->search_query = g_strdup(normalized_query);
}

static void set_search_query(MyApplication* self, const gchar* query) {
  const gchar* normalized_query = query == nullptr ? "" : query;
  if (self->search_entry == nullptr || !GTK_IS_ENTRY(self->search_entry)) {
    cache_search_query(self, normalized_query);
    return;
  }
  const gchar* current_query =
      gtk_entry_get_text(GTK_ENTRY(self->search_entry));
  const bool native_entry_has_authority =
      self->search_active && gtk_widget_has_focus(self->search_entry);
  switch (resolve_search_query_update(
      g_strcmp0(current_query, normalized_query) == 0,
      native_entry_has_authority)) {
    case SearchQueryUpdateDisposition::kAlreadyCurrent:
      cache_search_query(self, normalized_query);
      return;
    case SearchQueryUpdateDisposition::kPreserveNativeText:
      // GtkSearchEntry emits search-changed after a short delay. Dart can
      // therefore publish an older mirrored snapshot after the user has
      // already typed more text. While the active entry has focus, native
      // text is authoritative. Do not update the cache here: a pending
      // search-changed signal still needs to publish the newer native text.
      return;
    case SearchQueryUpdateDisposition::kApplyDartSnapshot:
      break;
  }

  cache_search_query(self, normalized_query);
  const gboolean previous_suppression = self->suppress_header_actions;
  self->suppress_header_actions = TRUE;
  gtk_entry_set_text(GTK_ENTRY(self->search_entry), normalized_query);
  self->suppress_header_actions = previous_suppression;
}

static void header_button_clicked_cb(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible) {
    return;
  }
  const gchar* action = static_cast<const gchar*>(
      g_object_get_data(G_OBJECT(widget), "busymark-action"));
  focus_flutter_view(self);
  invoke_header_bar_action(self, action);
}

static void connect_header_action(MyApplication* self,
                                  GtkWidget* widget,
                                  const gchar* action) {
  g_object_set_data(G_OBJECT(widget), "busymark-action",
                    const_cast<gchar*>(action));
  g_signal_connect(widget, "clicked", G_CALLBACK(header_button_clicked_cb),
                   self);
}

static void search_entry_changed_cb(GtkSearchEntry* entry,
                                    gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible ||
      !self->search_active) {
    return;
  }
  const gchar* query = gtk_entry_get_text(GTK_ENTRY(entry));
  if (g_strcmp0(self->search_query, query) == 0) {
    return;
  }
  cache_search_query(self, query);
  invoke_header_bar_string_action(self, "searchQueryChanged", query);
}

static void search_entry_activate_cb(GtkEntry* entry, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible ||
      !self->search_active) {
    return;
  }
  invoke_header_bar_string_action(self, "searchSubmitted",
                                  gtk_entry_get_text(entry));
  focus_flutter_view(self);
}

static gboolean search_entry_focus_in_cb(GtkWidget*,
                                         GdkEventFocus*,
                                         gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->modal_barrier_visible) {
    invoke_header_bar_bool_action(self, "searchFocusChanged", TRUE);
  }
  return FALSE;
}

static gboolean search_entry_focus_out_cb(GtkWidget*,
                                          GdkEventFocus*,
                                          gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->modal_barrier_visible) {
    invoke_header_bar_bool_action(self, "searchFocusChanged", FALSE);
  }
  return FALSE;
}

static void search_entry_icon_release_cb(GtkEntry* entry,
                                         GtkEntryIconPosition icon_position,
                                         GdkEvent*,
                                         gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible ||
      !self->search_active ||
      icon_position != GTK_ENTRY_ICON_SECONDARY ||
      gtk_entry_get_text(entry)[0] == '\0') {
    return;
  }

  // GtkSearchEntry clears the entry after this signal. Cache the semantic
  // result now so its subsequent search-changed signal is deduplicated.
  cache_search_query(self, "");
  invoke_header_bar_action(self, "searchCleared");
}

static void search_entry_stop_search_cb(GtkSearchEntry*, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible ||
      !self->search_active) {
    return;
  }
  invoke_header_bar_action(self, "searchEscapePressed");
}

static void make_icon_button_square(GtkWidget* button) {
  gtk_widget_set_size_request(button, kHeaderButtonHeight,
                              kHeaderButtonHeight);
  gtk_widget_set_valign(button, GTK_ALIGN_CENTER);
}

static GtkWidget* create_header_icon_button(const gchar* icon_name) {
  GtkWidget* button = gtk_button_new();
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-control");
  GtkWidget* image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_MENU);
  gtk_button_set_image(GTK_BUTTON(button), image);
  make_icon_button_square(button);
  return button;
}

static GtkWidget* create_header_toggle_button(const gchar* icon_name) {
  GtkWidget* button = gtk_toggle_button_new();
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-control");
  GtkWidget* image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_MENU);
  gtk_button_set_image(GTK_BUTTON(button), image);
  make_icon_button_square(button);
  return button;
}

static const gchar* main_menu_icon_name(const gchar* action) {
  if (g_strcmp0(action, "settings") == 0) {
    return "preferences-system-symbolic";
  }
  if (g_strcmp0(action, "keyboardShortcuts") == 0) {
    return "input-keyboard-symbolic";
  }
  if (g_strcmp0(action, "markdownAndHtml") == 0) {
    return "text-x-generic-symbolic";
  }
  if (g_strcmp0(action, "reportIssue") == 0) {
    return "dialog-warning-symbolic";
  }
  if (g_strcmp0(action, "aboutBusyMark") == 0) {
    return "help-about-symbolic";
  }
  return "open-menu-symbolic";
}

static const gchar* localized_label_or(FlValue* labels,
                                       const gchar* key,
                                       const gchar* fallback) {
  const gchar* value = fl_lookup_string_arg(labels, key);
  return value != nullptr ? value : fallback;
}

static void append_action_menu_item(GMenu* menu,
                                    const gchar* label,
                                    const gchar* action,
                                    const gchar* icon_name,
                                    const gchar* shortcut) {
  GMenuItem* item = g_menu_item_new(label, action);
  if (icon_name != nullptr) {
    GIcon* icon = g_themed_icon_new(icon_name);
    g_menu_item_set_icon(item, icon);
    g_object_unref(icon);
  }
  if (shortcut != nullptr && shortcut[0] != '\0') {
    g_menu_item_set_attribute(item, "accel", "s", shortcut);
  }
  g_menu_append_item(menu, item);
  g_object_unref(item);
}

static void rebuild_main_menu_model(MyApplication* self, FlValue* labels) {
  if (self->main_menu_model == nullptr) {
    return;
  }
  g_menu_remove_all(self->main_menu_model);
  append_action_menu_item(
      self->main_menu_model,
      localized_label_or(labels, "settings", ""), "header.settings",
      main_menu_icon_name("settings"),
      fl_lookup_string_arg(labels, "settingsShortcut"));
  append_action_menu_item(
      self->main_menu_model,
      localized_label_or(labels, "keyboardShortcuts", ""),
      "header.keyboard-shortcuts",
      main_menu_icon_name("keyboardShortcuts"),
      fl_lookup_string_arg(labels, "keyboardShortcutsShortcut"));
  append_action_menu_item(
      self->main_menu_model,
      localized_label_or(labels, "markdownAndHtml", ""),
      "header.markdown-and-html", main_menu_icon_name("markdownAndHtml"),
      fl_lookup_string_arg(labels, "markdownAndHtmlShortcut"));
  append_action_menu_item(
      self->main_menu_model,
      localized_label_or(labels, "reportIssue", ""),
      "header.report-issue", main_menu_icon_name("reportIssue"), nullptr);
  append_action_menu_item(
      self->main_menu_model,
      localized_label_or(labels, "aboutBusyMark", ""),
      "header.about", main_menu_icon_name("aboutBusyMark"), nullptr);
}

static const gchar* view_mode_dart_action(const gchar* mode) {
  if (g_strcmp0(mode, "editor") == 0) {
    return "viewModeEditor";
  }
  if (g_strcmp0(mode, "source") == 0) {
    return "viewModeSource";
  }
  if (g_strcmp0(mode, "preview") == 0) {
    return "viewModePreview";
  }
  if (g_strcmp0(mode, "split") == 0) {
    return "viewModeSplit";
  }
  return nullptr;
}

static const gchar* view_mode_icon_name(const gchar* mode) {
  if (g_strcmp0(mode, "editor") == 0) {
    return "accessories-text-editor-symbolic";
  }
  if (g_strcmp0(mode, "source") == 0) {
    return "text-x-generic-symbolic";
  }
  if (g_strcmp0(mode, "preview") == 0) {
    return "document-print-preview-symbolic";
  }
  if (g_strcmp0(mode, "split") == 0) {
    return "view-dual-symbolic";
  }
  return "view-dual-symbolic";
}

static void update_view_mode_icon(MyApplication* self) {
  if (self->view_mode_icon == nullptr ||
      !GTK_IS_IMAGE(self->view_mode_icon)) {
    return;
  }
  const gchar* mode = self->view_mode != nullptr ? self->view_mode : "split";
  gtk_image_set_from_icon_name(GTK_IMAGE(self->view_mode_icon),
                               view_mode_icon_name(mode), GTK_ICON_SIZE_MENU);
}

static void set_view_mode(MyApplication* self, const gchar* mode) {
  if (view_mode_dart_action(mode) == nullptr) {
    return;
  }
  g_free(self->view_mode);
  self->view_mode = g_strdup(mode);
  if (self->view_mode_action != nullptr) {
    g_simple_action_set_state(self->view_mode_action,
                              g_variant_new_string(mode));
  }
  update_view_mode_icon(self);
}

static void header_gaction_activated_cb(GSimpleAction* action,
                                        GVariant* parameter,
                                        gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible) {
    return;
  }
  const gchar* dart_action = static_cast<const gchar*>(
      g_object_get_data(G_OBJECT(action), "busymark-dart-action"));
  if (dart_action == nullptr) {
    return;
  }
  focus_flutter_view(self);
  invoke_header_bar_action(self, dart_action);
}

static void view_mode_gaction_activated_cb(GSimpleAction* action,
                                           GVariant* parameter,
                                           gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions || self->modal_barrier_visible) {
    return;
  }
  if (parameter == nullptr ||
      !g_variant_is_of_type(parameter, G_VARIANT_TYPE_STRING)) {
    return;
  }
  const gchar* mode = g_variant_get_string(parameter, nullptr);
  const gchar* dart_action = view_mode_dart_action(mode);
  if (dart_action == nullptr) {
    return;
  }
  set_view_mode(self, mode);
  focus_flutter_view(self);
  invoke_header_bar_action(self, dart_action);
}

static void add_header_gaction(MyApplication* self,
                               const gchar* action_name,
                               const gchar* dart_action) {
  GSimpleAction* action = g_simple_action_new(action_name, nullptr);
  g_object_set_data_full(G_OBJECT(action), "busymark-dart-action",
                         g_strdup(dart_action), g_free);
  g_signal_connect(action, "activate", G_CALLBACK(header_gaction_activated_cb),
                   self);
  g_action_map_add_action(G_ACTION_MAP(self->header_action_group),
                          G_ACTION(action));
  g_object_unref(action);
}

static void setup_header_actions(MyApplication* self) {
  self->header_action_group = g_simple_action_group_new();
  add_header_gaction(self, "settings", "settings");
  add_header_gaction(self, "keyboard-shortcuts", "keyboardShortcuts");
  add_header_gaction(self, "markdown-and-html", "markdownAndHtml");
  add_header_gaction(self, "report-issue", "reportIssue");
  add_header_gaction(self, "about", "aboutBusyMark");

  self->view_mode_action = g_simple_action_new_stateful(
      "view-mode", G_VARIANT_TYPE_STRING, g_variant_new_string("split"));
  g_signal_connect(self->view_mode_action, "activate",
                   G_CALLBACK(view_mode_gaction_activated_cb), self);
  g_action_map_add_action(G_ACTION_MAP(self->header_action_group),
                          G_ACTION(self->view_mode_action));
  gtk_widget_insert_action_group(self->titlebar_box, "header",
                                 G_ACTION_GROUP(self->header_action_group));
}

static void append_view_mode_menu_item(GMenu* menu,
                                       const gchar* label,
                                       const gchar* mode,
                                       const gchar* shortcut) {
  GMenuItem* item = g_menu_item_new(label, nullptr);
  g_menu_item_set_action_and_target(item, "header.view-mode", "s", mode);
  GIcon* icon = g_themed_icon_new(view_mode_icon_name(mode));
  g_menu_item_set_icon(item, icon);
  g_object_unref(icon);
  if (shortcut != nullptr && shortcut[0] != '\0') {
    g_menu_item_set_attribute(item, "accel", "s", shortcut);
  }
  g_menu_append_item(menu, item);
  g_object_unref(item);
}

static void rebuild_view_mode_menu_model(MyApplication* self,
                                         FlValue* labels) {
  if (self->view_mode_menu_model == nullptr) {
    return;
  }
  g_menu_remove_all(self->view_mode_menu_model);
  append_view_mode_menu_item(
      self->view_mode_menu_model,
      localized_label_or(labels, "editor", ""), "editor",
      fl_lookup_string_arg(labels, "editorShortcut"));
  append_view_mode_menu_item(
      self->view_mode_menu_model,
      localized_label_or(labels, "source", ""), "source",
      fl_lookup_string_arg(labels, "sourceShortcut"));
  append_view_mode_menu_item(
      self->view_mode_menu_model,
      localized_label_or(labels, "preview", ""), "preview",
      fl_lookup_string_arg(labels, "previewShortcut"));
  append_view_mode_menu_item(
      self->view_mode_menu_model,
      localized_label_or(labels, "split", ""), "split",
      fl_lookup_string_arg(labels, "splitShortcut"));
}

static GtkWidget* create_model_menu_button(GMenuModel* model,
                                           const gchar* icon_name,
  GtkWidget** popover_out) {
  GtkWidget* button = gtk_menu_button_new();
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-control");
  gtk_button_set_image(GTK_BUTTON(button),
                       gtk_image_new_from_icon_name(icon_name,
                                                    GTK_ICON_SIZE_MENU));
  // Pointer-opened model menus should not paint a keyboard focus ring around
  // their first row. Keyboard traversal can still focus the trigger.
  gtk_widget_set_focus_on_click(button, FALSE);
  gtk_menu_button_set_use_popover(GTK_MENU_BUTTON(button), TRUE);
  gtk_menu_button_set_menu_model(GTK_MENU_BUTTON(button), model);
  make_icon_button_square(button);
  GtkPopover* popover = gtk_menu_button_get_popover(GTK_MENU_BUTTON(button));
  if (popover != nullptr) {
    gtk_popover_set_position(popover, GTK_POS_BOTTOM);
    if (popover_out != nullptr) {
      *popover_out = GTK_WIDGET(popover);
    }
  }
  return button;
}

static void set_widget_tooltip(GtkWidget* widget, const gchar* tooltip) {
  if (widget != nullptr && GTK_IS_WIDGET(widget) && tooltip != nullptr) {
    gtk_widget_set_tooltip_text(widget, tooltip);
  }
}

static void set_widget_tooltip_with_shortcut(GtkWidget* widget,
                                             const gchar* tooltip,
                                             const gchar* shortcut) {
  if (widget == nullptr || !GTK_IS_WIDGET(widget) || tooltip == nullptr) {
    return;
  }
  if (shortcut == nullptr || shortcut[0] == '\0') {
    gtk_widget_set_tooltip_text(widget, tooltip);
    return;
  }
  gchar* value = g_strdup_printf("%s (%s%s%s)", tooltip, kLtrIsolateStart,
                                 shortcut, kBidiIsolateEnd);
  gtk_widget_set_tooltip_text(widget, value);
  g_free(value);
}

static void set_localized_labels(MyApplication* self, FlValue* args) {
  const gchar* view_mode = fl_lookup_string_arg(args, "viewMode");
  const gchar* search = fl_lookup_string_arg(args, "search");
  const gchar* refresh = fl_lookup_string_arg(args, "refresh");
  const gchar* menu = fl_lookup_string_arg(args, "menu");
  const gchar* sidebar = fl_lookup_string_arg(args, "sidebar");
  const gchar* sidebar_shortcut =
      fl_lookup_string_arg(args, "sidebarShortcut");
  const gchar* back = fl_lookup_string_arg(args, "back");

  set_widget_tooltip(self->back_button, back);
  set_widget_tooltip_with_shortcut(self->sidebar_toggle_button, sidebar,
                                   sidebar_shortcut);
  set_widget_tooltip(self->sidebar_search_button, search);
  set_widget_tooltip(self->adaptive_search_button, search);
  if (self->search_entry != nullptr && GTK_IS_ENTRY(self->search_entry) &&
      search != nullptr) {
    gtk_entry_set_placeholder_text(GTK_ENTRY(self->search_entry), search);
  }
  set_widget_tooltip(self->sidebar_menu_button, menu);
  set_widget_tooltip(self->adaptive_menu_button, menu);
  set_widget_tooltip(self->refresh_button, refresh);
  set_widget_tooltip(self->view_mode_button, view_mode);
  rebuild_main_menu_model(self, args);
  rebuild_view_mode_menu_model(self, args);
  update_view_mode_icon(self);
}

static void set_modal_barrier_depth(MyApplication* self, gint64 depth) {
  const gint effective_depth =
      depth <= 0 ? 0
                 : depth > G_MAXINT ? G_MAXINT : static_cast<gint>(depth);
  const gboolean visible = effective_depth > 0;
  self->modal_barrier_depth = effective_depth;
  self->modal_barrier_visible = visible;
  refresh_header_bar_css(self);
  if (self->titlebar_box != nullptr &&
      GTK_IS_WIDGET(self->titlebar_box)) {
    GtkStyleContext* context =
        gtk_widget_get_style_context(self->titlebar_box);
    if (visible) {
      gtk_style_context_add_class(context, "busymark-modal-open");
    } else {
      gtk_style_context_remove_class(context, "busymark-modal-open");
    }
  }
  set_widget_visible(self->modal_scrim, visible);
  if (visible) {
    close_header_menu_button(self->sidebar_menu_button);
    close_header_menu_button(self->adaptive_menu_button);
    close_header_menu_button(self->view_mode_button);
    focus_flutter_view(self);
  }
}

static void set_modal_barrier_visible(MyApplication* self, gboolean visible) {
  set_modal_barrier_depth(self, visible ? 1 : 0);
}

static void set_sidebar_visible(MyApplication* self, gboolean visible) {
  self->sidebar_visible = visible;
  set_toggle_button_active(self, self->sidebar_toggle_button, visible);
  update_sidebar_header_geometry(self);
  refresh_header_bar_css(self);
}

static void set_sidebar_toggle_visible(MyApplication* self, gboolean visible) {
  set_widget_visible(self->sidebar_toggle_button, visible);
}

static void set_sidebar_width(MyApplication* self, gdouble width) {
  if (width <= 0) {
    return;
  }
  self->sidebar_width = static_cast<gint>(width);
  update_sidebar_header_geometry(self);
}

static void set_text_direction(MyApplication* self, const gchar* value) {
  self->text_direction_rtl = g_strcmp0(value, "rtl") == 0;
  update_titlebar_direction(self);
  refresh_header_bar_css(self);
}

static void set_back_visible(MyApplication* self, gboolean visible) {
  self->back_visible = visible;
  set_widget_visible(self->back_button, visible);
}

static void set_document_controls_visible(MyApplication* self,
                                          gboolean visible) {
  self->document_controls_visible = visible;
  const gboolean effective_visible = visible && !self->search_active;
  set_widget_visible(self->refresh_button, effective_visible);
  set_widget_visible(self->view_mode_box, effective_visible);
}

static void set_search_active(MyApplication* self, gboolean active) {
  const gboolean changed = self->search_active != active;
  self->search_active = active;
  set_toggle_button_active(self, self->sidebar_search_button, active);
  set_toggle_button_active(self, self->adaptive_search_button, active);
  if (self->title_stack != nullptr && GTK_IS_STACK(self->title_stack)) {
    GtkWidget* visible_child = active ? self->search_entry : self->title_label;
    if (visible_child != nullptr && GTK_IS_WIDGET(visible_child)) {
      gtk_stack_set_visible_child(GTK_STACK(self->title_stack), visible_child);
    }
  }
  const gboolean document_controls_visible =
      self->document_controls_visible && !active;
  set_widget_visible(self->refresh_button, document_controls_visible);
  set_widget_visible(self->view_mode_box, document_controls_visible);
  if (changed && active && self->search_entry != nullptr &&
      GTK_IS_ENTRY(self->search_entry)) {
    gtk_widget_grab_focus(self->search_entry);
    gtk_editable_select_region(GTK_EDITABLE(self->search_entry), 0, -1);
  } else if (changed && !active) {
    focus_flutter_view(self);
  }
}

static gboolean focus_search_entry(MyApplication* self) {
  if (self->modal_barrier_visible || !self->search_active ||
      self->search_entry == nullptr || !GTK_IS_ENTRY(self->search_entry) ||
      !gtk_widget_get_visible(self->search_entry) ||
      !gtk_widget_get_child_visible(self->search_entry) ||
      !gtk_widget_get_sensitive(self->search_entry)) {
    return FALSE;
  }

  gtk_widget_grab_focus(self->search_entry);
  gtk_editable_select_region(GTK_EDITABLE(self->search_entry), 0, -1);
  return gtk_widget_has_focus(self->search_entry);
}

static void set_search_visible(MyApplication* self, gboolean visible) {
  self->search_visible = visible;
  set_widget_visible(self->sidebar_search_button, visible);
  update_adaptive_header_actions(self);
  if (!visible && self->search_active) {
    set_search_active(self, FALSE);
  }
}

static gboolean begin_header_configuration_session(MyApplication* self,
                                                   FlValue* args) {
  const gchar* session_id = fl_lookup_string_arg(args, "sessionId");
  if (session_id == nullptr || session_id[0] == '\0') {
    return FALSE;
  }
  if (g_strcmp0(session_id, self->header_configuration_session_id) != 0) {
    g_free(self->header_configuration_session_id);
    self->header_configuration_session_id = g_strdup(session_id);
    self->header_configuration_revision = -1;
  }
  return TRUE;
}

static gboolean decode_header_bar_configuration(
    FlValue* args,
    HeaderBarConfiguration* configuration) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP ||
      (configuration->session_id =
           fl_lookup_string_arg(args, "sessionId")) == nullptr ||
      !fl_lookup_int64_arg(args, "revision", &configuration->revision)) {
    return FALSE;
  }

  configuration->title = fl_lookup_string_arg(args, "title");
  configuration->view_mode = fl_lookup_string_arg(args, "viewMode");
  configuration->search_query = fl_lookup_string_arg(args, "searchQuery");
  configuration->text_direction =
      fl_lookup_string_arg(args, "textDirection");
  configuration->labels = fl_lookup_map_arg(args, "labels");
  configuration->theme = fl_lookup_map_arg(args, "theme");

  if (configuration->session_id[0] == '\0' || configuration->revision < 0 ||
      configuration->title == nullptr ||
      configuration->view_mode == nullptr ||
      view_mode_dart_action(configuration->view_mode) == nullptr ||
      configuration->search_query == nullptr ||
      configuration->text_direction == nullptr ||
      (g_strcmp0(configuration->text_direction, "ltr") != 0 &&
       g_strcmp0(configuration->text_direction, "rtl") != 0) ||
      configuration->labels == nullptr || configuration->theme == nullptr ||
      !fl_lookup_double_arg(args, "sidebarWidth",
                            &configuration->sidebar_width) ||
      configuration->sidebar_width <= 0 ||
      !fl_lookup_optional_bool_arg(args, "canRefresh",
                                   &configuration->can_refresh) ||
      !fl_lookup_optional_bool_arg(
          args, "documentControlsVisible",
          &configuration->document_controls_visible) ||
      !fl_lookup_optional_bool_arg(args, "searchActive",
                                   &configuration->search_active) ||
      !fl_lookup_optional_bool_arg(args, "searchVisible",
                                   &configuration->search_visible) ||
      !fl_lookup_optional_bool_arg(args, "sidebarVisible",
                                   &configuration->sidebar_visible) ||
      !fl_lookup_optional_bool_arg(args, "sidebarToggleVisible",
                                   &configuration->sidebar_toggle_visible) ||
      !fl_lookup_optional_bool_arg(args, "backVisible",
                                   &configuration->back_visible) ||
      !fl_lookup_optional_bool_arg(args, "modalBarrierVisible",
                                   &configuration->modal_barrier_visible) ||
      !fl_lookup_int64_arg(args, "modalBarrierDepth",
                           &configuration->modal_barrier_depth) ||
      configuration->modal_barrier_depth < 0 ||
      configuration->modal_barrier_depth > G_MAXINT ||
      configuration->modal_barrier_visible !=
          (configuration->modal_barrier_depth > 0)) {
    return FALSE;
  }

  return configuration->search_visible || !configuration->search_active;
}

static void apply_header_bar_configuration(
    MyApplication* self,
    const HeaderBarConfiguration& configuration) {
  const gboolean previous_suppression = self->suppress_header_actions;
  self->suppress_header_actions = TRUE;
  if (self->titlebar_box != nullptr) {
    g_object_freeze_notify(G_OBJECT(self->titlebar_box));
  }

  set_header_bar_theme(self, configuration.theme);
  set_localized_labels(self, configuration.labels);
  if (self->title_label != nullptr && GTK_IS_LABEL(self->title_label)) {
    gtk_label_set_text(GTK_LABEL(self->title_label), configuration.title);
  }
  set_widget_sensitive(self->refresh_button, configuration.can_refresh);
  set_sidebar_width(self, configuration.sidebar_width);
  set_text_direction(self, configuration.text_direction);
  set_sidebar_visible(self, configuration.sidebar_visible);
  set_sidebar_toggle_visible(self, configuration.sidebar_toggle_visible);
  set_search_visible(self, configuration.search_visible);
  set_back_visible(self, configuration.back_visible);
  set_document_controls_visible(
      self, configuration.document_controls_visible);
  set_search_query(self, configuration.search_query);
  set_search_active(self, configuration.search_active);
  set_view_mode(self, configuration.view_mode);
  set_modal_barrier_depth(self, configuration.modal_barrier_depth);
  self->header_configuration_revision = configuration.revision;

  if (self->titlebar_box != nullptr) {
    g_object_thaw_notify(G_OBJECT(self->titlebar_box));
    gtk_widget_queue_draw(self->titlebar_box);
  }
  self->suppress_header_actions = previous_suppression;
}

static GtkWidget* create_busymark_titlebar(MyApplication* self) {
  self->titlebar_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_halign(self->titlebar_box, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->titlebar_box, TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->titlebar_box),
                              "busymark-titlebar");
  setup_header_actions(self);
  self->main_menu_model = g_menu_new();
  self->view_mode_menu_model = g_menu_new();
  rebuild_main_menu_model(self, nullptr);
  rebuild_view_mode_menu_model(self, nullptr);

  self->sidebar_header_box = gtk_overlay_new();
  gtk_widget_set_halign(self->sidebar_header_box, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->sidebar_header_box, FALSE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_header_box),
                              "busymark-sidebar-header");

  GtkWidget* sidebar_action_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  gtk_widget_set_halign(sidebar_action_box, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(sidebar_action_box, TRUE);
  gtk_container_add(GTK_CONTAINER(self->sidebar_header_box),
                    sidebar_action_box);

  self->sidebar_search_button = create_header_toggle_button("system-search-symbolic");
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_search_button),
                              "busymark-sidebar-action-button");
  connect_header_action(self, self->sidebar_search_button, "search");
  gtk_box_pack_start(GTK_BOX(sidebar_action_box),
                     self->sidebar_search_button, FALSE, FALSE, 0);

  self->sidebar_title_label = gtk_label_new(kApplicationDisplayName);
  gtk_widget_set_halign(self->sidebar_title_label, GTK_ALIGN_CENTER);
  gtk_widget_set_valign(self->sidebar_title_label, GTK_ALIGN_CENTER);
  gtk_label_set_ellipsize(GTK_LABEL(self->sidebar_title_label),
                          PANGO_ELLIPSIZE_END);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_title_label),
                              GTK_STYLE_CLASS_TITLE);
  gtk_overlay_add_overlay(GTK_OVERLAY(self->sidebar_header_box),
                          self->sidebar_title_label);
  gtk_overlay_set_overlay_pass_through(GTK_OVERLAY(self->sidebar_header_box),
                                       self->sidebar_title_label, TRUE);

  self->sidebar_menu_button = create_model_menu_button(
      G_MENU_MODEL(self->main_menu_model), "open-menu-symbolic",
      &self->sidebar_menu);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_menu_button),
                              "busymark-sidebar-action-button");
  gtk_box_pack_end(GTK_BOX(sidebar_action_box),
                   self->sidebar_menu_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(self->titlebar_box), self->sidebar_header_box,
                     FALSE, FALSE, 0);

  self->header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
  gtk_header_bar_set_show_close_button(self->header_bar, TRUE);
  gtk_widget_set_hexpand(GTK_WIDGET(self->header_bar), TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(self->header_bar)),
                              "busymark-headerbar");

  self->header_start_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  self->back_button = create_header_icon_button("go-previous-symbolic");
  self->sidebar_toggle_button =
      create_header_toggle_button("sidebar-show-symbolic");
  connect_header_action(self, self->back_button, "back");
  connect_header_action(self, self->sidebar_toggle_button, "sidebarToggle");
  gtk_box_pack_start(GTK_BOX(self->header_start_box), self->sidebar_toggle_button,
                     FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(self->header_start_box), self->back_button,
                     FALSE, FALSE, 0);
  gtk_header_bar_pack_start(self->header_bar, self->header_start_box);

  self->title_stack = gtk_stack_new();
  gtk_widget_set_hexpand(self->title_stack, TRUE);
  gtk_stack_set_transition_type(GTK_STACK(self->title_stack),
                                GTK_STACK_TRANSITION_TYPE_NONE);
  self->title_label = gtk_label_new("");
  gtk_label_set_ellipsize(GTK_LABEL(self->title_label), PANGO_ELLIPSIZE_END);
  gtk_label_set_max_width_chars(GTK_LABEL(self->title_label), 48);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->title_label),
                              "busymark-header-title");
  self->search_entry = gtk_search_entry_new();
  gtk_entry_set_placeholder_text(GTK_ENTRY(self->search_entry), "");
  gtk_widget_set_hexpand(self->search_entry, TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->search_entry),
                              "busymark-search-entry");
  g_signal_connect(self->search_entry, "search-changed",
                   G_CALLBACK(search_entry_changed_cb), self);
  g_signal_connect(self->search_entry, "activate",
                   G_CALLBACK(search_entry_activate_cb), self);
  g_signal_connect(self->search_entry, "focus-in-event",
                   G_CALLBACK(search_entry_focus_in_cb), self);
  g_signal_connect(self->search_entry, "focus-out-event",
                   G_CALLBACK(search_entry_focus_out_cb), self);
  g_signal_connect(self->search_entry, "icon-release",
                   G_CALLBACK(search_entry_icon_release_cb), self);
  g_signal_connect(self->search_entry, "stop-search",
                   G_CALLBACK(search_entry_stop_search_cb), self);
  gtk_stack_add_named(GTK_STACK(self->title_stack), self->title_label, "title");
  gtk_stack_add_named(GTK_STACK(self->title_stack), self->search_entry,
                      "search");
  gtk_stack_set_visible_child(GTK_STACK(self->title_stack), self->title_label);
  gtk_header_bar_set_custom_title(self->header_bar, self->title_stack);

  GtkWidget* end_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  self->view_mode_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  self->view_mode_button = create_model_menu_button(
      G_MENU_MODEL(self->view_mode_menu_model), view_mode_icon_name("split"),
      &self->view_mode_menu);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->view_mode_button),
                              "busymark-view-mode-button");
  self->view_mode_icon =
      gtk_button_get_image(GTK_BUTTON(self->view_mode_button));
  gtk_box_pack_start(GTK_BOX(self->view_mode_box), self->view_mode_button,
                     FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(end_box), self->view_mode_box, FALSE, FALSE, 0);

  self->refresh_button = create_header_icon_button("tools-check-spelling-symbolic");
  connect_header_action(self, self->refresh_button, "refresh");
  gtk_box_pack_start(GTK_BOX(end_box), self->refresh_button, FALSE, FALSE, 0);
  self->adaptive_search_button =
      create_header_toggle_button("system-search-symbolic");
  connect_header_action(self, self->adaptive_search_button, "search");
  gtk_box_pack_start(GTK_BOX(end_box), self->adaptive_search_button, FALSE,
                     FALSE, 0);
  self->adaptive_menu_button = create_model_menu_button(
      G_MENU_MODEL(self->main_menu_model), "open-menu-symbolic",
      &self->adaptive_menu);
  gtk_box_pack_start(GTK_BOX(end_box), self->adaptive_menu_button, FALSE, FALSE,
                     0);
  gtk_header_bar_pack_end(self->header_bar, end_box);

  gtk_box_pack_start(GTK_BOX(self->titlebar_box), GTK_WIDGET(self->header_bar),
                     TRUE, TRUE, 0);
  update_titlebar_direction(self);
  set_view_mode(self, "split");
  set_document_controls_visible(self, FALSE);
  set_sidebar_visible(self, TRUE);
  set_back_visible(self, FALSE);
  refresh_header_bar_css(self);
  return self->titlebar_box;
}

static GtkWidget* create_busymark_titlebar_overlay(MyApplication* self) {
  self->titlebar_overlay = gtk_overlay_new();
  gtk_widget_set_halign(self->titlebar_overlay, GTK_ALIGN_FILL);
  gtk_widget_set_valign(self->titlebar_overlay, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->titlebar_overlay, TRUE);
  // The titlebar is packed as a fixed-height row above the Flutter view.
  // Prevent expansion requests from overlay children from turning it into a
  // second vertically expanding application surface.
  gtk_widget_set_vexpand(self->titlebar_overlay, FALSE);
  gtk_container_add(GTK_CONTAINER(self->titlebar_overlay),
                    create_busymark_titlebar(self));

  // A real overlay is the GTK equivalent of Flutter's modal barrier. Painting
  // only the header backgrounds leaves descendant icons and button surfaces
  // above the scrim.
  self->modal_scrim = gtk_event_box_new();
  gtk_event_box_set_visible_window(GTK_EVENT_BOX(self->modal_scrim), TRUE);
  gtk_widget_set_halign(self->modal_scrim, GTK_ALIGN_FILL);
  gtk_widget_set_valign(self->modal_scrim, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->modal_scrim, TRUE);
  // GTK_ALIGN_FILL gives the scrim the overlay's full allocation. Asking it
  // to expand vertically instead propagates through GtkOverlay and
  // HdyWindowHandle when the scrim becomes visible, making the header consume
  // the window's spare height.
  gtk_widget_set_vexpand(self->modal_scrim, FALSE);
  gtk_widget_add_events(self->modal_scrim, GDK_ALL_EVENTS_MASK);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->modal_scrim),
                              "busymark-modal-scrim");
  // Keep the header subtree visually enabled beneath the modal tint. The
  // overlay owns pointer input while visible and consumes it here so events
  // cannot bubble into HdyWindowHandle's drag and window-menu handlers.
  g_signal_connect(self->modal_scrim, "event",
                   G_CALLBACK(stop_modal_scrim_event), nullptr);
  set_widget_visible(self->modal_scrim, FALSE);
  gtk_overlay_add_overlay(GTK_OVERLAY(self->titlebar_overlay),
                          self->modal_scrim);
  gtk_overlay_set_overlay_pass_through(GTK_OVERLAY(self->titlebar_overlay),
                                       self->modal_scrim, FALSE);
  return self->titlebar_overlay;
}

static void header_bar_method_call_cb(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  if (strcmp(method, "initialize") == 0) {
    respond_bool(method_call,
                 begin_header_configuration_session(self, args) &&
                     has_header_bar(self));
  } else if (strcmp(method, "applyConfiguration") == 0) {
    HeaderBarConfiguration configuration = {};
    if (!decode_header_bar_configuration(args, &configuration)) {
      respond_invalid_configuration(
          method_call,
          "applyConfiguration requires a complete, typed header snapshot");
    } else if (g_strcmp0(configuration.session_id,
                         self->header_configuration_session_id) != 0) {
      respond_invalid_configuration(
          method_call,
          "applyConfiguration requires the active Dart session");
    } else if (configuration.revision <=
               self->header_configuration_revision) {
      respond_int64(method_call, self->header_configuration_revision);
    } else {
      apply_header_bar_configuration(self, configuration);
      respond_int64(method_call, self->header_configuration_revision);
    }
  } else if (strcmp(method, "setTitleRange") == 0) {
    const gchar* value = fl_method_string_arg(args);
    if (self->title_label != nullptr && GTK_IS_LABEL(self->title_label) &&
        value != nullptr) {
      gtk_label_set_text(GTK_LABEL(self->title_label), value);
    }
    respond_success(method_call);
  } else if (strcmp(method, "setViewMode") == 0) {
    set_view_mode(self, fl_method_string_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setCanRefresh") == 0) {
    set_widget_sensitive(self->refresh_button, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setDocumentControlsVisible") == 0) {
    set_document_controls_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSearchActive") == 0) {
    set_search_active(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "focusSearch") == 0) {
    respond_bool(method_call, focus_search_entry(self));
  } else if (strcmp(method, "setSearchQuery") == 0) {
    set_search_query(self, fl_method_string_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarVisible") == 0) {
    set_sidebar_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarToggleVisible") == 0) {
    set_sidebar_toggle_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSearchVisible") == 0) {
    set_search_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarWidth") == 0) {
    set_sidebar_width(self, fl_method_double_arg(args, 300));
    respond_success(method_call);
  } else if (strcmp(method, "setTextDirection") == 0) {
    set_text_direction(self, fl_method_string_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setBackVisible") == 0) {
    set_back_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setLocalizedLabels") == 0) {
    set_localized_labels(self, args);
    respond_success(method_call);
  } else if (strcmp(method, "setTheme") == 0) {
    set_header_bar_theme(self, args);
    respond_success(method_call);
  } else if (strcmp(method, "setModalBarrierVisible") == 0) {
    set_modal_barrier_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setModalBarrierDepth") == 0) {
    set_modal_barrier_depth(self, fl_method_int_arg(args, 0));
    respond_success(method_call);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void register_header_bar_channel(MyApplication* self, FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->header_bar_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kHeaderBarChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->header_bar_channel, header_bar_method_call_cb, self, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
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

  self->titlebar_handle = hdy_window_handle_new();
  gtk_widget_set_hexpand(self->titlebar_handle, TRUE);
  gtk_widget_set_vexpand(self->titlebar_handle, FALSE);
  gtk_container_add(GTK_CONTAINER(self->titlebar_handle),
                    create_busymark_titlebar_overlay(self));
  gtk_widget_show_all(self->titlebar_handle);

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  self->flutter_view = GTK_WIDGET(view);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));

  GtkWidget* window_content = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_box_pack_start(GTK_BOX(window_content), self->titlebar_handle, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(window_content), GTK_WIDGET(view), TRUE, TRUE, 0);
  gtk_widget_show(window_content);
  gtk_container_add(GTK_CONTAINER(window), window_content);

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  register_header_bar_channel(self, view);

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

  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    g_signal_connect_object(settings, "notify::gtk-theme-name",
                            G_CALLBACK(gtk_theme_name_changed_cb), application,
                            G_CONNECT_DEFAULT);
  }
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  GdkScreen* screen = gdk_screen_get_default();
  if (screen != nullptr) {
    if (self->header_bar_css_provider != nullptr) {
      gtk_style_context_remove_provider_for_screen(
          screen, GTK_STYLE_PROVIDER(self->header_bar_css_provider));
    }
  }
  g_clear_object(&self->header_bar_css_provider);
  g_clear_object(&self->header_bar_channel);
  g_clear_object(&self->main_menu_model);
  g_clear_object(&self->view_mode_menu_model);
  g_clear_object(&self->view_mode_action);
  g_clear_object(&self->header_action_group);
  g_clear_pointer(&self->background_color, g_free);
  g_clear_pointer(&self->sidebar_background_color, g_free);
  g_clear_pointer(&self->sidebar_border_color, g_free);
  g_clear_pointer(&self->modal_barrier_color, g_free);
  g_clear_pointer(&self->view_mode, g_free);
  g_clear_pointer(&self->search_query, g_free);
  g_clear_pointer(&self->foreground_color, g_free);
  g_clear_pointer(&self->header_configuration_session_id, g_free);
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

static void my_application_init(MyApplication* self) {
  self->dart_entrypoint_arguments = nullptr;
  self->header_bar_channel = nullptr;
  self->header_bar_css_provider = nullptr;
  self->main_window = nullptr;
  self->flutter_view = nullptr;
  self->titlebar_handle = nullptr;
  self->titlebar_box = nullptr;
  self->titlebar_overlay = nullptr;
  self->modal_scrim = nullptr;
  self->header_bar = nullptr;
  self->sidebar_header_box = nullptr;
  self->sidebar_search_button = nullptr;
  self->sidebar_title_label = nullptr;
  self->sidebar_menu_button = nullptr;
  self->sidebar_menu = nullptr;
  self->main_menu_model = nullptr;
  self->header_start_box = nullptr;
  self->back_button = nullptr;
  self->sidebar_toggle_button = nullptr;
  self->title_stack = nullptr;
  self->title_label = nullptr;
  self->search_entry = nullptr;
  self->document_controls_visible = FALSE;
  self->search_visible = TRUE;
  self->view_mode_box = nullptr;
  self->view_mode_button = nullptr;
  self->view_mode_icon = nullptr;
  self->view_mode_menu = nullptr;
  self->view_mode_menu_model = nullptr;
  self->refresh_button = nullptr;
  self->adaptive_search_button = nullptr;
  self->adaptive_menu_button = nullptr;
  self->adaptive_menu = nullptr;
  self->header_action_group = nullptr;
  self->view_mode_action = nullptr;
  self->view_mode = nullptr;
  self->search_query = g_strdup("");
  self->background_color = g_strdup(kDefaultHeaderbarBackground);
  self->sidebar_background_color = g_strdup(kDefaultSidebarBackground);
  self->foreground_color = g_strdup(kDefaultForeground);
  self->sidebar_border_color = nullptr;
  self->modal_barrier_color = nullptr;
  self->sidebar_width = 300;
  self->sidebar_visible = TRUE;
  self->text_direction_rtl = FALSE;
  self->back_visible = FALSE;
  self->search_active = FALSE;
  self->modal_barrier_visible = FALSE;
  self->modal_barrier_depth = 0;
  self->suppress_header_actions = FALSE;
  self->header_configuration_session_id = nullptr;
  self->header_configuration_revision = -1;
}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  g_set_application_name(kApplicationDisplayName);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
