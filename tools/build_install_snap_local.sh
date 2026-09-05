#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tools/build_install_snap_local.sh [version] [options]

Build the Flutter Linux release, replace the payload in an installed snap
scaffold, pack it, install it locally, and optionally run it.

Options:
  --no-install         Pack and verify the snap without replacing the installed snap.
  --no-run             Install the snap but do not run it.
  --skip-tests         Skip flutter analyze/test.
  --output FILE        Write the packed snap to FILE.
  --root DIR           Use DIR as the temporary snap root.
  --scaffold DIR       Use DIR instead of /snap/<snap-name>/current.
  --snap-name NAME     Override the snap name.
  --binary-name NAME   Override the Linux executable name.
  --app-id ID          Override the desktop/application id.
  --skip-bundled-git   Do not stage host Git/OpenSSH tools into the local snap.
  --dart-define K=V    Pass a compile-time Flutter define. Repeatable.
  --dart-define-from-file FILE
                       Pass Flutter compile-time defines from FILE.
  -h, --help           Show this help.

Environment overrides are also supported:
  VERSION, OUT, SNAP_ROOT, SNAP_SCAFFOLD, SNAP_NAME, BINARY_NAME, APP_ID,
  INSTALL_AFTER_BUILD=0, RUN_AFTER_INSTALL=0, SKIP_TESTS=1, BUNDLE_GIT=0,
  DART_DEFINE_FROM_FILE, BUSYMARK_FLUTTER_BIN, BUSYMARK_FLUTTER_CACHE,
  BUSYMARK_BOOTSTRAP_FLUTTER=0, BUSYMARK_BUILD_TMP_ROOT
EOF
}

fail() {
  echo "error: $*" >&2
  exit 1
}

project_value() {
  local key="$1"
  sed -nE "s/^${key}:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\\1/p" \
    pubspec.yaml | head -n 1
}

project_flutter_version() {
  sed -nE \
    "/^environment:/,/^[^[:space:]#]/{s/^[[:space:]]+flutter:[[:space:]]*['\"]?([^'\"[:space:]]+)['\"]?[[:space:]]*$/\\1/p}" \
    pubspec.yaml | head -n 1
}

flutter_binary_version() {
  local executable
  executable="$(readlink -f "$1")"
  local sdk_root
  sdk_root="$(cd "$(dirname "$executable")/.." && pwd)"
  local version=""

  version="$(git -C "$sdk_root" describe --tags --exact-match HEAD 2>/dev/null || true)"
  if [[ -n "$version" ]]; then
    echo "$version"
    return
  fi
  if [[ -f "$sdk_root/bin/cache/flutter.version.json" ]]; then
    python3 -c \
      'import json,sys; print(json.load(open(sys.argv[1]))["frameworkVersion"])' \
      "$sdk_root/bin/cache/flutter.version.json"
    return
  fi
  "$1" --version --machine |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])'
}

select_project_flutter() {
  local required_version="$1"
  local explicit_bin="${BUSYMARK_FLUTTER_BIN:-}"
  local candidate=""
  local actual_version=""

  if [[ -n "$explicit_bin" ]]; then
    candidate="$(command -v "$explicit_bin" || true)"
    [[ -n "$candidate" && -x "$candidate" ]] || \
      fail "BUSYMARK_FLUTTER_BIN is not executable: $explicit_bin"
    actual_version="$(flutter_binary_version "$candidate")" || \
      fail "could not determine Flutter version from $candidate"
    [[ "$actual_version" == "$required_version" ]] || \
      fail "BUSYMARK_FLUTTER_BIN provides Flutter $actual_version; project requires $required_version"
    FLUTTER_BIN="$candidate"
    return
  fi

  candidate="$PROJECT_ROOT/.fvm/flutter_sdk/bin/flutter"
  if [[ -x "$candidate" ]]; then
    actual_version="$(flutter_binary_version "$candidate")" || true
    if [[ "$actual_version" == "$required_version" ]]; then
      FLUTTER_BIN="$candidate"
      return
    fi
  fi

  candidate="$(command -v flutter || true)"
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    actual_version="$(flutter_binary_version "$candidate")" || true
    if [[ "$actual_version" == "$required_version" ]]; then
      FLUTTER_BIN="$candidate"
      return
    fi
    if [[ -n "$actual_version" ]]; then
      echo "Flutter $actual_version on PATH does not match required $required_version."
    fi
  fi

  local cache_root="${BUSYMARK_FLUTTER_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/busymark/flutter}"
  local cached_sdk="$cache_root/$required_version"
  candidate="$cached_sdk/bin/flutter"
  if [[ -x "$candidate" ]]; then
    actual_version="$(flutter_binary_version "$candidate")" || true
    [[ "$actual_version" == "$required_version" ]] || \
      fail "cached Flutter SDK at $cached_sdk reports version ${actual_version:-unknown}"
    FLUTTER_BIN="$candidate"
    return
  fi

  [[ "${BUSYMARK_BOOTSTRAP_FLUTTER:-1}" == "1" ]] || \
    fail "Flutter $required_version is unavailable; install it or set BUSYMARK_FLUTTER_BIN"
  [[ ! -e "$cached_sdk" ]] || \
    fail "cached Flutter SDK is incomplete: $cached_sdk"

  local partial_sdk="${cached_sdk}.partial.$$"
  mkdir -p "$cache_root"
  echo "== Bootstrap Flutter $required_version =="
  echo "Cache: $cached_sdk"
  if ! git clone --depth 1 --branch "$required_version" \
    https://github.com/flutter/flutter.git "$partial_sdk"; then
    rm -rf "$partial_sdk"
    fail "could not download Flutter $required_version"
  fi
  mv "$partial_sdk" "$cached_sdk"
  candidate="$cached_sdk/bin/flutter"
  actual_version="$(flutter_binary_version "$candidate")" || \
    fail "could not initialize Flutter at $cached_sdk"
  [[ "$actual_version" == "$required_version" ]] || \
    fail "downloaded Flutter reports $actual_version; expected $required_version"
  FLUTTER_BIN="$candidate"
}

prepare_build_tmp() {
  local build_tmp_root="${BUSYMARK_BUILD_TMP_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/busymark/tmp}"
  mkdir -p "$build_tmp_root"
  BUSYMARK_BUILD_TMP_DIR="$(mktemp -d "$build_tmp_root/snap-build.XXXXXX")" || \
    fail "could not create build temporary directory under $build_tmp_root"
  export TMPDIR="$BUSYMARK_BUILD_TMP_DIR"
}

cleanup_build_tmp() {
  if [[ -n "${BUSYMARK_BUILD_TMP_DIR:-}" ]]; then
    rm -rf -- "$BUSYMARK_BUILD_TMP_DIR" || true
  fi
}

cmake_value() {
  local key="$1"
  sed -nE "s/^[[:space:]]*set\\(${key}[[:space:]]+\"([^\"]+)\"\\).*/\\1/p" \
    linux/CMakeLists.txt | head -n 1
}

snapcraft_value() {
  local key="$1"
  [[ -f snap/snapcraft.yaml ]] || return 0
  sed -nE "s/^${key}:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\\1/p" \
    snap/snapcraft.yaml | head -n 1
}

copy_into_snap_root() {
  local source="$1"
  local target="$SNAP_ROOT/${source#/}"
  install -Dm755 "$source" "$target"
}

copy_tree_into_snap_root() {
  local source="$1"
  local target="$SNAP_ROOT/${source#/}"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -a "$source" "$target"
}

is_core_runtime_library() {
  local path="$1"
  case "$(basename "$path")" in
    ld-linux*.so*|libBrokenLocale.so*|libanl.so*|libc.so*|libdl.so*|libm.so*|libmvec.so*|libnsl.so*|libnss_*.so*|libpthread.so*)
      return 0
      ;;
    libresolv.so*|librt.so*|libthread_db.so*|libutil.so*)
      return 0
      ;;
  esac
  return 1
}

stage_ldd_dependencies() {
  local binary="$1"
  local ldd_output
  ldd_output="$(ldd "$binary" 2>/dev/null || true)"
  while read -r line; do
    local dependency=""
    if [[ "$line" =~ "=>" ]]; then
      dependency="$(awk '{print $3}' <<<"$line")"
    else
      dependency="$(awk '{print $1}' <<<"$line")"
    fi
    [[ "$dependency" == /* ]] || continue
    [[ -f "$dependency" ]] || continue
    is_core_runtime_library "$dependency" && continue
    copy_into_snap_root "$dependency"
  done <<<"$ldd_output"
}

stage_bundled_git_tools() {
  local git_bin
  git_bin="$(command -v git || true)"
  [[ -n "$git_bin" && -x "$git_bin" ]] || fail "git is required to stage bundled Git tools"

  local setsid_bin
  setsid_bin="$(command -v setsid || true)"
  [[ -n "$setsid_bin" && -x "$setsid_bin" ]] || \
    fail "setsid from util-linux is required to run bundled Git commands"

  echo "== Stage bundled Git tools =="
  echo "Git:      $git_bin"
  copy_into_snap_root "$git_bin"
  stage_ldd_dependencies "$git_bin"

  echo "setsid:   $setsid_bin"
  install -Dm755 "$setsid_bin" "$SNAP_ROOT/usr/bin/setsid"
  stage_ldd_dependencies "$setsid_bin"

  local git_exec_path
  git_exec_path="$(git --exec-path)"
  if [[ -d "$git_exec_path" ]]; then
    echo "Git core: $git_exec_path"
    copy_tree_into_snap_root "$git_exec_path"
    while IFS= read -r helper; do
      stage_ldd_dependencies "$helper"
    done < <(find "$git_exec_path" -maxdepth 1 -type f -perm -111 | sort)
  fi

  if [[ -d /usr/share/git-core ]]; then
    copy_tree_into_snap_root /usr/share/git-core
  fi

  local tool
  for tool in ssh scp sftp ssh-keyscan; do
    local tool_path
    tool_path="$(command -v "$tool" || true)"
    if [[ -n "$tool_path" && -x "$tool_path" ]]; then
      echo "OpenSSH:  $tool_path"
      copy_into_snap_root "$tool_path"
      stage_ldd_dependencies "$tool_path"
    fi
  done

  test -x "$SNAP_ROOT/usr/bin/git" || fail "failed to stage $SNAP_ROOT/usr/bin/git"
  test -x "$SNAP_ROOT/usr/bin/setsid" || \
    fail "failed to stage $SNAP_ROOT/usr/bin/setsid"
}

scaffold_has_bundled_git_tools() {
  local tool
  for tool in git setsid ssh scp sftp ssh-keyscan; do
    [[ -x "$SNAP_ROOT/usr/bin/$tool" ]] || return 1
  done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

VERSION_ARG=""
INSTALL_AFTER_BUILD="${INSTALL_AFTER_BUILD:-1}"
RUN_AFTER_INSTALL="${RUN_AFTER_INSTALL:-1}"
SKIP_TESTS="${SKIP_TESTS:-0}"
BUNDLE_GIT="${BUNDLE_GIT:-1}"
declare -a DART_DEFINE_ARGS=()
declare -a DART_DEFINE_FILE_ARGS=()

if [[ -n "${DART_DEFINE_FROM_FILE:-}" ]]; then
  DART_DEFINE_FILE_ARGS+=("--dart-define-from-file=$DART_DEFINE_FROM_FILE")
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-install)
      INSTALL_AFTER_BUILD=0
      RUN_AFTER_INSTALL=0
      ;;
    --no-run)
      RUN_AFTER_INSTALL=0
      ;;
    --skip-tests)
      SKIP_TESTS=1
      ;;
    --output)
      [[ $# -ge 2 ]] || fail "--output requires a value"
      OUT="$2"
      shift
      ;;
    --root)
      [[ $# -ge 2 ]] || fail "--root requires a value"
      SNAP_ROOT="$2"
      shift
      ;;
    --scaffold)
      [[ $# -ge 2 ]] || fail "--scaffold requires a value"
      SNAP_SCAFFOLD="$2"
      shift
      ;;
    --snap-name)
      [[ $# -ge 2 ]] || fail "--snap-name requires a value"
      SNAP_NAME="$2"
      shift
      ;;
    --binary-name)
      [[ $# -ge 2 ]] || fail "--binary-name requires a value"
      BINARY_NAME="$2"
      shift
      ;;
    --app-id)
      [[ $# -ge 2 ]] || fail "--app-id requires a value"
      APP_ID="$2"
      shift
      ;;
    --skip-bundled-git)
      BUNDLE_GIT=0
      ;;
    --dart-define)
      [[ $# -ge 2 ]] || fail "--dart-define requires KEY=VALUE"
      DART_DEFINE_ARGS+=("--dart-define=$2")
      shift
      ;;
    --dart-define=*)
      DART_DEFINE_ARGS+=("$1")
      ;;
    --dart-define-from-file)
      [[ $# -ge 2 ]] || fail "--dart-define-from-file requires a file"
      DART_DEFINE_FILE_ARGS+=("--dart-define-from-file=$2")
      shift
      ;;
    --dart-define-from-file=*)
      DART_DEFINE_FILE_ARGS+=("$1")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      fail "unknown option: $1"
      ;;
    *)
      [[ -z "$VERSION_ARG" ]] || fail "only one version argument is supported"
      VERSION_ARG="$1"
      ;;
  esac
  shift
done

PROJECT_NAME="$(project_value name)"
[[ -n "$PROJECT_NAME" ]] || fail "could not read project name from pubspec.yaml"

VERSION="${VERSION_ARG:-${VERSION:-$(project_value version)}}"
[[ -n "$VERSION" ]] || fail "could not read version from pubspec.yaml"

REQUIRED_FLUTTER_VERSION="$(project_flutter_version)"
[[ -n "$REQUIRED_FLUTTER_VERSION" ]] || \
  fail "pubspec.yaml must declare an exact environment.flutter version"
select_project_flutter "$REQUIRED_FLUTTER_VERSION"
prepare_build_tmp
trap cleanup_build_tmp EXIT

SNAP_NAME="${SNAP_NAME:-$PROJECT_NAME}"
BINARY_NAME="${BINARY_NAME:-$(cmake_value BINARY_NAME)}"
BINARY_NAME="${BINARY_NAME:-$PROJECT_NAME}"
APP_ID="${APP_ID:-$(cmake_value APPLICATION_ID)}"
APP_ID="${APP_ID:-$SNAP_NAME}"
ICON_SOURCE="${ICON_SOURCE:-$(snapcraft_value icon)}"

SNAP_SCAFFOLD="${SNAP_SCAFFOLD:-/snap/${SNAP_NAME}/current}"
SNAP_ROOT="${SNAP_ROOT:-/tmp/${SNAP_NAME}-snap-root}"
OUT="${OUT:-${SNAP_NAME}_${VERSION}_amd64_$(date +%Y%m%d%H%M%S).snap}"
BUNDLE_DIR="build/linux/x64/release/bundle"

echo "== ${SNAP_NAME} local snap build =="
echo "Project:  $PROJECT_ROOT"
echo "Version:  $VERSION"
echo "Binary:   $BINARY_NAME"
echo "App ID:   $APP_ID"
echo "Flutter:  $REQUIRED_FLUTTER_VERSION ($FLUTTER_BIN)"
echo "Temp:     $BUSYMARK_BUILD_TMP_DIR"
echo "Scaffold: $SNAP_SCAFFOLD"
echo "Root:     $SNAP_ROOT"
echo "Output:   $OUT"
echo "Defines:  $((${#DART_DEFINE_ARGS[@]} + ${#DART_DEFINE_FILE_ARGS[@]})) build-time entries"

echo "== Resolve locked dependencies =="
"$FLUTTER_BIN" pub get --enforce-lockfile

if [[ "$SKIP_TESTS" != "1" ]]; then
  echo "== Validate source =="
  "$FLUTTER_BIN" analyze --no-pub
  "$FLUTTER_BIN" test --no-pub --reporter=compact
else
  echo "== Validate source =="
  echo "Skipping tests because SKIP_TESTS=1"
fi

echo "== Build Flutter Linux release =="
"$FLUTTER_BIN" build linux --release --no-pub \
  "${DART_DEFINE_ARGS[@]}" "${DART_DEFINE_FILE_ARGS[@]}"

test -f "$BUNDLE_DIR/$BINARY_NAME" || fail "missing built binary: $BUNDLE_DIR/$BINARY_NAME"

echo "== Recreate snap root from installed scaffold =="
test -d "$SNAP_SCAFFOLD" || {
  echo "No installed snap scaffold at $SNAP_SCAFFOLD"
  echo "Install the snap once from the store or pass --scaffold DIR."
  exit 1
}

rm -rf "$SNAP_ROOT"
mkdir -p "$SNAP_ROOT"
cp -a "$SNAP_SCAFFOLD/." "$SNAP_ROOT/"

test -f "$SNAP_ROOT/meta/snap.yaml" || fail "missing $SNAP_ROOT/meta/snap.yaml"

echo "== Align GTK SVG runtime =="
# The GNOME content snap owns both its SVG pixbuf loader and matching librsvg.
# An older copy retained from the scaffold breaks every GTK symbolic SVG icon.
rm -f "$SNAP_ROOT/usr/lib/x86_64-linux-gnu/librsvg-2.so.2"*

echo "== Replace Flutter payload =="
rm -rf "$SNAP_ROOT/$BINARY_NAME" "$SNAP_ROOT/data" "$SNAP_ROOT/lib"
cp -a "$BUNDLE_DIR/." "$SNAP_ROOT/"

test -f "$SNAP_ROOT/$BINARY_NAME" || fail "missing staged binary: $SNAP_ROOT/$BINARY_NAME"

echo "== Stage desktop integration files =="
DESKTOP_SOURCE="linux/${APP_ID}.desktop"
METAINFO_SOURCE="linux/${APP_ID}.metainfo.xml"

if [[ -f "$DESKTOP_SOURCE" ]]; then
  install -Dm644 "$DESKTOP_SOURCE" \
    "$SNAP_ROOT/share/applications/${APP_ID}.desktop"
  mkdir -p "$SNAP_ROOT/meta/gui"
  find "$SNAP_ROOT/meta/gui" -mindepth 1 -maxdepth 1 \
    \( -type f -o -type l \) -name '*.desktop' -exec rm -f -- {} +
else
  echo "No desktop file found at $DESKTOP_SOURCE"
fi

if [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]]; then
  ICON_EXT="${ICON_SOURCE##*.}"
  install -Dm644 "$ICON_SOURCE" "$SNAP_ROOT/meta/gui/${APP_ID}.${ICON_EXT}"
  install -Dm644 "$ICON_SOURCE" "$SNAP_ROOT/meta/gui/icon.${ICON_EXT}"
  install -Dm644 "$ICON_SOURCE" \
    "$SNAP_ROOT/share/icons/hicolor/scalable/apps/${APP_ID}.${ICON_EXT}"

  if [[ -f "$DESKTOP_SOURCE" ]]; then
    sed "s#^Icon=.*#Icon=\${SNAP}/meta/gui/icon.${ICON_EXT}#" \
      "$DESKTOP_SOURCE" > "$SNAP_ROOT/meta/gui/${SNAP_NAME}.desktop"
  fi
else
  echo "No icon file found from snapcraft icon: ${ICON_SOURCE:-<unset>}"
fi

if [[ -f "$METAINFO_SOURCE" ]]; then
  install -Dm644 "$METAINFO_SOURCE" \
    "$SNAP_ROOT/share/metainfo/${APP_ID}.metainfo.xml"
fi

if [[ "$BUNDLE_GIT" == "1" ]]; then
  if scaffold_has_bundled_git_tools; then
    echo "== Stage bundled Git tools =="
    echo "Retaining core24-compatible Git and OpenSSH tools from the snap scaffold"
  else
    stage_bundled_git_tools
  fi
else
  echo "== Stage bundled Git tools =="
  echo "Skipping bundled Git tools because BUNDLE_GIT=0"
fi

echo "== Patch staged snap metadata =="
python3 - "$SNAP_ROOT/meta/snap.yaml" "snap/snapcraft.yaml" "$VERSION" "$SNAP_NAME" <<'PY'
from pathlib import Path
import re
import sys

meta_path = Path(sys.argv[1])
source_path = Path(sys.argv[2])
version = sys.argv[3]
app_name = sys.argv[4]

text = meta_path.read_text()
text, count = re.subn(r"(?m)^version:\s*.*$", f"version: {version}", text, count=1)
if count != 1:
    raise SystemExit("version line not found in meta/snap.yaml")

# snap pack consumes installed-style metadata. Source snapcraft-only keys are
# removed from the temporary root only; source files are left untouched.
text = re.sub(r"(?m)^icon:\s*.*\n", "", text)
text = re.sub(r"(?m)^    desktop:[^\r\n]*(?:\r?\n|$)", "", text)


def extract_app_list(source: str, app: str, key: str) -> list[str]:
    lines = source.splitlines()
    apps_index = next(
        (i for i, line in enumerate(lines) if line.rstrip() == "apps:"), None
    )
    if apps_index is None:
        return []

    app_start = None
    for i in range(apps_index + 1, len(lines)):
        if re.match(r"^\S", lines[i]):
            break
        if lines[i].rstrip() == f"  {app}:":
            app_start = i
            break
    if app_start is None:
        return []

    app_end = len(lines)
    for i in range(app_start + 1, len(lines)):
        if re.match(r"^  \S.*:\s*$", lines[i]):
            app_end = i
            break
        if re.match(r"^\S", lines[i]):
            app_end = i
            break

    key_start = None
    for i in range(app_start + 1, app_end):
        if lines[i].rstrip() == f"    {key}:":
            key_start = i
            break
    if key_start is None:
        return []

    items: list[str] = []
    for i in range(key_start + 1, app_end):
        if re.match(r"^    [A-Za-z0-9_-][^:]*:", lines[i]):
            break
        match = re.match(r"^\s*-\s+(.+?)\s*$", lines[i])
        if match:
            items.append(match.group(1))
    return items


def top_level_section_bounds(
    lines: list[str], section: str
) -> tuple[int, int] | None:
    start = next(
        (i for i, line in enumerate(lines) if line.rstrip() == f"{section}:"),
        None,
    )
    if start is None:
        return None

    end = len(lines)
    for i in range(start + 1, len(lines)):
        stripped = lines[i].strip()
        if (
            stripped
            and not stripped.startswith("#")
            and not lines[i].startswith(" ")
        ):
            end = i
            break
    return start, end


def top_level_plug_bounds(
    lines: list[str], plug: str
) -> tuple[int, int] | None:
    section = top_level_section_bounds(lines, "plugs")
    if section is None:
        return None
    section_start, section_end = section
    start = next(
        (
            i
            for i in range(section_start + 1, section_end)
            if lines[i].rstrip() == f"  {plug}:"
        ),
        None,
    )
    if start is None:
        return None

    end = section_end
    for i in range(start + 1, section_end):
        stripped = lines[i].strip()
        if (
            stripped
            and not stripped.startswith("#")
            and not lines[i].startswith("    ")
        ):
            end = i
            break
    return start, end


def ensure_app_list_items(target: str, app: str, key: str, items: list[str]) -> str:
    if not items:
        return target

    lines = target.splitlines(keepends=True)
    app_start = next(
        (i for i, line in enumerate(lines) if line.rstrip() == f"  {app}:"),
        None,
    )
    if app_start is None:
        raise SystemExit(f"app {app!r} not found in meta/snap.yaml")

    app_end = len(lines)
    for i in range(app_start + 1, len(lines)):
        if re.match(r"^  \S.*:\s*$", lines[i]):
            app_end = i
            break
        if re.match(r"^\S", lines[i]):
            app_end = i
            break

    key_start = None
    for i in range(app_start + 1, app_end):
        if lines[i].rstrip() == f"    {key}:":
            key_start = i
            break

    if key_start is None:
        insertion = [f"    {key}:\n", *[f"      - {item}\n" for item in items]]
        lines[app_start + 1:app_start + 1] = insertion
        return "".join(lines)

    key_end = app_end
    existing: set[str] = set()
    item_indent = "      "
    for i in range(key_start + 1, app_end):
        if re.match(r"^    [A-Za-z0-9_-][^:]*:", lines[i]):
            key_end = i
            break
        match = re.match(r"^(\s*)-\s+(.+?)\s*$", lines[i])
        if match:
            item_indent = match.group(1)
            existing.add(match.group(2))

    missing = [item for item in items if item not in existing]
    if missing:
        lines[key_end:key_end] = [f"{item_indent}- {item}\n" for item in missing]
    return "".join(lines)


def remove_top_level_plug(target: str, plug: str) -> str:
    lines = target.splitlines(keepends=True)
    plug_bounds = top_level_plug_bounds(lines, plug)
    if plug_bounds is None:
        return "".join(lines)
    plug_start, plug_end = plug_bounds
    del lines[plug_start:plug_end]
    return "".join(lines)


if source_path.exists():
    source = source_path.read_text()
    text = ensure_app_list_items(
        text,
        app_name,
        "plugs",
        extract_app_list(source, app_name, "plugs"),
    )

# The installed scaffold can carry attributes from an older revision. The
# standard desktop plug is implicit from the app's plug list; retaining the
# old top-level desktop-file-ids claim would force Store manual review.
text = remove_top_level_plug(text, "desktop")

meta_path.write_text(text)
PY

grep '^version:' "$SNAP_ROOT/meta/snap.yaml"
grep -A80 "^  ${SNAP_NAME}:" "$SNAP_ROOT/meta/snap.yaml" | sed -n '/plugs:/,/^[[:space:]]*[[:alpha:]_-].*:/p'
! grep -q '^  desktop:$' "$SNAP_ROOT/meta/snap.yaml"

STAGED_DESKTOP_MANIFEST="$(
  find "$SNAP_ROOT/meta/gui" -mindepth 1 -maxdepth 1 \
    -type f -name '*.desktop' -printf '%f\n' | LC_ALL=C sort
)"
[[ "$STAGED_DESKTOP_MANIFEST" == "${SNAP_NAME}.desktop" ]] ||
  fail "expected exactly one staged launcher: ${SNAP_NAME}.desktop"

echo "== Pack snap =="
snap pack "$SNAP_ROOT" --filename="$OUT"

echo "== Verify packed snap =="
unsquashfs -cat "$OUT" meta/snap.yaml | grep '^version:'
unsquashfs -ll "$OUT" "$BINARY_NAME"
PACKED_DESKTOP_MANIFEST="$(
  unsquashfs -ll "$OUT" |
    sed -nE 's#^.*squashfs-root/meta/gui/([^/]+\.desktop)$#\1#p' |
    LC_ALL=C sort
)"
[[ "$PACKED_DESKTOP_MANIFEST" == "${SNAP_NAME}.desktop" ]] ||
  fail "expected exactly one packed launcher: ${SNAP_NAME}.desktop"
if [[ "$BUNDLE_GIT" == "1" ]]; then
  unsquashfs -ll "$OUT" usr/bin/git
  unsquashfs -ll "$OUT" usr/bin/setsid
fi
if [[ -d "$BUNDLE_DIR/lib" ]]; then
  while IFS= read -r plugin; do
    name="$(basename "$plugin")"
    unsquashfs -ll "$OUT" | grep -F "$name" >/dev/null
  done < <(find "$BUNDLE_DIR/lib" -maxdepth 1 -type f -name 'lib*_plugin.so' | sort)
fi
! unsquashfs -cat "$OUT" meta/snap.yaml | grep -q '^icon:'
! unsquashfs -cat "$OUT" meta/snap.yaml | grep -q '^[[:space:]]*desktop:'
! unsquashfs -ll "$OUT" | grep -q \
  'squashfs-root/usr/lib/x86_64-linux-gnu/librsvg-2.so.2'

echo "Built snap: $OUT"
if [[ "$INSTALL_AFTER_BUILD" == "1" ]]; then
  echo "== Install snap =="
  sudo snap remove --purge "$SNAP_NAME" 2>/dev/null || true
  sudo snap install --dangerous "./$OUT"

  echo "== Verify installed snap =="
  snap connections "$SNAP_NAME" || true
  snap info "$SNAP_NAME" | sed -n '/installed:/p;/tracking:/p'

  if [[ "$RUN_AFTER_INSTALL" == "1" ]]; then
    echo "== Running ${SNAP_NAME} =="
    snap run "$SNAP_NAME"
  else
    echo "Run skipped. Start it with: snap run $SNAP_NAME"
  fi
else
  echo "Install skipped; the currently installed snap was not changed."
fi
