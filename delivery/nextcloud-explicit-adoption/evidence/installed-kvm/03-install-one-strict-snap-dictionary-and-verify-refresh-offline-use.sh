#!/bin/bash
set -euo pipefail
export RUNNER_TEMP=/home/tester/acceptance
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
  "/home/tester/package.snap"
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

