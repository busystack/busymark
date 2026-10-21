#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
engine_root="$project_root/linux/flutter/ephemeral"
# Build the application first with the pinned Flutter SDK. A missing engine is
# a failure, never a successful skip; CI runs this target after the release build.
test -f "$engine_root/libflutter_linux_gtk.so"
fixture_root="$(mktemp -d /tmp/busymark-gtk-accent-host.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/gtk_accent_host_probe.cc" \
  "$project_root/linux/runner/gtk_accent.cc" \
  "$project_root/linux/runner/gtk_accent_host.cc" \
  -I"$project_root/linux/runner" -I"$engine_root" \
  $(pkg-config --cflags --libs gtk+-3.0) \
  -L"$engine_root" -lflutter_linux_gtk -Wl,-rpath,"$engine_root" \
  -Wl,--wrap=fl_engine_get_binary_messenger \
  -o "$fixture_root/probe"
# The probe enables the AT-SPI bridge and keeps GTK warnings fatal. Give its
# accessibility service (at-spi2-core) a private bus, including on headless CI.
mkdir -p "$fixture_root"/{home,config,cache,data,state,tmp}
HOME="$fixture_root/home" XDG_CONFIG_HOME="$fixture_root/config" \
  XDG_CACHE_HOME="$fixture_root/cache" XDG_DATA_HOME="$fixture_root/data" \
  XDG_STATE_HOME="$fixture_root/state" TMPDIR="$fixture_root/tmp" \
  GSETTINGS_BACKEND=memory dbus-run-session -- env G_DEBUG=fatal-warnings \
  "$fixture_root/probe" "$fixture_root/data"
