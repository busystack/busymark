#!/bin/bash
set -euo pipefail
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus LP_NUM_THREADS=2 LIBGL_ALWAYS_SOFTWARE=1 BUSYMARK_RELEASE_SMOKE=1
mkdir -p "$HOME/snap-evidence"
weston --backend=headless --renderer=pixman --socket=wayland-99 --idle-time=0 --log="$HOME/snap-evidence/weston-final.log" &
wpid=$!
sudo snap disconnect busymark:network
trap 'sudo snap connect busymark:network >/dev/null; kill "$wpid" 2>/dev/null || true' EXIT
for attempt in {1..40}; do
 test ! -S "$XDG_RUNTIME_DIR/wayland-99" || break
 kill -0 "$wpid"
 sleep 0.25
done
test -S "$XDG_RUNTIME_DIR/wayland-99"
export WAYLAND_DISPLAY=wayland-99 GDK_BACKEND=wayland
report="$HOME/snap/busymark/common/spelling-release-wayland-final.json"
timeout --signal=TERM 300s snap run busymark --spelling-release-smoke="$report"
python3 -c 'import json,sys; r=json.load(open(sys.argv[1])); assert r["ok"],r; assert r["checks"]["sourceEditorTransaction"] and r["checks"]["formattedRichEditorTransaction"] and r["checks"]["tableCellEditorTransaction"],r; assert not r["checks"]["dictionaryInstalledDuringRun"] and r["checks"]["personalWordPresentBeforeRun"],r' "$report"
report="$HOME/snap/busymark/common/visualization-release-wayland-final.json"
timeout --signal=TERM 300s snap run busymark --visualization-release-smoke="$report"
python3 -c 'import json,sys; r=json.load(open(sys.argv[1])); assert r["ok"],r' "$report"
test -s "$HOME/snap/busymark/common/visualization-smoke.pdf"
