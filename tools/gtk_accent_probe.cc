// Exercises the production GTK lookup and notification observer with disposable
// themes. No desktop settings or BusyMark application data are read or written.
#include "gtk_accent.h"

#include <cmath>
#include <string>
#include <vector>

static void theme(const char* root, const char* name, const char* light,
                  const char* dark = nullptr) {
  const std::string dir = std::string(root) + "/themes/" + name + "/gtk-3.0";
  g_assert_cmpint(g_mkdir_with_parents(dir.c_str(), 0700), ==, 0);
  g_assert_true(g_file_set_contents((dir + "/gtk.css").c_str(), light, -1, nullptr));
  if (dark != nullptr) {
    g_assert_true(g_file_set_contents((dir + "/gtk-dark.css").c_str(), dark, -1,
                                     nullptr));
  }
}

static void drain() {
  // GTK settings notification invalidates CSS synchronously but observers
  // deliberately sample on the next idle, after the new style is installed.
  int iterations = 0;
  while (g_main_context_pending(nullptr)) {
    g_main_context_iteration(nullptr, FALSE);
    g_assert_cmpint(++iterations, <, 10000);
  }
}

static void color(const busymark::GtkAccent& accent, int r, int g, int b) {
  g_assert_true(accent.available);
  g_assert_cmpint(std::lround(accent.rgba.red * 255), ==, r);
  g_assert_cmpint(std::lround(accent.rgba.green * 255), ==, g);
  g_assert_cmpint(std::lround(accent.rgba.blue * 255), ==, b);
}

int main(int argc, char** argv) {
  g_assert_cmpint(argc, ==, 2);
  const char* root = argv[1];
  theme(root, "BusyMarkOld", "@define-color theme_selected_bg_color #336699;",
        "@define-color theme_selected_bg_color #7764d8;");
  theme(root, "BusyMarkModern",
        "@define-color accent_bg_color #006600;"
        "@define-color theme_selected_bg_color #336699;");
  theme(root, "BusyMarkTransparent",
        "@define-color accent_bg_color transparent;"
        "@define-color theme_selected_bg_color #336699;");
  theme(root, "BusyMarkUnavailable",
        "@define-color accent_bg_color transparent;"
        "@define-color theme_selected_bg_color transparent;");
  theme(root, "BusyMarkMissing", "window { color: #abcdef; }");
  g_setenv("XDG_DATA_HOME", root, TRUE);
  g_setenv("GTK_THEME", "BusyMarkOld", TRUE);
  g_setenv("NO_AT_BRIDGE", "1", TRUE);
  gtk_init(&argc, &argv);
  // GTK_THEME forces a theme even across notifications; release that fixture
  // startup override before changing per-process GtkSettings below.
  g_unsetenv("GTK_THEME");
  GtkSettings* settings = gtk_settings_get_default();
  g_object_set(settings, "gtk-theme-name", "BusyMarkOld",
               "gtk-application-prefer-dark-theme", FALSE, nullptr);
  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_widget_realize(window);
  auto* context = gtk_widget_get_style_context(window);
  GdkRGBA ignored = {0, 0, 0, 0};
  g_assert_false(gtk_style_context_lookup_color(context, "accent_bg_color", &ignored));
  color(busymark::LookupGtkAccent(context), 51, 102, 153);
  g_print("PASS older-only lookup: #336699 (modern symbol absent)\n");

  std::vector<busymark::GtkAccent> events;
  {
    busymark::GtkAccentObserver observer(window);
    color(observer.Read(), 51, 102, 153);  // Initial snapshot.
    // A change between snapshot and subscription must be replayed on listen.
    g_object_set(settings, "gtk-theme-name", "BusyMarkModern", nullptr);
    drain();
    observer.Listen([&events](const busymark::GtkAccent& accent) {
      events.push_back(accent);
    });
    color(events.back(), 0, 102, 0);
    g_assert_cmpuint(events.size(), ==, 1);
    g_print("PASS listener attachment replays current modern color\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkOld", nullptr);
    drain();
    color(events.back(), 51, 102, 153);
    g_assert_cmpuint(events.size(), ==, 2);
    g_object_set(settings, "gtk-application-prefer-dark-theme", TRUE, nullptr);
    drain();
    color(events.back(), 119, 100, 216);
    g_assert_cmpuint(events.size(), ==, 3);
    g_object_set(settings, "gtk-application-prefer-dark-theme", FALSE, nullptr);
    drain();
    color(events.back(), 51, 102, 153);
    g_assert_cmpuint(events.size(), ==, 4);
    g_print("PASS runtime theme-name and dark-preference notifications read refreshed CSS\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkTransparent", nullptr);
    drain();
    color(observer.Read(), 51, 102, 153);
    g_assert_cmpuint(events.size(), ==, 4);  // Same effective fallback.
    g_object_set(settings, "gtk-theme-name", "BusyMarkUnavailable", nullptr);
    drain();
    g_assert_false(observer.Read().available);
    g_assert_false(events.back().available);
    g_assert_cmpuint(events.size(), ==, 5);
    g_object_set(settings, "gtk-theme-name", "BusyMarkMissing", nullptr);
    drain();
    g_assert_false(observer.Read().available);
    g_assert_cmpuint(events.size(), ==, 5);
    g_print("PASS transparent and missing lookups remain unavailable; duplicates suppressed\n");

    // Simulate Flutter's native header CSS refresh: ordinary CSS must not
    // generate accent changes or redefine accent symbols.
    g_autoptr(GtkCssProvider) header = gtk_css_provider_new();
    gtk_css_provider_load_from_data(header, "window { background-color: #f0f0f0; }",
                                    -1, nullptr);
    gtk_style_context_add_provider_for_screen(gtk_widget_get_screen(window),
        GTK_STYLE_PROVIDER(header), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    drain();
    g_assert_cmpuint(events.size(), ==, 5);
    gtk_style_context_remove_provider_for_screen(gtk_widget_get_screen(window),
                                                  GTK_STYLE_PROVIDER(header));
    drain();
    g_assert_cmpuint(events.size(), ==, 5);
    g_print("PASS header CSS refresh produces no accent feedback\n");

    g_object_set(settings, "gtk-theme-name", "BusyMarkModern", nullptr);
    observer.Cancel();  // Cancel with a refresh queued.
    drain();
    g_assert_cmpuint(events.size(), ==, 5);
    observer.Listen([&events](const busymark::GtkAccent& accent) {
      events.push_back(accent);
    });
    color(events.back(), 0, 102, 0);
    g_assert_cmpuint(events.size(), ==, 6);
    g_object_set(settings, "gtk-theme-name", "BusyMarkOld", nullptr);
    // Destroy the observer with a refresh queued, exactly as host shutdown does.
  }
  drain();
  g_assert_cmpuint(events.size(), ==, 6);
  gtk_widget_destroy(window);
  g_print("PASS cancellation, resubscription and queued-callback cleanup\n");
  g_print("GTK %u.%u.%u; backend=%s; fixture package=unpackaged native probe\n",
          gtk_get_major_version(), gtk_get_minor_version(), gtk_get_micro_version(),
          G_OBJECT_TYPE_NAME(gdk_display_get_default()));
  return 0;
}
