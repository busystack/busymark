#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/checkout_shared_dependencies.py --check
python3 ../busystack_git_flutter/tool/test_consumer_consistency.py
python3 ../busystack_git_flutter/tool/check_consumer_consistency.py --consumer "$PWD"
(cd ../busystack_git_flutter && dart run tool/test_native_presentation_audit.dart && dart run tool/check_native_presentation.dart lib/src ../busymark/lib/src/git --host-source ../busymark/lib/src/git/application/shared_git_presentation.dart --host-root BusyMarkGitPresentation --host-root BusyMarkGitDialogShell)
(cd ../busystack_git_flutter && dart run tool/check_native_presentation.dart lib/src ../busyfiles/apps/busyfiles_ui/lib/src/features/browser/git_workspace.dart --host-source ../busyfiles/apps/busyfiles_ui/lib/src/app/busyfiles_design.dart --host-root BusyFilesGitPresentation --host-root BusyFilesDialog && dart run tool/check_native_presentation.dart --host-source ../busyfiles/apps/busyfiles_ui/lib/src/app/busyfiles_dialogs.dart --host-root _BusyFilesDialogRoute)

(cd tools/git_ui_audit && dart pub get --offline --enforce-lockfile && dart run bin/check.dart --self-test && dart run bin/check.dart && dart run bin/check_design_boundary.dart --self-test && dart run bin/check_design_boundary.dart && dart run bin/check_sidebar.dart --self-test && dart run bin/check_sidebar.dart)

# Resolved source compliance is paired with actual host geometry/state checks.
flutter test --no-pub test/src/git/actions_native_contract_test.dart test/src/git/log_layout_correction_test.dart test/src/git/native_presentation_contract_test.dart test/src/git/log_comparison_native_test.dart test/src/git/git_navigation_visual_contract_test.dart test/src/git/git_navigation_golden_test.dart test/src/sidebar_native_contract_test.dart
