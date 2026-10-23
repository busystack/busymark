# Deferred dialog and document-selection focus

## Scope and baseline

This follow-up starts at `b8dd70c` with a clean worktree. It changes focus
coordination only, not the heading/Enter/inline-image repair on this branch.
The parser, document controller, serializers, dependency pins and native UI are
unchanged. Repository Linux and compiled-application verification instructions
were followed. No applicable `AGENTS.md` was present.

The official SDK is `/home/albert/flutter-sdk`: Flutter 3.47.5,
framework `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, engine revision
`af7e796e161ae0bb1ff0758c71a7105418bd9ded`, Dart 3.13.4.
`flutter pub get --enforce-lockfile` passed without changing either manifest.

Evidence below is retained locally under `build/deferred-focus-evidence/` and
the named native output directories. These ignored artifacts are not committed.
The committed tests and probes reproduce the checks without those artifacts.

## Independently confirmed findings

| Finding | Reproduction and actual cause | Repair |
| --- | --- | --- |
| Delayed modal release can reclaim an older editor. | Close a production dialog, hold native barrier release, focus another field, then deactivate the application. The old guard accepts *any* `FocusScopeNode`, including the desktop root while the newer owner is suspended. A newer owner followed by unfocus also bypasses it. Capturing `closingFocus` after `pop()` additionally mistakes a newer control for the closing dialog. | Identify the actual closing route. A per-release permission observes focus ownership and lifecycle, permanently invalidating on a newer owner or inactivity. Only the previous owner, its ancestor scopes and that closing route are eligible. Flush pending FocusManager requests before the final check; remove listeners on invalidation or completion. |
| Deferred cross-block selection extent can override another control or inactive desktop focus. | Perform a real production pointer drag across blocks; release it, then focus a search-like control or deactivate before the post-frame handoff. The original callback checks selection and generation but not owner/lifecycle. Table-ended ranges also have a second, unconditional child autofocus callback. | One guarded handoff owns ordinary and table-ended range input. Capture selection/request/document/navigation identities and the actual focus owner. Cancel on a competing owner or newer action; wait without focusing while the desktop suspends the owner. Resume only when FocusManager restores that same ownership. Remove the child's independent autofocus. |
| A canceled toolbar dialog can bypass the shared dialog guard. | Hold release of the real Link toolbar dialog and focus another field. The shared guard can leave it alone, but toolbar `whenComplete` snapshots the new owner and schedules an editor return anyway. | Completion is not a new editing intent: check permission before scheduling toolbar restoration. |
| A newer focus request can be pending, not yet primary. | Register a newer-control request earlier in the same post-frame phase, then queue `restoreEditingFocus()`. Without flushing FocusManager, the old callback sees the old primary and overwrites the newer request. | Apply pending focus changes before the existing request/document/selection/navigation checks. |

Both supplied findings are confirmed, but not every neighboring path was broken.
The existing resumed newer-owner modal case already passes. Document replacement,
disposal, ordinary completion, intentional keyboard collapse and quick lifecycle
round trips are retained as controls, not claimed as additional original defects.
The existing canceled nested-menu regression is preserved; its ordinary
cancellation is not evidence of a new defect.

## Why editing and reading remain independent

No repair moves a caret, fabricates composition, changes read-only state,
unfocuses an editor, restores a viewport after a jump, or uses a timer/fixed
frame-count suppression. The existing operation-scoped caret-reveal protection
is unchanged. A passive handoff does not call its intentional `reveal()` API.
Actual input and purposeful navigation continue through the original editing
and reveal paths.

Validation of the first repair exposed a necessary lifetime detail: an ordinary
selection extent waiting through prolonged inactivity can leave the virtualized
cache before its handoff. The pending operation now holds a keep-alive lease for
that one target only, released on success, cancellation or disposal. Tests assert
that the rest of the document remains virtualized. This is not whole-document
retention, and the lease neither requests focus nor changes scrolling.

## Regression evidence

The final 56 new cases were copied into a separate `git archive b8dd70c`
checkout. Its production editor/dialog blobs were verified unchanged
(`52bb3fda7412e6c1de67d5ee2301a057108c02e1` and
`a855768ad0c11853e1c8c974fa298c627ff0a1c0`, respectively).

```sh
# Run in the unchanged archive and in the repaired checkout:
/home/albert/flutter-sdk/bin/flutter test --no-pub --reporter expanded \
  test/src/busymark_dialogs_test.dart \
  test/src/wysiwyg_selection_lifecycle_test.dart \
  --name 'deferred modal focus|deferred extent|deferred toolbar'
```

The unchanged production code fails **29** cases; **27** controls pass
(`before-definitive.log`, exit 1). The repaired checkout passes all 56 as part
of the complete affected suites (`affected-final.log`, exit 0).

Coverage includes both range directions, ordinary/table extents, competing
owners before/after close, newer-owner-to-scope transitions, inactivity and
resumption, cancellation, 90 inactive frames, disposal, document replacement,
new caret navigation, and a newer request in the same post-frame phase.
Off-cache reading tests measure actual visible geometry every frame with a
0.1-logical-pixel tolerance. They assert unchanged range endpoints, source and
undo history, deliver platform text input without tapping/refocusing, verify
replacement at the correct target and deliberate reveal, then undo.

The original lifecycle helper explicitly enables Linux FocusManager lifecycle
listening and asserts inactive primary focus is the desktop root. It is not a
test that merely changes an unrelated lifecycle value.

An early pending-owner test did not schedule a frame, and early toolbar tests
used an obstructed target/incorrect dialog finder. Those attempts are not
regression evidence; `before-definitive.log` uses the corrected tests.

One combined run encountered an existing test-harness pointer-ID collision:
an old context-menu test fixes pointer 71, while newly auto-allocated gestures
advanced to 71. The same GestureArena assertion was independently reproduced
on unchanged production code by seeding the test pointer allocator to 71
(`original-pointer-id-collision.log`). New tests use explicit noncolliding IDs;
the old test and its assertions are unchanged. The final full affected run
passes, as does the isolated old context-menu test.

## Verification commands

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --reporter expanded test/src/busymark_dialogs_test.dart \
  test/src/wysiwyg_selection_lifecycle_test.dart \
  test/src/wysiwyg_session_test.dart test/src/source_editor_widget_test.dart

TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --reporter expanded test/src/app_smoke_test.dart \
  test/src/busymark_design_test.dart test/src/workspace_controller_test.dart \
  test/src/workspace_document_context_test.dart \
  test/src/writerside_toc_menu_test.dart test/src/source_commands_test.dart
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub \
  --reporter expanded test/src/busymark_document_test.dart \
  --name 'WYSIWYG link dialog'

/home/albert/flutter-sdk/bin/cache/dart-sdk/bin/dart format \
  --output=none --set-exit-if-changed lib/src/app/busymark_dialogs.dart \
  lib/src/editor/editor_focus_restoration.dart \
  lib/src/editor/wysiwyg/wysiwyg_editor.dart \
  test/src/busymark_dialogs_test.dart \
  test/src/wysiwyg_selection_lifecycle_test.dart tools/focus_restoration_smoke.dart
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter analyze --no-pub
/usr/bin/python3 -m py_compile tools/focus_restoration_native.py \
  tools/deferred_focus_native.py
/usr/bin/python3 -m unittest tools/test_owned_processes.py \
  tools/test_application_close_smoke.py tools/test_run_owned_fixture.py \
  tools/test_official_flutter_workflow.py

PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter build linux --release \
  --no-pub -t lib/main.dart
```

The four affected suites pass **487 tests** in 3m24s (`affected-final.log`).
The six broader integration suites pass **505 tests** in 4m56s
(`integration-suites.log`), including existing menu cancellation, workspace
navigation, search and view transitions. All **3** existing accepted Link-dialog
editing tests pass (`accepted-dialog.log`). No assertions were weakened or new
regressions skipped. The unrelated entire Flutter suite was not rerun.

Formatting checks all six Dart files with zero changes (`format-final.log`).
Static analysis reports no issues (`analyze-commit.log`, 26.0s). Both Python
drivers compile; the existing process/acceptance/workflow tooling suites pass
**92** tests (`tooling-final.log`). The normal `lib/main.dart` Linux release
build passes (`linux-release-final.log`); its bundle is separately retained in
`build/deferred-focus-shipping-bundle/` while compiling probes. The shipping
engine SHA-256 matches the official SDK artifact:
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.

## Native Linux acceptance

The probe uses the actual application and official engine, disposable Markdown,
private GNOME/Mutter headless desktops, a separate GTK companion application,
and real Mutter Alt-Tab/key injection. Profiles are isolated *before* starting
the owned D-Bus broker; activated helpers inherit that isolation. The owned-tree
supervisor checks cleanup and does not signal unrelated processes.

Four application-switch cycles include a 15-second inactive interval. Every
rendered frame records focus/lifecycle and reading geometry, never document
contents. Native `z` input is delivered without clicking/refocusing the field.
Deferred dialog setup deterministically closes the production Navigator route
and gates its real barrier release; this is explicitly **programmatic dialog
dismissal**, not proof of native Escape handling. Selection setup uses real
native XTest pointer input on XWayland, accounting for GTK frame extents, and
introduces a newer owner before the post-frame handoff.

```sh
# Build the alternate entry point, retain that bundle, then restore lib/main.dart.
PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter build linux --release \
  --no-pub -t tools/focus_restoration_smoke.dart
/usr/bin/python3 tools/deferred_focus_native.py \
  build/deferred-focus-release-probe/busymark NEW_SHORT_OUTPUT x11 deferred-dialog
# Backends: x11 (XWayland), wayland. Modes: editor, deferred-dialog,
# deferred-selection, deferred-selection-table (selection gesture: x11 only).
```

The XWayland Editor control passes in debug (`build/df-xe/desktop/probe/`) and
release (`build/df-xe2/desktop/probe/`): all
passive geometry/focus/source/history checks, correct insertion and intentional
reveal. Its supervisor exits 0 with no unresolved descendants. A too-long
Wayland socket path and two native Escape-dismissal prerequisites failed in
earlier attempts; none is counted as acceptance. Their logs are retained.
The Editor control is explicitly retired by the supervisor after its focus/input
measurements; it is not a successful natural-shutdown claim. The three deferred
release cases below do require natural application exit.

The final release XWayland delayed-dialog case passes
(`build/df-xd4/desktop/probe/{frames.json,result.json}`): barrier completion while
inactive leaves focus at the root, resumed input edits only the newer control,
and all per-frame viewport, range, bytes/history/dirty/revision assertions pass.
The application exits naturally with status 0; the owned-tree supervisor reports
no unresolved descendants (`build/df-xd4/ownership.json`).

Release XWayland ordinary and table-ended cross-block selections both pass
(`build/df-xs4/desktop/probe/` and `build/df-xt/desktop/probe/`). The recorded
native pointer-up coordinates equal the requested rendered caret positions;
the production editor reports a cross-block range. Each case preserves the
range and reading geometry through all four native focus cycles and directs
native input only to the newer control. Both applications exit naturally with
status 0 and both ownership reports contain no unresolved descendants.

The native Wayland dialog case remains **unverified**: even after a real Alt-Tab
activation attempt, GTK does not report the application's window active on
this owned desktop (`build/df-wd3/desktop/probe/error.txt`). Earlier Mutter
relative-pointer attempts also failed to deliver the native selection; those
failed prerequisites are retained separately and not counted as passes.
The final XTest cases do not weaken any production assertion. The native GTK
Escape dismissal path is not established by the deterministic dialog prelude.

Native acceptance is limited to the recorded owned headless desktops; it is not
a claim about an untested physical desktop, strict Snap, minimize/restore, or
window-chrome reactivation. The entire unrelated Flutter suite is not rerun by
this focused follow-up.
