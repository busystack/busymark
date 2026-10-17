#ifndef BUSYMARK_NATIVE_SHORTCUT_METADATA_H_
#define BUSYMARK_NATIVE_SHORTCUT_METADATA_H_

#include <gtk/gtk.h>
#include <cstring>

inline gchar* gtk_accelerator_from_shortcut_label(const gchar* shortcut) {
  if (shortcut == nullptr || shortcut[0] == '\0') {
    return nullptr;
  }

  // Dart sends logical Unicode identity, never a translated shortcut badge.
  // GDK supplies legacy keysym names such as eacute or Cyrillic_a.
  const gchar* unicode = strstr(shortcut, "U+");
  if (unicode != nullptr) {
    const gchar* digits = unicode + 2;
    const gsize count = strlen(digits);
    if (count == 0 || count > 6 ||
        strspn(digits, "0123456789abcdefABCDEF") != count) {
      return nullptr;
    }
    const guint64 codepoint = g_ascii_strtoull(digits, nullptr, 16);
    if (codepoint == 0 || codepoint > 0x10ffff ||
        !g_unichar_validate(codepoint)) {
      return nullptr;
    }
    g_autofree gchar* prefix = g_strndup(shortcut, unicode - shortcut);
    g_autofree gchar* sample = g_strconcat(prefix, "a", nullptr);
    guint sample_key = 0;
    GdkModifierType modifiers = static_cast<GdkModifierType>(0);
    gtk_accelerator_parse(sample, &sample_key, &modifiers);
    if (sample_key != GDK_KEY_a) return nullptr;
    // GTK normalizes alphabetic accelerator keys to lowercase. Shift remains
    // a separate modifier, as it is in the structured application binding.
    const guint expected_key = gdk_keyval_to_lower(
        gdk_unicode_to_keyval(codepoint));
    g_autofree gchar* canonical = gtk_accelerator_name(expected_key, modifiers);
    guint verified = 0;
    GdkModifierType verified_modifiers = static_cast<GdkModifierType>(0);
    gtk_accelerator_parse(canonical, &verified, &verified_modifiers);
    // Some Unicode keys have no GTK 3 accelerator name. The caller retains the
    // truthful display label instead of publishing invalid accelerator syntax.
    return verified == expected_key && verified_modifiers == modifiers
               ? g_strdup(canonical)
               : nullptr;
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

#endif
