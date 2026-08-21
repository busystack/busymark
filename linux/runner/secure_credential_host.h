#ifndef RUNNER_SECURE_CREDENTIAL_HOST_H_
#define RUNNER_SECURE_CREDENTIAL_HOST_H_

#include <flutter_linux/flutter_linux.h>

// Creates the native channel used to store AI provider credentials. The
// caller owns the returned reference.
FlMethodChannel* busymark_secure_credential_channel_new(FlView* view);

#endif  // RUNNER_SECURE_CREDENTIAL_HOST_H_
