#!/bin/bash
set -euo pipefail
export RUNNER_TEMP=/home/tester/acceptance
mkdir -p "$RUNNER_TEMP"
snap run --shell busymark -c '
  test ! -e \
    "$SNAP/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/librsvg-2.so.2"
  query="$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders"
  loader="$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so"
  "$query" "$loader" | grep -q "\"svg\" 6 \"gdk-pixbuf\""
'

