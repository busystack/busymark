#!/usr/bin/env bash

set -euo pipefail

D2_VERSION="0.7.1"
BUILD_ARCH="${2:-$(uname -m)}"
case "${BUILD_ARCH}" in
  x86_64|amd64)
    D2_TARGET="linux-amd64"
    D2_ARCHIVE_SHA256="eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7"
    D2_BINARY_SHA256="48db68dfb42b76970a6769f038ec60da932adbb058257e07c50f5baaa3046016"
    ;;
  *)
    echo "BusyMark visualization does not package D2 ${D2_VERSION} for Linux architecture ${BUILD_ARCH}." >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${PROJECT_DIR}/build/d2/${D2_TARGET}}"
D2_URL="https://github.com/terrastruct/d2/releases/download/v${D2_VERSION}/d2-v${D2_VERSION}-${D2_TARGET}.tar.gz"

if [[ -x "${OUTPUT_DIR}/d2" ]] &&
   [[ -f "${OUTPUT_DIR}/VERSION" ]] &&
   [[ -s "${OUTPUT_DIR}/LICENSE.txt" ]] &&
   [[ -s "${OUTPUT_DIR}/NOTICE" ]] &&
   [[ "$(<"${OUTPUT_DIR}/VERSION")" == "${D2_VERSION}" ]] &&
   printf '%s  %s\n' "${D2_BINARY_SHA256}" "${OUTPUT_DIR}/d2" | sha256sum --check --status; then
  exit 0
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
ARCHIVE_PATH="${TEMP_DIR}/d2.tar.gz"
if [[ -n "${BUSYMARK_D2_ARCHIVE:-}" ]]; then
  cp -- "${BUSYMARK_D2_ARCHIVE}" "${ARCHIVE_PATH}"
else
  curl --fail --location --retry 3 --retry-delay 1 --output "${ARCHIVE_PATH}" "${D2_URL}"
fi
printf '%s  %s\n' "${D2_ARCHIVE_SHA256}" "${ARCHIVE_PATH}" | sha256sum --check --status
tar --extract --gzip --file "${ARCHIVE_PATH}" --directory "${TEMP_DIR}"

EXTRACTED_DIR="${TEMP_DIR}/d2-v${D2_VERSION}"
mkdir -p -- "${OUTPUT_DIR}"
install -m 0755 "${EXTRACTED_DIR}/bin/d2" "${OUTPUT_DIR}/d2"
printf '%s  %s\n' "${D2_BINARY_SHA256}" "${OUTPUT_DIR}/d2" | sha256sum --check --status
install -m 0644 "${EXTRACTED_DIR}/LICENSE.txt" "${OUTPUT_DIR}/LICENSE.txt"
printf '%s\n' "${D2_VERSION}" > "${OUTPUT_DIR}/VERSION"
printf '%s\n' \
  "D2 ${D2_VERSION}" \
  "Source: https://github.com/terrastruct/d2" \
  "Release artifact: ${D2_URL}" > "${OUTPUT_DIR}/NOTICE"
echo "Prepared D2 ${D2_VERSION} in ${OUTPUT_DIR}"
