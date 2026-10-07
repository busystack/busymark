#!/bin/bash
set -euo pipefail
cd /home/tester
for pair in x11:04-exercise-strict-snap-visualization-and-pdf-paths-under-x11.sh wayland:05-exercise-strict-snap-spelling-and-visualization-under-wayland.sh; do
  backend=${pair%%:*}
  script=${pair#*:}
  destination="acceptance/$backend-repeat"
  mkdir -p "$destination"
  started=$(date +%s)
  bash "$script" > "$destination/run.log" 2>&1
  printf '%s-repeat\t0\t%s\n' "$backend" "$(( $(date +%s) - started ))" >> acceptance/status.tsv
  cp "snap/busymark/common/visualization-release-$backend.json" snap/busymark/common/visualization-smoke.pdf "$destination/"
  if [ "$backend" = wayland ]; then cp snap/busymark/common/spelling-release-wayland.json "$destination/"; fi
done
bash collect-identity.sh > acceptance/installed-identity-final.log 2>&1
sudo journalctl -k --since '2026-10-07 18:35:00 UTC' --no-pager > acceptance/kernel-audit.log
