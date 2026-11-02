#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/checkout_shared_dependencies.py --check
(cd ../busystack_git_flutter && dart run tool/test_native_presentation_audit.dart && dart run tool/check_native_presentation.dart lib/src ../busymark/lib/src/git)

(cd tools/git_ui_audit && dart pub get --offline --enforce-lockfile && dart run bin/check.dart --self-test && dart run bin/check.dart)

# Resolved source compliance is paired with actual host geometry/state checks.
flutter test --no-pub test/src/git/native_presentation_contract_test.dart
