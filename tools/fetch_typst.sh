#!/usr/bin/env bash

set -euo pipefail

# BusyMark intentionally ships a pinned, static Typst compiler. The checksum is
# verified before anything is installed so release builds are reproducible and
# never execute an unverified download.
TYPST_VERSION="0.15.1"
BUILD_ARCH="${2:-$(uname -m)}"
case "${BUILD_ARCH}" in
  x86_64|amd64)
    TYPST_TARGET="x86_64-unknown-linux-musl"
    TYPST_SHA256="a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c"
    TYPST_BINARY_SHA256="29273eaa04f6d00edd0c2bec578f565fc9c65be856bfbffc894567c68ed0b237"
    ;;
  aarch64|arm64)
    TYPST_TARGET="aarch64-unknown-linux-musl"
    TYPST_SHA256="5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee"
    TYPST_BINARY_SHA256="3088dd985a891d804a98c69db24dfca77a35878e45d40e38c79cf36d72bcd4c1"
    ;;
  *)
    echo "BusyMark's bundled Typst ${TYPST_VERSION} is not available for Linux architecture ${BUILD_ARCH}." >&2
    exit 1
    ;;
esac
TYPST_URL="https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_TARGET}.tar.xz"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${PROJECT_DIR}/build/typst/linux-${BUILD_ARCH}}"

if [[ -x "${OUTPUT_DIR}/typst" ]] &&
   [[ -f "${OUTPUT_DIR}/VERSION" ]] &&
   [[ "$(<"${OUTPUT_DIR}/VERSION")" == "${TYPST_VERSION}" ]]; then
  if printf '%s  %s\n' "${TYPST_BINARY_SHA256}" "${OUTPUT_DIR}/typst" |
     sha256sum --check --status; then
    exit 0
  fi
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
ARCHIVE_PATH="${TEMP_DIR}/typst.tar.xz"

if [[ -n "${BUSYMARK_TYPST_ARCHIVE:-}" ]]; then
  cp -- "${BUSYMARK_TYPST_ARCHIVE}" "${ARCHIVE_PATH}"
else
  curl --fail --location --retry 3 --retry-delay 1 \
    --output "${ARCHIVE_PATH}" "${TYPST_URL}"
fi

printf '%s  %s\n' "${TYPST_SHA256}" "${ARCHIVE_PATH}" | sha256sum --check --status
tar --extract --xz --file "${ARCHIVE_PATH}" --directory "${TEMP_DIR}"

EXTRACTED_DIR="${TEMP_DIR}/typst-${TYPST_TARGET}"
mkdir -p -- "${OUTPUT_DIR}"
install -m 0755 "${EXTRACTED_DIR}/typst" "${OUTPUT_DIR}/typst"
printf '%s  %s\n' "${TYPST_BINARY_SHA256}" "${OUTPUT_DIR}/typst" |
  sha256sum --check --status
install -m 0644 "${EXTRACTED_DIR}/LICENSE" "${OUTPUT_DIR}/LICENSE"
install -m 0644 "${EXTRACTED_DIR}/NOTICE" "${OUTPUT_DIR}/NOTICE"
printf '%s\n' "${TYPST_VERSION}" > "${OUTPUT_DIR}/VERSION"

echo "Prepared Typst ${TYPST_VERSION} in ${OUTPUT_DIR}"
