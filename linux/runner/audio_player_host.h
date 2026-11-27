#ifndef BUSYMARK_AUDIO_PLAYER_HOST_H_
#define BUSYMARK_AUDIO_PLAYER_HOST_H_

#include <flutter_linux/flutter_linux.h>

struct BusyMarkAudioPlayerHost;

BusyMarkAudioPlayerHost* busymark_audio_player_host_new(FlView* view);
void busymark_audio_player_host_destroy(BusyMarkAudioPlayerHost* host);

#endif
