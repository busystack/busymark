#ifndef BUSYMARK_SAVE_CHOOSER_HOST_H_
#define BUSYMARK_SAVE_CHOOSER_HOST_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

FlMethodChannel* busymark_save_chooser_channel_new(FlView* view,
                                                  GtkWindow* parent);

#endif
