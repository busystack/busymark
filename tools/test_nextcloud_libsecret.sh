#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$(mktemp -d /tmp/busymark-libsecret.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror \
  "$project_root/tools/nextcloud_libsecret_probe.cc" \
  -I"$project_root/linux/runner" $(pkg-config --cflags --libs libsecret-1) \
  -o "$fixture_root/probe"
# Keep the probe in an isolated Secret Service session and data directory.
# This does not add fixture credentials to the user's ordinary desktop keyring.
mkdir -m 700 "$fixture_root/data" "$fixture_root/control"
XDG_DATA_HOME="$fixture_root/data" timeout 30s dbus-run-session -- \
  bash -c '
    printf "%s" "isolated-test-keyring-password" | \
      gnome-keyring-daemon --login --components=secrets \
      --control-directory "$1/control" >/dev/null
    export GNOME_KEYRING_CONTROL="$1/control"
    gnome-keyring-daemon --start --components=secrets \
      --control-directory "$1/control" >/dev/null
    "$1/probe"
  ' bash "$fixture_root"
