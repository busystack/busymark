#!/usr/bin/env bash
set -euo pipefail

bundle="${1:?Usage: install_piper_runtime.sh BUNDLE}"
recipe_dir="${2:-snap/speech-python}"
test -d "$bundle"
test -f "$recipe_dir/requirements-cp314-amd64.txt"

venv="$(mktemp -d)"
trap 'rm -rf -- "$venv"' EXIT
/usr/bin/python3.14 -I -m venv "$venv"
"$venv/bin/python" -I -m pip --isolated install \
  --disable-pip-version-check --only-binary=:all: --require-hashes \
  --no-compile --target "$bundle/libexec/busymark/piper" \
  -r "$recipe_dir/requirements-cp314-amd64.txt"
install -Dm755 "$recipe_dir/busymark-piper-python" \
  "$bundle/bin/busymark-piper-python"
