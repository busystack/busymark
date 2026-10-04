#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// Exercise the production GTK builders. Only the final channel response is
// intercepted; the widget tree, dialog loop and button handling are real GTK.
#include "../../linux/runner/writerside_dialog_host.cc"

namespace {

FlValue* received_result = nullptr;
guint response_count = 0;

struct DirectionCase {
  GtkTextDirection desktop_direction;
  GtkTextDirection application_direction;
  bool duplicate;
};

struct DialogCheck {
  const DirectionCase* test_case;
  GtkWindow* parent;
  GtkWidget* filename_entry;
  guint entries;
  guint labels;
  bool checked;
};

void assert_widget_direction(GtkWidget* widget, gpointer user_data) {
  auto* check = static_cast<DialogCheck*>(user_data);
  const GtkTextDirection expected = widget == check->filename_entry
                                        ? GTK_TEXT_DIR_LTR
                                        : check->test_case->application_direction;
  g_assert_cmpint(gtk_widget_get_direction(widget), ==, expected);
  if (GTK_IS_ENTRY(widget)) ++check->entries;
  if (GTK_IS_LABEL(widget)) ++check->labels;
  if (GTK_IS_CONTAINER(widget)) {
    gtk_container_forall(GTK_CONTAINER(widget), assert_widget_direction, check);
  }
}

gboolean inspect_and_accept_dialog(gpointer user_data) {
  auto* check = static_cast<DialogCheck*>(user_data);
  GList* windows = gtk_window_list_toplevels();
  GtkWidget* dialog = nullptr;
  for (GList* node = windows; node != nullptr; node = node->next) {
    if (GTK_IS_DIALOG(node->data)) dialog = GTK_WIDGET(node->data);
  }
  g_list_free(windows);
  g_assert_nonnull(dialog);
  g_assert_true(gtk_window_get_modal(GTK_WINDOW(dialog)));
  g_assert_true(gtk_window_get_transient_for(GTK_WINDOW(dialog)) == check->parent);
  g_assert_cmpint(gtk_widget_get_default_direction(), ==,
                  check->test_case->desktop_direction);
  if (check->test_case->duplicate) {
    check->filename_entry = gtk_window_get_focus(GTK_WINDOW(dialog));
    g_assert_true(GTK_IS_ENTRY(check->filename_entry));
  }
  assert_widget_direction(dialog, check);
  g_assert_cmpuint(check->entries, ==, check->test_case->duplicate ? 1 : 3);
  g_assert_cmpuint(check->labels, >=, 4);
  check->checked = true;
  GtkWidget* ok =
      gtk_dialog_get_widget_for_response(GTK_DIALOG(dialog), GTK_RESPONSE_OK);
  gtk_button_clicked(GTK_BUTTON(ok));
  return G_SOURCE_REMOVE;
}

void set_string(FlValue* args, const gchar* key, const gchar* value) {
  fl_value_set_string_take(args, key, fl_value_new_string(value));
}

void test_dialog_direction(gconstpointer user_data) {
  const auto* test_case = static_cast<const DirectionCase*>(user_data);
  const GtkTextDirection original_direction = gtk_widget_get_default_direction();
  // Simulate a desktop language opposite to the application language. The
  // production dialog must not change this process-wide setting.
  gtk_widget_set_default_direction(test_case->desktop_direction);
  GtkWidget* parent = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  GtkWidget* view = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(parent), view);
  gtk_widget_show_all(parent);
  DialogHandlerData handler = {view, GTK_WINDOW(parent)};
  g_autoptr(FlValue) args = fl_value_new_map();
  set_string(args, "textDirection",
             test_case->application_direction == GTK_TEXT_DIR_RTL ? "rtl" : "ltr");
  set_string(args, "title", "Localized dialog title");
  set_string(args, "cancelLabel", "Localized cancel");
  set_string(args, "okLabel", "Localized accept");
  if (test_case->duplicate) {
    set_string(args, "fileNameLabel", "Localized filename label");
    set_string(args, "initialValue", "original-copy");
    set_string(args, "requiredError", "Localized required error");
    set_string(args, "invalidCharactersError", "Localized identifier error");
    set_string(args, "duplicateError", "Localized duplicate error");
    fl_value_set_string_take(args, "existingTopicIds", fl_value_new_list());
  } else {
    set_string(args, "topicTitleLabel", "Localized topic label");
    set_string(args, "advancedLabel", "Localized advanced label");
    set_string(args, "instanceTitleLabel", "Localized instance label");
    set_string(args, "tocTitleLabel", "Localized TOC label");
    set_string(args, "instanceExplanation", "Localized instance explanation");
    set_string(args, "tocExplanation", "Localized TOC explanation");
    set_string(args, "documentationLabel", "Localized documentation link");
    set_string(args, "documentationUrl", "https://example.test/titles");
    set_string(args, "initialTitle", "Original title");
    set_string(args, "initialInstanceTitle", "Instance title");
    set_string(args, "initialTocTitle", "TOC title");
  }
  DialogCheck check = {test_case, GTK_WINDOW(parent), nullptr, 0, 0, false};
  response_count = 0;
  g_idle_add(inspect_and_accept_dialog, &check);
  if (test_case->duplicate) {
    show_duplicate_topic(&handler, nullptr, args);
  } else {
    show_edit_title(&handler, nullptr, args);
  }
  g_assert_true(check.checked);
  g_assert_cmpuint(response_count, ==, 1);
  if (test_case->duplicate) {
    g_assert_cmpstr(fl_value_get_string(received_result), ==, "original-copy");
  } else {
    g_assert_cmpstr(fl_value_get_string(
                       fl_value_lookup_string(received_result, "title")),
                    ==, "Original title");
    g_assert_cmpstr(fl_value_get_string(
                       fl_value_lookup_string(received_result, "instanceTitle")),
                    ==, "Instance title");
    g_assert_cmpstr(fl_value_get_string(
                       fl_value_lookup_string(received_result, "tocTitle")),
                    ==, "TOC title");
  }
  fl_value_unref(received_result);
  received_result = nullptr;
  g_assert_cmpint(gtk_widget_get_default_direction(), ==,
                  test_case->desktop_direction);
  gtk_widget_destroy(parent);
  gtk_widget_set_default_direction(original_direction);
}

}  // namespace

extern "C" gboolean __wrap_fl_method_call_respond_success(FlMethodCall*,
                                                         FlValue* result,
                                                         GError**) {
  g_assert_null(received_result);
  received_result = fl_value_ref(result);
  ++response_count;
  return TRUE;
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  g_test_init(&argc, &argv, nullptr);
  const DirectionCase cases[] = {
      {GTK_TEXT_DIR_LTR, GTK_TEXT_DIR_RTL, false},
      {GTK_TEXT_DIR_RTL, GTK_TEXT_DIR_LTR, false},
      {GTK_TEXT_DIR_LTR, GTK_TEXT_DIR_RTL, true},
      {GTK_TEXT_DIR_RTL, GTK_TEXT_DIR_LTR, true},
  };
  g_test_add_data_func("/writerside/edit-title/rtl-on-ltr-desktop", &cases[0],
                        test_dialog_direction);
  g_test_add_data_func("/writerside/edit-title/ltr-on-rtl-desktop", &cases[1],
                        test_dialog_direction);
  g_test_add_data_func("/writerside/duplicate/rtl-on-ltr-desktop", &cases[2],
                        test_dialog_direction);
  g_test_add_data_func("/writerside/duplicate/ltr-on-rtl-desktop", &cases[3],
                        test_dialog_direction);
  return g_test_run();
}
