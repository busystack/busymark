#!/usr/bin/env bash
# Run only on a disposable Ubuntu desktop account with the candidate installed.
set -euo pipefail

output="${1:?Usage: run_installed_media_acceptance.sh OUTPUT SNAP SOURCE_SHA [VOICE_DIR]}"
artifact="${2:?Pass the exact candidate Snap}"
source_sha="${3:?Pass the candidate source SHA}"
voice_source="${4:-}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
runtime="/run/user/$(id -u)"
export XDG_RUNTIME_DIR="$runtime"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"
export LC_ALL=C.UTF-8 NO_AT_BRIDGE=0 LIBGL_ALWAYS_SOFTWARE=1
export PULSE_SINK=busymark_native_media
export PULSE_SERVER="unix:$runtime/pulse/native"
test -S "$runtime/bus"
[[ "$source_sha" =~ ^[0-9a-f]{40}$ ]]
case "$output" in "$HOME"/*) ;; *) echo 'Results must be in the disposable user’s home.' >&2; exit 2 ;; esac
mkdir -m 700 -p "$(dirname -- "$output")"
mkdir -m 700 -- "$output"
output="$(realpath -- "$output")"

snapshot="$(mktemp -d)"
session_pids=()
wayland_socket=""
settings=""
staged_voice=""
auth=""
pulse_module=""
pulse_default=""
accessibility="$(dconf read /org/gnome/desktop/interface/toolkit-accessibility)"
connection() {
  snap connections busymark | awk -v plug="busymark:$1" '$2 == plug { print $3 }'
}
network="$(connection network)"
password_manager="$(connection password-manager-service)"
if [[ -z "$network" || -z "$password_manager" ]]; then
  rm -r -- "$snapshot"
  echo 'The installed candidate does not expose its expected interfaces.' >&2
  exit 1
fi
restore_connection() {
  local plug="$1" before="$2" after
  after="$(connection "$plug")"
  if [[ "$before" != "$after" ]]; then
    if [[ "$before" == '-' ]]; then
      sudo -n snap disconnect "busymark:$plug"
    else
      sudo -n snap connect "busymark:$plug" "$before"
    fi
  fi
}
cleanup() {
  local result=$? cleanup_failed=0 index pid
  trap - EXIT
  if [[ -n "$pulse_module" ]]; then
    pactl unload-module "$pulse_module" || cleanup_failed=1
    if [[ -n "$pulse_default" && "$(pactl get-default-sink)" != "$pulse_default" ]]; then
      pactl set-default-sink "$pulse_default" || cleanup_failed=1
    fi
  fi
  # Weston and the window manager must exit while their X server is alive.
  for (( index=${#session_pids[@]}-1; index>=0; index-- )); do
    pid="${session_pids[index]}"
    if kill -0 "$pid" 2>/dev/null; then kill "$pid" || cleanup_failed=1; fi
    wait "$pid" 2>/dev/null || true
  done
  if [[ -n "$wayland_socket" ]]; then
    rm -f -- "$wayland_socket" "$wayland_socket.lock" || cleanup_failed=1
  fi
  if [[ -n "$auth" ]]; then rm -f -- "$auth" || cleanup_failed=1; fi
  if [[ -n "$staged_voice" ]]; then rm -r -- "$staged_voice" || cleanup_failed=1; fi
  if [[ -n "$settings" ]]; then
    if [[ -f "$snapshot/settings.json" ]]; then
      cp -p -- "$snapshot/settings.json" "$settings" || cleanup_failed=1
    else
      rm -f -- "$settings" || cleanup_failed=1
    fi
  fi
  if [[ -n "$accessibility" ]]; then
    dconf write /org/gnome/desktop/interface/toolkit-accessibility "$accessibility" || cleanup_failed=1
  else
    dconf reset /org/gnome/desktop/interface/toolkit-accessibility || cleanup_failed=1
  fi
  restore_connection password-manager-service "$password_manager" || cleanup_failed=1
  restore_connection network "$network" || cleanup_failed=1
  snap connections busymark >"$output/connections-restored.txt" || cleanup_failed=1
  rm -r -- "$snapshot" || cleanup_failed=1
  printf '%s\n' "$cleanup_failed" >"$output/fixture-cleanup-exit.txt"
  if (( cleanup_failed )); then result=1; fi
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

sha="$(sha256sum -- "$artifact" | cut -d ' ' -f1)"
revision="$(snap list busymark | awk '$1 == "busymark" { print $3 }')"
[[ "$revision" =~ ^x?[0-9]+$ ]]
printf '%s  %s\n' "$sha" "/var/lib/snapd/snaps/busymark_$revision.snap" \
  | tee "$output/installed-snap-sha256.txt" | sudo -n sha256sum --check
printf '%s\n' "$source_sha" >"$output/source-commit.txt"
snap version >"$output/snap-version.txt"
cat /etc/os-release >"$output/os-release.txt"
snap connections busymark >"$output/connections-before.txt"
profile="$(snap run --shell busymark -c 'printf "%s\n" "$XDG_DATA_HOME"')/io.busystack.busymark"
case "$profile" in "$HOME/snap/busymark/"*'/.local/share/io.busystack.busymark') ;; *) exit 2 ;; esac
mkdir -p -- "$profile"
settings="$profile/settings.json"
test ! -L "$settings"
if [[ -f "$settings" ]]; then cp -p -- "$settings" "$snapshot/settings.json"; fi

voice_id=en_US-joe-medium
voice="$profile/speech/piper-voices/$voice_id"
voice_url='https://huggingface.co/rhasspy/piper-voices/resolve/cf910fb59f1d79ab3b625a63993a108751c6c25d/en/en_US/joe/medium'
if [[ -z "$voice_source" ]]; then
  voice_source="$snapshot/voice"
  mkdir -m 700 -- "$voice_source"
  for file in "$voice_id.onnx" "$voice_id.onnx.json" MODEL_CARD; do
    curl --silent --show-error --fail --location --proto '=https' --proto-redir '=https' \
      --connect-timeout 10 --max-time 180 --max-filesize 70000000 \
      --output "$voice_source/$file" "$voice_url/$file"
  done
fi
cat >"$output/piper-voice.sha256" <<'CHECKSUMS'
abf4b998e34045cbd00eaf050de2de620f81ded6eb8b85a24b022a1c2b3f08d2  en_US-joe-medium.onnx
7b5f0293c0bf5bda8e377be1696da84af798befeef31038e43beefc01fe858da  en_US-joe-medium.onnx.json
4b319248135916e8f5433ce7a9fe5271026b05cb598bab05807b22cb17fd129b  MODEL_CARD
CHECKSUMS
(
  cd -- "$voice_source"
  sha256sum --check "$output/piper-voice.sha256"
)
test ! -e "$voice" && test ! -L "$voice"
mkdir -m 700 -p -- "$voice"
staged_voice="$voice"
for file in "$voice_id.onnx" "$voice_id.onnx.json" MODEL_CARD; do
  install -m 600 -- "$voice_source/$file" "$voice/$file"
done
(cd -- "$voice" && sha256sum --check "$output/piper-voice.sha256")
cp -- "$voice/MODEL_CARD" "$output/MODEL_CARD"
printf '%s\n' "$voice_url" >"$output/piper-voice-source.txt"

if [[ "$network" != '-' ]]; then sudo -n snap disconnect busymark:network; fi
[[ "$(connection network)" == '-' ]]
snap connections busymark >"$output/connections-offline.txt"

gsettings set org.gnome.desktop.interface toolkit-accessibility true
if timeout 5s pactl info 2>/dev/null | sed '/^Cookie:/d' >"$output/pulse-server.txt"; then
  [[ -z "$(pactl list short sink-inputs)" ]]
  pulse_default="$(pactl get-default-sink)"
  pulse_module="$(pactl load-module module-null-sink "sink_name=$PULSE_SINK" rate=48000 channels=1)"
  [[ "$pulse_module" =~ ^[0-9]+$ ]]
else
  test ! -e "$runtime/pulse/native"
  mkdir -p -- "$runtime/pulse"
  pulseaudio --daemonize=no --exit-idle-time=-1 --log-target="file:$output/pulse.log" -n \
    -L "module-native-protocol-unix socket=$runtime/pulse/native" \
    -L "module-null-sink sink_name=$PULSE_SINK rate=48000 channels=1" &
  session_pids+=("$!")
fi
for attempt in {1..40}; do
  if pactl list short sources 2>/dev/null | grep -F "${PULSE_SINK}.monitor"; then break; fi
  sleep 0.25
done
pactl list short sources | grep -F "${PULSE_SINK}.monitor"
pactl set-default-sink "$PULSE_SINK"

# X11 input is directed solely at this display. The runtime Xauthority path
# matches the desktop interface policy used by the standard Snap launcher.
export DISPLAY=:43
export XAUTHORITY="$runtime/.Xauthority"
export GDK_BACKEND=x11
unset WAYLAND_DISPLAY
test ! -e "$XAUTHORITY" && test ! -L "$XAUTHORITY"
test ! -e /tmp/.X11-unix/X43 && test ! -e /tmp/.X43-lock
install -m 600 /dev/null "$XAUTHORITY"
auth="$XAUTHORITY"
xauth add "$DISPLAY" . "$(mcookie)"
Xvfb "$DISPLAY" -auth "$XAUTHORITY" -screen 0 1280x900x24 -nolisten tcp >"$output/xvfb.log" 2>&1 &
session_pids+=("$!")
for attempt in {1..40}; do
  if test -S /tmp/.X11-unix/X43; then break; fi
  kill -0 "${session_pids[-1]}"
  sleep 0.25
done
test -S /tmp/.X11-unix/X43
openbox --sm-disable >"$output/openbox.log" 2>&1 &
session_pids+=("$!")
for attempt in {1..40}; do
  if xprop -root _NET_SUPPORTING_WM_CHECK | grep -F 'window id #'; then break; fi
  kill -0 "${session_pids[-1]}"
  sleep 0.25
done
xprop -root _NET_SUPPORTING_WM_CHECK | grep -F 'window id #'
accessibility_bus="$(gdbus call --session --dest org.a11y.Bus --object-path /org/a11y/bus \
  --method org.a11y.Bus.GetAddress \
  | /usr/bin/python3 -c 'import ast,sys; print(ast.literal_eval(sys.stdin.read())[0])')"
gdbus call --address "$accessibility_bus" --dest org.a11y.atspi.Registry \
  --object-path /org/a11y/atspi/registry --method org.a11y.atspi.Registry.GetRegisteredEvents \
  >"$output/x11-session-ready.txt"

seed_settings() {
  /usr/bin/python3 - "$settings" "$1" "$2" "$voice_id" <<'PY'
import json
from pathlib import Path
import sys
path = Path(sys.argv[1])
settings = json.loads(path.read_bytes()) if path.exists() else {}
settings.update(documentViewMode=sys.argv[2], autoSave=False, reopenPreviousWorkspaceOnStartup=False)
settings['speech'] = {'backend': sys.argv[3]}
if sys.argv[3] == 'piper':
    settings['speech']['providers'] = {'piper': {'voice': sys.argv[4]}}
path.write_text(json.dumps(settings) + '\n', encoding='utf-8')
PY
}

failed=0
run_vault() {
  local backend="$1"
  if [[ "$password_manager" == '-' ]]; then sudo -n snap connect busymark:password-manager-service; fi
  seed_settings editor elevenLabs
  /usr/bin/python3 "$script_dir/speech_vault_desktop_smoke.py" \
    --output "$output/vault-$backend" --backend "$backend" \
    --sink "$PULSE_SINK" --profile "$profile" || failed=1
  restore_connection password-manager-service "$password_manager"
}

run_audio() {
  local backend="$1" mode="$2"
  seed_settings "$mode" espeak
  /usr/bin/python3 "$script_dir/audio_desktop_smoke.py" \
    --output "$output/audio-$backend-$mode" --mode "$mode" --backend "$backend" \
    --sink "$PULSE_SINK" --installed -- snap run busymark || failed=1
}
run_speech() {
  local backend="$1" engine
  for engine in espeak piper; do
    seed_settings editor "$engine"
    /usr/bin/python3 "$script_dir/speech_desktop_smoke.py" \
      --output "$output/speech-$backend-$engine" --sink "$PULSE_SINK" \
      --backend "$backend" --engine "$engine" || failed=1
  done
  seed_settings editor piper
  /usr/bin/python3 "$script_dir/speech_desktop_smoke.py" --output "$output/speech-$backend-cancel" \
    --sink "$PULSE_SINK" --backend "$backend" --engine piper --cancel-synthesis || failed=1
}
run_vault x11
run_audio x11 editor
run_audio x11 preview
run_speech x11

export WAYLAND_DISPLAY="wayland-$BASHPID"
socket="$runtime/$WAYLAND_DISPLAY"
if [[ -e "$socket" || -L "$socket" || -e "$socket.lock" || -L "$socket.lock" ]]; then
  echo 'The disposable Wayland socket path is already occupied.' >&2
  exit 1
fi
wayland_socket="$socket"
# The desktop shell needs a real seat to post GTK menus. Weston receives its
# seat from the test X server. BusyMark itself only sees the Wayland socket.
weston --backend=x11-backend.so --renderer=pixman --width=1200 --height=850 \
  --socket="$WAYLAND_DISPLAY" --idle-time=0 \
  --log="$output/weston.log" &
session_pids+=("$!")
for attempt in {1..40}; do
  if test -S "$runtime/$WAYLAND_DISPLAY"; then break; fi
  kill -0 "${session_pids[-1]}"
  sleep 0.25
done
if ! test -S "$wayland_socket"; then
  echo 'The disposable Wayland compositor did not open its socket.' >&2
  exit 1
fi
export BUSYMARK_INPUT_DISPLAY="$DISPLAY" BUSYMARK_INPUT_XAUTHORITY="$XAUTHORITY"
for attempt in {1..40}; do
  if BUSYMARK_INPUT_WINDOW="$(xdotool search --onlyvisible --name '^Weston Compositor - screen0$')"; then break; fi
  kill -0 "${session_pids[-1]}"
  sleep 0.25
done
if ! [[ "$BUSYMARK_INPUT_WINDOW" =~ ^[0-9]+$ ]]; then
  echo 'The disposable compositor has no uniquely identified input window.' >&2
  exit 1
fi
export BUSYMARK_INPUT_WINDOW
export GDK_BACKEND=wayland
unset DISPLAY XAUTHORITY
printf '%s\n' "$WAYLAND_DISPLAY" >"$output/wayland-session-ready.txt"
run_vault wayland
run_audio wayland editor
run_audio wayland preview
run_speech wayland
exit "$failed"
