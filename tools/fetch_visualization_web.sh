#!/usr/bin/env bash

set -euo pipefail

MERMAID_VERSION="11.16.1"
MERMAID_SHA256="ebd9885111092c78cefc79a76f6c1dc34ed5b834b02ae8f338227ce79c003de4"
PLANTUML_VERSION="1.2026.6"
PLANTUML_SHA256="798f99592eb03a6446519d2becf78e6f1008d0d25c75d60b37a0f46e39e3c413"
SCALAR_PARSER_VERSION="0.28.14"
SCALAR_PARSER_SHA256="993bb7ebb3480cc574665b0eac52d9cd4a817fdf5b4444894bb70e174880513d"
SCALAR_REFERENCE_VERSION="1.65.1"
SCALAR_REFERENCE_SHA256="68b6f22ca530ac50e3cd034c5189d89cc5457c3c2d325b44e90db05c9f08c573"
SCALAR_JSON_MAGIC_VERSION="0.13.0"
SCALAR_JSON_MAGIC_SHA256="f1adefc461f3594afd4ad16974820a5a88b271f7e8051045c2ac7a34eb974d33"
YAML_VERSION="2.9.0"
YAML_SHA256="008fa204cb1ba700e0272ba045abbf09a6ffe63456e8146ba97cac6c2ad1ef91"
ESBUILD_VERSION="0.28.2"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/visualization"
OUTPUT_DIR="${1:-${PROJECT_DIR}/build/visualization/web}"
SOURCE_FINGERPRINT="$({
  sha256sum \
    "${SOURCE_DIR}/package.json" \
    "${SOURCE_DIR}/package-lock.json" \
    "${SOURCE_DIR}/render_engines.js" \
    "${SOURCE_DIR}/reference.js" \
    "${SOURCE_DIR}/bootstrap.js" \
    "${SOURCE_DIR}/harness.html" \
    "${SOURCE_DIR}/reference.html" \
    "${SOURCE_DIR}/generate_notices.js"
} | sha256sum | cut -d ' ' -f 1)"
VERSION_FINGERPRINT="mermaid=${MERMAID_VERSION};plantuml=${PLANTUML_VERSION};scalar-parser=${SCALAR_PARSER_VERSION};scalar-reference=${SCALAR_REFERENCE_VERSION};scalar-json-magic=${SCALAR_JSON_MAGIC_VERSION};yaml=${YAML_VERSION};esbuild=${ESBUILD_VERSION};sources=${SOURCE_FINGERPRINT}"

if [[ -f "${OUTPUT_DIR}/VERSION" ]] &&
   [[ "$(<"${OUTPUT_DIR}/VERSION")" == "${VERSION_FINGERPRINT}" ]] &&
   [[ -s "${OUTPUT_DIR}/render-engines.js" ]] &&
   [[ -s "${OUTPUT_DIR}/scalar.js" ]] &&
   [[ -s "${OUTPUT_DIR}/viz-global.js" ]] &&
   [[ -s "${OUTPUT_DIR}/harness.html" ]] &&
   [[ -s "${OUTPUT_DIR}/reference.html" ]] &&
   [[ -s "${OUTPUT_DIR}/reference.js" ]] &&
   [[ -s "${OUTPUT_DIR}/bootstrap.js" ]] &&
   [[ -s "${OUTPUT_DIR}/licenses/package-lock.json" ]] &&
   [[ -s "${OUTPUT_DIR}/licenses/npm/THIRD_PARTY_NOTICES.md" ]]; then
  exit 0
fi

command -v node >/dev/null
command -v npm >/dev/null
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if (( NODE_MAJOR < 22 )); then
  echo "BusyMark visualization assets require Node.js 22 or newer." >&2
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
TOOL_DIR="${TEMP_DIR}/tool"
mkdir -p -- "${TOOL_DIR}"
cp -- "${SOURCE_DIR}/package.json" "${SOURCE_DIR}/package-lock.json" "${TOOL_DIR}/"
cp -- "${SOURCE_DIR}/render_engines.js" "${TOOL_DIR}/"
npm ci \
  --prefix "${TOOL_DIR}" \
  --ignore-scripts \
  --no-audit \
  --no-fund \
  --fetch-retries=5 \
  --fetch-retry-mintimeout=2000 \
  --fetch-retry-maxtimeout=30000 \
  --fetch-timeout=120000

verify_package() {
  local name="$1"
  local url="$2"
  local expected_sha256="$3"
  local archive="${TEMP_DIR}/${name}.tgz"
  curl --fail --location --retry 3 --retry-delay 1 --output "${archive}" "${url}"
  printf '%s  %s\n' "${expected_sha256}" "${archive}" | sha256sum --check --status
  mkdir -p -- "${TEMP_DIR}/${name}"
  tar --extract --gzip --file "${archive}" --directory "${TEMP_DIR}/${name}"
}

verify_package \
  mermaid \
  "https://registry.npmjs.org/mermaid/-/mermaid-${MERMAID_VERSION}.tgz" \
  "${MERMAID_SHA256}"
verify_package \
  plantuml \
  "https://registry.npmjs.org/@plantuml/core/-/core-${PLANTUML_VERSION}.tgz" \
  "${PLANTUML_SHA256}"
verify_package \
  scalar-parser \
  "https://registry.npmjs.org/@scalar/openapi-parser/-/openapi-parser-${SCALAR_PARSER_VERSION}.tgz" \
  "${SCALAR_PARSER_SHA256}"
verify_package \
  scalar-reference \
  "https://registry.npmjs.org/@scalar/api-reference/-/api-reference-${SCALAR_REFERENCE_VERSION}.tgz" \
  "${SCALAR_REFERENCE_SHA256}"
verify_package \
  scalar-json-magic \
  "https://registry.npmjs.org/@scalar/json-magic/-/json-magic-${SCALAR_JSON_MAGIC_VERSION}.tgz" \
  "${SCALAR_JSON_MAGIC_SHA256}"
verify_package \
  yaml \
  "https://registry.npmjs.org/yaml/-/yaml-${YAML_VERSION}.tgz" \
  "${YAML_SHA256}"

BUILD_DIR="${TEMP_DIR}/output"
mkdir -p -- "${BUILD_DIR}"
node "${TOOL_DIR}/node_modules/esbuild/bin/esbuild" \
  "${TOOL_DIR}/render_engines.js" \
  --bundle \
  --format=esm \
  --platform=browser \
  --target=safari16 \
  --outfile="${BUILD_DIR}/render-engines.js"

install -m 0644 "${SOURCE_DIR}/harness.html" "${BUILD_DIR}/harness.html"
install -m 0644 "${SOURCE_DIR}/reference.html" "${BUILD_DIR}/reference.html"
install -m 0644 "${SOURCE_DIR}/reference.js" "${BUILD_DIR}/reference.js"
install -m 0644 "${SOURCE_DIR}/bootstrap.js" "${BUILD_DIR}/bootstrap.js"
install -m 0644 \
  "${TEMP_DIR}/scalar-reference/package/dist/browser/standalone.js" \
  "${BUILD_DIR}/scalar.js"
install -m 0644 \
  "${TEMP_DIR}/plantuml/package/viz-global.js" \
  "${BUILD_DIR}/viz-global.js"
printf '%s\n' "${VERSION_FINGERPRINT}" > "${BUILD_DIR}/VERSION"

LICENSE_DIR="${BUILD_DIR}/licenses"
node "${SOURCE_DIR}/generate_notices.js" \
  "${TOOL_DIR}/node_modules" \
  "${LICENSE_DIR}/npm"
# @scalar/api-reference and @scalar/openapi-parser are released from the same
# Scalar repository. The reference package omits LICENSE from its npm files;
# preserve the repository's distributed MIT text from the parser package.
install -D -m 0644 \
  "${TEMP_DIR}/scalar-parser/package/LICENSE" \
  "${LICENSE_DIR}/scalar-api-reference/LICENSE"
install -D -m 0644 \
  "${SOURCE_DIR}/package-lock.json" \
  "${LICENSE_DIR}/package-lock.json"

mkdir -p -- "${OUTPUT_DIR}"
cp -R -- "${BUILD_DIR}/." "${OUTPUT_DIR}/"
echo "Prepared offline visualization web assets in ${OUTPUT_DIR}"
