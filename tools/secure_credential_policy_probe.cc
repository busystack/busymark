#include "credential_key_policy.h"

#include <cassert>
#include <string>

int main() {
  using busymark_credentials::is_allowed_key;
  using busymark_credentials::is_nextcloud_key;
  assert(is_allowed_key("busymark.ai.provider-key.openai"));
  assert(is_allowed_key("busymark.ai.provider-key.gemini"));
  const std::string prefix = busymark_credentials::kNextcloudPrefix;
  const std::string id = "f85b9c8d-bc26-4cc9-920c-7f7765597f19";
  assert(is_allowed_key((prefix + id).c_str()));
  assert(is_nextcloud_key((prefix + id).c_str()));
  assert(!is_nextcloud_key("busymark.ai.provider-key.openai"));
  assert(!is_allowed_key(nullptr));
  for (const auto& invalid : {"", "openai", "../openai", "nextcloud", "OPENAI",
                              "f85b9c8d-bc26-1cc9-920c-7f7765597f19",
                              "f85b9c8d-bc26-4cc9-120c-7f7765597f19",
                              "F85b9c8d-bc26-4cc9-920c-7f7765597f19",
                              "f85b9c8d/bc26/4cc9/920c/7f7765597f19"}) {
    assert(!is_allowed_key(invalid));
    assert(!is_nextcloud_key((prefix + invalid).c_str()));
  }
  assert(!is_allowed_key((prefix + id + ".other-secret").c_str()));
  assert(!is_allowed_key("busymark.ai.provider-key.arbitrary"));
  return 0;
}
