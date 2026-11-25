// External GTK owner for the clipboard smoke probe. On a private display, run:
// c++ tools/clipboard_quota_provider.cc $(pkg-config --cflags --libs gtk+-3.0) -o quota-provider
// quota-provider TEXT_BYTES HTML_BYTES [change-owner|HTML_FILE]
#include <gtk/gtk.h>

#include <cstring>
#include <fstream>
#include <iostream>
#include <string>

namespace {
std::string text;
std::string html;
bool change_owner = false;

void provide(GtkClipboard*, GtkSelectionData* selection, guint info,
             gpointer) {
  if (info == 0) {
    gtk_selection_data_set_text(selection, text.data(), text.size());
  } else {
    gtk_selection_data_set(
        selection, gtk_selection_data_get_target(selection), 8,
        reinterpret_cast<const guchar*>(html.data()), html.size());
    if (change_owner) {
      // Give up CLIPBOARD before the reader can assemble a complete snapshot.
      g_idle_add(
          +[](gpointer) -> gboolean {
            const char* name = gdk_display_get_name(gdk_display_get_default());
            auto* new_display = gdk_display_open(name);
            auto* new_owner =
                gtk_clipboard_get_for_display(new_display, GDK_SELECTION_CLIPBOARD);
            gtk_clipboard_set_text(new_owner, "New owner", -1);
            gdk_display_sync(new_display);
            return G_SOURCE_REMOVE;
          },
          nullptr);
    }
  }
}

void cleared(GtkClipboard*, gpointer) {}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4 || !gtk_init_check(&argc, &argv)) return 2;
  const auto text_bytes = std::stoul(argv[1]);
  const auto html_bytes = std::stoul(argv[2]);
  change_owner = argc == 4 && strcmp(argv[3], "change-owner") == 0;
  // Use multibyte text so the probe distinguishes byte and character limits.
  text.reserve(text_bytes);
  for (size_t i = 0; i < text_bytes / 2; ++i) text.append("\xc3\xa9");
  if (text_bytes % 2 != 0) text.push_back('x');
  // A syntactically valid but deliberately unusable HTML representation.
  const std::string open = "<script>";
  const std::string close = "</script>";
  if (argc == 4 && !change_owner) {
    std::ifstream fixture(argv[3], std::ios::binary);
    if (!fixture) return 2;
    html.assign(std::istreambuf_iterator<char>(fixture),
                std::istreambuf_iterator<char>());
  } else if (html_bytes >= open.size() + close.size()) {
    html = open + std::string(html_bytes - open.size() - close.size(), 'x') +
           close;
  }
  auto* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  auto* targets = gtk_target_list_new(nullptr, 0);
  gtk_target_list_add_text_targets(targets, 0);
  gtk_target_list_add(targets, gdk_atom_intern_static_string("text/html"), 0, 1);
  gint count = 0;
  auto* table = gtk_target_table_new_from_list(targets, &count);
  const auto success = gtk_clipboard_set_with_data(
      clipboard, table, count, provide, cleared, nullptr);
  gtk_target_table_free(table, count);
  gtk_target_list_unref(targets);
  if (!success) return 1;
  std::cout << "ready" << std::endl;
  gtk_main();
}
