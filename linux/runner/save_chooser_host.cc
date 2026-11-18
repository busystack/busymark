#include "save_chooser_host.h"

#include <fcntl.h>
#include <sys/stat.h>

#include <cstring>
#include <string>

namespace {

constexpr char kActiveChooser[] = "busymark-active-save-chooser";

const gchar* string_arg(FlValue* args, const gchar* key) {
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : nullptr;
}

bool bool_arg(FlValue* args, const gchar* key) {
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
         fl_value_get_bool(value);
}

void set_string(FlValue* value, const char* key, const gchar* string) {
  fl_value_set_string_take(value, key, string == nullptr
                                          ? fl_value_new_null()
                                          : fl_value_new_string(string));
}

bool read_stamp(const gchar* path, int flags, struct statx& stamp) {
  constexpr unsigned int required = STATX_TYPE | STATX_MODE | STATX_INO |
                                    STATX_SIZE | STATX_MTIME | STATX_CTIME;
  return statx(AT_FDCWD, path, flags, required | STATX_BTIME, &stamp) == 0 &&
         (stamp.stx_mask & required) == required;
}

std::string timestamp(const struct statx_timestamp& time) {
  return std::to_string(time.tv_sec) + ":" + std::to_string(time.tv_nsec);
}

std::string identity(const struct statx& stamp) {
  std::string result = std::to_string(stamp.stx_dev_major) + ":" +
                       std::to_string(stamp.stx_dev_minor) + ":" +
                       std::to_string(static_cast<int64_t>(stamp.stx_ino));
  if (stamp.stx_mask & STATX_BTIME) result += ":" + timestamp(stamp.stx_btime);
  return result;
}

std::string version(const struct statx& stamp) {
  return identity(stamp) + "/" + std::to_string(stamp.stx_mode) + "/" +
         std::to_string(stamp.stx_size) + "/" + timestamp(stamp.stx_mtime) +
         "/" + timestamp(stamp.stx_ctime);
}

FlValue* selection(const gchar* path, bool replacing, bool allow_link) {
  g_autofree gchar* folder = g_path_get_dirname(path);
  struct statx parent;
  if (!g_utf8_validate(path, -1, nullptr) || !read_stamp(folder, 0, parent) ||
      !S_ISDIR(parent.stx_mode)) {
    return nullptr;
  }
  g_autoptr(FlValue) result = fl_value_new_map();
  set_string(result, "path", path);
  set_string(result, "parent", identity(parent).c_str());
  if (replacing) {
    struct statx entry;
    if (!read_stamp(path, AT_SYMLINK_NOFOLLOW, entry)) return nullptr;
    if (allow_link && S_ISLNK(entry.stx_mode)) {
      g_autofree gchar* target = g_file_read_link(path, nullptr);
      struct statx referent;
      if (target == nullptr || !g_utf8_validate(target, -1, nullptr) ||
          !read_stamp(path, 0, referent) ||
          !S_ISREG(referent.stx_mode)) {
        return nullptr;
      }
      set_string(result, "linkTarget", target);
      set_string(result, "referent", version(referent).c_str());
    } else if (!S_ISREG(entry.stx_mode)) {
      return nullptr;
    }
    set_string(result, "entry", version(entry).c_str());
  }
  return g_steal_pointer(&result);
}

struct SaveChooser {
  FlMethodCall* call;
  FlValue* review = nullptr;
  std::string reviewed_path;
  std::string suffix;
  bool suffix_only_when_missing;
  bool allow_link;
  bool replied = false;

  ~SaveChooser() {
    g_clear_pointer(&review, fl_value_unref);
    g_object_unref(call);
  }
};

void finish(GtkWidget* dialog, SaveChooser* state, FlValue* result,
            const gchar* error = nullptr) {
  state->replied = true;
  if (error != nullptr) {
    fl_method_call_respond_error(state->call, error, nullptr, nullptr, nullptr);
  } else {
    fl_method_call_respond_success(state->call, result, nullptr);
  }
  gtk_widget_destroy(dialog);
}

void dialog_destroyed(GtkWidget* widget, gpointer data) {
  auto* state = static_cast<SaveChooser*>(data);
  GtkWindow* parent = gtk_window_get_transient_for(GTK_WINDOW(widget));
  if (parent != nullptr) g_object_set_data(G_OBJECT(parent), kActiveChooser, nullptr);
  if (!state->replied) {
    fl_method_call_respond_success(state->call, nullptr, nullptr);
  }
}

// Keep the amended name in the chooser. GTK then validates that pathname
// itself and prompts only if that exact destination exists.
bool amend_name(GtkFileChooser* chooser, const gchar* path,
                const SaveChooser* state) {
  if (state->suffix.empty()) return false;
  g_autofree gchar* name = g_path_get_basename(path);
  const gchar* extension = strrchr(name, '.');
  if (extension != nullptr && extension != name &&
      (state->suffix_only_when_missing ||
       g_ascii_strcasecmp(extension, state->suffix.c_str()) == 0)) {
    return false;
  }
  g_autofree gchar* folder = g_path_get_dirname(path);
  g_autofree gchar* current = gtk_file_chooser_get_current_folder(chooser);
  if (g_strcmp0(folder, current) != 0) {
    gtk_file_chooser_set_current_folder(chooser, folder);
  }
  const std::string amended = std::string(name) + state->suffix;
  gtk_file_chooser_set_current_name(chooser, amended.c_str());
  return true;
}

GtkFileChooserConfirmation confirm_overwrite(GtkFileChooser* chooser,
                                              gpointer data) {
  auto* state = static_cast<SaveChooser*>(data);
  g_clear_pointer(&state->review, fl_value_unref);
  state->reviewed_path.clear();
  g_autofree gchar* path = gtk_file_chooser_get_filename(chooser);
  if (path == nullptr || amend_name(chooser, path, state)) {
    return GTK_FILE_CHOOSER_CONFIRMATION_SELECT_AGAIN;
  }
  // This hook runs before GTK shows its stock Cancel/Replace prompt. A later
  // response is useful only for this exact entry and this exact pathname.
  state->reviewed_path = path;
  state->review = selection(path, true, state->allow_link);
  return GTK_FILE_CHOOSER_CONFIRMATION_CONFIRM;
}

void response(GtkDialog* dialog, gint response_id, gpointer data) {
  auto* state = static_cast<SaveChooser*>(data);
  GtkWidget* widget = GTK_WIDGET(dialog);
  if (response_id != GTK_RESPONSE_ACCEPT) {
    finish(widget, state, nullptr);
    return;
  }
  GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
  g_autofree gchar* path = gtk_file_chooser_get_filename(chooser);
  if (path == nullptr) {
    finish(widget, state, nullptr, "invalid-destination");
    return;
  }
  if (amend_name(chooser, path, state)) {
    g_clear_pointer(&state->review, fl_value_unref);
    state->reviewed_path.clear();
    return;
  }
  if (state->reviewed_path == path) {
    finish(widget, state, state->review,
           state->review == nullptr ? "invalid-destination" : nullptr);
    return;
  }
  g_autoptr(FlValue) result = selection(path, false, state->allow_link);
  finish(widget, state, result,
         result == nullptr ? "invalid-destination" : nullptr);
}

void add_filter(GtkFileChooser* chooser, FlValue* args) {
  const auto* label = string_arg(args, "filterLabel");
  auto* patterns = fl_value_lookup_string(args, "patterns");
  if (label == nullptr || patterns == nullptr ||
      fl_value_get_type(patterns) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(patterns) == 0) {
    return;
  }
  GtkFileFilter* filter = gtk_file_filter_new();
  gtk_file_filter_set_name(filter, label);
  for (size_t index = 0; index < fl_value_get_length(patterns); ++index) {
    auto* value = fl_value_get_list_value(patterns, index);
    if (fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
      gtk_file_filter_add_pattern(filter, fl_value_get_string(value));
    }
  }
  gtk_file_chooser_add_filter(chooser, filter);
  GtkFileFilter* all_files = gtk_file_filter_new();
  gtk_file_filter_set_name(all_files, g_dgettext("gtk30", "All Files"));
  gtk_file_filter_add_pattern(all_files, "*");
  gtk_file_chooser_add_filter(chooser, all_files);
  gtk_file_chooser_set_filter(chooser, filter);
}

void method_call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  if (g_strcmp0(fl_method_call_get_name(call), "save") != 0) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  GtkWindow* parent = GTK_WINDOW(data);
  if (g_object_get_data(G_OBJECT(parent), kActiveChooser) != nullptr) {
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  FlValue* args = fl_method_call_get_args(call);
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    fl_method_call_respond_error(call, "invalid-arguments", nullptr, nullptr,
                                 nullptr);
    return;
  }
  const gchar* action = string_arg(args, "actionLabel");
  const gchar* cancel = string_arg(args, "cancelLabel");
  const gchar* name = string_arg(args, "suggestedName");
  const gchar* suffix = string_arg(args, "suffix");
  if (action == nullptr || cancel == nullptr || name == nullptr) {
    fl_method_call_respond_error(call, "invalid-arguments", nullptr, nullptr,
                                 nullptr);
    return;
  }
  GtkWidget* dialog = gtk_file_chooser_dialog_new(
      action, parent, GTK_FILE_CHOOSER_ACTION_SAVE, cancel, GTK_RESPONSE_CANCEL,
      action, GTK_RESPONSE_ACCEPT, nullptr);
  auto* state = new SaveChooser{
      FL_METHOD_CALL(g_object_ref(call)), nullptr, {},
      suffix != nullptr ? suffix : "", bool_arg(args, "suffixOnlyWhenMissing"),
      bool_arg(args, "allowLink")};
  g_object_set_data_full(G_OBJECT(dialog), "busymark-save-chooser", state,
                         [](gpointer state) {
                           delete static_cast<SaveChooser*>(state);
                         });
  g_object_set_data(G_OBJECT(parent), kActiveChooser, dialog);
  gtk_window_set_modal(GTK_WINDOW(dialog), TRUE);
  gtk_window_set_destroy_with_parent(GTK_WINDOW(dialog), TRUE);
  gtk_dialog_set_default_response(GTK_DIALOG(dialog), GTK_RESPONSE_ACCEPT);
  GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
  gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
  if (const gchar* folder = string_arg(args, "initialDirectory")) {
    gtk_file_chooser_set_current_folder(chooser, folder);
  }
  gtk_file_chooser_set_current_name(chooser, name);
  add_filter(chooser, args);
  g_signal_connect(dialog, "confirm-overwrite", G_CALLBACK(confirm_overwrite),
                   state);
  g_signal_connect(dialog, "response", G_CALLBACK(response), state);
  g_signal_connect(dialog, "destroy", G_CALLBACK(dialog_destroyed), state);
  gtk_widget_show(dialog);
}

}  // namespace

FlMethodChannel* busymark_save_chooser_channel_new(FlView* view,
                                                  GtkWindow* parent) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "busymark/save_chooser", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call, parent,
                                          nullptr);
  return channel;
}
