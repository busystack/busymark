#!/usr/bin/env bash
set -euo pipefail

readonly builder_version="2026.07.8925"
readonly source_root="${1:-test/fixtures/writerside/conformance_project}"
readonly module_instance="${2:-Conformance/conformance}"
readonly work_root="$(mktemp -d)"
readonly source_copy="$work_root/sources"
readonly output_root="$work_root/output"
readonly builder_log="$work_root/builder.log"
mkdir -p "$source_copy" "$output_root"
trap 'rm -rf -- "$work_root"' EXIT

cp -a -- "$(realpath "$source_root")/." "$source_copy/"

if ! docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$source_copy:/opt/sources" \
  -v "$output_root:/opt/builder-output" \
  -e HOME=/tmp/writerside-home \
  -e SOURCE_DIR=/opt/sources \
  -e MODULE_INSTANCE="$module_instance" \
  -e OUTPUT_DIR=/opt/builder-output/artifacts \
  -e RUNNER=other \
  "jetbrains/writerside-builder:$builder_version" >"$builder_log" 2>&1; then
  cat "$builder_log"
  exit 1
fi

find "$output_root/artifacts" -type f -size +0c -print -quit | grep -q .
