#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$(mktemp -d /tmp/busymark-native-shortcuts.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/native_shortcut_metadata_probe.cc" \
  -I"$project_root/linux/runner" $(pkg-config --cflags --libs gtk+-3.0) \
  -o "$fixture_root/probe"
"$fixture_root/probe"
