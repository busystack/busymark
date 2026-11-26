#include "rich_clipboard_host.h"

#include <cstring>
#include <cstdint>
#include <memory>
#include <string>

namespace {
constexpr char kChannel[] = "com.busymark.app/rich_clipboard";
constexpr char kToken[] = "application/x-busymark-token";
constexpr gsize kMaximumBytes = 16 * 1024 * 1024;
constexpr gsize kMaximumTokenBytes = 256;

struct Payload {
  std::string text;
  std::string html;
  std::string token;
};

void provide(GtkClipboard*, GtkSelectionData* selection, guint info,
             gpointer user_data) {
  const auto* payload = static_cast<Payload*>(user_data);
  if (info == 0) {
    gtk_selection_data_set_text(selection, payload->text.c_str(),
                                payload->text.size());
    return;
  }
  const auto& bytes = info == 1 ? payload->html : payload->token;
  gtk_selection_data_set(selection, gtk_selection_data_get_target(selection),
                          8, reinterpret_cast<const guchar*>(bytes.data()),
                          bytes.size());
}

void clear_payload(GtkClipboard*, gpointer data) {
  delete static_cast<Payload*>(data);
}

struct Host {
  GtkClipboard* clipboard;
  guint64 generation = 0;
  gulong owner_changed;

  explicit Host(GtkClipboard* value)
      : clipboard(GTK_CLIPBOARD(g_object_ref(value))) {
    owner_changed = g_signal_connect(
        clipboard, "owner-change",
        G_CALLBACK(+[](GtkClipboard*, GdkEventOwnerChange*, gpointer data) {
          static_cast<Host*>(data)->generation++;
        }), this);
  }
  ~Host() {
    g_signal_handler_disconnect(clipboard, owner_changed);
    g_object_unref(clipboard);
  }
};

using SharedHost = std::shared_ptr<Host>;

bool argument(FlValue* args, const char* key, std::string* out, bool required) {
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) return !required;
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return false;
  const char* text = fl_value_get_string(value);
  const gsize length = strlen(text);
  if (length > kMaximumBytes || !g_utf8_validate(text, length, nullptr)) {
    return false;
  }
  out->assign(text, length);
  return true;
}

void write_clipboard(const SharedHost& host, FlMethodCall* call) {
  FlValue* args = fl_method_call_get_args(call);
  auto payload = std::make_unique<Payload>();
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP ||
      !argument(args, "text", &payload->text, true) ||
      !argument(args, "html", &payload->html, false) ||
      !argument(args, "token", &payload->token, true) ||
      payload->token.empty() ||
      payload->text.size() + payload->html.size() + payload->token.size() >
          kMaximumBytes) {
    fl_method_call_respond_error(call, "clipboard.invalid-data",
                                 "Clipboard content is invalid or too large.",
                                 nullptr, nullptr);
    return;
  }
  GtkTargetList* list = gtk_target_list_new(nullptr, 0);
  gtk_target_list_add_text_targets(list, 0);
  if (!payload->html.empty()) {
    gtk_target_list_add(list, gdk_atom_intern_static_string("text/html"), 0, 1);
  }
  gtk_target_list_add(list, gdk_atom_intern_static_string(kToken), 0, 2);
  gint count = 0;
  GtkTargetEntry* targets = gtk_target_table_new_from_list(list, &count);
  const gboolean success = gtk_clipboard_set_with_data(
      host->clipboard, targets, count, provide, clear_payload, payload.get());
  if (success) {
    payload.release();
    host->generation++;
    gtk_clipboard_set_can_store(host->clipboard, nullptr, 0);
  }
  gtk_target_table_free(targets, count);
  gtk_target_list_unref(list);
  g_autoptr(FlValue) result = fl_value_new_bool(success);
  fl_method_call_respond_success(call, result, nullptr);
}

struct Read {
  SharedHost host;
  FlMethodCall* call;
  FlValue* result = fl_value_new_map();
  guint64 generation;
  enum class Step { kToken, kHtml, kText, kDone };
  Step step;

  Read(SharedHost value, FlMethodCall* request, bool plain_text_only)
      : host(std::move(value)),
        call(FL_METHOD_CALL(g_object_ref(request))),
        generation(host->generation),
        step(plain_text_only ? Step::kText : Step::kToken) {}
  ~Read() {
    fl_value_unref(result);
    g_object_unref(call);
  }
  bool current() const { return generation == host->generation; }
};

void next_read(Read* request);

void received(GtkClipboard*, GtkSelectionData* selection, gpointer data) {
  auto* request = static_cast<Read*>(data);
  const gint length = gtk_selection_data_get_length(selection);
  const guchar* bytes = gtk_selection_data_get_data(selection);
  const bool token = request->step == Read::Step::kHtml;
  const gsize limit = token ? kMaximumTokenBytes : kMaximumBytes;
  if (request->current() && bytes != nullptr && length > 0 &&
      static_cast<gsize>(length) <= limit &&
      gtk_selection_data_get_format(selection) == 8) {
    // Some HTML providers include a terminating NUL in the byte count.
    gsize size = length;
    while (size > 0 && bytes[size - 1] == 0) size--;
    if (g_utf8_validate(reinterpret_cast<const char*>(bytes), size, nullptr)) {
      fl_value_set_string_take(
          request->result, token ? "token" : "html",
          fl_value_new_string_sized(reinterpret_cast<const char*>(bytes), size));
    }
  }
  next_read(request);
}

void received_text(GtkClipboard*, const gchar* text, gpointer data) {
  auto* request = static_cast<Read*>(data);
  if (request->current() && text != nullptr) {
    const gsize length = strlen(text);
    // Keep an independent bounded fallback if HTML is accepted but unusable.
    if (length <= kMaximumBytes && g_utf8_validate(text, length, nullptr)) {
      fl_value_set_string_take(
          request->result, "text", fl_value_new_string_sized(text, length));
    }
  }
  next_read(request);
}

void next_read(Read* request) {
  if (!request->current() || request->step == Read::Step::kDone) {
    // Never combine representations from different clipboard owners.
    if (!request->current()) {
      fl_value_unref(request->result);
      request->result = fl_value_new_map();
    } else {
      fl_value_set_string_take(
          request->result, "generation",
          fl_value_new_int(static_cast<int64_t>(request->generation)));
    }
    fl_method_call_respond_success(request->call, request->result, nullptr);
    delete request;
    return;
  }
  switch (request->step) {
    case Read::Step::kToken:
      request->step = Read::Step::kHtml;
      gtk_clipboard_request_contents(request->host->clipboard,
                                     gdk_atom_intern_static_string(kToken),
                                     received, request);
      break;
    case Read::Step::kHtml:
      request->step = Read::Step::kText;
      gtk_clipboard_request_contents(request->host->clipboard,
                                     gdk_atom_intern_static_string("text/html"),
                                     received, request);
      break;
    case Read::Step::kText:
      request->step = Read::Step::kDone;
      gtk_clipboard_request_text(request->host->clipboard, received_text, request);
      break;
    case Read::Step::kDone:
      break;
  }
}

void method_call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  const auto& host = *static_cast<SharedHost*>(data);
  const char* method = fl_method_call_get_name(call);
  if (strcmp(method, "write") == 0) {
    write_clipboard(host, call);
  } else if (strcmp(method, "read") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    FlValue* plain_text =
        args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
            ? fl_value_lookup_string(args, "plainTextOnly")
            : nullptr;
    const bool plain_text_only = plain_text != nullptr &&
        fl_value_get_type(plain_text) == FL_VALUE_TYPE_BOOL &&
        fl_value_get_bool(plain_text);
    next_read(new Read(host, call, plain_text_only));
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}
}  // namespace

FlMethodChannel* busymark_rich_clipboard_channel_new(FlView* view) {
  auto host = std::make_shared<Host>(gtk_widget_get_clipboard(
      GTK_WIDGET(view), GDK_SELECTION_CLIPBOARD));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kChannel,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call, new SharedHost(std::move(host)),
      +[](gpointer data) { delete static_cast<SharedHost*>(data); });
  return channel;
}
