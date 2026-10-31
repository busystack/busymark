#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/checkout_shared_dependencies.py --check
(cd ../busystack_git_flutter && dart run tool/test_native_presentation_audit.dart && dart run tool/check_native_presentation.dart lib/src ../busymark/lib/src/git)
