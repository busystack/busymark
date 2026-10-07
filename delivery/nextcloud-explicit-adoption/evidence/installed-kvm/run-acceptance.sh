#!/bin/bash
set -uo pipefail
mkdir -p /home/tester/acceptance
cd /home/tester
for script in 0[1-5]-*.sh; do
  name="${script%.sh}"
  mkdir -p "acceptance/$name"
  started=$(date +%s)
  bash "$script" > "acceptance/$name/run.log" 2>&1
  result=$?
  elapsed=$(( $(date +%s) - started ))
  printf '%s\t%s\t%s\n' "$name" "$result" "$elapsed" | tee -a acceptance/status.tsv
  for report in /home/tester/snap/busymark/common/*.json /home/tester/snap/busymark/common/visualization-smoke*; do
    if [ -f "$report" ]; then cp "$report" "acceptance/$name/"; fi
  done
  if [ "$result" -ne 0 ]; then exit "$result"; fi
 done
