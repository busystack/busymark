#ifndef BUSYMARK_WRITERSIDE_DIALOG_HOST_H_
#define BUSYMARK_WRITERSIDE_DIALOG_HOST_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// Creates the method channel that owns BusyMark's native Linux Writerside
// dialogs. The caller owns the returned reference.
FlMethodChannel* busymark_writerside_dialog_channel_new(FlView* view,
                                                        GtkWindow* parent);

#endif  // BUSYMARK_WRITERSIDE_DIALOG_HOST_H_
