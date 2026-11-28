#include <string>
#include <vector>

#include "../linux/runner/audio_player_host.cc"

namespace {

constexpr gint64 kPlayerId = 81;
std::vector<std::string> states;

}  // namespace

extern "C" void __wrap_fl_method_channel_invoke_method(
    FlMethodChannel*, const gchar* method, FlValue* args, GCancellable*,
    GAsyncReadyCallback, gpointer) {
  g_assert_cmpstr(method, ==, "state");
  g_assert_cmpint(fl_value_get_int(fl_value_lookup_string(args, "id")), ==,
                  kPlayerId);
  states.emplace_back(fl_value_get_string(fl_value_lookup_string(args, "state")));
}

int main(int argc, char** argv) {
  gst_init(&argc, &argv);
  g_autoptr(GError) error = nullptr;
  // A finite, non-seekable source drives real EOS and PAUSED bus messages.
  g_autoptr(GstElement) player =
      gst_parse_launch("appsrc name=stream ! fakesink", &error);
  g_assert_no_error(error);
  g_assert_nonnull(player);
  g_autoptr(GstBus) bus = gst_element_get_bus(player);
  g_autoptr(GstElement) source = gst_bin_get_by_name(GST_BIN(player), "stream");
  g_assert_nonnull(source);
  configure_stream_source(player, source, nullptr);
  g_assert_cmpint(gst_element_set_state(player, GST_STATE_PLAYING), !=,
                  GST_STATE_CHANGE_FAILURE);
  g_autoptr(GstBuffer) data = gst_buffer_new_allocate(nullptr, 64, nullptr);
  GstFlowReturn flow = GST_FLOW_ERROR;
  g_signal_emit_by_name(source, "push-buffer", data, &flow);
  g_assert_cmpint(flow, ==, GST_FLOW_OK);
  g_signal_emit_by_name(source, "end-of-stream", &flow);
  g_assert_cmpint(flow, ==, GST_FLOW_OK);
  g_autoptr(GstMessage) eos = gst_bus_timed_pop_filtered(
      bus, 5 * GST_SECOND,
      static_cast<GstMessageType>(GST_MESSAGE_EOS | GST_MESSAGE_ERROR));
  g_assert_nonnull(eos);
  g_assert_cmpint(GST_MESSAGE_TYPE(eos), ==, GST_MESSAGE_EOS);

  BusyMarkAudioPlayerHost host;
  host.player = player;
  host.id = kPlayerId;
  host.playing = true;
  host.streamed = true;
  on_message(bus, eos, &host);
  g_assert_true(host.ended);
  g_assert_false(host.playing);

  for (;;) {
    g_autoptr(GstMessage) transition = gst_bus_timed_pop_filtered(
        bus, GST_SECOND, GST_MESSAGE_STATE_CHANGED);
    g_assert_nonnull(transition);
    if (GST_MESSAGE_SRC(transition) != GST_OBJECT(player)) continue;
    GstState current, pending;
    gst_message_parse_state_changed(transition, nullptr, &current, &pending);
    g_assert_cmpint(current, ==, GST_STATE_PAUSED);
    g_assert_cmpint(pending, ==, GST_STATE_VOID_PENDING);
    on_message(bus, transition, &host);
    g_assert_true(states == std::vector<std::string>{"ended"});

    // Outside the EOF state, the same transition still reports a normal pause.
    host.ended = false;
    on_message(bus, transition, &host);
    g_assert_cmpuint(states.size(), ==, 2);
    g_assert_cmpstr(states.back().c_str(), ==, "paused");
    break;
  }

  gst_element_set_state(player, GST_STATE_NULL);
  g_print("PASS native audio EOS survives the subsequent PAUSED transition\n");
}
