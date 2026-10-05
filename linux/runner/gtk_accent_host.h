#ifndef BUSYMARK_GTK_ACCENT_HOST_H_
#define BUSYMARK_GTK_ACCENT_HOST_H_
#include <flutter_linux/flutter_linux.h>

struct BusyMarkGtkAccentHost;
BusyMarkGtkAccentHost* busymark_gtk_accent_host_new(FlView* view,
                                                  GtkWidget* window);
void busymark_gtk_accent_host_free(BusyMarkGtkAccentHost* host);
#endif  // BUSYMARK_GTK_ACCENT_HOST_H_
