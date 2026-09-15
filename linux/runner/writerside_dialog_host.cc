#include "writerside_dialog_host.h"

#include <cstring>

namespace {

constexpr char kChannelName[] = "busymark/native_writerside_dialogs";

struct DialogHandlerData {
  GtkWidget* view;
  GtkWindow* parent;
};

const gchar* lookup_string(FlValue* args, const gchar* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : nullptr;
}

void respond_invalid_arguments(FlMethodCall* call, const gchar* message) {
  fl_method_call_respond_error(call, "invalid-arguments", message, nullptr,
                               nullptr);
}

GtkTextDirection requested_direction(FlValue* args, GtkWidget* fallback) {
  const gchar* value = lookup_string(args, "textDirection");
  if (g_strcmp0(value, "rtl") == 0) {
    return GTK_TEXT_DIR_RTL;
  }
  if (g_strcmp0(value, "ltr") == 0) {
    return GTK_TEXT_DIR_LTR;
  }
  return gtk_widget_get_direction(fallback);
}

void configure_dialog(GtkWidget* dialog,
                      GtkTextDirection direction,
                      gint width) {
  gtk_widget_set_direction(dialog, direction);
  gtk_window_set_resizable(GTK_WINDOW(dialog), FALSE);
  gtk_window_set_default_size(GTK_WINDOW(dialog), width, -1);
  gtk_dialog_set_default_response(GTK_DIALOG(dialog), GTK_RESPONSE_OK);
  GtkWidget* content = gtk_dialog_get_content_area(GTK_DIALOG(dialog));
  gtk_widget_set_margin_start(content, 18);
  gtk_widget_set_margin_end(content, 18);
  gtk_widget_set_margin_top(content, 14);
  gtk_widget_set_margin_bottom(content, 8);
  gtk_box_set_spacing(GTK_BOX(content), 8);
}

GtkWidget* left_aligned_label(const gchar* text) {
  GtkWidget* label = gtk_label_new(text);
  gtk_label_set_xalign(GTK_LABEL(label), 0.0);
  return label;
}

GtkWidget* wrapping_explanation(const gchar* text) {
  GtkWidget* label = left_aligned_label(text);
  gtk_label_set_line_wrap(GTK_LABEL(label), TRUE);
  gtk_label_set_max_width_chars(GTK_LABEL(label), 62);
  GtkStyleContext* style = gtk_widget_get_style_context(label);
  gtk_style_context_add_class(style, "dim-label");
  return label;
}

gboolean has_only_identifier_characters(const gchar* value) {
  if (value == nullptr || value[0] == '\0') {
    return FALSE;
  }
  for (const guchar* current = reinterpret_cast<const guchar*>(value);
       *current != '\0'; ++current) {
    if (!g_ascii_isalnum(*current) && *current != '_' && *current != '-') {
      return FALSE;
    }
  }
  return TRUE;
}

struct DuplicateValidation {
  GtkWidget* entry;
  GtkWidget* error_label;
  GtkWidget* ok_button;
  const gchar* required_error;
  const gchar* invalid_characters_error;
  const gchar* duplicate_error;
  GHashTable* existing_ids;
};

void update_duplicate_validation(GtkEditable*, gpointer user_data) {
  auto* validation = static_cast<DuplicateValidation*>(user_data);
  const gchar* value = gtk_entry_get_text(GTK_ENTRY(validation->entry));
  g_autofree gchar* trimmed = g_strdup(value);
  g_strstrip(trimmed);
  const gchar* error = nullptr;
  if (trimmed[0] == '\0') {
    error = validation->required_error;
  } else if (!has_only_identifier_characters(value)) {
    error = validation->invalid_characters_error;
  } else if (g_hash_table_contains(validation->existing_ids, value)) {
    error = validation->duplicate_error;
  }
  gtk_label_set_text(GTK_LABEL(validation->error_label),
                     error != nullptr ? error : "");
  gtk_widget_set_visible(validation->error_label, error != nullptr);
  gtk_widget_set_sensitive(validation->ok_button, error == nullptr);
}

void show_duplicate_topic(DialogHandlerData* data,
                          FlMethodCall* call,
                          FlValue* args) {
  const gchar* title = lookup_string(args, "title");
  const gchar* field_label = lookup_string(args, "fileNameLabel");
  const gchar* initial_value = lookup_string(args, "initialValue");
  const gchar* cancel_label = lookup_string(args, "cancelLabel");
  const gchar* ok_label = lookup_string(args, "okLabel");
  const gchar* required_error = lookup_string(args, "requiredError");
  const gchar* invalid_error =
      lookup_string(args, "invalidCharactersError");
  const gchar* duplicate_error = lookup_string(args, "duplicateError");
  FlValue* existing_ids = args == nullptr
                              ? nullptr
                              : fl_value_lookup_string(args,
                                                       "existingTopicIds");
  if (title == nullptr || field_label == nullptr || initial_value == nullptr ||
      cancel_label == nullptr || ok_label == nullptr ||
      required_error == nullptr || invalid_error == nullptr ||
      duplicate_error == nullptr || existing_ids == nullptr ||
      fl_value_get_type(existing_ids) != FL_VALUE_TYPE_LIST) {
    respond_invalid_arguments(call,
                              "Duplicate Topic dialog arguments are invalid.");
    return;
  }

  g_autoptr(GHashTable) ids =
      g_hash_table_new_full(g_str_hash, g_str_equal, g_free, nullptr);
  for (size_t index = 0; index < fl_value_get_length(existing_ids); ++index) {
    FlValue* item = fl_value_get_list_value(existing_ids, index);
    if (item == nullptr || fl_value_get_type(item) != FL_VALUE_TYPE_STRING) {
      respond_invalid_arguments(call,
                                "existingTopicIds must contain strings.");
      return;
    }
    g_hash_table_add(ids, g_strdup(fl_value_get_string(item)));
  }

  GtkWidget* dialog = gtk_dialog_new_with_buttons(
      title, data->parent,
      static_cast<GtkDialogFlags>(GTK_DIALOG_MODAL |
                                  GTK_DIALOG_DESTROY_WITH_PARENT),
      cancel_label, GTK_RESPONSE_CANCEL, ok_label, GTK_RESPONSE_OK, nullptr);
  configure_dialog(dialog, requested_direction(args, data->view), 470);
  GtkWidget* ok_button =
      gtk_dialog_get_widget_for_response(GTK_DIALOG(dialog), GTK_RESPONSE_OK);

  GtkWidget* content = gtk_dialog_get_content_area(GTK_DIALOG(dialog));
  GtkWidget* label = left_aligned_label(field_label);
  GtkWidget* entry = gtk_entry_new();
  gtk_entry_set_text(GTK_ENTRY(entry), initial_value);
  gtk_entry_set_activates_default(GTK_ENTRY(entry), TRUE);
  gtk_label_set_mnemonic_widget(GTK_LABEL(label), entry);
  GtkWidget* error_label = left_aligned_label("");
  gtk_style_context_add_class(gtk_widget_get_style_context(error_label),
                              "error");
  gtk_box_pack_start(GTK_BOX(content), label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(content), entry, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(content), error_label, FALSE, FALSE, 0);

  DuplicateValidation validation = {entry,
                                    error_label,
                                    ok_button,
                                    required_error,
                                    invalid_error,
                                    duplicate_error,
                                    ids};
  g_signal_connect(entry, "changed", G_CALLBACK(update_duplicate_validation),
                   &validation);
  update_duplicate_validation(GTK_EDITABLE(entry), &validation);
  gtk_widget_show_all(dialog);
  gtk_widget_set_visible(error_label,
                         gtk_label_get_text(GTK_LABEL(error_label))[0] != '\0');
  gtk_widget_grab_focus(entry);
  gtk_editable_select_region(GTK_EDITABLE(entry), 0, -1);

  const gint response = gtk_dialog_run(GTK_DIALOG(dialog));
  g_autofree gchar* selected = response == GTK_RESPONSE_OK
                                   ? g_strdup(gtk_entry_get_text(GTK_ENTRY(entry)))
                                   : nullptr;
  gtk_widget_destroy(dialog);
  if (data->view != nullptr && gtk_widget_get_realized(data->view)) {
    gtk_widget_grab_focus(data->view);
  }
  g_autoptr(FlValue) result = selected == nullptr
                                  ? fl_value_new_null()
                                  : fl_value_new_string(selected);
  fl_method_call_respond_success(call, result, nullptr);
}

struct TitleInheritance {
  GtkWidget* topic_entry;
  GtkWidget* instance_entry;
  GtkWidget* toc_entry;
};

void update_title_inheritance(GtkEditable*, gpointer user_data) {
  auto* inheritance = static_cast<TitleInheritance*>(user_data);
  const gchar* topic =
      gtk_entry_get_text(GTK_ENTRY(inheritance->topic_entry));
  const gchar* instance =
      gtk_entry_get_text(GTK_ENTRY(inheritance->instance_entry));
  gtk_entry_set_placeholder_text(GTK_ENTRY(inheritance->instance_entry),
                                 topic);
  gtk_entry_set_placeholder_text(GTK_ENTRY(inheritance->toc_entry),
                                 instance[0] == '\0' ? topic : instance);
}

void update_title_validity(GtkEditable* editable, gpointer user_data) {
  GtkWidget* ok_button = GTK_WIDGET(user_data);
  g_autofree gchar* title =
      g_strdup(gtk_entry_get_text(GTK_ENTRY(editable)));
  g_strstrip(title);
  gtk_widget_set_sensitive(ok_button, title[0] != '\0');
}

void add_title_field(GtkGrid* grid,
                     gint* row,
                     const gchar* label_text,
                     GtkWidget* entry,
                     GtkWidget* explanation) {
  GtkWidget* label = left_aligned_label(label_text);
  gtk_label_set_mnemonic_widget(GTK_LABEL(label), entry);
  gtk_grid_attach(grid, label, 0, *row, 1, 1);
  ++*row;
  gtk_grid_attach(grid, entry, 0, *row, 1, 1);
  ++*row;
  if (explanation != nullptr) {
    gtk_grid_attach(grid, explanation, 0, *row, 1, 1);
    ++*row;
  }
}

void show_edit_title(DialogHandlerData* data,
                     FlMethodCall* call,
                     FlValue* args) {
  const gchar* keys[] = {
      "title",          "topicTitleLabel",      "advancedLabel",
      "instanceTitleLabel", "tocTitleLabel",   "instanceExplanation",
      "tocExplanation", "documentationLabel", "documentationUrl",
      "initialTitle",   "initialInstanceTitle", "initialTocTitle",
      "cancelLabel",    "okLabel",
  };
  for (const gchar* key : keys) {
    if (lookup_string(args, key) == nullptr) {
      respond_invalid_arguments(call,
                                "Edit Title dialog arguments are invalid.");
      return;
    }
  }

  GtkWidget* dialog = gtk_dialog_new_with_buttons(
      lookup_string(args, "title"), data->parent,
      static_cast<GtkDialogFlags>(GTK_DIALOG_MODAL |
                                  GTK_DIALOG_DESTROY_WITH_PARENT),
      lookup_string(args, "cancelLabel"), GTK_RESPONSE_CANCEL,
      lookup_string(args, "okLabel"), GTK_RESPONSE_OK, nullptr);
  configure_dialog(dialog, requested_direction(args, data->view), 560);
  GtkWidget* ok_button =
      gtk_dialog_get_widget_for_response(GTK_DIALOG(dialog), GTK_RESPONSE_OK);
  GtkWidget* content = gtk_dialog_get_content_area(GTK_DIALOG(dialog));

  GtkWidget* topic_entry = gtk_entry_new();
  gtk_entry_set_text(GTK_ENTRY(topic_entry),
                     lookup_string(args, "initialTitle"));
  gtk_entry_set_activates_default(GTK_ENTRY(topic_entry), TRUE);
  GtkWidget* topic_label = left_aligned_label(
      lookup_string(args, "topicTitleLabel"));
  gtk_label_set_mnemonic_widget(GTK_LABEL(topic_label), topic_entry);
  gtk_box_pack_start(GTK_BOX(content), topic_label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(content), topic_entry, FALSE, FALSE, 0);

  GtkWidget* advanced = gtk_expander_new(
      lookup_string(args, "advancedLabel"));
  GtkWidget* grid = gtk_grid_new();
  gtk_grid_set_column_spacing(GTK_GRID(grid), 8);
  gtk_grid_set_row_spacing(GTK_GRID(grid), 6);
  gtk_widget_set_margin_top(grid, 8);
  gtk_widget_set_margin_start(grid, 18);
  GtkWidget* instance_entry = gtk_entry_new();
  GtkWidget* toc_entry = gtk_entry_new();
  gtk_entry_set_text(GTK_ENTRY(instance_entry),
                     lookup_string(args, "initialInstanceTitle"));
  gtk_entry_set_text(GTK_ENTRY(toc_entry),
                     lookup_string(args, "initialTocTitle"));
  gtk_entry_set_activates_default(GTK_ENTRY(instance_entry), TRUE);
  gtk_entry_set_activates_default(GTK_ENTRY(toc_entry), TRUE);
  gint row = 0;
  add_title_field(GTK_GRID(grid), &row,
                  lookup_string(args, "instanceTitleLabel"), instance_entry,
                  wrapping_explanation(
                      lookup_string(args, "instanceExplanation")));
  GtkWidget* toc_explanation_box =
      gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
  gtk_box_pack_start(
      GTK_BOX(toc_explanation_box),
      wrapping_explanation(lookup_string(args, "tocExplanation")), TRUE, TRUE,
      0);
  GtkWidget* documentation = gtk_link_button_new_with_label(
      lookup_string(args, "documentationUrl"),
      lookup_string(args, "documentationLabel"));
  gtk_widget_set_valign(documentation, GTK_ALIGN_CENTER);
  gtk_box_pack_start(GTK_BOX(toc_explanation_box), documentation, FALSE, FALSE,
                     0);
  add_title_field(GTK_GRID(grid), &row, lookup_string(args, "tocTitleLabel"),
                  toc_entry, toc_explanation_box);
  gtk_container_add(GTK_CONTAINER(advanced), grid);
  gtk_box_pack_start(GTK_BOX(content), advanced, FALSE, FALSE, 0);

  TitleInheritance inheritance = {topic_entry, instance_entry, toc_entry};
  g_signal_connect(topic_entry, "changed",
                   G_CALLBACK(update_title_inheritance), &inheritance);
  g_signal_connect(instance_entry, "changed",
                   G_CALLBACK(update_title_inheritance), &inheritance);
  g_signal_connect(topic_entry, "changed", G_CALLBACK(update_title_validity),
                   ok_button);
  update_title_inheritance(GTK_EDITABLE(topic_entry), &inheritance);
  update_title_validity(GTK_EDITABLE(topic_entry), ok_button);
  gtk_widget_show_all(dialog);
  gtk_widget_grab_focus(topic_entry);
  gtk_editable_select_region(GTK_EDITABLE(topic_entry), 0, -1);

  const gint response = gtk_dialog_run(GTK_DIALOG(dialog));
  g_autofree gchar* topic = response == GTK_RESPONSE_OK
                                ? g_strdup(gtk_entry_get_text(
                                      GTK_ENTRY(topic_entry)))
                                : nullptr;
  g_autofree gchar* instance = response == GTK_RESPONSE_OK
                                   ? g_strdup(gtk_entry_get_text(
                                         GTK_ENTRY(instance_entry)))
                                   : nullptr;
  g_autofree gchar* toc = response == GTK_RESPONSE_OK
                              ? g_strdup(gtk_entry_get_text(GTK_ENTRY(toc_entry)))
                              : nullptr;
  gtk_widget_destroy(dialog);
  if (data->view != nullptr && gtk_widget_get_realized(data->view)) {
    gtk_widget_grab_focus(data->view);
  }

  if (response != GTK_RESPONSE_OK) {
    g_autoptr(FlValue) result = fl_value_new_null();
    fl_method_call_respond_success(call, result, nullptr);
    return;
  }
  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "title", fl_value_new_string(topic));
  fl_value_set_string_take(result, "instanceTitle",
                           fl_value_new_string(instance));
  fl_value_set_string_take(result, "tocTitle", fl_value_new_string(toc));
  fl_method_call_respond_success(call, result, nullptr);
}

void method_call_cb(FlMethodChannel*,
                    FlMethodCall* call,
                    gpointer user_data) {
  auto* data = static_cast<DialogHandlerData*>(user_data);
  if (data->view == nullptr || data->parent == nullptr ||
      !gtk_widget_get_realized(GTK_WIDGET(data->parent))) {
    fl_method_call_respond_error(call, "unavailable",
                                 "The native dialog host is unavailable.",
                                 nullptr, nullptr);
    return;
  }
  const gchar* method = fl_method_call_get_name(call);
  if (std::strcmp(method, "showDuplicateTopic") == 0) {
    show_duplicate_topic(data, call, fl_method_call_get_args(call));
  } else if (std::strcmp(method, "showEditTitle") == 0) {
    show_edit_title(data, call, fl_method_call_get_args(call));
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}

void handler_data_free(gpointer user_data) {
  auto* data = static_cast<DialogHandlerData*>(user_data);
  if (data->view != nullptr) {
    g_object_remove_weak_pointer(
        G_OBJECT(data->view), reinterpret_cast<gpointer*>(&data->view));
  }
  if (data->parent != nullptr) {
    g_object_remove_weak_pointer(
        G_OBJECT(data->parent), reinterpret_cast<gpointer*>(&data->parent));
  }
  g_free(data);
}

}  // namespace

FlMethodChannel* busymark_writerside_dialog_channel_new(FlView* view,
                                                        GtkWindow* parent) {
  g_return_val_if_fail(FL_IS_VIEW(view), nullptr);
  g_return_val_if_fail(GTK_IS_WINDOW(parent), nullptr);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kChannelName,
      FL_METHOD_CODEC(codec));
  auto* data = g_new0(DialogHandlerData, 1);
  data->view = GTK_WIDGET(view);
  data->parent = parent;
  g_object_add_weak_pointer(G_OBJECT(data->view),
                            reinterpret_cast<gpointer*>(&data->view));
  g_object_add_weak_pointer(G_OBJECT(data->parent),
                            reinterpret_cast<gpointer*>(&data->parent));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, data,
                                            handler_data_free);
  return channel;
}
