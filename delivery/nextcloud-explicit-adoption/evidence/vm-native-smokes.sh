#!/bin/bash
set -euo pipefail
export DISPLAY=:101 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2 BUSYMARK_RELEASE_SMOKE=1
mkdir -p "$HOME/native-evidence" "$HOME/native-spelling-profile-final"
Xvfb :101 -screen 0 1280x1024x24 -nolisten tcp > "$HOME/native-evidence/xvfb.log" 2>&1 &
xpid=$!
trap 'kill "$xpid" 2>/dev/null || true' EXIT
sleep 2
export XDG_DATA_HOME="$HOME/native-spelling-profile-final" GDK_BACKEND=x11
"$HOME/busymark-release/busymark" --spelling-release-smoke="$HOME/native-evidence/spelling-online-final.json" > "$HOME/native-evidence/spelling-online.log" 2>&1
sudo unshare --net --fork -- runuser -u tester -- env DISPLAY=:101 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_DATA_HOME="$XDG_DATA_HOME" GDK_BACKEND=x11 BUSYMARK_RELEASE_SMOKE=1 LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2 "$HOME/busymark-release/busymark" --spelling-release-smoke="$HOME/native-evidence/spelling-x11-denied-network-final.json" > "$HOME/native-evidence/spelling-x11-denied-network.log" 2>&1
weston --backend=headless --renderer=pixman --socket=wayland-native --idle-time=0 --log="$HOME/native-evidence/weston.log" &
wpid=$!
trap 'kill "$xpid" "$wpid" 2>/dev/null || true' EXIT
sleep 3
sudo unshare --net --fork -- runuser -u tester -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-native XDG_DATA_HOME="$XDG_DATA_HOME" GDK_BACKEND=wayland BUSYMARK_RELEASE_SMOKE=1 LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "$HOME/busymark-release/busymark" --spelling-release-smoke="$HOME/native-evidence/spelling-wayland-denied-network-final.json" > "$HOME/native-evidence/spelling-wayland-denied-network.log" 2>&1
python3 - <<'PY'
import json,pathlib
r=pathlib.Path.home()/'native-evidence'
for p in r.glob('spelling*-final.json'):
 d=json.loads(p.read_text());assert d['ok'],d
 if 'denied' in p.name:assert not d['checks']['dictionaryInstalledDuringRun'] and d['checks']['personalWordPresentBeforeRun'],d
print('Native dictionary install and actual denied-network restarts passed on X11 and Wayland.')
PY
