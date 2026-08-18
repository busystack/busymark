#ifndef BUSYMARK_WEB_RENDER_HOST_H_
#define BUSYMARK_WEB_RENDER_HOST_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(BusyMarkWebRenderHost,
                     busymark_web_render_host,
                     BUSYMARK,
                     WEB_RENDER_HOST,
                     GObject)

BusyMarkWebRenderHost* busymark_web_render_host_new(
    GtkApplication* application,
    GtkWindow* parent_window);

void busymark_web_render_host_register_channel(BusyMarkWebRenderHost* self,
                                               FlView* view);

void busymark_web_render_host_shutdown(BusyMarkWebRenderHost* self);

#endif  // BUSYMARK_WEB_RENDER_HOST_H_
