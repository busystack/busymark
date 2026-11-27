#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions adds the runner to the lxd group before this step. Re-enter
# as the same user to load that membership. Ubuntu 26.04 sudo-rs ignores -E,
# so supply the manifest and recipe flag in the command's own environment.
: "${GITHUB_OUTPUT:?This helper runs inside the native CI Snap job}"
runner_user="$(id -un)"
snapcraft=/snap/bin/snapcraft
sudo -n -u "$runner_user" -- "$snapcraft" clean --use-lxd
rm -f -- ./busymark_*.snap
sudo -n -u "$runner_user" -- env SNAPCRAFT_BUILD_INFO=1 \
  "$snapcraft" pack --use-lxd --verbosity=debug

shopt -s nullglob
artifacts=(./busymark_*.snap)
if (( ${#artifacts[@]} != 1 )); then
  echo "Expected exactly one BusyMark Snap, found ${#artifacts[@]}." >&2
  exit 1
fi
printf 'snap=%s\n' "$(realpath "${artifacts[0]}")" >> "$GITHUB_OUTPUT"
