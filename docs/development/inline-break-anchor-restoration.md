# Inline images beside existing hard breaks

## Scope and independent reproduction

Started from clean `d0844de` on 2026-10-22, following the README and Linux/native
development instructions. No applicable `AGENTS.md` was present. The official
Flutter 3.47.5 SDK at `/home/albert/flutter-sdk` and the enforced dependency
lockfile are unchanged. Heading/Enter splitting, Backspace and focus-restoration
logic are unchanged. The parser, serializer, UI architecture and dependency pins
are not modified by this correction.

The report is confirmed through three independent production paths:

1. Parse `a  \n![](first.png)b\n` with `MarkdownParser`. Its paragraph text is
   `a\nb`, with the empty-alt image at text offset 2. Call `insertHardBreak(id, 1)`
   or `insertBlankLine(id, 1)`. Before repair the image stays at offset 2 rather
   than advancing to 3 or 4.
2. The production editor's Hard Break and Blank Line toolbar buttons reproduce
   the same failure. Real application/workspace tests independently reproduce
   Shift+Enter and the Blank Line button before the correction.
3. The compiled official-engine Linux GTK application on an isolated X11/Xvfb
   display reproduces the error with an actual XTest Shift+Enter event. The
   retained `native-before/probe/failure-source.md` is:

   `"a  \n![](first.png)  \nb\n"`

   The image has incorrectly moved between the two breaks. The driver reports
   failure, exits nonzero, and does not claim native acceptance for this run.

Evidence is retained locally under ignored `build/hard-break-anchor-evidence/`.
It uses only synthetic fixtures and isolated profiles, not personal documents.

## Cause and narrowly scoped repair

`_insertHardBreaks` already knows the clamped insertion offset and exact length.
Its style-range remapping uses those coordinates, but semantic-anchor restoration
previously discarded them and inferred a common prefix/suffix from old/new text.
For `a\nb` → `a\n\nb`, the common prefix includes the *existing* newline. That
plausible text diff places the insertion after the old break instead of at the
actual caret. An anchor at offset 2 is consequently classified as preceding
the insertion and left in the wrong place. Consecutive breaks make the same
ambiguity possible over a longer span.

The command now passes `(offset: safeOffset, length: count)` into
`_restoreSemanticInlineAnchors`. Known insertions use those coordinates directly;
they do not infer the edit from text. Other callers retain their existing
text-input inference and heading-specific behavior. Wrapper normalization and
the established boundary rule are unchanged: an object exactly at the insertion
point stays before the inserted breaks; an object after it advances by the
inserted length. Objects remain in order, exactly once, with their formatting
and attributes intact. No additional production defect was established in this
scoped investigation.

## Regression evidence

- The unmodified existing structured suite passed **226 tests**
  (`baseline-structured.log`).
- The final new matrix against an isolated archive of `d0844de` has **38 failing
  regressions and 36 passing controls** (`before-final-regressions.log`). Only
  the test file was overlaid; the original controller blob is
  `35b3fa803e6ccc716472da4442f7c8642e359d73`, matching the archived commit exactly.
- The separate real-workspace regression failed both commands before the fix
  (`before-workspace.log`), with image offset 2 instead of 3/4.
- After repair, all **76 focused regressions/controls pass** (`after-focused.log`).
  This includes 72 parser/controller cases, two local-editor widget cases and
  two real-workspace cases. Coverage includes CommonMark, GFM and Writerside
  Markdown; single/consecutive existing breaks; insertion on either side of
  breaks; multiple images at a shared offset; images before, at and after the
  caret; strong/emphasis contexts; source rebinding and reparsing; single-step
  local/external undo/redo; focus/caret; view switching; actual save and reopen.

Tests inspect each leaf image's actual text offset, destination, attributes and
enclosing inline formatting, not only the image count or a saved session. Two
equivalent adjacent formatting wrappers may be coalesced without changing these
semantics. Preliminary exploratory tests incorrectly equated that wrapper
grouping with object identity, used one invalid emphasis fixture, and assumed
single paragraph-boundary breaks survive reparsing. Those assumptions were
corrected without production changes; the definitive before/after matrix uses
valid parsed formatting and interior insertions. It does not change the existing
blank-paragraph or boundary-break lifecycle.

Focused commands (from the repository root unless noted):

```sh
flutter pub get --enforce-lockfile
TMPDIR=/tmp flutter test --no-pub --concurrency=2 \
  test/src/wysiwyg_structured_regression_test.dart test/src/app_smoke_test.dart \
  --name 'explicit line-break anchors|inline break anchors survive workspace' \
  --reporter expanded
# Inside build/hard-break-anchor-baseline (original commit, tests overlaid):
TMPDIR=/tmp flutter test --no-pub --concurrency=1 \
  test/src/wysiwyg_structured_regression_test.dart \
  --name 'explicit line-break anchors' --reporter expanded
```

## Native Linux acceptance

The existing structural acceptance driver has an opt-in `inline-breaks` scenario;
it does not run or alter the prior heading/list/focus scenarios. It uses the real
application, workspace, editor, publication and save/close/reopen workflows.
Both default Shift+Enter and an actual pointer click on Blank Line are tested.
The runner establishes private XDG directories before private D-Bus/Xvfb startup
and injects events only into its own PID-owned window.

The eight cases cross Markdown/Writerside Markdown, existing/consecutive breaks,
and Hard Break/Blank Line. Each checks the actual document mode, live object
positions/formatting, focus/caret, exactly one undo operation, native undo/redo,
actual saved bytes, and the reopened inline tree. Saved Markdown and screenshots
are retained per case; screenshots are not substituted for structural assertions.
The simple tracked fixture uses the equivalent backslash hard-break spelling to
avoid trailing-space warnings; controller/widget regressions also test the
two-space spelling from the reproduction.

```sh
TMPDIR=/tmp flutter build linux --debug --no-pub \
  -t tools/structural_editing_smoke.dart
python3 tools/structural_editing_native.py \
  build/hard-break-anchor-native-bundle/busymark \
  build/hard-break-anchor-evidence/native-final inline-breaks
```

The bundle was copied from `build/linux/x64/debug/bundle` after the repaired
driver build. Output directories must be new on each run. Both `native-after`
(two-space break fixture) and `native-final` (final tracked backslash fixture)
passed **all 88 checks across eight scenarios**. Each exited naturally with code
0; both ownership reports have `ok: true`, `cleanupRequired: false`, and no
unresolved survivors. The original expected-failure run exited 1 and also left
no unresolved descendants. No forced cleanup is counted as acceptance.

The retained bundle's debug engine matches the official SDK engine byte for byte
(SHA-256 `7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`).
This campaign covers X11/Xvfb with the official debug GTK engine, not Wayland,
Writerside XML native interaction, or a separate uninstrumented release-GUI
campaign. The normal release build uses `lib/main.dart`, not the driver.

## Final verification

- `affected.log`: **811 tests passed** in 2m30s, no skips/failures.
- `after-focused.log`: **76 tests passed** in 18s, including both real-file
  workspace/save/reopen tests.
- `analyze.log`: `flutter analyze --no-pub` found no issues (105.8s).
- `format.log`: four changed Dart files checked, zero formatting changes.
- Python compilation passed; `tooling-tests.log`: all **19** owned-process
  tooling tests passed. The fixture-report rejection message is from an
  intentional negative test, not a failed test.
- Dependency pins and the official SDK's tracked tree are unchanged.
- `linux-release.log`: the normal Linux release build passed, using
  `lib/main.dart`. Its `libapp.so` SHA-256 is
  `623df5ac13a3eeaed4d4129f45be2f898df589cffb81d834fd3f437f9cac1cd4`.
  The packaged release engine matches the official SDK release engine (SHA-256
  `d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`).
- `full-suite.log`: **5,109 passed, 62 existing skips, one failure**, in 17m38s.
  `general Markdown fixture finishes automatic rich spelling` exceeded its
  existing deadline while its status was still `checking` (catalog available).
  This exact failure also appears in the retained pre-change
  `build/structural-evidence/full-suite.log` and the earlier committed repair
  report. No spelling/test-deadline code changed. The unchanged isolated retry
  passed in **14s** (`spelling-retry.log`); no assertions were weakened and no new
  regressions were skipped. The full run is not reported as an all-green pass.

All `flutter` / `dart` commands below use `/home/albert/flutter-sdk/bin/`.

```sh
TMPDIR=/tmp flutter test --no-pub --concurrency=2 \
  test/src/busymark_document_test.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  test/src/wysiwyg_clipboard_test.dart \
  test/src/writerside_authoring_test.dart \
  test/src/writerside_native_list_inspector_test.dart \
  test/src/writerside_inspector_session_test.dart --reporter expanded
dart format --output=none --set-exit-if-changed \
  lib/src/editor/wysiwyg/wysiwyg_document_controller.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  test/src/app_smoke_test.dart tools/structural_editing_smoke.dart
flutter analyze --no-pub
python3 -m py_compile tools/structural_editing_native.py
python3 -m unittest tools/test_owned_processes.py tools/test_run_owned_fixture.py
PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  TMPDIR=/tmp flutter build linux --release --no-pub -t lib/main.dart
TMPDIR=/tmp flutter test --no-pub --concurrency=4 --reporter expanded
TMPDIR=/tmp flutter test --no-pub --concurrency=1 \
  test/src/spelling_workspace_test.dart \
  --name 'general Markdown fixture finishes automatic rich spelling' \
  --reporter expanded
git diff --check
```

No push or publication is part of this work.
