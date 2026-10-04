#include "writerside_dialog_host.h"

#include <cstring>
#include <memory>
#include <string>
#include <vector>

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
  if (value == nullptr || value[0] == '\0' ||
      !g_utf8_validate(value, -1, nullptr)) {
    return FALSE;
  }
  for (const gchar* current = value; *current != '\0';
       current = g_utf8_next_char(current)) {
    const gunichar character = g_utf8_get_char(current);
    if (!g_unichar_isalnum(character) && character != '_' &&
        character != '-') {
      return FALSE;
    }
  }
  g_autofree gchar* upper = g_ascii_strup(value, -1);
  const gchar* reserved[] = {
      "CON",  "PRN",  "AUX",  "NUL",  "COM1", "COM2", "COM3",
      "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1",
      "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8",
      "LPT9",
  };
  for (const gchar* candidate : reserved) {
    if (std::strcmp(upper, candidate) == 0) {
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

// Interactive forms leave the show call pending until cancellation or success.
// GTK owns the widgets; Dart owns validation, slugging and workspace mutation.
struct InteractiveDialog {
  FlMethodChannel* channel;
  FlMethodCall* call;
  GWeakRef view;
  GtkWidget* dialog = nullptr;
  GtkWidget* entry = nullptr;
  GtkWidget* title_entry = nullptr;
  GtkWidget* error_label = nullptr;
  GtkWidget* title_error = nullptr;
  GtkWidget* ok_button = nullptr;
  GtkWidget* preview_button = nullptr;
  GtkWidget* cancel_button = nullptr;
  GtkWidget* list = nullptr;
  GtkWidget* scroll = nullptr;
  std::vector<std::string> file_names;
  gint64 session;
  guint revision = 0;
  bool create = false;
  bool rename = false;
  bool picker = false;
  bool applying = false;
  bool file_name_edited = false;
  bool pending = false;
  bool valid = false;
  bool finished = false;

  InteractiveDialog(FlMethodChannel* channel, FlMethodCall* call,
                    GtkWidget* view, gint64 session)
      : channel(FL_METHOD_CHANNEL(g_object_ref(channel))),
        call(FL_METHOD_CALL(g_object_ref(call))),
        session(session) {
    g_weak_ref_init(&this->view, G_OBJECT(view));
  }
  ~InteractiveDialog() {
    g_weak_ref_clear(&view);
    g_object_unref(call);
    g_object_unref(channel);
  }
};
using InteractivePtr = std::shared_ptr<InteractiveDialog>;

InteractivePtr interactive_ref(InteractiveDialog* state) {
  return *static_cast<InteractivePtr*>(
      g_object_get_data(G_OBJECT(state->dialog), "writerside-state"));
}

void finish_interactive(const InteractivePtr& state, FlValue* value,
                        const char* error = nullptr) {
  if (state->finished) return;
  state->finished = true;
  if (error != nullptr) {
    fl_method_call_respond_error(state->call, error,
                                 "Native dialog interaction failed.", nullptr,
                                 nullptr);
  } else {
    fl_method_call_respond_success(state->call, value, nullptr);
  }
  GtkWidget* dialog = state->dialog;
  state->dialog = nullptr;
  if (dialog != nullptr) gtk_widget_destroy(dialog);
  g_autoptr(GObject) view = G_OBJECT(g_weak_ref_get(&state->view));
  if (view != nullptr && gtk_widget_get_realized(GTK_WIDGET(view))) {
    gtk_widget_grab_focus(GTK_WIDGET(view));
  }
}

void set_interactive_sensitive(InteractiveDialog* state) {
  gtk_widget_set_sensitive(state->entry, !state->pending);
  if (state->title_entry != nullptr) {
    gtk_widget_set_sensitive(state->title_entry, !state->pending);
  }
  if (state->ok_button != nullptr) {
    gtk_widget_set_sensitive(state->ok_button, state->valid && !state->pending);
  }
  if (state->preview_button != nullptr) {
    gtk_widget_set_sensitive(state->preview_button,
                             state->valid && !state->pending);
  }
  if (state->cancel_button != nullptr) {
    gtk_widget_set_sensitive(state->cancel_button, !state->pending);
  }
  gtk_window_set_deletable(GTK_WINDOW(state->dialog), !state->pending);
}

void set_error_label(GtkWidget* label, const gchar* error) {
  gtk_label_set_text(GTK_LABEL(label), error == nullptr ? "" : error);
  gtk_widget_set_visible(label, error != nullptr && error[0] != '\0');
}

struct InteractiveReply {
  InteractivePtr state;
  guint revision;
  bool submit;
};

void interactive_reply_cb(GObject* object, GAsyncResult* result,
                          gpointer user_data) {
  std::unique_ptr<InteractiveReply> reply(
      static_cast<InteractiveReply*>(user_data));
  const auto state = reply->state;
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  if (state->finished) return;
  if (reply->revision != state->revision) return;
  FlValue* value = response == nullptr
                       ? nullptr
                       : fl_method_response_get_result(response, &error);
  if (value == nullptr || error != nullptr) {
    finish_interactive(state, nullptr, "dialog-callback-failed");
    return;
  }
  if (state->picker) {
    if (fl_value_get_type(value) != FL_VALUE_TYPE_LIST) {
      finish_interactive(state, nullptr, "invalid-result");
      return;
    }
    GList* children = gtk_container_get_children(GTK_CONTAINER(state->list));
    for (GList* item = children; item != nullptr; item = item->next) {
      gtk_widget_destroy(GTK_WIDGET(item->data));
    }
    g_list_free(children);
    for (size_t i = 0; i < fl_value_get_length(value); ++i) {
      FlValue* index = fl_value_get_list_value(value, i);
      if (fl_value_get_type(index) != FL_VALUE_TYPE_INT ||
          fl_value_get_int(index) < 0 ||
          static_cast<size_t>(fl_value_get_int(index)) >=
              state->file_names.size()) {
        finish_interactive(state, nullptr, "invalid-result");
        return;
      }
      const gint original = static_cast<gint>(fl_value_get_int(index));
      GtkWidget* row = gtk_list_box_row_new();
      GtkWidget* label =
          left_aligned_label(state->file_names[original].c_str());
      gtk_widget_set_margin_start(label, 8);
      gtk_widget_set_margin_end(label, 8);
      gtk_widget_set_size_request(row, -1, 48);
      gtk_container_add(GTK_CONTAINER(row), label);
      g_object_set_data(G_OBJECT(row), "topic-index",
                        GINT_TO_POINTER(original));
      gtk_container_add(GTK_CONTAINER(state->list), row);
    }
    gtk_widget_show_all(state->list);
    gtk_list_box_select_row(
        GTK_LIST_BOX(state->list),
        gtk_list_box_get_row_at_index(GTK_LIST_BOX(state->list), 0));
    gtk_adjustment_set_value(
        gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(state->scroll)),
        0);
    state->valid = true;
    return;
  }
  if (fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    finish_interactive(state, nullptr, "invalid-result");
    return;
  }
  if (state->create) {
    const gchar* file_name = lookup_string(value, "fileName");
    FlValue* created = fl_value_lookup_string(value, "created");
    if (file_name == nullptr || created == nullptr ||
        fl_value_get_type(created) != FL_VALUE_TYPE_BOOL) {
      finish_interactive(state, nullptr, "invalid-result");
      return;
    }
    if (reply->submit && fl_value_get_bool(created)) {
      g_autoptr(FlValue) success = fl_value_new_bool(TRUE);
      finish_interactive(state, success);
      return;
    }
    state->applying = true;
    if (g_strcmp0(gtk_entry_get_text(GTK_ENTRY(state->entry)), file_name) !=
        0) {
      gtk_entry_set_text(GTK_ENTRY(state->entry), file_name);
    }
    state->applying = false;
    const gchar* title_error = lookup_string(value, "titleError");
    const gchar* file_error = lookup_string(value, "fileNameError");
    const gchar* creation_error = lookup_string(value, "error");
    set_error_label(state->title_error, title_error);
    set_error_label(state->error_label,
                    creation_error != nullptr ? creation_error : file_error);
    state->valid = title_error == nullptr && file_error == nullptr;
  } else {
    const gchar* validation_error = lookup_string(value, "error");
    set_error_label(state->error_label, validation_error);
    state->valid = validation_error == nullptr;
  }
  state->pending = false;
  set_interactive_sensitive(state.get());
  if (reply->submit) gtk_widget_grab_focus(state->entry);
}

void send_interactive_event(InteractiveDialog* state, bool submit = false) {
  if (state->finished || state->applying || state->pending) return;
  if (submit) state->pending = true;
  state->valid = false;
  set_interactive_sensitive(state);
  ++state->revision;
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "session", fl_value_new_int(state->session));
  fl_value_set_string_take(args, "event",
                           fl_value_new_string(state->picker ? "filter"
                                               : submit      ? "submit"
                                                             : "changed"));
  const gchar* entry = gtk_entry_get_text(GTK_ENTRY(state->entry));
  if (state->create) {
    fl_value_set_string_take(
        args, "title",
        fl_value_new_string(gtk_entry_get_text(GTK_ENTRY(state->title_entry))));
    fl_value_set_string_take(args, "fileName", fl_value_new_string(entry));
    fl_value_set_string_take(args, "fileNameEdited",
                             fl_value_new_bool(state->file_name_edited));
  } else {
    fl_value_set_string_take(args, "value", fl_value_new_string(entry));
  }
  auto* reply =
      new InteractiveReply{interactive_ref(state), state->revision, submit};
  fl_method_channel_invoke_method(state->channel, "writersideDialogEvent", args,
                                  nullptr, interactive_reply_cb, reply);
}

void interactive_changed(GtkEditable* entry, gpointer user_data) {
  auto* state = static_cast<InteractiveDialog*>(user_data);
  if (state->applying || state->pending) return;
  if (state->create && GTK_WIDGET(entry) == state->entry) {
    state->file_name_edited = true;
  }
  send_interactive_event(state);
}

void interactive_response(GtkDialog*, gint response, gpointer user_data) {
  auto* state = static_cast<InteractiveDialog*>(user_data);
  if (state->pending || state->finished) return;
  if (response != GTK_RESPONSE_OK && response != GTK_RESPONSE_APPLY) {
    g_autoptr(FlValue) cancelled = fl_value_new_null();
    finish_interactive(interactive_ref(state), cancelled);
    return;
  }
  if (!state->valid) return;
  if (state->create) {
    send_interactive_event(state, true);
  } else if (state->picker) {
    GtkListBoxRow* row =
        gtk_list_box_get_selected_row(GTK_LIST_BOX(state->list));
    if (row == nullptr) return;
    g_autoptr(FlValue) selected = fl_value_new_int(
        GPOINTER_TO_INT(g_object_get_data(G_OBJECT(row), "topic-index")));
    finish_interactive(interactive_ref(state), selected);
  } else {
    const gchar* text = gtk_entry_get_text(GTK_ENTRY(state->entry));
    g_autoptr(FlValue) selected =
        state->rename ? fl_value_new_map() : fl_value_new_string(text);
    if (state->rename) {
      fl_value_set_string_take(selected, "value", fl_value_new_string(text));
      fl_value_set_string_take(
          selected, "preview",
          fl_value_new_bool(response == GTK_RESPONSE_APPLY));
    }
    finish_interactive(interactive_ref(state), selected);
  }
}

gboolean interactive_delete(GtkWidget*, GdkEvent*, gpointer user_data) {
  auto* state = static_cast<InteractiveDialog*>(user_data);
  if (!state->pending) {
    interactive_response(nullptr, GTK_RESPONSE_CANCEL, state);
  }
  return TRUE;
}

gboolean interactive_key(GtkWidget*, GdkEventKey* event, gpointer user_data) {
  auto* state = static_cast<InteractiveDialog*>(user_data);
  if (event->keyval == GDK_KEY_Escape) {
    interactive_response(nullptr, GTK_RESPONSE_CANCEL, state);
    return TRUE;
  }
  if (!state->picker ||
      (event->keyval != GDK_KEY_Down && event->keyval != GDK_KEY_Up))
    return FALSE;
  if (!state->valid) return TRUE;
  GtkListBox* list = GTK_LIST_BOX(state->list);
  GtkListBoxRow* current = gtk_list_box_get_selected_row(list);
  gint index = current == nullptr ? 0 : gtk_list_box_row_get_index(current);
  gint next = MAX(0, index + (event->keyval == GDK_KEY_Down ? 1 : -1));
  GtkListBoxRow* row = gtk_list_box_get_row_at_index(list, next);
  if (row == nullptr) row = current;
  if (row != nullptr) {
    gtk_list_box_select_row(list, row);
    GtkAllocation allocation;
    gtk_widget_get_allocation(GTK_WIDGET(row), &allocation);
    GtkAdjustment* adjustment =
        gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(state->scroll));
    gtk_adjustment_clamp_page(adjustment, allocation.y,
                              allocation.y + allocation.height);
  }
  return TRUE;
}

void show_interactive(DialogHandlerData* data, FlMethodChannel* channel,
                      FlMethodCall* call, FlValue* args, const gchar* method) {
  FlValue* session =
      args == nullptr ? nullptr : fl_value_lookup_string(args, "session");
  const bool picker = std::strcmp(method, "showExistingTopicPicker") == 0;
  const bool create = std::strcmp(method, "showCreateTopic") == 0;
  const bool rename = std::strcmp(method, "showRenameTopic") == 0;
  const gchar* title = lookup_string(args, "title");
  if (session == nullptr || fl_value_get_type(session) != FL_VALUE_TYPE_INT ||
      title == nullptr) {
    respond_invalid_arguments(call,
                              "Interactive dialog arguments are invalid.");
    return;
  }
  const gchar* keys[] = {"fileNameLabel", "cancelLabel", "okLabel"};
  if (!picker) {
    for (const gchar* key : keys) {
      if (lookup_string(args, key) == nullptr) {
        respond_invalid_arguments(call,
                                  "Interactive dialog labels are invalid.");
        return;
      }
    }
  }
  if ((create && (lookup_string(args, "titleLabel") == nullptr ||
                  lookup_string(args, "initialTitle") == nullptr ||
                  lookup_string(args, "initialFileName") == nullptr)) ||
      (!create && !picker && lookup_string(args, "initialValue") == nullptr) ||
      (rename && lookup_string(args, "previewLabel") == nullptr) ||
      (picker && lookup_string(args, "searchLabel") == nullptr)) {
    respond_invalid_arguments(call, "Interactive dialog fields are invalid.");
    return;
  }
  FlValue* names = picker ? fl_value_lookup_string(args, "fileNames") : nullptr;
  if (picker &&
      (names == nullptr || fl_value_get_type(names) != FL_VALUE_TYPE_LIST)) {
    respond_invalid_arguments(call, "Topic filenames are invalid.");
    return;
  }
  auto state = std::make_shared<InteractiveDialog>(channel, call, data->view,
                                                   fl_value_get_int(session));
  state->create = create;
  state->rename = rename;
  state->picker = picker;
  if (picker) {
    for (size_t i = 0; i < fl_value_get_length(names); ++i) {
      FlValue* name = fl_value_get_list_value(names, i);
      if (fl_value_get_type(name) != FL_VALUE_TYPE_STRING) {
        respond_invalid_arguments(call, "Topic filenames must be strings.");
        return;
      }
      state->file_names.emplace_back(fl_value_get_string(name));
    }
  }
  state->dialog = gtk_dialog_new_with_buttons(
      title, data->parent,
      static_cast<GtkDialogFlags>(GTK_DIALOG_MODAL |
                                  GTK_DIALOG_DESTROY_WITH_PARENT),
      nullptr, nullptr);
  configure_dialog(state->dialog, requested_direction(args, data->view), 470);
  FlValue* enter_only_value =
      picker ? nullptr : fl_value_lookup_string(args, "enterOnly");
  const bool enter_only =
      enter_only_value != nullptr &&
      fl_value_get_type(enter_only_value) == FL_VALUE_TYPE_BOOL &&
      fl_value_get_bool(enter_only_value);
  if (!picker) {
    state->cancel_button = gtk_dialog_add_button(
        GTK_DIALOG(state->dialog), lookup_string(args, "cancelLabel"),
        GTK_RESPONSE_CANCEL);
    if (rename) {
      state->preview_button = gtk_dialog_add_button(
          GTK_DIALOG(state->dialog), lookup_string(args, "previewLabel"),
          GTK_RESPONSE_APPLY);
    }
    state->ok_button =
        gtk_dialog_add_button(GTK_DIALOG(state->dialog),
                              lookup_string(args, "okLabel"), GTK_RESPONSE_OK);
    if (enter_only) {
      gtk_widget_set_no_show_all(state->cancel_button, TRUE);
      gtk_widget_set_no_show_all(state->ok_button, TRUE);
    }
    // configure_dialog runs before these actions exist. Assign the default
    // after installing the OK action.
    gtk_dialog_set_default_response(GTK_DIALOG(state->dialog), GTK_RESPONSE_OK);
  }
  GtkWidget* content = gtk_dialog_get_content_area(GTK_DIALOG(state->dialog));
  if (create) {
    state->title_entry = gtk_entry_new();
    gtk_entry_set_text(GTK_ENTRY(state->title_entry),
                       lookup_string(args, "initialTitle"));
    GtkWidget* label = left_aligned_label(lookup_string(args, "titleLabel"));
    gtk_label_set_mnemonic_widget(GTK_LABEL(label), state->title_entry);
    gtk_box_pack_start(GTK_BOX(content), label, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(content), state->title_entry, FALSE, FALSE, 0);
    state->title_error = left_aligned_label("");
    gtk_style_context_add_class(
        gtk_widget_get_style_context(state->title_error), "error");
    gtk_box_pack_start(GTK_BOX(content), state->title_error, FALSE, FALSE, 0);
  }
  state->entry = picker ? gtk_search_entry_new() : gtk_entry_new();
  if (create || rename)
    gtk_widget_set_direction(state->entry, GTK_TEXT_DIR_LTR);
  if (picker) {
    const gchar* search_label = lookup_string(args, "searchLabel");
    gtk_entry_set_placeholder_text(GTK_ENTRY(state->entry), search_label);
  } else {
    gtk_entry_set_text(
        GTK_ENTRY(state->entry),
        lookup_string(args, create ? "initialFileName" : "initialValue"));
    GtkWidget* label = left_aligned_label(lookup_string(args, "fileNameLabel"));
    gtk_label_set_mnemonic_widget(GTK_LABEL(label), state->entry);
    gtk_box_pack_start(GTK_BOX(content), label, FALSE, FALSE, 0);
  }
  gtk_box_pack_start(GTK_BOX(content), state->entry, FALSE, FALSE, 0);
  state->error_label = left_aligned_label("");
  gtk_style_context_add_class(gtk_widget_get_style_context(state->error_label),
                              "error");
  gtk_box_pack_start(GTK_BOX(content), state->error_label, FALSE, FALSE, 0);
  if (picker) {
    state->scroll = gtk_scrolled_window_new(nullptr, nullptr);
    gtk_widget_set_size_request(state->scroll, -1, 300);
    state->list = gtk_list_box_new();
    gtk_list_box_set_activate_on_single_click(GTK_LIST_BOX(state->list), TRUE);
    gtk_container_add(GTK_CONTAINER(state->scroll), state->list);
    gtk_box_pack_start(GTK_BOX(content), state->scroll, TRUE, TRUE, 0);
    g_signal_connect(
        state->list, "row-activated",
        G_CALLBACK(
            +[](GtkListBox* list, GtkListBoxRow* row, gpointer user_data) {
              gtk_list_box_select_row(list, row);
              interactive_response(nullptr, GTK_RESPONSE_OK, user_data);
            }),
        state.get());
  }
  // Explicit activation also supports the Group form without visible actions.
  g_signal_connect(state->entry, "activate",
                   G_CALLBACK(+[](GtkEntry*, gpointer user_data) {
                     interactive_response(nullptr, GTK_RESPONSE_OK, user_data);
                   }),
                   state.get());
  if (create) {
    g_signal_connect(state->title_entry, "activate",
                     G_CALLBACK(+[](GtkEntry*, gpointer user_data) {
                       interactive_response(nullptr, GTK_RESPONSE_OK,
                                            user_data);
                     }),
                     state.get());
    g_signal_connect(state->title_entry, "changed",
                     G_CALLBACK(interactive_changed), state.get());
  }
  g_signal_connect(state->entry, "changed", G_CALLBACK(interactive_changed),
                   state.get());
  g_signal_connect(state->dialog, "response", G_CALLBACK(interactive_response),
                   state.get());
  g_signal_connect(state->dialog, "key-press-event",
                   G_CALLBACK(interactive_key), state.get());
  g_signal_connect(state->dialog, "delete-event",
                   G_CALLBACK(interactive_delete), state.get());
  g_object_set_data_full(
      G_OBJECT(state->dialog), "writerside-state", new InteractivePtr(state),
      +[](gpointer ptr) { delete static_cast<InteractivePtr*>(ptr); });
  g_signal_connect(state->dialog, "destroy",
                   G_CALLBACK(+[](GtkWidget*, gpointer user_data) {
                     auto* state = static_cast<InteractiveDialog*>(user_data);
                     if (state->finished) return;
                     auto retained = interactive_ref(state);
                     state->dialog = nullptr;
                     g_autoptr(FlValue) cancelled = fl_value_new_null();
                     finish_interactive(retained, cancelled);
                   }),
                   state.get());
  gtk_widget_show_all(state->dialog);
  set_error_label(state->error_label, nullptr);
  if (create) set_error_label(state->title_error, nullptr);
  gtk_widget_grab_focus(create ? state->title_entry : state->entry);
  send_interactive_event(state.get());
}

void method_call_cb(FlMethodChannel* channel,
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
  } else if (std::strcmp(method, "showCreateTopic") == 0 ||
             std::strcmp(method, "showRenameTopic") == 0 ||
             std::strcmp(method, "showTocText") == 0 ||
             std::strcmp(method, "showExistingTopicPicker") == 0) {
    show_interactive(data, channel, call, fl_method_call_get_args(call), method);
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
