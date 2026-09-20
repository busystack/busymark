#!/usr/bin/env bash

set -euo pipefail

HUNSPELL_VERSION="1.7.3"
HUNSPELL_REVISION="c5f98152a274e25b5107101104bef632b83a0cc9"
HUNSPELL_ARCHIVE_SHA256="933be3dac6fd55f6e752331a170efb7e33800e40fae1156d8434cc8c85379a1b"
HUNSPELL_URL="https://github.com/hunspell/hunspell/archive/refs/tags/v${HUNSPELL_VERSION}.tar.gz"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DESTINATION="${PACKAGE_DIR}/third_party/hunspell"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

ARCHIVE="${TEMP_DIR}/hunspell.tar.gz"
if [[ -n "${BUSYMARK_HUNSPELL_ARCHIVE:-}" ]]; then
  cp -- "${BUSYMARK_HUNSPELL_ARCHIVE}" "${ARCHIVE}"
else
  curl --fail --location --retry 3 --retry-delay 1 \
    --output "${ARCHIVE}" "${HUNSPELL_URL}"
fi
printf '%s  %s\n' "${HUNSPELL_ARCHIVE_SHA256}" "${ARCHIVE}" |
  sha256sum --check --status

mkdir -p -- "${TEMP_DIR}/source" "${TEMP_DIR}/prepared/src"
tar --extract --gzip --file "${ARCHIVE}" --directory "${TEMP_DIR}/source" \
  --strip-components=1
cp -R -- "${TEMP_DIR}/source/src/hunspell" "${TEMP_DIR}/prepared/src/"
mkdir -p -- "${TEMP_DIR}/prepared/licenses"
for license in COPYING COPYING.LESSER COPYING.MPL license.hunspell license.myspell; do
  test -f "${TEMP_DIR}/source/${license}"
  cp -- "${TEMP_DIR}/source/${license}" "${TEMP_DIR}/prepared/licenses/${license}"
done
printf '%s\n' "${HUNSPELL_REVISION}" > "${TEMP_DIR}/prepared/REVISION"
printf '%s\n' "${HUNSPELL_ARCHIVE_SHA256}" > "${TEMP_DIR}/prepared/ARCHIVE.sha256"

rm -rf -- "${DESTINATION}"
mv -- "${TEMP_DIR}/prepared" "${DESTINATION}"
