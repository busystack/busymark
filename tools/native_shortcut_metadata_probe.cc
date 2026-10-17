#include <gtk/gtk.h>
#include "native_shortcut_metadata.h"

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  const char* inputs[] = {"<Primary>comma", "<Primary>U+00E9",
    "<Primary>U+0026", "<Primary><Alt>KP_7", "Ctrl+S", "<Primary>U+0410"};
  const guint keys[] = {GDK_KEY_comma, GDK_KEY_eacute, GDK_KEY_ampersand,
    GDK_KEY_KP_7, GDK_KEY_s, GDK_KEY_Cyrillic_a};
  for (size_t i = 0; i < G_N_ELEMENTS(inputs); ++i) {
    g_autofree gchar* canonical = gtk_accelerator_from_shortcut_label(inputs[i]);
    g_assert_nonnull(canonical);
    guint key = 0;
    GdkModifierType modifiers = static_cast<GdkModifierType>(0);
    gtk_accelerator_parse(canonical, &key, &modifiers);
    g_assert_cmpuint(key, ==, keys[i]);
    g_assert_true((modifiers & GDK_CONTROL_MASK) != 0);
  }
  const char* rejected[] = {"", "<Primary>U+110000", "<Alt>U+D800", "<Primary>U+oops", "<Primary>U+4E2D"};
  for (const auto* input : rejected) {
    g_autofree gchar* invalid = gtk_accelerator_from_shortcut_label(input);
    g_assert_null(invalid);
  }
  g_print("Native shortcut metadata: 6 round trips, 5 safe rejections passed.\n");
  return 0;
}
