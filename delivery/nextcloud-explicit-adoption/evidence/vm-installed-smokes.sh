#!/bin/bash
set -euo pipefail
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export LP_NUM_THREADS=2
export RUNNER_TEMP=/home/tester/snap-evidence
mkdir -p "$RUNNER_TEMP"

report="$HOME/snap/busymark/common/spelling-release.json"
rm -f "$report"
xvfb-run -a -s '-screen 0 1280x1024x24' \
  env GDK_BACKEND=x11 BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 snap run busymark \
  --spelling-release-smoke="$report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report; assert report["checks"]["bundledDictionaryFileCount"] == 0, report; assert report["checks"]["dictionaryInstalledDuringRun"], report; assert report["checks"]["installedDictionaryCount"] == 1, report' "$report"
test -d "$HOME/snap/busymark/common/spelling/dictionaries/downloaded/en-US"
before_revision="$(snap list busymark | awk 'NR == 2 {print $3}')"
sudo snap install --dangerous \
  "/home/tester/busymark_0.6.1_amd64.snap"
after_revision="$(snap list busymark | awk 'NR == 2 {print $3}')"
test -n "$before_revision"
test -n "$after_revision"
test "$before_revision" != "$after_revision"
sudo snap disconnect busymark:network
trap 'sudo snap connect busymark:network >/dev/null' EXIT
xvfb-run -a -s '-screen 0 1280x1024x24' \
  env GDK_BACKEND=x11 BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 snap run busymark \
  --spelling-release-smoke="$report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report; assert not report["checks"]["dictionaryInstalledDuringRun"], report; assert report["checks"]["installedDictionaryCount"] == 1, report; assert report["checks"]["personalWordPresentBeforeRun"], report' "$report"
sudo snap connect busymark:network
trap - EXIT


report="$HOME/snap/busymark/common/visualization-release-x11.json"
mkdir -p "$(dirname "$report")"
timeout --signal=TERM 300s \
  xvfb-run -a -s '-screen 0 1280x1024x24' \
  env GDK_BACKEND=x11 BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 snap run busymark \
  --visualization-release-smoke="$report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report' "$report"
test -s "$HOME/snap/busymark/common/visualization-smoke.pdf"


runtime_dir="/run/user/$(id -u)"
sudo install -d -m 700 -o "$(id -u)" -g "$(id -g)" "$runtime_dir"
XDG_RUNTIME_DIR="$runtime_dir" \
  weston --backend=headless-backend.so --socket=wayland-99 \
  --idle-time=0 --log="${RUNNER_TEMP}/weston-snap.log" &
weston_pid=$!
sudo snap disconnect busymark:network
trap 'sudo snap connect busymark:network >/dev/null; kill "$weston_pid" 2>/dev/null || true' EXIT
for attempt in {1..40}; do
  if [ -S "$runtime_dir/wayland-99" ]; then
    break
  fi
  if ! kill -0 "$weston_pid" 2>/dev/null; then
    cat "${RUNNER_TEMP}/weston-snap.log"
    exit 1
  fi
  sleep 0.25
done
test -S "$runtime_dir/wayland-99"
spelling_report="$HOME/snap/busymark/common/spelling-release-wayland.json"
XDG_RUNTIME_DIR="$runtime_dir" WAYLAND_DISPLAY=wayland-99 \
  GDK_BACKEND=wayland BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 \
  timeout --signal=TERM 300s snap run busymark \
  --spelling-release-smoke="$spelling_report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report; assert report["checks"]["sourceEditorTransaction"], report; assert report["checks"]["formattedRichEditorTransaction"], report; assert report["checks"]["tableCellEditorTransaction"], report' "$spelling_report"
report="$HOME/snap/busymark/common/visualization-release-wayland.json"
XDG_RUNTIME_DIR="$runtime_dir" WAYLAND_DISPLAY=wayland-99 \
  GDK_BACKEND=wayland BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 \
  timeout --signal=TERM 300s snap run busymark \
  --visualization-release-smoke="$report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report' "$report"
test -s "$HOME/snap/busymark/common/visualization-smoke.pdf"
sudo snap connect busymark:network
trap 'kill "$weston_pid" 2>/dev/null || true' EXIT
