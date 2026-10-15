#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
engine_root="$project_root/linux/flutter/ephemeral"
test -f "$engine_root/libflutter_linux_gtk.so"
assets="${BUSYMARK_VISUALIZATION_ASSETS:-$project_root/build/linux/x64/release/bundle/share/busymark/visualization}"
test -f "$assets/harness.html"
fixture_root="$(mktemp -d /tmp/bm-web-host.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-clang++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/web_render_host_probe.cc" \
  "$project_root/linux/runner/video_player_host.cc" \
  -I"$engine_root" $(pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1) \
  -L"$engine_root" -lflutter_linux_gtk -Wl,-rpath,"$engine_root" \
  -Wl,--wrap=fl_engine_get_binary_messenger \
  -Wl,--wrap=webkit_web_context_new_ephemeral \
  -Wl,--wrap=webkit_web_view_new_with_context \
  -Wl,--wrap=webkit_web_view_load_uri \
  -Wl,--wrap=g_file_get_contents \
  -o "$fixture_root/probe"
export BUSYMARK_VISUALIZATION_ASSETS="$assets"
export GSETTINGS_BACKEND=memory
export NO_AT_BRIDGE=1
unset BUSYMARK_RELEASE_SMOKE
# Each case gets a fresh process and profile. Keep WebKit's sandbox enabled.
operations=(video-no-init video-first video-failure video-view-failure video-playback video-mini-playback video-source-failure no-init pre-cancel renderMermaid renderPlantUml renderMathBatch \
  inspectOpenApi parseOpenApi rasterizeSvg openOpenApiReference concurrent-cancel \
  active-cancel engine-cancel snapshot-cancel engine-failure graphviz-failure failure load-failure harness-failure \
  shutdown-scheduled shutdown-loading shutdown-readiness shutdown-active \
  shutdown-channel shutdown-engine reference-shutdown recovery)
if (( $# > 0 )); then operations=("$@"); fi
repetitions="${BUSYMARK_NATIVE_PROBE_REPETITIONS:-1}"
[[ "$repetitions" =~ ^[1-9][0-9]*$ ]]
for ((iteration=1; iteration<=repetitions; iteration++)); do
for operation in "${operations[@]}"; do
  profile="$fixture_root/$iteration-$operation"
  mkdir -p "$profile"/{home,config,cache,data,state,tmp}
  command=("$fixture_root/probe" "$operation")
  if [[ -n "${BUSYMARK_NATIVE_SLOW_CAPTURE_DIR:-}" ]]; then
    command=(python3 "$project_root/tools/capture_native_slow_operation.py"
      --output "$BUSYMARK_NATIVE_SLOW_CAPTURE_DIR/$iteration-$operation"
      --threshold-ms "${BUSYMARK_NATIVE_SLOW_THRESHOLD_MS:-500}"
      --duration 40 --expect-exit -- "${command[@]}")
  fi
  if [[ -n "${BUSYMARK_NATIVE_SYSCALL_TRACE_DIR:-}" ]]; then
    mkdir -p "$BUSYMARK_NATIVE_SYSCALL_TRACE_DIR"
    command=(strace -f -ttt -T
      -o "$BUSYMARK_NATIVE_SYSCALL_TRACE_DIR/$iteration-$operation.strace"
      -e 'trace=%process,%file,%network,mmap,mprotect,munmap,write,writev,futex,poll,ppoll,epoll_wait,epoll_pwait,fsync,fdatasync'
      "${command[@]}")
  fi
  HOME="$profile/home" XDG_CONFIG_HOME="$profile/config" \
    XDG_CACHE_HOME="$profile/cache" XDG_DATA_HOME="$profile/data" \
    XDG_STATE_HOME="$profile/state" TMPDIR="$profile/tmp" \
    timeout --signal=TERM 45s "${command[@]}"
done
done
