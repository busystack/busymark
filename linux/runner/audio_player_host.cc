#include "audio_player_host.h"

#include <gst/gst.h>
#include <sys/stat.h>

#include <cmath>
#include <cstring>

struct BusyMarkAudioPlayerHost {
  FlMethodChannel* channel = nullptr;
  GstElement* player = nullptr;
  guint watch = 0;
  gint64 id = 0;
  bool playing = false;
  bool looping = false;
  double rate = 1;
};

namespace {

constexpr guint64 kMaximumAudioBytes = 100 * 1024 * 1024;

void stop(BusyMarkAudioPlayerHost* host) {
  if (host->watch != 0) {
    g_source_remove(host->watch);
    host->watch = 0;
  }
  if (host->player != nullptr) {
    gst_element_set_state(host->player, GST_STATE_NULL);
    gst_object_unref(host->player);
    host->player = nullptr;
  }
  host->playing = false;
  host->id = 0;
  host->rate = 1;
}

void notify(BusyMarkAudioPlayerHost* host, const char* state) {
  g_autoptr(FlValue) payload = fl_value_new_map();
  fl_value_set_string_take(payload, "id", fl_value_new_int(host->id));
  fl_value_set_string_take(payload, "state", fl_value_new_string(state));
  fl_method_channel_invoke_method(host->channel, "state", payload, nullptr,
                                  nullptr, nullptr);
}

gboolean on_message(GstBus*, GstMessage* message, gpointer data) {
  auto* host = static_cast<BusyMarkAudioPlayerHost*>(data);
  switch (GST_MESSAGE_TYPE(message)) {
    case GST_MESSAGE_ERROR:
      host->playing = false;
      gst_element_set_state(host->player, GST_STATE_NULL);
      notify(host, "failed");
      break;
    case GST_MESSAGE_EOS:
      if (host->looping && host->playing &&
          gst_element_seek_simple(host->player, GST_FORMAT_TIME,
                                  GST_SEEK_FLAG_FLUSH, 0)) {
        break;
      }
      host->playing = false;
      gst_element_set_state(host->player, GST_STATE_PAUSED);
      notify(host, "ended");
      break;
    case GST_MESSAGE_BUFFERING: {
      gint percent = 0;
      gst_message_parse_buffering(message, &percent);
      if (host->playing) {
        gst_element_set_state(host->player, percent < 100 ? GST_STATE_PAUSED
                                                          : GST_STATE_PLAYING);
        if (percent < 100) notify(host, "buffering");
      }
      break;
    }
    case GST_MESSAGE_STATE_CHANGED:
      if (GST_MESSAGE_SRC(message) == GST_OBJECT(host->player)) {
        GstState current, pending;
        gst_message_parse_state_changed(message, nullptr, &current, &pending);
        if (current == GST_STATE_PLAYING && host->playing) {
          gint audio_streams = 0;
          g_object_get(host->player, "n-audio", &audio_streams, nullptr);
          if (audio_streams > 0) {
            notify(host, "playing");
          } else {
            host->playing = false;
            gst_element_set_state(host->player, GST_STATE_NULL);
            notify(host, "failed");
          }
        } else if (current == GST_STATE_PAUSED && !host->playing &&
                   pending == GST_STATE_VOID_PENDING) {
          notify(host, "paused");
        }
      }
      break;
    default:
      break;
  }
  return G_SOURCE_CONTINUE;
}

FlValue* lookup(FlValue* args, const char* key, FlValueType type) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == type ? value : nullptr;
}

bool boolean(FlValue* args, const char* key) {
  FlValue* value = lookup(args, key, FL_VALUE_TYPE_BOOL);
  return value != nullptr && fl_value_get_bool(value);
}

double seconds(FlValue* args, const char* key, double fallback) {
  FlValue* value = lookup(args, key, FL_VALUE_TYPE_FLOAT);
  return value == nullptr ? fallback : fl_value_get_float(value);
}

void reply(FlMethodCall* call, bool ok) {
  g_autoptr(FlValue) value = fl_value_new_bool(ok);
  fl_method_call_respond_success(call, value, nullptr);
}

void on_call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* host = static_cast<BusyMarkAudioPlayerHost*>(data);
  FlValue* args = fl_method_call_get_args(call);
  const char* method = fl_method_call_get_name(call);
  FlValue* id_value = lookup(args, "id", FL_VALUE_TYPE_INT);
  const gint64 id = id_value == nullptr ? 0 : fl_value_get_int(id_value);

  if (g_str_equal(method, "open")) {
    FlValue* path_value = lookup(args, "path", FL_VALUE_TYPE_STRING);
    const char* path = path_value == nullptr ? nullptr
                                            : fl_value_get_string(path_value);
    struct stat stat_buffer;
    if (id <= 0 || path == nullptr || !g_path_is_absolute(path) ||
        lstat(path, &stat_buffer) != 0 || !S_ISREG(stat_buffer.st_mode) ||
        stat_buffer.st_size <= 0 ||
        static_cast<guint64>(stat_buffer.st_size) > kMaximumAudioBytes) {
      reply(call, false);
      return;
    }
    g_autofree char* uri = g_filename_to_uri(path, nullptr, nullptr);
    stop(host);
    if (uri == nullptr || !gst_init_check(nullptr, nullptr, nullptr)) {
      reply(call, false);
      return;
    }
    host->player = gst_element_factory_make("playbin", nullptr);
    if (host->player == nullptr) {
      reply(call, false);
      return;
    }
    host->id = id;
    host->looping = boolean(args, "loop");
    host->playing = true;
    guint flags = 0;
    g_object_get(host->player, "flags", &flags, nullptr);
    // Disable video, subtitles and visualizations. Keep the normal audio sink.
    flags &= ~((1u << 0) | (1u << 2) | (1u << 3));
    g_object_set(host->player, "uri", uri, "flags", flags,
                 "mute", boolean(args, "mute"), nullptr);
    GstBus* bus = gst_element_get_bus(host->player);
    host->watch = gst_bus_add_watch(bus, on_message, host);
    gst_object_unref(bus);
    if (gst_element_set_state(host->player, GST_STATE_PLAYING) ==
        GST_STATE_CHANGE_FAILURE) {
      stop(host);
      reply(call, false);
      return;
    }
    reply(call, true);
    return;
  }

  if (host->id != id || host->player == nullptr) {
    reply(call, false);
    return;
  }

  if (g_str_equal(method, "close")) {
    stop(host);
    reply(call, true);
  } else if (g_str_equal(method, "play") || g_str_equal(method, "pause")) {
    host->playing = g_str_equal(method, "play");
    reply(call, gst_element_set_state(host->player, host->playing
                     ? GST_STATE_PLAYING : GST_STATE_PAUSED) != GST_STATE_CHANGE_FAILURE);
  } else if (g_str_equal(method, "position")) {
    gint64 position = -1, duration = -1;
    gst_element_query_position(host->player, GST_FORMAT_TIME, &position);
    gst_element_query_duration(host->player, GST_FORMAT_TIME, &duration);
    GstQuery* seeking = gst_query_new_seeking(GST_FORMAT_TIME);
    gboolean seekable = FALSE;
    if (gst_element_query(host->player, seeking)) {
      gst_query_parse_seeking(seeking, nullptr, &seekable, nullptr, nullptr);
    }
    gst_query_unref(seeking);
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "position",
                             fl_value_new_float(position / double(GST_SECOND)));
    fl_value_set_string_take(result, "duration", fl_value_new_float(
        duration < 0 ? -1.0 : duration / double(GST_SECOND)));
    fl_value_set_string_take(result, "seekable", fl_value_new_bool(seekable));
    fl_method_call_respond_success(call, result, nullptr);
  } else if (g_str_equal(method, "audio")) {
    const double volume = seconds(args, "volume", 1.0);
    if (!std::isfinite(volume) || volume < 0 || volume > 1) {
      reply(call, false);
      return;
    }
    host->looping = boolean(args, "loop");
    g_object_set(host->player, "volume", volume, "mute", boolean(args, "mute"),
                 nullptr);
    reply(call, true);
  } else if (g_str_equal(method, "seek")) {
    const double position = seconds(args, "position", -1);
    const double rate = seconds(args, "rate", host->rate);
    if (!std::isfinite(position) || position < 0 || position > 86400 ||
        !std::isfinite(rate) || rate < 0.5 || rate > 2) {
      reply(call, false);
      return;
    }
    const bool ok = gst_element_seek(
        host->player, rate, GST_FORMAT_TIME,
        static_cast<GstSeekFlags>(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
        GST_SEEK_TYPE_SET, static_cast<gint64>(position * GST_SECOND),
        GST_SEEK_TYPE_NONE, GST_CLOCK_TIME_NONE);
    if (ok) host->rate = rate;
    reply(call, ok);
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}

}  // namespace

BusyMarkAudioPlayerHost* busymark_audio_player_host_new(FlView* view) {
  auto* host = new BusyMarkAudioPlayerHost();
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  host->channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.busymark.app/audio_player", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(host->channel, on_call, host,
                                             nullptr);
  return host;
}

void busymark_audio_player_host_destroy(BusyMarkAudioPlayerHost* host) {
  if (host == nullptr) return;
  fl_method_channel_set_method_call_handler(host->channel, nullptr, nullptr,
                                             nullptr);
  stop(host);
  g_object_unref(host->channel);
  delete host;
}
