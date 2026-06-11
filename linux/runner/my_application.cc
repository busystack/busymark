#include "my_application.h"

#include <cairo.h>
#include <flutter_linux/flutter_linux.h>
#include <pango/pango.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

constexpr char kApplicationDisplayName[] = "BusyMark";
constexpr char kHeaderBarChannel[] = "com.busymark.app/headerbar";
constexpr gint kHeaderButtonHeight = 34;
constexpr gint kHeaderButtonRadius = 8;
constexpr gint kHeaderButtonHorizontalPadding = 8;
constexpr gint kHeaderButtonSpacing = 6;
constexpr gint kHeaderSidebarInset = 6;
constexpr gint kHeaderWindowRadius = 8;
constexpr gint kHeaderTooltipVerticalPadding = 5;
constexpr gint kHeaderTooltipHorizontalPadding = 8;
constexpr char kDefaultHeaderbarBackground[] = "#242424";
constexpr char kDefaultSidebarBackground[] = "#303030";

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* header_bar_channel;
  GtkCssProvider* header_bar_css_provider;
  GtkWindow* main_window;
  GtkWidget* flutter_view;
  GtkWidget* titlebar_box;
  GtkHeaderBar* header_bar;
  GtkWidget* sidebar_header_box;
  GtkWidget* sidebar_search_button;
  GtkWidget* sidebar_title_label;
  GtkWidget* sidebar_menu_button;
  GtkWidget* sidebar_menu;
  GtkWidget* export_item;
  GtkWidget* settings_item;
  GtkWidget* about_item;
  GtkWidget* header_start_box;
  GtkWidget* back_button;
  GtkWidget* sidebar_toggle_button;
  GtkWidget* title_label;
  GtkWidget* view_mode_box;
  GtkWidget* view_mode_button;
  GtkWidget* view_mode_label;
  GtkWidget* view_mode_menu;
  GtkWidget* view_mode_editor_item;
  GtkWidget* view_mode_source_item;
  GtkWidget* view_mode_preview_item;
  GtkWidget* view_mode_split_item;
  GtkWidget* save_button;
  GtkWidget* refresh_button;
  gchar* view_mode;
  gchar* background_color;
  gchar* sidebar_background_color;
  gchar* foreground_color;
  gchar* muted_foreground_color;
  gchar* disabled_foreground_color;
  gchar* control_color;
  gchar* control_hover_color;
  gchar* control_active_color;
  gchar* accent_color;
  gchar* accent_foreground_color;
  gchar* popover_background_color;
  gchar* border_color;
  gchar* sidebar_border_color;
  gchar* shade_color;
  gchar* modal_barrier_color;
  gint sidebar_width;
  gboolean sidebar_visible;
  gboolean back_visible;
  gboolean modal_barrier_visible;
  gboolean suppress_header_actions;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void respond_success(FlMethodCall* method_call) {
  g_autoptr(FlValue) result = fl_value_new_null();
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void respond_bool(FlMethodCall* method_call, gboolean value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  fl_method_call_respond_success(method_call, result, nullptr);
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

static void set_css_color_field(gchar** target, const gchar* value) {
  if (!is_css_color_token(value)) {
    return;
  }
  g_free(*target);
  *target = g_strdup(value);
}

static void set_widget_visible(GtkWidget* widget, gboolean visible) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_visible(widget, visible);
  }
}

static void set_widget_sensitive(GtkWidget* widget, gboolean sensitive) {
  if (widget != nullptr && GTK_IS_WIDGET(widget)) {
    gtk_widget_set_sensitive(widget, sensitive);
  }
}

static void set_save_dirty(MyApplication* self, gboolean dirty) {
  if (self->save_button == nullptr || !GTK_IS_WIDGET(self->save_button)) {
    return;
  }
  GtkStyleContext* context = gtk_widget_get_style_context(self->save_button);
  if (dirty) {
    gtk_style_context_add_class(context, "busymark-save-dirty");
  } else {
    gtk_style_context_remove_class(context, "busymark-save-dirty");
  }
  gtk_widget_set_sensitive(self->save_button, TRUE);
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

static void update_sidebar_header_geometry(MyApplication* self) {
  if (self->sidebar_header_box == nullptr ||
      !GTK_IS_WIDGET(self->sidebar_header_box)) {
    return;
  }
  const gint width = self->sidebar_visible ? self->sidebar_width : 0;
  gtk_widget_set_size_request(self->sidebar_header_box, width, -1);
  set_widget_visible(self->sidebar_header_box, width > 0);
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
      css_color_or(self->foreground_color, "rgba(255,255,255,0.92)");
  const gchar* muted =
      css_color_or(self->muted_foreground_color, "rgba(255,255,255,0.70)");
  const gchar* disabled =
      css_color_or(self->disabled_foreground_color, "rgba(255,255,255,0.38)");
  const gchar* control =
      css_color_or(self->control_color, "rgba(255,255,255,0.10)");
  const gchar* control_hover =
      css_color_or(self->control_hover_color, "rgba(255,255,255,0.14)");
  const gchar* control_active =
      css_color_or(self->control_active_color, "rgba(255,255,255,0.18)");
  const gchar* accent = css_color_or(self->accent_color, "#3584e4");
  const gchar* accent_foreground =
      css_color_or(self->accent_foreground_color, "#ffffff");
  const gchar* popover =
      css_color_or(self->popover_background_color, background);
  const gchar* border =
      css_color_or(self->border_color, "rgba(255,255,255,0.10)");
  const gchar* sidebar_border =
      css_color_or(self->sidebar_border_color, border);
  const gchar* shade = css_color_or(self->shade_color, "rgba(0,0,0,0.28)");
  const gchar* modal =
      css_color_or(self->modal_barrier_color, "rgba(0,0,0,0.32)");
  const gint headerbar_left_radius =
      self->sidebar_visible ? 0 : kHeaderWindowRadius;

  gtk_style_context_add_class(gtk_widget_get_style_context(self->titlebar_box),
                              "busymark-titlebar");
  gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(self->header_bar)),
                              "busymark-headerbar");

  g_autofree gchar* css = g_strdup_printf(
      "window#busymark-window,"
      "window#busymark-window:backdrop {"
      "background-color: transparent;"
      "background-image: none;"
      "}"
      "window#busymark-window decoration,"
      "window#busymark-window decoration:backdrop {"
      "background-color: transparent;"
      "background-image: none;"
      "border: none;"
      "outline: none;"
      "border-radius: %dpx;"
      "box-shadow: 0 3px 18px 2px %s;"
      "}"
      ".busymark-titlebar,"
      ".busymark-titlebar:backdrop,"
      "headerbar.busymark-headerbar,"
      "headerbar.busymark-headerbar:backdrop {"
      "background-color: %s;"
      "background-image: none;"
      "border: none;"
      "box-shadow: none;"
      "border-top-left-radius: %dpx;"
      "border-top-right-radius: %dpx;"
      "}"
      "headerbar.busymark-headerbar,"
      "headerbar.busymark-headerbar:backdrop {"
      "border-top-left-radius: %dpx;"
      "padding-left: 0;"
      "}"
      ".busymark-sidebar-header {"
      "background-color: %s;"
      "background-image: none;"
      "border: none;"
      "border-right: 1px solid %s;"
      "box-shadow: none;"
      "border-top-left-radius: %dpx;"
      "border-top-right-radius: 0;"
      "}"
      ".busymark-sidebar-header label,"
      ".busymark-header-title {"
      "color: %s;"
      "}"
      ".busymark-titlebar.busymark-modal-barrier,"
      ".busymark-titlebar.busymark-modal-barrier .busymark-sidebar-header,"
      ".busymark-titlebar.busymark-modal-barrier headerbar.busymark-headerbar {"
      "background-image: linear-gradient(%s, %s);"
      "}"
      ".busymark-titlebar button.busymark-header-button,"
      ".busymark-titlebar button.busymark-view-mode-button {"
      "color: %s;"
      "background-color: %s;"
      "background-image: none;"
      "border: none;"
      "border-width: 0;"
      "border-color: transparent;"
      "box-shadow: 0 1px 1px %s;"
      "text-shadow: none;"
      "-gtk-icon-shadow: none;"
      "outline-style: none;"
      "transition: none;"
      "min-height: %dpx;"
      "min-width: %dpx;"
      "padding: 0 %dpx;"
      "border-radius: %dpx;"
      "}"
      ".busymark-titlebar button.busymark-header-icon-button {"
      "min-width: %dpx;"
      "padding-left: 0;"
      "padding-right: 0;"
      "}"
      ".busymark-titlebar button.busymark-header-button:hover,"
      ".busymark-titlebar button.busymark-view-mode-button:hover {"
      "background-color: %s;"
      "}"
      ".busymark-titlebar button.busymark-header-button:active,"
      ".busymark-titlebar button.busymark-header-button:checked,"
      ".busymark-titlebar button.busymark-view-mode-button:active,"
      ".busymark-titlebar button.busymark-view-mode-button:checked {"
      "background-color: %s;"
      "}"
      ".busymark-titlebar button.busymark-save-button.busymark-save-dirty,"
      ".busymark-titlebar button.busymark-save-button.busymark-save-dirty:hover,"
      ".busymark-titlebar button.busymark-save-button.busymark-save-dirty:active,"
      ".busymark-titlebar button.busymark-save-button.busymark-save-dirty:checked {"
      "color: %s;"
      "background-color: %s;"
      "}"
      ".busymark-titlebar button.busymark-save-button.busymark-save-dirty image {"
      "color: %s;"
      "-gtk-icon-shadow: none;"
      "}"
      ".busymark-titlebar button.busymark-header-button:disabled,"
      ".busymark-titlebar button.busymark-view-mode-button:disabled {"
      "color: %s;"
      "background-color: transparent;"
      "box-shadow: none;"
      "}"
      ".busymark-titlebar.busymark-modal-barrier label,"
      ".busymark-titlebar.busymark-modal-barrier button,"
      ".busymark-titlebar.busymark-modal-barrier button image {"
      "color: %s;"
      "text-shadow: none;"
      "-gtk-icon-shadow: none;"
      "}"
      "popover.busymark-header-popover,"
      "popover.background.busymark-header-popover,"
      "popover.background.busymark-header-popover > contents,"
      "popover.background.busymark-header-popover arrow {"
      "background-color: %s;"
      "color: %s;"
      "}"
      "popover.busymark-header-popover > contents {"
      "border: 1px solid %s;"
      "box-shadow: 0 6px 18px %s;"
      "}"
      "popover.busymark-header-popover button.busymark-menu-row {"
      "color: %s;"
      "background-color: transparent;"
      "background-image: none;"
      "border: none;"
      "border-width: 0;"
      "border-color: transparent;"
      "box-shadow: none;"
      "text-shadow: none;"
      "outline-style: none;"
      "outline-width: 0;"
      "outline-offset: 0;"
      "transition: none;"
      "min-height: %dpx;"
      "padding: 0 %dpx;"
      "border-radius: %dpx;"
      "}"
      "popover.busymark-header-popover button.busymark-menu-row:focus,"
      "popover.busymark-header-popover button.busymark-menu-row:active,"
      "popover.busymark-header-popover button.busymark-menu-row:checked {"
      "border: none;"
      "border-width: 0;"
      "border-color: transparent;"
      "box-shadow: none;"
      "outline-style: none;"
      "outline-width: 0;"
      "outline-offset: 0;"
      "text-shadow: none;"
      "}"
      "popover.busymark-header-popover button.busymark-menu-row:hover {"
      "background-color: %s;"
      "}"
      "popover.busymark-header-popover button.busymark-menu-row label {"
      "color: %s;"
      "}"
      "popover.busymark-header-popover button.busymark-menu-row image {"
      "color: %s;"
      "}"
      "tooltip, tooltip.background {"
      "margin: 0;"
      "padding: 0;"
      "min-height: 0;"
      "border-radius: %dpx;"
      "}"
      "tooltip > box, tooltip.background > box {"
      "margin: 0;"
      "padding: 0;"
      "min-height: 0;"
      "}"
      "tooltip label {"
      "margin: 0;"
      "padding: %dpx %dpx;"
      "min-height: 0;"
      "border-radius: %dpx;"
      "}",
      kHeaderWindowRadius, shade, background, kHeaderWindowRadius,
      kHeaderWindowRadius, headerbar_left_radius, sidebar_background,
      sidebar_border, kHeaderWindowRadius, foreground, modal, modal,
      foreground, control, shade, kHeaderButtonHeight, kHeaderButtonHeight,
      kHeaderButtonHorizontalPadding, kHeaderButtonRadius, kHeaderButtonHeight,
      control_hover, control_active, accent_foreground, accent,
      accent_foreground, disabled, disabled, popover, foreground,
      border, shade, foreground, kHeaderButtonHeight,
      kHeaderButtonHorizontalPadding, kHeaderButtonRadius, control_hover,
      foreground, muted, kHeaderButtonRadius, kHeaderTooltipVerticalPadding,
      kHeaderTooltipHorizontalPadding, kHeaderButtonRadius);

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

static void set_header_bar_theme(MyApplication* self, FlValue* args) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return;
  }
  set_css_color_field(&self->background_color,
                      fl_lookup_string_arg(args, "backgroundColor"));
  set_css_color_field(&self->sidebar_background_color,
                      fl_lookup_string_arg(args, "sidebarBackgroundColor"));
  set_css_color_field(&self->foreground_color,
                      fl_lookup_string_arg(args, "foregroundColor"));
  set_css_color_field(&self->muted_foreground_color,
                      fl_lookup_string_arg(args, "mutedForegroundColor"));
  set_css_color_field(&self->disabled_foreground_color,
                      fl_lookup_string_arg(args, "disabledForegroundColor"));
  set_css_color_field(&self->control_color,
                      fl_lookup_string_arg(args, "controlColor"));
  set_css_color_field(&self->control_hover_color,
                      fl_lookup_string_arg(args, "controlHoverColor"));
  set_css_color_field(&self->control_active_color,
                      fl_lookup_string_arg(args, "controlActiveColor"));
  set_css_color_field(&self->accent_color,
                      fl_lookup_string_arg(args, "accentColor"));
  set_css_color_field(&self->accent_foreground_color,
                      fl_lookup_string_arg(args, "accentForegroundColor"));
  set_css_color_field(&self->popover_background_color,
                      fl_lookup_string_arg(args, "popoverBackgroundColor"));
  set_css_color_field(&self->border_color,
                      fl_lookup_string_arg(args, "borderColor"));
  set_css_color_field(&self->sidebar_border_color,
                      fl_lookup_string_arg(args, "sidebarBorderColor"));
  set_css_color_field(&self->shade_color,
                      fl_lookup_string_arg(args, "shadeColor"));
  set_css_color_field(&self->modal_barrier_color,
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
  if (self->header_bar_channel == nullptr || action == nullptr) {
    return;
  }
  fl_method_channel_invoke_method(self->header_bar_channel, action, nullptr,
                                  nullptr, nullptr, nullptr);
}

static void header_button_clicked_cb(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->suppress_header_actions) {
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

static void make_icon_button_square(GtkWidget* button) {
  gtk_widget_set_size_request(button, kHeaderButtonHeight,
                              kHeaderButtonHeight);
  gtk_widget_set_valign(button, GTK_ALIGN_CENTER);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-icon-button");
}

static GtkWidget* create_header_icon_button(const gchar* icon_name) {
  GtkWidget* button = gtk_button_new();
  GtkWidget* image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_MENU);
  gtk_button_set_image(GTK_BUTTON(button), image);
  gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-button");
  make_icon_button_square(button);
  return button;
}

static GtkWidget* create_header_toggle_button(const gchar* icon_name) {
  GtkWidget* button = gtk_toggle_button_new();
  GtkWidget* image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_MENU);
  gtk_button_set_image(GTK_BUTTON(button), image);
  gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-button");
  make_icon_button_square(button);
  return button;
}

static GtkWidget* create_header_popover() {
  GtkWidget* popover = gtk_popover_menu_new();
  gtk_popover_set_position(GTK_POPOVER(popover), GTK_POS_BOTTOM);
  gtk_style_context_add_class(gtk_widget_get_style_context(popover),
                              "busymark-header-popover");
  return popover;
}

static GtkWidget* create_popover_box(GtkWidget* popover) {
  GtkWidget* box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_widget_set_margin_top(box, kHeaderButtonSpacing);
  gtk_widget_set_margin_bottom(box, kHeaderButtonSpacing);
  gtk_widget_set_margin_start(box, kHeaderButtonSpacing);
  gtk_widget_set_margin_end(box, kHeaderButtonSpacing);
  gtk_container_add(GTK_CONTAINER(popover), box);
  return box;
}

static void close_menu_button(GtkWidget* button) {
  if (button == nullptr || !GTK_IS_MENU_BUTTON(button)) {
    return;
  }
  GtkPopover* popover = gtk_menu_button_get_popover(GTK_MENU_BUTTON(button));
  if (popover != nullptr && GTK_IS_POPOVER(popover)) {
    gtk_popover_popdown(popover);
  }
}

static void menu_item_clicked_cb(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* action = static_cast<const gchar*>(
      g_object_get_data(G_OBJECT(widget), "busymark-action"));
  close_menu_button(self->sidebar_menu_button);
  focus_flutter_view(self);
  invoke_header_bar_action(self, action);
}

static GtkWidget* create_menu_item(MyApplication* self, const gchar* action) {
  GtkWidget* item = gtk_button_new();
  GtkWidget* box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  GtkWidget* check =
      gtk_image_new_from_icon_name("object-select-symbolic", GTK_ICON_SIZE_MENU);
  GtkWidget* label = gtk_label_new("");
  gtk_widget_set_opacity(check, 0.0);
  gtk_label_set_xalign(GTK_LABEL(label), 0.0);
  gtk_widget_set_hexpand(label, TRUE);
  gtk_box_pack_start(GTK_BOX(box), check, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);
  gtk_container_add(GTK_CONTAINER(item), box);
  gtk_button_set_relief(GTK_BUTTON(item), GTK_RELIEF_NONE);
  gtk_widget_set_halign(item, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(item, TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(item),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(item),
                              "busymark-menu-row");
  g_object_set_data(G_OBJECT(item), "busymark-label-widget", label);
  g_object_set_data(G_OBJECT(item), "busymark-check-widget", check);
  g_object_set_data_full(G_OBJECT(item), "busymark-action",
                         g_strdup(action), g_free);
  g_signal_connect(item, "clicked", G_CALLBACK(menu_item_clicked_cb), self);
  return item;
}

static const gchar* view_mode_action(const gchar* mode) {
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

static GtkWidget* view_mode_item(MyApplication* self, const gchar* mode) {
  if (g_strcmp0(mode, "editor") == 0) {
    return self->view_mode_editor_item;
  }
  if (g_strcmp0(mode, "source") == 0) {
    return self->view_mode_source_item;
  }
  if (g_strcmp0(mode, "preview") == 0) {
    return self->view_mode_preview_item;
  }
  if (g_strcmp0(mode, "split") == 0) {
    return self->view_mode_split_item;
  }
  return nullptr;
}

static const gchar* menu_item_label(GtkWidget* item) {
  if (item == nullptr) {
    return "";
  }
  GtkWidget* label = static_cast<GtkWidget*>(
      g_object_get_data(G_OBJECT(item), "busymark-label-widget"));
  if (label != nullptr && GTK_IS_LABEL(label)) {
    return gtk_label_get_text(GTK_LABEL(label));
  }
  return "";
}

static void set_menu_item_label(GtkWidget* item, const gchar* text) {
  if (item == nullptr || text == nullptr) {
    return;
  }
  GtkWidget* label = static_cast<GtkWidget*>(
      g_object_get_data(G_OBJECT(item), "busymark-label-widget"));
  if (label != nullptr && GTK_IS_LABEL(label)) {
    gtk_label_set_text(GTK_LABEL(label), text);
  }
}

static void set_menu_item_checked(GtkWidget* item, gboolean checked) {
  if (item == nullptr) {
    return;
  }
  GtkWidget* check = static_cast<GtkWidget*>(
      g_object_get_data(G_OBJECT(item), "busymark-check-widget"));
  if (check != nullptr && GTK_IS_WIDGET(check)) {
    gtk_widget_set_opacity(check, checked ? 1.0 : 0.0);
  }
}

static void update_view_mode_label(MyApplication* self) {
  if (self->view_mode_label == nullptr ||
      !GTK_IS_LABEL(self->view_mode_label)) {
    return;
  }
  const gchar* mode = self->view_mode != nullptr ? self->view_mode : "split";
  gtk_label_set_text(GTK_LABEL(self->view_mode_label),
                     menu_item_label(view_mode_item(self, mode)));
}

static void set_view_mode(MyApplication* self, const gchar* mode) {
  if (view_mode_action(mode) == nullptr) {
    return;
  }
  g_free(self->view_mode);
  self->view_mode = g_strdup(mode);
  set_menu_item_checked(self->view_mode_editor_item,
                        g_strcmp0(mode, "editor") == 0);
  set_menu_item_checked(self->view_mode_source_item,
                        g_strcmp0(mode, "source") == 0);
  set_menu_item_checked(self->view_mode_preview_item,
                        g_strcmp0(mode, "preview") == 0);
  set_menu_item_checked(self->view_mode_split_item,
                        g_strcmp0(mode, "split") == 0);
  update_view_mode_label(self);
}

static void view_mode_clicked_cb(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* mode = static_cast<const gchar*>(
      g_object_get_data(G_OBJECT(widget), "busymark-view-mode"));
  const gchar* action = view_mode_action(mode);
  if (action == nullptr) {
    return;
  }
  set_view_mode(self, mode);
  close_menu_button(self->view_mode_button);
  focus_flutter_view(self);
  invoke_header_bar_action(self, action);
}

static GtkWidget* create_view_mode_item(MyApplication* self,
                                        const gchar* mode) {
  GtkWidget* item = gtk_button_new();
  GtkWidget* box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  GtkWidget* check =
      gtk_image_new_from_icon_name("object-select-symbolic", GTK_ICON_SIZE_MENU);
  GtkWidget* label = gtk_label_new("");
  gtk_widget_set_opacity(check, 0.0);
  gtk_label_set_xalign(GTK_LABEL(label), 0.0);
  gtk_widget_set_hexpand(label, TRUE);
  gtk_box_pack_start(GTK_BOX(box), check, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);
  gtk_container_add(GTK_CONTAINER(item), box);
  gtk_button_set_relief(GTK_BUTTON(item), GTK_RELIEF_NONE);
  gtk_widget_set_halign(item, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(item, TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(item),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(item),
                              "busymark-menu-row");
  g_object_set_data(G_OBJECT(item), "busymark-label-widget", label);
  g_object_set_data(G_OBJECT(item), "busymark-check-widget", check);
  g_object_set_data_full(G_OBJECT(item), "busymark-view-mode",
                         g_strdup(mode), g_free);
  g_signal_connect(item, "clicked", G_CALLBACK(view_mode_clicked_cb), self);
  return item;
}

static GtkWidget* create_menu_button(GtkWidget* popover,
                                     const gchar* icon_name) {
  GtkWidget* button = gtk_menu_button_new();
  gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
  gtk_button_set_image(GTK_BUTTON(button),
                       gtk_image_new_from_icon_name(icon_name,
                                                    GTK_ICON_SIZE_MENU));
  gtk_menu_button_set_use_popover(GTK_MENU_BUTTON(button), TRUE);
  gtk_menu_button_set_popover(GTK_MENU_BUTTON(button), popover);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "busymark-header-button");
  make_icon_button_square(button);
  return button;
}

static void set_widget_tooltip(GtkWidget* widget, const gchar* tooltip) {
  if (widget != nullptr && GTK_IS_WIDGET(widget) && tooltip != nullptr) {
    gtk_widget_set_tooltip_text(widget, tooltip);
  }
}

static void set_localized_labels(MyApplication* self, FlValue* args) {
  const gchar* editor = fl_lookup_string_arg(args, "editor");
  const gchar* source = fl_lookup_string_arg(args, "source");
  const gchar* preview = fl_lookup_string_arg(args, "preview");
  const gchar* split = fl_lookup_string_arg(args, "split");
  const gchar* view_mode = fl_lookup_string_arg(args, "viewMode");
  const gchar* search = fl_lookup_string_arg(args, "search");
  const gchar* refresh = fl_lookup_string_arg(args, "refresh");
  const gchar* menu = fl_lookup_string_arg(args, "menu");
  const gchar* sidebar = fl_lookup_string_arg(args, "sidebar");
  const gchar* back = fl_lookup_string_arg(args, "back");
  const gchar* save = fl_lookup_string_arg(args, "save");
  const gchar* settings = fl_lookup_string_arg(args, "settings");
  const gchar* about = fl_lookup_string_arg(args, "aboutBusyMark");
  const gchar* export_preview = fl_lookup_string_arg(args, "exportPreview");

  set_widget_tooltip(self->back_button, back);
  set_widget_tooltip(self->sidebar_toggle_button, sidebar);
  set_widget_tooltip(self->sidebar_search_button, search);
  set_widget_tooltip(self->sidebar_menu_button, menu);
  set_widget_tooltip(self->refresh_button, refresh);
  set_widget_tooltip(self->save_button, save);
  set_widget_tooltip(self->view_mode_button, view_mode);
  set_menu_item_label(self->view_mode_editor_item, editor);
  set_menu_item_label(self->view_mode_source_item, source);
  set_menu_item_label(self->view_mode_preview_item, preview);
  set_menu_item_label(self->view_mode_split_item, split);
  set_menu_item_label(self->export_item, export_preview);
  set_menu_item_label(self->settings_item, settings);
  set_menu_item_label(self->about_item, about);
  update_view_mode_label(self);
}

static void set_modal_barrier_visible(MyApplication* self, gboolean visible) {
  self->modal_barrier_visible = visible;
  if (self->titlebar_box != nullptr && GTK_IS_WIDGET(self->titlebar_box)) {
    GtkStyleContext* context = gtk_widget_get_style_context(self->titlebar_box);
    if (visible) {
      gtk_style_context_add_class(context, "busymark-modal-barrier");
    } else {
      gtk_style_context_remove_class(context, "busymark-modal-barrier");
    }
    gtk_widget_set_sensitive(self->titlebar_box, !visible);
  }
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

static void set_back_visible(MyApplication* self, gboolean visible) {
  self->back_visible = visible;
  set_widget_visible(self->back_button, visible);
}

static void set_document_controls_visible(MyApplication* self,
                                          gboolean visible) {
  set_widget_visible(self->save_button, visible);
  set_widget_visible(self->refresh_button, visible);
  set_widget_visible(self->view_mode_box, visible);
}

static GtkWidget* create_busymark_titlebar(MyApplication* self) {
  self->titlebar_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_halign(self->titlebar_box, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->titlebar_box, TRUE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->titlebar_box),
                              "busymark-titlebar");

  self->sidebar_header_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  gtk_widget_set_halign(self->sidebar_header_box, GTK_ALIGN_FILL);
  gtk_widget_set_hexpand(self->sidebar_header_box, FALSE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_header_box),
                              "busymark-sidebar-header");

  self->sidebar_search_button = create_header_toggle_button("system-search-symbolic");
  gtk_widget_set_margin_start(self->sidebar_search_button, kHeaderSidebarInset);
  connect_header_action(self, self->sidebar_search_button, "search");
  gtk_box_pack_start(GTK_BOX(self->sidebar_header_box),
                     self->sidebar_search_button, FALSE, FALSE, 0);

  GtkWidget* sidebar_title_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  gtk_widget_set_hexpand(sidebar_title_box, TRUE);
  gtk_widget_set_halign(sidebar_title_box, GTK_ALIGN_CENTER);
  self->sidebar_title_label = gtk_label_new(kApplicationDisplayName);
  gtk_label_set_ellipsize(GTK_LABEL(self->sidebar_title_label),
                          PANGO_ELLIPSIZE_END);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->sidebar_title_label),
                              GTK_STYLE_CLASS_TITLE);
  gtk_box_pack_start(GTK_BOX(sidebar_title_box), self->sidebar_title_label,
                     FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(self->sidebar_header_box), sidebar_title_box,
                     TRUE, TRUE, 0);

  self->sidebar_menu = create_header_popover();
  GtkWidget* sidebar_menu_box = create_popover_box(self->sidebar_menu);
  self->export_item = create_menu_item(self, "exportPreview");
  self->settings_item = create_menu_item(self, "settings");
  self->about_item = create_menu_item(self, "aboutBusyMark");
  gtk_box_pack_start(GTK_BOX(sidebar_menu_box), self->export_item, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(sidebar_menu_box), self->settings_item, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(sidebar_menu_box), self->about_item, FALSE,
                     FALSE, 0);
  gtk_widget_show_all(sidebar_menu_box);
  self->sidebar_menu_button =
      create_menu_button(self->sidebar_menu, "open-menu-symbolic");
  gtk_widget_set_margin_end(self->sidebar_menu_button, kHeaderSidebarInset);
  gtk_box_pack_end(GTK_BOX(self->sidebar_header_box),
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
  gtk_widget_set_margin_start(self->header_start_box, kHeaderSidebarInset);
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

  self->title_label = gtk_label_new("");
  gtk_label_set_ellipsize(GTK_LABEL(self->title_label), PANGO_ELLIPSIZE_END);
  gtk_label_set_max_width_chars(GTK_LABEL(self->title_label), 48);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->title_label),
                              "busymark-header-title");
  gtk_header_bar_set_custom_title(self->header_bar, self->title_label);

  GtkWidget* end_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  self->view_mode_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  self->view_mode_menu = create_header_popover();
  GtkWidget* view_menu_box = create_popover_box(self->view_mode_menu);
  self->view_mode_editor_item = create_view_mode_item(self, "editor");
  self->view_mode_source_item = create_view_mode_item(self, "source");
  self->view_mode_preview_item = create_view_mode_item(self, "preview");
  self->view_mode_split_item = create_view_mode_item(self, "split");
  gtk_box_pack_start(GTK_BOX(view_menu_box), self->view_mode_editor_item, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(view_menu_box), self->view_mode_source_item, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(view_menu_box), self->view_mode_preview_item, FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(view_menu_box), self->view_mode_split_item, FALSE,
                     FALSE, 0);
  gtk_widget_show_all(view_menu_box);

  self->view_mode_button = gtk_menu_button_new();
  gtk_button_set_relief(GTK_BUTTON(self->view_mode_button), GTK_RELIEF_NONE);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->view_mode_button),
                              GTK_STYLE_CLASS_FLAT);
  gtk_style_context_add_class(gtk_widget_get_style_context(self->view_mode_button),
                              "busymark-header-button");
  gtk_style_context_add_class(gtk_widget_get_style_context(self->view_mode_button),
                              "busymark-view-mode-button");
  gtk_menu_button_set_use_popover(GTK_MENU_BUTTON(self->view_mode_button),
                                  TRUE);
  gtk_menu_button_set_popover(GTK_MENU_BUTTON(self->view_mode_button),
                              self->view_mode_menu);
  GtkWidget* view_button_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonSpacing);
  self->view_mode_label = gtk_label_new("");
  gtk_label_set_ellipsize(GTK_LABEL(self->view_mode_label),
                          PANGO_ELLIPSIZE_END);
  GtkWidget* view_arrow =
      gtk_image_new_from_icon_name("pan-down-symbolic", GTK_ICON_SIZE_MENU);
  gtk_box_pack_start(GTK_BOX(view_button_box), self->view_mode_label, TRUE,
                     TRUE, 0);
  gtk_box_pack_start(GTK_BOX(view_button_box), view_arrow, FALSE, FALSE, 0);
  gtk_container_add(GTK_CONTAINER(self->view_mode_button), view_button_box);
  gtk_box_pack_start(GTK_BOX(self->view_mode_box), self->view_mode_button,
                     FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(end_box), self->view_mode_box, FALSE, FALSE, 0);

  self->save_button = create_header_icon_button("emblem-ok-symbolic");
  gtk_style_context_add_class(gtk_widget_get_style_context(self->save_button),
                              "busymark-save-button");
  self->refresh_button = create_header_icon_button("tools-check-spelling-symbolic");
  connect_header_action(self, self->save_button, "save");
  connect_header_action(self, self->refresh_button, "refresh");
  gtk_box_pack_start(GTK_BOX(end_box), self->save_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(end_box), self->refresh_button, FALSE, FALSE, 0);
  gtk_header_bar_pack_end(self->header_bar, end_box);

  gtk_box_pack_start(GTK_BOX(self->titlebar_box), GTK_WIDGET(self->header_bar),
                     TRUE, TRUE, 0);
  set_view_mode(self, "split");
  set_sidebar_visible(self, TRUE);
  set_back_visible(self, FALSE);
  refresh_header_bar_css(self);
  return self->titlebar_box;
}

static void header_bar_method_call_cb(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  if (strcmp(method, "initialize") == 0) {
    respond_bool(method_call, has_header_bar(self));
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
  } else if (strcmp(method, "setCanSave") == 0) {
    set_save_dirty(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setDocumentControlsVisible") == 0) {
    set_document_controls_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSearchActive") == 0) {
    set_toggle_button_active(self, self->sidebar_search_button,
                             fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarVisible") == 0) {
    set_sidebar_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarToggleVisible") == 0) {
    set_sidebar_toggle_visible(self, fl_method_bool_arg(args));
    respond_success(method_call);
  } else if (strcmp(method, "setSidebarWidth") == 0) {
    set_sidebar_width(self, fl_method_double_arg(args, 300));
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

static gboolean clear_transparent_window_cb(GtkWidget* widget,
                                            cairo_t* cr,
                                            gpointer user_data) {
  cairo_save(cr);
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  cairo_restore(cr);
  return FALSE;
}

static cairo_region_t* create_rounded_window_region(gint width,
                                                    gint height,
                                                    gint radius) {
  cairo_region_t* region = cairo_region_create();
  if (width <= 0 || height <= 0) {
    return region;
  }

  if (radius <= 0 || width < radius * 2 || height < radius * 2) {
    const cairo_rectangle_int_t rect = {0, 0, width, height};
    cairo_region_union_rectangle(region, &rect);
    return region;
  }

  const gdouble radius_squared = radius * radius;
  for (gint y = 0; y < height; y++) {
    gint inset = 0;
    if (y < radius) {
      const gdouble dy = radius - y - 1;
      inset = radius - static_cast<gint>(std::sqrt(radius_squared - dy * dy));
    } else if (y >= height - radius) {
      const gdouble dy = y - (height - radius);
      inset = radius - static_cast<gint>(std::sqrt(radius_squared - dy * dy));
    }

    const gint row_width = width - inset * 2;
    if (row_width <= 0) {
      continue;
    }

    const cairo_rectangle_int_t row = {inset, y, row_width, 1};
    cairo_region_union_rectangle(region, &row);
  }

  return region;
}

static void configure_rounded_window_shape(GtkWidget* widget) {
  if (widget == nullptr || !GTK_IS_WIDGET(widget) ||
      !gtk_widget_get_realized(widget)) {
    return;
  }

  GdkWindow* window = gtk_widget_get_window(widget);
  if (window == nullptr || !GDK_IS_WINDOW(window)) {
    return;
  }

  const GdkWindowState state = gdk_window_get_state(window);
  if ((state & GDK_WINDOW_STATE_MAXIMIZED) != 0 ||
      (state & GDK_WINDOW_STATE_FULLSCREEN) != 0) {
    gdk_window_shape_combine_region(window, nullptr, 0, 0);
    return;
  }

  const gint width = gtk_widget_get_allocated_width(widget);
  const gint height = gtk_widget_get_allocated_height(widget);
  if (width <= 0 || height <= 0) {
    return;
  }

  cairo_region_t* region =
      create_rounded_window_region(width, height, kHeaderWindowRadius);
  gdk_window_shape_combine_region(window, region, 0, 0);
  cairo_region_destroy(region);
}

static void rounded_window_realize_cb(GtkWidget* widget, gpointer user_data) {
  configure_rounded_window_shape(widget);
}

static gboolean rounded_window_configure_event_cb(GtkWidget* widget,
                                                  GdkEventConfigure* event,
                                                  gpointer user_data) {
  configure_rounded_window_shape(widget);
  return FALSE;
}

static void configure_transparent_window_backing(GtkWindow* window) {
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr) {
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
  g_signal_connect(window, "draw", G_CALLBACK(clear_transparent_window_cb),
                   nullptr);
  g_signal_connect_after(window, "realize",
                         G_CALLBACK(rounded_window_realize_cb), nullptr);
  g_signal_connect(window, "configure-event",
                   G_CALLBACK(rounded_window_configure_event_cb), nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->main_window = window;
  gtk_widget_set_name(GTK_WIDGET(window), "busymark-window");
  configure_transparent_window_backing(window);

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkWidget* titlebar = create_busymark_titlebar(self);
    gtk_widget_show_all(titlebar);
    gtk_window_set_titlebar(window, titlebar);
  } else {
    gtk_window_set_title(window, kApplicationDisplayName);
  }

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
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

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
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  if (self->header_bar_css_provider != nullptr) {
    gtk_style_context_remove_provider_for_screen(
        gdk_screen_get_default(), GTK_STYLE_PROVIDER(self->header_bar_css_provider));
    g_clear_object(&self->header_bar_css_provider);
  }
  g_clear_object(&self->header_bar_channel);
  g_clear_pointer(&self->background_color, g_free);
  g_clear_pointer(&self->sidebar_background_color, g_free);
  g_clear_pointer(&self->foreground_color, g_free);
  g_clear_pointer(&self->muted_foreground_color, g_free);
  g_clear_pointer(&self->disabled_foreground_color, g_free);
  g_clear_pointer(&self->control_color, g_free);
  g_clear_pointer(&self->control_hover_color, g_free);
  g_clear_pointer(&self->control_active_color, g_free);
  g_clear_pointer(&self->accent_color, g_free);
  g_clear_pointer(&self->accent_foreground_color, g_free);
  g_clear_pointer(&self->popover_background_color, g_free);
  g_clear_pointer(&self->border_color, g_free);
  g_clear_pointer(&self->sidebar_border_color, g_free);
  g_clear_pointer(&self->shade_color, g_free);
  g_clear_pointer(&self->modal_barrier_color, g_free);
  g_clear_pointer(&self->view_mode, g_free);
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
  self->titlebar_box = nullptr;
  self->header_bar = nullptr;
  self->sidebar_header_box = nullptr;
  self->sidebar_search_button = nullptr;
  self->sidebar_title_label = nullptr;
  self->sidebar_menu_button = nullptr;
  self->sidebar_menu = nullptr;
  self->export_item = nullptr;
  self->settings_item = nullptr;
  self->about_item = nullptr;
  self->header_start_box = nullptr;
  self->back_button = nullptr;
  self->sidebar_toggle_button = nullptr;
  self->title_label = nullptr;
  self->view_mode_box = nullptr;
  self->view_mode_button = nullptr;
  self->view_mode_label = nullptr;
  self->view_mode_menu = nullptr;
  self->view_mode_editor_item = nullptr;
  self->view_mode_source_item = nullptr;
  self->view_mode_preview_item = nullptr;
  self->view_mode_split_item = nullptr;
  self->save_button = nullptr;
  self->refresh_button = nullptr;
  self->view_mode = nullptr;
  self->background_color = g_strdup(kDefaultHeaderbarBackground);
  self->sidebar_background_color = g_strdup(kDefaultSidebarBackground);
  self->foreground_color = nullptr;
  self->muted_foreground_color = nullptr;
  self->disabled_foreground_color = nullptr;
  self->control_color = nullptr;
  self->control_hover_color = nullptr;
  self->control_active_color = nullptr;
  self->accent_color = nullptr;
  self->accent_foreground_color = nullptr;
  self->popover_background_color = nullptr;
  self->border_color = nullptr;
  self->sidebar_border_color = nullptr;
  self->shade_color = nullptr;
  self->modal_barrier_color = nullptr;
  self->sidebar_width = 300;
  self->sidebar_visible = TRUE;
  self->back_visible = FALSE;
  self->modal_barrier_visible = FALSE;
  self->suppress_header_actions = FALSE;
}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
