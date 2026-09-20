#!/usr/bin/env bash

set -euo pipefail

DICTIONARY_REVISION="32b006a2c22a4ac7e8ed3f03346f7b3d85a970a4"
DICTIONARY_ARCHIVE_SHA256="cbd790eca560de5e8ec8bd64117a00dfd0bc06b091c8f52d23e44ea00d3e8461"
DICTIONARY_URL="https://github.com/LibreOffice/dictionaries/archive/${DICTIONARY_REVISION}.tar.gz"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${PROJECT_DIR}/build/spelling}"
EXPECTED_MANIFEST="${PROJECT_DIR}/assets/spelling/dictionaries.json"

if [[ -f "${OUTPUT_DIR}/VERSION" ]] &&
   [[ -f "${OUTPUT_DIR}/dictionaries.json" ]] &&
   [[ -f "${OUTPUT_DIR}/CHECKSUMS.sha256" ]] &&
   [[ "$(<"${OUTPUT_DIR}/VERSION")" == "${DICTIONARY_REVISION}" ]] &&
   cmp --silent "${OUTPUT_DIR}/dictionaries.json" "${EXPECTED_MANIFEST}" &&
   (cd -- "${OUTPUT_DIR}" && sha256sum --check --status CHECKSUMS.sha256); then
  exit 0
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
ARCHIVE_PATH="${TEMP_DIR}/dictionaries.tar.gz"
if [[ -n "${BUSYMARK_SPELLING_DICTIONARIES_ARCHIVE:-}" ]]; then
  cp -- "${BUSYMARK_SPELLING_DICTIONARIES_ARCHIVE}" "${ARCHIVE_PATH}"
else
  curl --fail --location --retry 3 --retry-delay 1 \
    --output "${ARCHIVE_PATH}" "${DICTIONARY_URL}"
fi
printf '%s  %s\n' "${DICTIONARY_ARCHIVE_SHA256}" "${ARCHIVE_PATH}" |
  sha256sum --check --status
mkdir -p -- "${TEMP_DIR}/source"
tar --extract --gzip --file "${ARCHIVE_PATH}" --directory "${TEMP_DIR}/source" \
  --strip-components=1

dart run "${PROJECT_DIR}/tools/prepare_spelling_dictionaries.dart" \
  "${TEMP_DIR}/source" "${TEMP_DIR}/prepared"
cmp --silent "${TEMP_DIR}/prepared/dictionaries.json" "${EXPECTED_MANIFEST}" || {
  echo "Generated spelling manifest differs from assets/spelling/dictionaries.json" >&2
  diff --unified "${EXPECTED_MANIFEST}" "${TEMP_DIR}/prepared/dictionaries.json" >&2 || true
  exit 1
}
(cd -- "${TEMP_DIR}/prepared" && sha256sum --check --status CHECKSUMS.sha256)
rm -rf -- "${OUTPUT_DIR}"
mkdir -p -- "$(dirname -- "${OUTPUT_DIR}")"
mv -- "${TEMP_DIR}/prepared" "${OUTPUT_DIR}"
echo "Prepared pinned spelling dictionaries in ${OUTPUT_DIR}"
