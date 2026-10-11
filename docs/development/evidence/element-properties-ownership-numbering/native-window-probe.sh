#!/usr/bin/env bash
set -euo pipefail
cd /workspace
build/linux/x64/debug/bundle/busymark \
  test/fixtures/writerside/conformance_project \
  /evidence/busymark-ownership-numbering-native-final-20261011 &
probe_pid=$!
for attempt in {1..100}; do
  probe_window=$(xdotool search --onlyvisible --pid "$probe_pid" | head -1) || true
  if [[ -n "$probe_window" ]]; then
    xdotool windowmove "$probe_window" 0 0
    break
  fi
  sleep 0.1
done
wait "$probe_pid"
