#!/bin/bash
set -euo pipefail
date -u --iso-8601=seconds
cat /etc/os-release
uname -a
systemd-detect-virt
lscpu | grep -E '^CPU\(s\)|^Model name|^Hypervisor vendor|^Virtualization type'
snap version
snap list
snap connections busymark
revision=$(snap list busymark | awk 'NR == 2 {print $3}')
installed="/var/lib/snapd/snaps/busymark_${revision}.snap"
expected=2b7c2a7b91a9aa7cbb7f23d35186e59a46173446b95ca9a14ddb5f667ca592ce
printf '%s  %s\n' "$expected" "$installed" | sudo sha256sum --check
sudo cat /sys/kernel/security/apparmor/profiles | grep -Fx 'snap.busymark.busymark (enforce)'
recipe_sha=$(unsquashfs -cat /home/tester/package.snap snap/snapcraft.yaml | sha256sum | cut -d' ' -f1)
test "$recipe_sha" = c337fa68d95a589562aa10ab1c63e809b900c711ff53466fd79a9ffd53bc7d1d
printf 'Installed embedded recipe SHA-256: %s\n' "$recipe_sha"
snap run --shell busymark -c 'readlink -f "$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/libwebkit2gtk-4.1.so.0"; sha256sum "$SNAP/busymark" "$SNAP/lib/libapp.so"'
