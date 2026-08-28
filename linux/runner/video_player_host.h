#ifndef BUSYMARK_VIDEO_PLAYER_HOST_H_
#define BUSYMARK_VIDEO_PLAYER_HOST_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(BusyMarkVideoPlayerHost,
                     busymark_video_player_host,
                     BUSYMARK,
                     VIDEO_PLAYER_HOST,
                     GObject)

BusyMarkVideoPlayerHost* busymark_video_player_host_new(GtkWidget* overlay);

void busymark_video_player_host_register_channel(
    BusyMarkVideoPlayerHost* self,
    FlView* view);

void busymark_video_player_host_shutdown(BusyMarkVideoPlayerHost* self);

#endif  // BUSYMARK_VIDEO_PLAYER_HOST_H_
