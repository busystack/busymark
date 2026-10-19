// Live GTK settings-provider regression; uses only the owned bus/display
// supplied by run_portal_initialization.py. No raw input or desktop portal
// replacement. Built from the exact selected engine sources.
#include <glib-unix.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <string.h>

#include "flutter/shell/platform/linux/fl_settings.h"
#ifndef BM_SYNCHRONOUS_SETTINGS_CONTROL
#include "flutter/shell/platform/linux/fl_settings_portal.h"
#endif

static GtkWidget *window;
static GMainLoop *loop;

static void close_window() {
  if (window != nullptr) {
    gtk_window_close(GTK_WINDOW(window));
  } else {
    g_main_loop_quit(loop);
  }
}
static FlSettings *settings;
static GCancellable *cancellable;
static gboolean finalized;
static guint initialized;
static guint errors;
static guint changes;

static void snapshot(const char *event) {
  printf(
      "{\"event\":\"%s\",\"clock12\":%s,\"dark\":%s,"
      "\"animations\":%s,\"contrast\":%s,\"scale\":%.6f}\n",
      event,
      fl_settings_get_clock_format(settings) == FL_CLOCK_FORMAT_12H ? "true"
                                                                    : "false",
      fl_settings_get_color_scheme(settings) == FL_COLOR_SCHEME_DARK ? "true"
                                                                     : "false",
      fl_settings_get_enable_animations(settings) ? "true" : "false",
      fl_settings_get_high_contrast(settings) ? "true" : "false",
      fl_settings_get_text_scaling_factor(settings));
  fflush(stdout);
}

#ifndef BM_SYNCHRONOUS_SETTINGS_CONTROL
static void ready_cb(GObject *, GAsyncResult *result, gpointer) {
  g_autoptr(GError) error = nullptr;
  if (fl_settings_portal_start_finish(result, &error)) {
    ++initialized;
    snapshot("initialized");
  } else {
    ++errors;
    printf("{\"event\":\"initialization-error\",\"code\":%d,"
           "\"cancelled\":%s,\"pending\":%s}\n",
           error->code,
           g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED) ? "true"
                                                                    : "false",
           g_error_matches(error, G_IO_ERROR, G_IO_ERROR_PENDING) ? "true"
                                                                  : "false");
    fflush(stdout);
  }
}
#endif

static gboolean startup(gpointer) {
  printf("{\"event\":\"entered\"}\n");
  fflush(stdout);
#ifdef BM_SYNCHRONOUS_SETTINGS_CONTROL
  settings = fl_settings_new();
#else
  settings = g_getenv("BM_PORTAL_FACTORY") != nullptr
                 ? fl_settings_new()
                 : FL_SETTINGS(fl_settings_portal_new());
#endif
  g_object_weak_ref(
      G_OBJECT(settings), +[](gpointer, GObject *) { finalized = TRUE; },
      nullptr);
  g_signal_connect(settings, "changed", G_CALLBACK(+[](FlSettings *, gpointer) {
                     ++changes;
                     snapshot("changed");
                   }),
                   nullptr);
#ifdef BM_SYNCHRONOUS_SETTINGS_CONTROL
  ++initialized;
  snapshot("initialized");
#else
  snapshot("local");
  if (g_getenv("BM_PORTAL_FACTORY") == nullptr) {
    fl_settings_portal_start(FL_SETTINGS_PORTAL(settings), cancellable,
                             ready_cb, nullptr);
  }
#endif
  return G_SOURCE_REMOVE;
}

static gboolean command(gint, GIOCondition, gpointer) {
  char line[100];
  if (fgets(line, sizeof(line), stdin) == nullptr) {
    close_window();
    return G_SOURCE_REMOVE;
  }
  if (strncmp(line, "ping", 4) == 0) {
    printf("{\"event\":\"progress\",\"initialized\":%u,\"errors\":%u,"
           "\"changes\":%u}\n",
           initialized, errors, changes);
  } else if (strncmp(line, "values", 6) == 0) {
    snapshot("values");
  } else if (strncmp(line, "local-change", 12) == 0) {
    g_autoptr(GSettings) local = g_settings_new("org.gnome.desktop.interface");
    g_settings_set_double(local, "text-scaling-factor", 1.75);
    g_settings_set_string(local, "clock-format", "12h");
    g_settings_set_string(local, "color-scheme", "prefer-dark");
    g_settings_set_boolean(local, "enable-animations", FALSE);
    g_autoptr(GSettings) accessibility =
        g_settings_new("org.gnome.desktop.a11y.interface");
    g_settings_set_boolean(accessibility, "high-contrast", TRUE);
  } else if (strncmp(line, "cancel", 6) == 0) {
    g_cancellable_cancel(cancellable);
  } else if (strncmp(line, "retire-publication", 18) == 0) {
    // Queue local publication and retire before returning to the main loop.
    // A pending source must not retain or later dereference this provider.
    g_autoptr(GSettings) local = g_settings_new("org.gnome.desktop.interface");
    g_settings_set_double(local, "text-scaling-factor", 1.75);
    g_assert_nonnull(g_main_context_find_source_by_user_data(
        g_main_context_default(), settings));
    g_object_run_dispose(G_OBJECT(settings));
    g_object_run_dispose(G_OBJECT(settings));
    g_assert_null(g_main_context_find_source_by_user_data(
        g_main_context_default(), settings));
    g_clear_object(&settings);
    printf("{\"event\":\"disposed\",\"finalized\":%s}\n",
           finalized ? "true" : "false");
  } else if (strncmp(line, "dispose", 7) == 0) {
    g_object_run_dispose(G_OBJECT(settings));
    g_object_run_dispose(G_OBJECT(settings));
    g_clear_object(&settings);
    printf("{\"event\":\"disposed\",\"finalized\":%s}\n",
           finalized ? "true" : "false");
#ifndef BM_SYNCHRONOUS_SETTINGS_CONTROL
  } else if (strncmp(line, "repeat", 6) == 0) {
    fl_settings_portal_start(FL_SETTINGS_PORTAL(settings), cancellable,
                             ready_cb, nullptr);
#endif
  } else if (strncmp(line, "close", 5) == 0) {
    close_window();
  } else {
    g_error("Unknown regression command");
  }
  fflush(stdout);
  return G_SOURCE_CONTINUE;
}

int main(int argc, char **argv) {
  setvbuf(stdin, nullptr, _IONBF, 0);
  cancellable = g_cancellable_new();
  // An unauthenticated bus also blocks GTK's unrelated AT-SPI initialization.
  // Test provider bus acquisition separately on the same GLib context; all
  // other cases use a real GTK window with normal accessibility enabled.
  const gboolean provider_only =
      g_getenv("BM_PORTAL_AUTH_COMPONENT") != nullptr;
  if (!provider_only) {
    gtk_init(&argc, &argv);
  }
  loop = g_main_loop_new(nullptr, FALSE);
  // Explicit nondefault local scale distinguishes a real local source from
  // historical hardcoded portal defaults. This is an isolated memory backend.
  g_autoptr(GSettings) local = g_settings_new("org.gnome.desktop.interface");
  g_settings_set_string(local, "clock-format", "24h");
  g_settings_set_string(local, "gtk-theme", "Adwaita");
  g_settings_set_string(local, "color-scheme", "prefer-light");
  g_settings_set_boolean(local, "enable-animations", TRUE);
  g_settings_set_double(local, "text-scaling-factor", 1.25);
  g_autoptr(GSettings) accessibility =
      g_settings_new("org.gnome.desktop.a11y.interface");
  g_settings_set_boolean(accessibility, "high-contrast", FALSE);
  if (!provider_only) {
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(window), 320, 120);
    gtk_container_add(GTK_CONTAINER(window),
                      gtk_label_new("Owned portal initialization regression"));
    g_signal_connect(window, "destroy", G_CALLBACK(+[](GtkWidget *, gpointer) {
                       g_cancellable_cancel(cancellable);
                       gtk_main_quit();
                     }),
                     nullptr);
  }
  const guint input_source = g_unix_fd_add(0, G_IO_IN, command, nullptr);
  g_idle_add(startup, nullptr);
  if (window != nullptr) {
    gtk_widget_show_all(window);
    gtk_main();
  } else {
    g_main_loop_run(loop);
  }
  g_main_loop_unref(loop);
  g_source_remove(input_source);
  g_cancellable_cancel(cancellable);
  g_clear_object(&settings);
  // A queued task may complete after retirement, but cannot retain or revive
  // this provider. No wait for a portal reply is required to finalize it.
  g_assert_true(finalized);
  while (g_main_context_pending(nullptr)) {
    g_main_context_iteration(nullptr, FALSE);
  }
  printf("{\"event\":\"closed\",\"finalized\":true}\n");
  g_clear_object(&cancellable);
  return 0;
}
