#!/bin/bash
set -euo pipefail
export RUNNER_TEMP=/home/tester/acceptance
mkdir -p "$RUNNER_TEMP"
snap run --shell busymark -c '
  set -eu
  inspect_dependencies() {
    dependency_object="$1"
    if dependency_output="$(ldd "$dependency_object" 2>&1)"; then
      :
    else
      printf "Dependency inspection failed: %s\n%s\n" \
        "$dependency_object" "$dependency_output" >&2
      exit 1
    fi
    case "$dependency_output" in
      *"not found"*)
        printf "Unresolved dependencies: %s\n%s\n" \
          "$dependency_object" "$dependency_output" >&2
        exit 1
        ;;
    esac
  }
  require_resolution() {
    required_library="$1"
    required_path="$2"
    resolved_path="$(printf "%s\n" "$dependency_output" | \
      awk -v name="$required_library" \
        "\$1 == name && \$2 == \"=>\" { print \$3; exit }")"
    if [ -z "$resolved_path" ] || \
        ! expected_real="$(readlink -e "$required_path")" || \
        ! resolved_real="$(readlink -e "$resolved_path")" || \
        [ "$resolved_real" != "$expected_real" ]; then
      printf "Unexpected resolution for %s in %s; expected %s\n%s\n" \
        "$required_library" "$dependency_object" \
        "$required_path" "$dependency_output" >&2
      exit 1
    fi
  }
  app_lib="$SNAP/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET"
  inspect_dependencies "$SNAP/busymark"
  for library in \
    libhandy-1.so.0 libsecret-1.so.0 libwebkit2gtk-4.1.so.0 \
    libgtk-3.so.0 libglib-2.0.so.0 libpango-1.0.so.0; do
    test ! -e "$app_lib/$library"
    require_resolution "$library" \
      "$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/$library"
  done
  graphics_lib="$SNAP/gpu-2404/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET"
  for library in \
    libX11.so.6 libXdamage.so.1 libXext.so.6 libXfixes.so.3 \
    libxcb-shm.so.0 libxcb.so.1 libwayland-client.so.0 \
    libwayland-cursor.so.0 libwayland-egl.so.1; do
    test ! -e "$app_lib/$library"
    test -e "$graphics_lib/$library"
    require_resolution "$library" "$graphics_lib/$library"
  done
  for helper in WebKitWebProcess WebKitNetworkProcess WebKitGPUProcess; do
    test -x "$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/webkit2gtk-4.1/$helper"
  done
  test -x "$SNAP/usr/bin/git"
  test -x "$SNAP/usr/bin/ssh"
  test -x "$SNAP/usr/bin/setsid"
  inspect_dependencies "$SNAP/usr/lib/git-core/git-remote-http"
  require_resolution libcurl-gnutls.so.4 \
    "$app_lib/libcurl-gnutls.so.4"
  GIT_EXEC_PATH="$SNAP/usr/lib/git-core" \
    "$SNAP/usr/bin/git" --exec-path | grep -Fx "$SNAP/usr/lib/git-core"
  "$SNAP/usr/bin/ssh" -V
  provider_plugins="$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/gstreamer-1.0"
  for plugin in libgstavi.so libgstisomp4.so libgstmatroska.so \
    libgstogg.so libgsttheora.so libgstvpx.so; do
    test -f "$provider_plugins/$plugin"
    inspect_dependencies "$provider_plugins/$plugin"
  done
  private_plugins="$SNAP/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/gstreamer-1.0"
  for plugin in libgstavi.so libgstisomp4.so libgstmatroska.so \
    libgstogg.so libgsttheora.so libgstvpx.so; do
    test ! -e "$private_plugins/$plugin"
  done
  for plugin in libgstlibav.so libgstvideoparsersbad.so \
    libgstmpeg2dec.so; do
    test -f "$private_plugins/$plugin"
    inspect_dependencies "$private_plugins/$plugin"
  done
  test -L "$SNAP/share/busymark/fonts"
  test "$(readlink "$SNAP/share/busymark/fonts")" = \
    ../../usr/share/fonts/truetype/noto
  test -f "$SNAP/share/busymark/fonts/NotoSans-Regular.ttf"
  test -f "$SNAP/usr/share/doc/fonts-noto-core/copyright"
  test -f "$SNAP/usr/share/doc/fonts-noto-mono/copyright"
  for resource_kind in themes icons; do
    for resource_name in Yaru Yaru-dark; do
      resource="$SNAP/share/$resource_kind/$resource_name"
      test -L "$resource"
      test -e "$resource"
    done
  done
'

