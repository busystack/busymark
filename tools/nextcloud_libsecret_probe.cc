#include "credential_key_policy.h"

#include <libsecret/secret.h>

#include <cstring>

int main() {
  g_autofree gchar* account = g_uuid_string_random();
  g_autofree gchar* key = g_strconcat(
      busymark_credentials::kNextcloudPrefix, account, nullptr);
  if (!busymark_credentials::is_allowed_key(key)) return 1;
  SecretSchema* schema = secret_schema_new(
      "io.busystack.busymark.nextcloud.credentials", SECRET_SCHEMA_NONE,
      "account", SECRET_SCHEMA_ATTRIBUTE_STRING, nullptr);
  constexpr char fixture[] = "BusyMark isolated acceptance fixture";
  g_autoptr(GError) error = nullptr;
  if (!secret_password_store_sync(
          schema, SECRET_COLLECTION_DEFAULT, "BusyMark libsecret test",
          fixture, nullptr, &error, "account", account, nullptr)) {
    g_printerr("Secure credential creation failed.\n");
    return 2;
  }
  gchar* value = secret_password_lookup_sync(schema, nullptr, &error,
                                           "account", account, nullptr);
  const bool matches = value != nullptr && std::strcmp(value, fixture) == 0;
  secret_password_free(value);
  if (!secret_password_clear_sync(schema, nullptr, &error, "account", account,
                                  nullptr)) {
    g_printerr("Secure credential deletion failed.\n");
    return 3;
  }
  value = secret_password_lookup_sync(schema, nullptr, &error,
                                      "account", account, nullptr);
  const bool absent = value == nullptr && error == nullptr;
  secret_password_free(value);
  secret_schema_unref(schema);
  return matches && absent ? 0 : 4;
}
