#!/bin/bash
set -euo pipefail
export RUNNER_TEMP=/home/tester/acceptance
mkdir -p "$RUNNER_TEMP"
report="$HOME/snap/busymark/common/visualization-release-x11.json"
mkdir -p "$(dirname "$report")"
timeout --signal=TERM 300s \
  xvfb-run -a -s '-screen 0 1280x1024x24' \
  env GDK_BACKEND=x11 BUSYMARK_RELEASE_SMOKE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 snap run busymark \
  --visualization-release-smoke="$report"
python3 -c 'import json,sys; report=json.load(open(sys.argv[1], encoding="utf-8")); assert report["ok"], report' "$report"
test -s "$HOME/snap/busymark/common/visualization-smoke.pdf"

