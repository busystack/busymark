#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
engine_root="$project_root/linux/flutter/ephemeral"
test -f "$engine_root/libflutter_linux_gtk.so"
fixture_root="$(mktemp -d /tmp/bm-audio-host.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-clang++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/audio_player_host_probe.cc" \
  -I"$engine_root" $(pkg-config --cflags --libs gtk+-3.0 gstreamer-1.0) \
  -L"$engine_root" -lflutter_linux_gtk -Wl,-rpath,"$engine_root" \
  -Wl,--wrap=fl_method_channel_invoke_method \
  -o "$fixture_root/probe"
G_DEBUG=fatal-warnings timeout --signal=TERM 15s "$fixture_root/probe"
