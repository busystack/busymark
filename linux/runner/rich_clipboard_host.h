#ifndef RUNNER_RICH_CLIPBOARD_HOST_H_
#define RUNNER_RICH_CLIPBOARD_HOST_H_

#include <flutter_linux/flutter_linux.h>

// The caller owns the channel; GTK owns copied payloads until ownership changes.
FlMethodChannel* busymark_rich_clipboard_channel_new(FlView* view);

#endif  // RUNNER_RICH_CLIPBOARD_HOST_H_
