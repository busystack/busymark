#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$(mktemp -d /tmp/busymark-gtk-accent.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/gtk_accent_probe.cc" \
  "$project_root/linux/runner/gtk_accent.cc" \
  -I"$project_root/linux/runner" $(pkg-config --cflags --libs gtk+-3.0) \
  -o "$fixture_root/probe"
# Use the caller's isolated display, or an existing display for a hidden probe.
# All GTK setting changes affect only this process; fixtures live under /tmp.
"$fixture_root/probe" "$fixture_root/data"
