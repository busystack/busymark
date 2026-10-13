#!/usr/bin/env bash
set -euo pipefail

readonly builder_version="2026.08.0328"
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

python3 - "$output_root/artifacts/report.json" <<'PYREPORT'
import json, sys
report = json.load(open(sys.argv[1]))
assert report['testsErrorsCount'] == 0, report['testsErrors']
assert report['testsWarningsCount'] == 0, report['testsWarnings']
print(f"Official builder: {report['testsPassedCount']} checks passed")
PYREPORT
if [[ "$source_root" == "test/fixtures/writerside/conformance_project" ]]; then
  python3 tools/extract_writerside_semantics.py \
    "$output_root/artifacts/webHelpCONFORMANCE2-all.zip" \
    test/fixtures/writerside/conformance_semantics.json --check
fi

if [[ -n "${WRITERSIDE_CONFORMANCE_OUTPUT:-}" ]]; then
  mkdir -p -- "$WRITERSIDE_CONFORMANCE_OUTPUT"
  cp -a -- "$output_root/artifacts/." "$WRITERSIDE_CONFORMANCE_OUTPUT/"
fi

if [[ "$source_root" == "test/fixtures/writerside/reference_conformance" ]]; then
  python3 tools/verify_writerside_reference_fixture.py \
    "$output_root/artifacts/webHelpGUIDE2-all.zip"
fi
if [[ "$source_root" == "test/fixtures/writerside/property_conformance" ]]; then
  python3 tools/verify_writerside_property_fixture.py \
    "$output_root/artifacts/webHelpCONFORMANCE2-all.zip"
fi
if [[ "$source_root" == "test/fixtures/writerside/property_contract_conformance" ]]; then
  python3 tools/verify_writerside_property_fixture.py \
    "$output_root/artifacts/webHelpCONFORMANCE2-all.zip" contract
fi
if [[ "$source_root" == "test/fixtures/writerside/list_capitalization_conformance" ]]; then
  python3 tools/verify_writerside_property_fixture.py \
    "$output_root/artifacts/webHelpCONFORMANCE2-all.zip" list-caps
  for variant in generic variable list-type list-start; do
    variant_sources="$work_root/$variant"
    variant_output="$work_root/$variant-output"
    cp -a -- "$source_copy" "$variant_sources"
    cp -- "$source_copy/variants/$variant.cfg" "$variant_sources/writerside.cfg"
    if [[ -f "$source_copy/variants/$variant.tree" ]]; then
      cp -- "$source_copy/variants/$variant.tree" "$variant_sources/conformance.tree"
    fi
    WRITERSIDE_CONFORMANCE_OUTPUT="$variant_output" bash tools/validate_writerside_conformance.sh "$variant_sources" Conformance/conformance
    python3 tools/verify_writerside_property_fixture.py "$variant_output/webHelpCONFORMANCE2-all.zip" "list-caps-$variant"
  done
fi
if [[ "$source_root" == "test/fixtures/writerside/property_defaults_conformance" ]]; then
  python3 tools/verify_writerside_property_fixture.py \
    "$output_root/artifacts/webHelpCONFORMANCE2-all.zip" defaults
fi
if [[ "$source_root" == "test/fixtures/writerside/conformance_project" ]]; then
  evidence_root="${WRITERSIDE_CONFORMANCE_OUTPUT:-$work_root/evidence}"
  WRITERSIDE_CONFORMANCE_OUTPUT="$evidence_root/reference-links" bash tools/validate_writerside_conformance.sh \
    test/fixtures/writerside/reference_conformance ReferenceLinks/guide
  WRITERSIDE_CONFORMANCE_OUTPUT="$evidence_root/properties" bash tools/validate_writerside_conformance.sh \
    test/fixtures/writerside/property_conformance Conformance/conformance
  WRITERSIDE_CONFORMANCE_OUTPUT="$evidence_root/property-defaults" bash tools/validate_writerside_conformance.sh \
    test/fixtures/writerside/property_defaults_conformance Conformance/conformance
  WRITERSIDE_CONFORMANCE_OUTPUT="$evidence_root/property-contract" bash tools/validate_writerside_conformance.sh \
    test/fixtures/writerside/property_contract_conformance Conformance/conformance
  WRITERSIDE_CONFORMANCE_OUTPUT="$evidence_root/list-capitalization" bash tools/validate_writerside_conformance.sh \
    test/fixtures/writerside/list_capitalization_conformance Conformance/conformance
fi
