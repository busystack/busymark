#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
engine_root="$project_root/linux/flutter/ephemeral"
source_root="$engine_root/.plugin_symlinks/yaru_window_linux"
fixture_root="$(mktemp -d /tmp/bm-yaru-lifetime.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
if [[ "${1:-}" == --unpatched ]]; then
  source_root="${2:-$source_root}"
  shift
  if (( $# )); then shift; fi
else
  python3 "$project_root/tools/native_patches/yaru_window_linux/prepare.py" \
    "$source_root" "$fixture_root/patched"
  source_root="$fixture_root/patched"
fi
"${CXX:-clang++}" -std=c++14 -Wall -Werror \
  "$project_root/tools/yaru_window_lifecycle_probe.cc" \
  -I"$source_root/linux" -I"$engine_root" \
  $(pkg-config --cflags --libs gtk+-3.0) \
  -L"$engine_root" -lflutter_linux_gtk -Wl,-rpath,"$engine_root" \
  -o "$fixture_root/probe"
mkdir -p "$fixture_root"/{home,config,cache,data,state}
HOME="$fixture_root/home" XDG_CONFIG_HOME="$fixture_root/config" \
  XDG_CACHE_HOME="$fixture_root/cache" XDG_DATA_HOME="$fixture_root/data" \
  XDG_STATE_HOME="$fixture_root/state" GSETTINGS_BACKEND=memory \
  NO_AT_BRIDGE=1 \
  "$fixture_root/probe" "$@"
