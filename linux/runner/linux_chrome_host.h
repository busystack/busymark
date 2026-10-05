#ifndef RUNNER_LINUX_CHROME_HOST_H_
#define RUNNER_LINUX_CHROME_HOST_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct BusyMarkLinuxChromeHost;
BusyMarkLinuxChromeHost* busymark_linux_chrome_host_new(
    FlView* view, GtkWindow* window, void (*set_theme)(gboolean));
void busymark_linux_chrome_host_free(BusyMarkLinuxChromeHost* host);

#endif
