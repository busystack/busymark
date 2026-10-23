# PR 59: editor and document-history integration

The merge combines `fix/editor-view` at `3007fa1` with
`release/v0.7.0` at `77a5b5a` (PR 58). The starting worktree was clean.
The five textual conflicts were in the Source editor, rich editor, and their
Source, selection-lifecycle and session suites. Both branches' test cases are
retained; the three conflicted test files lose no test declarations from either
parent. Dependency manifests, Flutter 3.47.5 and the official engine are unchanged.

## Integration decisions

- Document-owned Undo/Redo and monotonic, bounded typing groups remain the
  authority. Source editing epochs, publication preconditions, fresh input focus
  nodes on document changes, and immediate history synchronization are retained.
- Source's document-keyed input is wrapped in both `DocumentUndoActions` and the
  existing editor focus/scroll protection. Composition lifecycle observation uses
  the visible editing value; stale-input validation still uses the full value.
- Rich history restores model and historical selection synchronously, including
  a traversal followed by input before the next parent frame. Viewport restoration
  remains separately deferred and guarded by document/request/selection/navigation
  identity and focus ownership. A competing control or inactive application is
  not permission to focus an editor.
- The hidden table-range input keeps document Undo/Redo actions and the central
  guarded focus handoff. The release branch's independent child autofocus is not
  reintroduced.
- Every reconstructed rich session retains `viewportOffset`,
  `viewportEditingOffset` and `viewportLayoutSignature`, together with source
  bindings. Structural-editing, passive menu/dialog and selection protections are
  preserved.
- Automatically merged workspace publication still checks live buffer identity,
  source and revision, and caches only an accepted committed projection. Local
  History keeps the release branch's independent retained traversal obligations,
  retry/recovery, format preservation and retention-safe protection renewal.

## Independently reproduced integration failures

Evidence is retained locally in `build/pr59-merge-evidence/` (ignored artifacts).
The following tests first failed on the combined implementation before their
targeted corrections; no assertions were weakened.

| Failure | Evidence and regression | Correction |
| --- | --- | --- |
| Source loses passive scroll protection after a document switch. | `integration-before.log`: both wrap variants drift from 1800 to 1661.7494 logical pixels after a real Linux FocusManager suspend/resume. The new Source tests assert every frame within 0.1 pixel and deliver input without refocusing. | A retired wrapper clears its shared scroll controller hook only if it still owns that hook. This preserves the fresh document's input client and suppression callback. |
| Rich pre-edit history records the post-edit caret. | `integration-before.log` and `integration-extra-before.log`: expected offset 4, actual 5 in the clipped-code-block test. | Report the known pre-edit selection to shared history without subsequently overwriting it with a live post-input capture. Local snapshots are captured before mutation but recorded only after acceptance. |
| Table-cell history drops the pixel viewport anchor. | `integration-extra-before.log`: expected `viewportOffset` 2242, actual 0. The code/table session tests also assert the signed editing offset and layout signature. | Copy all viewport fields in the pre-edit session constructor. |
| Rejected structural input adds history and destroys Redo. | The existing rejected-newline regression fails in `affected-initial.log`; the new edit/Undo/reject/Redo case fails in `integration-extra-before.log` (expected zero snapshots, actual one). | Keep pre-edit session reporting separate from recording an accepted local undo operation. Rejected newline input remains atomic. |
| Rejected boundary Backspace also destroys Redo. | `backspace-before.log`: attributed sole-list-owner Backspace leaves source unchanged but adds an undo snapshot (expected zero, actual one). | Capture before the command, then record only when the controller accepts the boundary edit, matching Enter's transaction order. |

`integration-after.log` passes all seven integration checks, including the
existing rejected-newline test. The Source tests verify new document focus/input
ownership, prolonged inactivity, independent vertical/horizontal reading position,
correct insertion and deliberate reveal. The rich tests inspect the authoritative
history entry before a frame. Rejection tests preserve source/publication count,
Undo count and the existing Redo result.

### Non-editable selection endpoint found by the full suite

The full clipboard suite exposed another confirmed focus defect: a saved range
ending at a thematic break never settles on mount. The same loop is reachable by
ordinary Select All. `_focusDocumentSelectionExtent()` schedules another guarded
handoff whenever a non-editable endpoint has no auxiliary input, although only a
table mounts that input. A thematic break therefore schedules frames forever.

This defect predates the merge. The existing clipboard regression fails in an
unchanged `git archive 3007fa1` checkout (`nonfield-parent-editor.log`) and passes
in an unchanged `git archive 77a5b5a` checkout (`nonfield-parent-release.log`).
Both use the pinned SDK and offline, lockfile-enforced dependencies. The merged
implementation independently fails the same regression
(`nonfield-paste-isolated.log` and `full-batch-2-before-nonfield-fix.log`).

Retries now apply only to tables, matching the actual auxiliary-input lifetime.
Other non-editable endpoints keep document-command focus as on the release
branch. The table handoff retains all lifecycle/owner/request safeguards and has
no independent autofocus. No selection, viewport, source or history is changed
to stop the loop.

Four new lifecycle cases exercise both range directions and local/shared
history; a fifth uses actual Select All and Paste keys. Before correction, the
two forward restoration cases fail and both reverse controls pass
(`nonfield-new-before.log`); keyboard Select All also fails
(`nonfield-selectall-before.log`). The existing clipboard case plus all five
new cases pass afterward (`nonfield-after.log`, six tests in seven seconds).
They verify stable rendered geometry, range endpoints, neutral source/history,
command ownership, subsequent paste/input without refocusing, and Undo/Redo.
The original clipboard regression remains unchanged.

## Verification

The pinned SDK is `/home/albert/flutter-sdk`. Dependency resolution used
`flutter pub get --enforce-lockfile` and changed neither manifest.

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --reporter expanded test/src/source_editor_widget_test.dart \
  test/src/wysiwyg_session_test.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  --name 'merged |rejected text-input list exit'

TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --reporter expanded test/src/source_editor_widget_test.dart \
  test/src/wysiwyg_selection_lifecycle_test.dart \
  test/src/wysiwyg_session_test.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  test/src/writerside_authoring_ui_test.dart test/src/busymark_dialogs_test.dart \
  test/src/app_smoke_test.dart test/src/document_edit_history_test.dart \
  test/src/local_history_store_test.dart test/src/local_history_workspace_test.dart \
  test/src/nextcloud_workspace_test.dart

TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --concurrency=1 --reporter expanded test/src/local_history_store_test.dart

mapfile -t pr59_dart_files < <(git diff --cached --name-only --diff-filter=ACMR -- '*.dart')
TMPDIR=/tmp /home/albert/flutter-sdk/bin/dart format \
  --output=none --set-exit-if-changed "${pr59_dart_files[@]}"
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter analyze --no-pub

PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  CMAKE_BUILD_PARALLEL_LEVEL=2 TMPDIR=/tmp \
  /home/albert/flutter-sdk/bin/flutter build linux --release --no-pub -t lib/main.dart
```

The focused run passes seven tests in nine seconds. The combined affected run
passes 1,408 tests, but seven process tests share one failed fixture compilation:
its 60-second compiler deadline expires during concurrent AOT/analysis work.
The failure is retained in `affected-after.log`; it is not counted as a passing
run. With no competing builds, the complete store suite passes all 73 tests in
72 seconds (`history-store-isolated.log`), including actual contention, independent
writers, stale identities and failure cleanup. No compiler or operation deadline
was increased, and no test was skipped.

Formatting checks all 22 Dart files with zero changes (`format-final.log`).
Final-code analysis reports no issues (`analyze-final-code.log`, 47.0 seconds), and the normal
release build passes again after the last correction (`linux-release-final-code.log`). The shipped engine and the
official SDK engine have identical SHA-256:
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`
(`engine-final-code-sha256.log`).

A broader formatting check also passes all 642 maintained Dart files with zero
changes (`format-repository.log`, 36.81 seconds):

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/dart format \
  --output=none --set-exit-if-changed lib test tools packages
```

The same complete formatting check passes again after the non-editable endpoint
repair (`format-final-code.log`, 642 files, zero changes, 23.96 seconds).

The first unpartitioned full-suite command was:

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --concurrency=2 --reporter expanded
```

It received SIGTERM (exit 143) after 2,519 passes and 48 existing opt-in skips,
without a reported assertion failure (`full-suite.log`). It is not counted as a
completed verification. No project-owned compiler or test workers survived.
The complete corpus is rerun in four bounded batches: the large application
file alone, and all other files balanced by source size. The retained
`all-test-files.txt` and `test-batch-{0,1,2,3}.txt` manifests were checked to contain
all **229** discovered test files exactly once, with no omissions or duplicates.
Each batch uses the following command, substituting its manifest/log number:

```sh
set -euo pipefail
mapfile -t pr59_test_files < build/pr59-merge-evidence/test-batch-0.txt
PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
  BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
  BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" TMPDIR=/tmp \
  /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=2 \
  --reporter expanded "${pr59_test_files[@]}" 2>&1 | \
  tee build/pr59-merge-evidence/full-batch-0.log
```

The installed D2/Typst executables, Poppler tools and already prepared spelling
dictionaries enable the optional checks as well. No dependencies are upgraded,
test deadlines changed, or test assertions bypassed.

The first 76-file clipboard/session batch found the non-editable endpoint failure
described above (1,765 passes, one failure). Its before log is retained. All four
batches are rerun on the corrected production implementation; earlier runs are
not substituted for final-code results.

The final-code results (`full-batch-0.log` through `full-batch-3.log`, summarized
and coverage-checked in `full-suite-summary.json`) are:

| Batch | Files | Passed | Conditional skips | Runtime |
| --- | ---: | ---: | ---: | --- |
| 0 | 1 | 259 | 0 | 5m50s |
| 1 | 76 | 1,614 | 1 | 8m35s |
| 2 | 76 | 1,766 | 0 | 3m41s |
| 3 | 76 | 1,736 | 0 | 8m21s |
| Total | 229 | 5,375 | 1 | |

Every batch exits zero, without an assertion failure. The single conditional
case requires `BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY`. The complete two-test
`native_writerside_dialog_source_test.dart` file is then run under owned
Xvfb/private D-Bus with that variable set to its disposable display: both tests
pass, including the previously skipped case (`native-gtk-dialog-final.log`,
`/tmp/bm59-xDlujt/gtk-dialog-final/tests.log`). Its ownership report exits zero
with no forced cleanup or unresolved descendants. All discovered cases are thus
exercised; none of the new regressions is skipped.

## Native Linux evidence

Native artifacts are retained under `/tmp/bm59-xDlujt/`; summaries and build logs
are in `build/pr59-merge-evidence/`. All cases use disposable documents, isolated
XDG profiles established before their private D-Bus broker, the official release
engine, and the repository's owned-process supervisor. No installed application
or host display/session is used. Probe bundles are kept separately; the normal
`lib/main.dart` bundle is restored at `build/linux/x64/release/bundle/`.

| Case | Result and evidence |
| --- | --- |
| Document history, X11/Xvfb | `history-x11/`: 100 checks pass using XTest keyboard input through GTK. Covers exhausted history, repeated traversal, mode/tab return, autosave, actual saved bytes, Local History restore, conflict reload, and displaced-source recovery in Source and Editor. |
| Editor, XWayland/Mutter | `editor-min-x11/`: four Alt-Tab cycles including 15 seconds inactive, then native minimize/restore. All passive viewport/geometry/selection/source/history checks and subsequent input/reveal checks pass. Recorded frames include the hidden lifecycle. |
| Editor, Wayland/Mutter | `editor-wayland/`: four real Alt-Tab cycles including 15 seconds inactive. All passive state/geometry checks and native insertion/reveal checks pass without refocusing. |
| Source and Split, XWayland/Mutter | `source-x11/` and `split-x11/`: four real application-switch cycles, unchanged reading position and state, and native insertion at the old target without refocusing; all checks pass. |
| Table cell, XWayland/Mutter | `table-x11/`: the same real application-switch/input checks pass. |
| Deferred table-range selection, XWayland/Mutter | `extent-table-x11/`: actual native pointer drag establishes the document range; a newer control acquires focus before the deferred handoff. Four application-switch cycles preserve range/geometry/source/history, and subsequent native input reaches only that newer control. All checks pass. |
| Delayed modal release, XWayland/Mutter | `dialog-x11/`: a production Navigator dialog is dismissed programmatically with its barrier release gated. Release while inactive leaves the newer owner intact; resumed native input reaches it without editing or scrolling the document. All checks pass. This does not claim native Escape handling or the GTK menu-result interleaving. |
| Structural editing, X11/Xvfb | `structural-x11/`: 130 checks pass for Markdown/Writerside headings, immediate Enter/Backspace inverse, descendants in all native list kinds, inline objects/formatting, one-operation history, view transitions and saved/reopened bytes. |
| Inline images beside existing breaks, X11/Xvfb | `inline-breaks-x11/`: 88 checks pass for both one/two-break insertion commands, existing/consecutive newlines and Markdown/Writerside. Verifies exact live object positions, attributes, formatting, undo/redo and reopened bytes/objects. |
| Shipping application, X11/Xvfb | `shipping-close/results/summary.json`: the normal `lib/main.dart` executable starts and exits naturally through WM_DELETE_WINDOW, with clean shutdown and no surviving descendants. The probe verifies the actually mapped official engine through its retained file descriptor; zero failures. |

Each successful ownership report has exit code zero and no unresolved descendants.
The structural probes close through the production close listener. The document
history probe exits after its explicit clean-shutdown checkpoint. Ordinary focus
controls are retired after their measurements; they are not natural-shutdown
acceptance claims. Both deferred-focus probes exit naturally with status zero.
`frames.json` records every rendered focus-test frame with
0.1-logical-pixel passive tolerances; it does not log private document contents.

The initial `editor-x11/` **full** probe is not a pass: its native window lookup
cannot establish an unmapped normal window after minimize, before the chrome
reactivation stage. The separate maintained `minimize` scenario passes and
records the real hidden lifecycle. Window-chrome reactivation remains unverified
by that failed full attempt. Neither its prerequisite nor product assertions
were weakened.

After correcting the non-editable endpoint, the focus entry point is rebuilt
from final source (`build-focus-final-code.log`) and the native table-range race
is repeated in `extent-final-x11/`: every passive/selection/history and newer
control input assertion passes. The application exits naturally with code zero,
and its owned-tree report verifies complete retirement. The shipping bundle is
then rebuilt from `lib/main.dart`; no probe entry point is left in the normal
bundle directory.

Final-code Wayland acceptance also passes (`native-wayland-final-code.log`,
`editor-final-wayland/`): four application switches including 15 seconds inactive,
unchanged reading geometry/state, and native insertion at the original target
without refocusing. The final shipping executable passes the owned X11 natural
close check (`native-shipping-final-code.log`, `shipping-final-close/`), including
the mapped official engine verification. Both supervisors exit zero with no
unresolved descendants. The earlier window-chrome observation limitation remains
as recorded above.
