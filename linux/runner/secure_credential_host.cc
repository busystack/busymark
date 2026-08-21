#include "secure_credential_host.h"

#include <libsecret/secret.h>

#include <cstring>

namespace {

constexpr char kChannelName[] = "com.busymark.app/secure_credentials";
constexpr char kOpenAiCredential[] = "busymark.ai.provider-key.openai";
constexpr char kGeminiCredential[] = "busymark.ai.provider-key.gemini";
constexpr gsize kMaximumCredentialBytes = 16 * 1024;

struct CredentialRequest {
  FlMethodCall* method_call;
  gchar* key;
  gchar* secret;
};

SecretSchema* credential_schema() {
  static SecretSchema* schema =
      secret_schema_new("io.busystack.busymark.ai.credentials",
                        SECRET_SCHEMA_NONE, "credential",
                        SECRET_SCHEMA_ATTRIBUTE_STRING, nullptr);
  return schema;
}

bool is_allowed_key(const gchar* key) {
  return g_strcmp0(key, kOpenAiCredential) == 0 ||
         g_strcmp0(key, kGeminiCredential) == 0;
}

const gchar* credential_label(const gchar* key) {
  if (g_strcmp0(key, kOpenAiCredential) == 0) {
    return "BusyMark OpenAI API key";
  }
  return "BusyMark Google Gemini API key";
}

const gchar* map_string_value(FlValue* args, const gchar* name) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, name);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : nullptr;
}

void clear_and_free_secret(gchar* secret) {
  if (secret == nullptr) {
    return;
  }
  volatile gchar* cursor = secret;
  for (gsize index = 0; secret[index] != '\0'; ++index) {
    cursor[index] = '\0';
  }
  g_free(secret);
}

CredentialRequest* credential_request_new(FlMethodCall* method_call,
                                          const gchar* key,
                                          const gchar* secret = nullptr) {
  auto* request = g_new0(CredentialRequest, 1);
  request->method_call =
      FL_METHOD_CALL(g_object_ref(G_OBJECT(method_call)));
  request->key = g_strdup(key);
  request->secret = g_strdup(secret);
  return request;
}

void credential_request_free(CredentialRequest* request) {
  if (request == nullptr) {
    return;
  }
  g_clear_object(&request->method_call);
  g_clear_pointer(&request->key, g_free);
  clear_and_free_secret(request->secret);
  g_free(request);
}

void respond_error(CredentialRequest* request, GError* error) {
  const gchar* message = error != nullptr && error->message != nullptr
                             ? error->message
                             : "The desktop credential service is unavailable.";
  fl_method_call_respond_error(request->method_call,
                               "credential-store-unavailable", message,
                               nullptr, nullptr);
}

void lookup_finished(GObject*, GAsyncResult* result, gpointer user_data) {
  auto* request = static_cast<CredentialRequest*>(user_data);
  g_autoptr(GError) error = nullptr;
  gchar* secret = secret_password_lookup_finish(result, &error);
  if (error != nullptr) {
    respond_error(request, error);
  } else {
    g_autoptr(FlValue) value = secret == nullptr
                                  ? fl_value_new_null()
                                  : fl_value_new_string(secret);
    fl_method_call_respond_success(request->method_call, value, nullptr);
  }
  secret_password_free(secret);
  credential_request_free(request);
}

void store_finished(GObject*, GAsyncResult* result, gpointer user_data) {
  auto* request = static_cast<CredentialRequest*>(user_data);
  g_autoptr(GError) error = nullptr;
  const gboolean stored = secret_password_store_finish(result, &error);
  if (error != nullptr || !stored) {
    respond_error(request, error);
  } else {
    g_autoptr(FlValue) value = fl_value_new_null();
    fl_method_call_respond_success(request->method_call, value, nullptr);
  }
  credential_request_free(request);
}

void clear_finished(GObject*, GAsyncResult* result, gpointer user_data) {
  auto* request = static_cast<CredentialRequest*>(user_data);
  g_autoptr(GError) error = nullptr;
  secret_password_clear_finish(result, &error);
  if (error != nullptr) {
    respond_error(request, error);
  } else {
    g_autoptr(FlValue) value = fl_value_new_null();
    fl_method_call_respond_success(request->method_call, value, nullptr);
  }
  credential_request_free(request);
}

void respond_invalid_arguments(FlMethodCall* method_call,
                               const gchar* message) {
  fl_method_call_respond_error(method_call, "invalid-arguments", message,
                               nullptr, nullptr);
}

void secure_credential_method_call_cb(FlMethodChannel*,
                                      FlMethodCall* method_call,
                                      gpointer) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  const gchar* key = map_string_value(args, "key");
  if (!is_allowed_key(key)) {
    respond_invalid_arguments(method_call, "Unsupported credential key.");
    return;
  }

  if (std::strcmp(method, "read") == 0) {
    auto* request = credential_request_new(method_call, key);
    secret_password_lookup(credential_schema(), nullptr, lookup_finished,
                           request, "credential", key, nullptr);
    return;
  }

  if (std::strcmp(method, "write") == 0) {
    const gchar* secret = map_string_value(args, "value");
    if (secret == nullptr || secret[0] == '\0' ||
        std::strlen(secret) > kMaximumCredentialBytes) {
      respond_invalid_arguments(method_call,
                                "Credential value is empty or too large.");
      return;
    }
    auto* request = credential_request_new(method_call, key, secret);
    secret_password_store(credential_schema(), SECRET_COLLECTION_DEFAULT,
                          credential_label(key), request->secret, nullptr,
                          store_finished, request, "credential", key,
                          nullptr);
    return;
  }

  if (std::strcmp(method, "delete") == 0) {
    auto* request = credential_request_new(method_call, key);
    secret_password_clear(credential_schema(), nullptr, clear_finished,
                          request, "credential", key, nullptr);
    return;
  }

  fl_method_call_respond_not_implemented(method_call, nullptr);
}

}  // namespace

FlMethodChannel* busymark_secure_credential_channel_new(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, secure_credential_method_call_cb, nullptr, nullptr);
  return channel;
}
