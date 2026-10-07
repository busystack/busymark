#ifndef BUSYMARK_CREDENTIAL_KEY_POLICY_H_
#define BUSYMARK_CREDENTIAL_KEY_POLICY_H_

#include <cstring>

namespace busymark_credentials {

constexpr char kNextcloudPrefix[] = "busymark.nextcloud.account-password.";

// Caller-controlled namespaces are forbidden. Only canonical random v4 UUIDs
// in the dedicated account-password namespace reach the Nextcloud schema.
inline bool is_nextcloud_key(const char* key) {
  if (key == nullptr ||
      std::strncmp(key, kNextcloudPrefix, sizeof(kNextcloudPrefix) - 1) != 0) {
    return false;
  }
  const char* id = key + sizeof(kNextcloudPrefix) - 1;
  if (std::strlen(id) != 36 || id[14] != '4' ||
      (id[19] != '8' && id[19] != '9' && id[19] != 'a' && id[19] != 'b')) {
    return false;
  }
  for (unsigned int index = 0; index < 36; ++index) {
    if (index == 8 || index == 13 || index == 18 || index == 23) {
      if (id[index] != '-') return false;
    } else if (!((id[index] >= '0' && id[index] <= '9') ||
                 (id[index] >= 'a' && id[index] <= 'f'))) {
      return false;
    }
  }
  return true;
}

inline bool is_allowed_key(const char* key) {
  return key != nullptr &&
         (std::strcmp(key, "busymark.ai.provider-key.openai") == 0 ||
          std::strcmp(key, "busymark.ai.provider-key.gemini") == 0 ||
          is_nextcloud_key(key));
}

}  // namespace busymark_credentials

#endif  // BUSYMARK_CREDENTIAL_KEY_POLICY_H_
