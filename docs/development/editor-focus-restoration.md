# Editor focus and reading-position restoration

## Investigation boundary

The starting checkout was clean at
`aac4d66872b794b7722d0ededf11313ee7eccd15`. Repository/parent instructions,
dependency pins and the existing Linux verification documentation were checked
before production changes. The repair uses the existing official Flutter 3.47.5
SDK at `/home/albert/flutter-sdk`: framework
`6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, engine
`af7e796e161ae0bb1ff0758c71a7105418bd9ded`, Dart 3.13.4. The SDK checkout,
`pubspec.yaml`, and `pubspec.lock` are unchanged. `flutter pub get
--enforce-lockfile` succeeded; the installed positioned-list package is 0.3.8.

The supplied review was treated as leads. The installed Flutter and package
sources, rather than archive line numbers, determined the implementation.
Evidence is retained locally in `build/focus-evidence/`; these ignored build
artifacts are not document data and are not published. Early exploratory tests
with an incorrect platform setup, an off-screen tap, or a missing render-host
override were corrected and are not counted as defect evidence.

## Independently confirmed defects

Each row identifies a regression that failed before its respective repair. Some
additional paths were investigated after the first focus repair; their logs
therefore isolate those remaining defects, not an entirely unmodified baseline.

| Defect | Failing evidence | Passing evidence |
| --- | --- | --- |
| Linux desktop focus suspension/restoration schedules an old caret reveal in the rich document's ancestor viewport. The visible field moved from 50 to 431.12 logical pixels in an intervening frame. | `before-core.log`, `before-desktop-valid.log` | Editor lifecycle suite; native frame traces below |
| Source's own vertical controller also scrolls on passive focus: 1800 to 1661.75 pixels. Blocking ancestor implicit scrolling alone cannot fix this. | `before-source.log` | `after-source-composition.log`; Source lifecycle suite |
| A partially clipped/oversized block loses its intra-block position. A code block naturally scrolled 2300 pixels restored from top -2219 to 81. | `before-lifetime-dialog-session.log` | `after-session-layout.log`, `clipboard-and-viewport.log`; tall paragraph/code regressions |
| Recreating a session with an off-screen caret can restore reading position but leave no mounted text-input client. | `expanded-first.log` | `after-session-input.log`, `after-session-detach.log`, `after-session-owner.log` |
| A queued editor focus restoration can override a newer search/inspector-like focus owner. | `before-newer-focus.log` | `after-newer-focus.log` |
| A queued toolbar focus callback can reclaim primary focus while the desktop focus manager has suspended the application. | `before-toolbar-suspension.log` | `session-and-toolbar-verified.log` |
| A document refresh/session restore can take focus from an existing competing owner, including while the focus manager has suspended it. | `before-session-owner.log` (both resumed and inactive cases) | `after-session-owner.log` (4 tests passed, including existing recreation cases) |
| Canceling a dialog replaces a table cell's reversed 7..2 selection with 0..9. | `before-table-math.log` (dialog case only) | `math-and-restores.log`; lifecycle suite |
| A math editable can change to its rendered representation on inactivity, detaching its input client. | `math-and-restores.log` (valid render-host setup) | Lifecycle suite's prolonged math-source case |
| Source's pending session jump can overwrite a newer manual scroll (600 becomes 1200). | `before-source-pending.log` | `after-source-pending.log` |
| Legitimate platform composition cleanup while inactive triggers Source's separate horizontal-caret helper (400 becomes 68.67). | `before-source-composition.log` | `after-source-composition.log` (5 tests passed) |
| Delayed native modal-barrier release can restore an older focus owner over a control selected while release was pending. | `before-modal-owner.log` | `after-modal-owner.log`, `serial-retries-one.log` |
| A retained table outside the package's two-screen layout cache has a zero paint transform. Floating controls attempted to paint at NaN coordinates, and the new session metadata attempted to serialize NaN. | `short-table-outside-cache-before.log`; native `ship-x11-table/application.log` | `short-table-finite-verified.log`; the expanded short-cell recreation case in `focused-cache-complete.log` |

### Conclusions not supported by reproduction

- No BusyMark application-reactivation handler explicitly scrolling the document
  to the top was found. The reproduced mechanism is Flutter's focus-driven caret
  reveal, plus the independently reproduced Source horizontal helper.
- Ordinary table-cell *application resumption* did not reproduce select-all.
  The pinned `EditableText._justResumed` path protects that case. Dialog return
  is different and did reproduce it; the two are not conflated.
- The existing recreation test is useful and remains present, but its caret in
  the visible region does not establish application-reactivation behavior.
- Negative item leading edges are legitimate; negative `jumpTo` alignments are
  not the repair. The package's documented alignment range remains respected.
- Menu/dialog/Source/Split paths were not all declared defective merely because
  they restore focus. Passing cancellation, competing-owner and navigation
  cases are retained as coverage, not additional claimed bugs.
- A later native-probe failure initially suggested that a short table cell did
  not reveal on typing. Stronger measurements disproved that diagnosis: the
  active viewport moved from 1900 to 129.99 pixels and the target was visible at
  y=66. The probe retained an obsolete `ScrollPosition` after a viewport
  replacement (`accept-w-table/probe/frames.json`, `samePosition:false`). The
  measurement now follows the live viewport and also checks actual rendered
  reading/target geometry. No editor scrolling workaround was added for this
  false diagnosis. The separate non-finite table/session geometry was genuinely
  reproduced and repaired.

## Repair mechanism

`BusyMarkEditorFocusRestoration` surrounds only production editor fields. On a
focus-only restoration it intercepts both halves of the pinned framework's
deferred caret reveal: the field controller's direct `animateTo`/`jumpTo`, then
the descendant `showOnScreen` request that would reach ancestor viewports. The
actual `showOnScreen` callback consumes the operation token. There is no timer,
fixed number of ignored frames, delayed jump-back, temporary read-only state,
selection movement, SDK modification, or application-wide visibility policy.

Text/selection changes and real editing keys/pointer input release suppression;
explicit editor navigation/focus helpers identify purposeful reveal requests.
The framework still performs normal caret scrolling for input, selection changes,
search and explicit navigation. Manual wheel/drag scrolling is not disabled.
The repair does not fabricate or replay text-input/composition events. Source
ignores only composing-only, non-editing lifecycle notifications when deciding
whether to schedule its own horizontal reveal.

A focus-scoped keep-alive retains only the last editing target for each editor,
including while the desktop focus manager suspends primary focus. Changing to
another editing target releases the previous retained target. Ordinary document
virtualization remains enabled; the whole document is not retained. Math source
presentation also remains stable during inactivity.
For retained children beyond the layout cache, session capture uses the public
viewport's logical reveal coordinate when the paint transform is not invertible.
Unanchored table controls are not painted until their table has a valid paint
transform again. This avoids both non-finite persistence and invalid overlay
painting without widening the virtualization cache.

Session state adds optional/backward-readable clipped-pixel offset, editing-block
viewport offset and source/layout signature fields. With unchanged layout the
saved editable is mounted and the document's actual scroll position is restored
in the same operation, preserving its off-screen input client. Otherwise the
existing content anchor is used with legal `[0,1]` item alignment followed by a
synchronous pixel offset, including leading scroll padding and nested entries.
Current layout enforces genuine bounds. Old sessions retain their previous
alignment semantics: missing intra-block precision cannot be reconstructed.
JSON, workspace coalescing and Writerside source-binding copies include the new
fields; no state is discarded and no migration framework is introduced.

Queued operations use existing document generations plus request identity,
selection/navigation and focus-ownership checks. New scrolling or navigation,
replacement content, disposal, and a newer owner invalidate stale operations.
Document refresh does not claim focus while inactive or while another control
owns it. Shared dialogs validate their previous node and ownership again after
asynchronous barrier release. Table fields preserve their own caret/range;
explicit cell/document Select All commands remain in the editor.

## Automated regression coverage

`test/support/desktop_focus.dart` explicitly installs the pinned focus manager's
desktop lifecycle listener in the Linux-targeted test binding. It verifies that
inactive focus is the root scope and resumed focus is the original node. Tests
inspect geometry during every inactive/resumed frame and after callbacks and
animations, with 0.1 logical-pixel tolerance. They do not silently refocus the
field before delivering subsequent text input.

During implementation, an additional cross-cell Tab test caught an overbroad
suppression at an explicit focus handoff (`navigation-boundary-measured-before.log`,
caret x=-1275.67). Explicit navigation markers repair that handoff; the same test
and both pending-scroll/navigation cases pass in
`navigation-boundary-verified.log`. Its intentional horizontal offset is compared
with fresh Tab navigation at 0.1-pixel tolerance: assuming it must be exactly zero
was incorrect for the pinned framework's fractional caret geometry (0.1667).
Passive geometry checks were not relaxed. Existing exact-reparse tests also
caught an overly strict root/view-scope ownership check; root scopes without a
route are now distinguished from a competing dialog/control, retaining both
normal recreation and competing-owner protection.

The expanded lifecycle, session and Source suites cover caret above/below the
viewport; short/90-frame inactive intervals and repeated cycles; reversed local
and cross-block ranges; paragraphs, lists, code, table internal scrolling and
math representation; off-screen recreation; oversized/plain/nested blocks;
new scrolling/navigation while a callback is pending; canceled nested menus and
dialogs; newer focus owners; document replacement/disposal; committed input,
composition, paste and undo/redo. Existing viewport coverage is retained.
Workspace coverage checks meaningful pixel-only session updates, coalescing
sub-tolerance changes, unchanged bytes/dirty/history, and existing document/view
switching behavior. Native Source/Split coverage complements the widget cases.

## Native Linux acceptance

`tools/focus_restoration_smoke.dart` is an alternate entry point into the actual
application and production editors, not a substitute editor. The supervisor
`tools/focus_restoration_native.py` creates an owned GNOME/Mutter headless desktop
with a 1280x960 virtual monitor, isolated profiles, disposable Markdown/Writerside
documents, a separate real GTK application, and real Mutter keyboard input. It
does not operate the user's desktop. Both native Wayland and GTK X11 through
XWayland were exercised; this does not claim a separate standalone Xorg session.

The successful matrix is Markdown Editor, Source, Split, and table-cell editing
on both backends, plus Writerside Editor on both backends (10 runs). Each run
uses four real Alt-Tab out/back cycles, including a 15-second inactive interval,
then types a native `z` without tapping or refocusing the editor. All recorded
frames preserve the passive viewport. Exact insertion at the original authored
source position and deliberate caret reveal both pass. Passive checks also
verify focus suspension/restoration, original selection, exact bytes, dirty
state, edit revision and undo/redo counts.

Final frame-level evidence (no private document contents):

- `build/focus-evidence/safe-x-{editor,source,split,table,ws}/probe/{frames.json,result.json}` (XWayland)
- `build/focus-evidence/safe-w-{editor,source,split,table,ws}/probe/{frames.json,result.json}` (Wayland)
- `build/focus-evidence/native-final-summary.json` and `native-final-lifecycle.jsonl`

All 10 final runs pass. Each records four acknowledged real inactive/resumed
cycles. Live viewport drift is zero; rendered reading-anchor drift is zero where
the rich editor exposes an anchor. The probe follows the current scroll position
after viewport replacement and checks actual target visibility after input.
The normal release bundle is restored at `build/linux/x64/release/bundle/`;
its application-library hash matches `shipping-app-sha256.txt`. The separately
retained instrumentation bundle is `build/focus-verified-probe/`.

These frame traces are the equivalent frame-level evidence, not a video. Earlier
native attempts and prerequisite failures are retained separately and are not
counted as passes. Native pre-repair recording was not obtained: the initial
build was blocked by the existing visualization build step's missing Node on
PATH. An already-installed Node 24.13.0 was subsequently located and used only
on the build command's PATH; dependencies and build scripts were not changed.

Minimize/restore and non-editing window-chrome reactivation remain **unverified**.
The headless `full` and follow-up `minimize` attempts did not establish the native
window-state prerequisite. The final bounded X11 attempt also could not verify
native unmapping after the minimize request (`safe-x-full.log`). Failed
prerequisites and any failed focus/input results are retained, not represented as
successful acceptance. This limitation is not evidence that
the editor repair passes those transitions, nor a diagnosis of another editor
bug. The supervisor forcibly retires its owned processes afterward; it makes no
natural-shutdown acceptance claim.

### Native harness isolation correction

Earlier runs gave BusyMark disposable XDG directories but did not update the
private broker's environment for D-Bus-activated GNOME helpers. Some earlier
helper logs show attempted migrations of the host Evolution cache, reporting
file-exists errors. BusyMark itself used only disposable documents/profiles.
The harness now verifies that both its parent and broker belong to the dedicated
`dbus-run-session`, updates activation environment before starting the desktop
and after display discovery, and isolates keyring/session-agent settings too.
Final `safe-*` runs have no host-cache migration warnings. No host-cache cleanup,
deletion or attempted rollback was performed; the earlier logs do not establish
that every incidental helper action was side-effect-free.

Reproduction commands use a new output directory on every run:

```sh
PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter build linux --release --no-pub \
  -t tools/focus_restoration_smoke.dart
dbus-run-session -- /usr/bin/python3 tools/focus_restoration_native.py \
  build/linux/x64/release/bundle/busymark NEW_OUTPUT x11 editor alt-tab
dbus-run-session -- /usr/bin/python3 tools/focus_restoration_native.py \
  build/linux/x64/release/bundle/busymark NEW_OUTPUT wayland source alt-tab
# Other modes: split, table. Optional final document format: writerside.
# Final retained-bundle runs used build/focus-verified-probe/busymark instead.
```

## Verification record

The verification logs include unsuccessful runs as well as successful retries;
no assertions or deadlines were relaxed, no new regression was skipped, and no
unrelated production code was changed to make the broader suite pass.

All Flutter/Dart commands used the pinned SDK. Final formatter checking covered
the 14 changed/new Dart files; `git diff --check` and Python `py_compile` also
passed. `analyze-shipping-final.log` records `flutter analyze --no-pub`: no issues;
`format-shipping-final.log` records all 14 files checked with zero changes.
The bundled official release engine and the SDK artifact have the same SHA-256,
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`
(`engine-sha256.txt`); `sdk.json` and the empty `dependency-pin-diff.log` retain
the SDK identity and unchanged pins.

Commands and completed independent checks:

```sh
/home/albert/flutter-sdk/bin/flutter pub get --enforce-lockfile
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter analyze --no-pub
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/app_smoke_test.dart --name 'workspace coalesces pixel viewport' \
  --reporter expanded
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/busymark_dialogs_test.dart test/src/spellcheck_projection_test.dart \
  test/src/headless_chrome_support_test.dart --reporter expanded
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/nextcloud_notes_interaction_test.dart --reporter expanded
```

The workspace check passed 1 test (`workspace-coalescing.log`), the serial
dialog/projection/browser run passed all 111 (`serial-retries-one.log`), and the
unchanged Notes interaction suite passed all 12 (`notes-scan-normal-tmp.log`).
The six targeted exact-reparse/toolbar-suspension/table-Tab/competing-owner cases
passed together (`session-and-toolbar-verified.log`).

Two broad runs are retained, not presented as all-green results:

```sh
TMPDIR=/home/albert/busystack/busymark/.tmp/focus-regression \
  /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=2 \
  --reporter expanded
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=4 \
  --reporter expanded
```

`full-suite.log`: 4790 passed, 62 existing skips, 4 failed. It compiled before
the final Source composing-only and rich clipboard build-order corrections.
Those regressions subsequently passed (`after-source-composition.log`,
`clipboard-and-viewport.log`). Its unchanged Notes scan case was still displaying
"Scanning files" at its assertion; the normal-`/tmp` retry passed. Its unchanged
automatic-spelling case passed the serial retry below. The task-created temporary
cache was subsequently moved, recoverably, to `build/focus-temp-retained/`.

`full-suite-final.log`: 4782 passed, 62 existing skips, 13 failed. This run's
compilation predates the final modal ownership correction; that failure passes
in both later dialog runs. The remaining failures were the unchanged spelling
projection's 5-second performance assertion (5.039 seconds), browser writer
fixture, two asset-process deadlines, automatic spelling's existing deadline,
and seven History fixture cases. Serial projection/browser/dialog retries pass
all 111 as above. The following unchanged serial retry passed the entire asset
and spelling suites; only the seven History cases remained (98 passed, 7 failed):

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/local_history_store_test.dart test/src/asset_ingestion_service_test.dart \
  test/src/spelling_workspace_test.dart --reporter expanded
```

See `serial-retries-two.log`. A direct build of the unchanged History fixture
succeeded (exit 0), but a further isolated suite retry still exceeded its
supervisor's existing 60-second compilation deadline: 52 passed, 7 failed in
`history-warm-retry.log`. The supervisor diagnostics verify retirement of its
owned child tree. The fixture imports History/store/format modules, not the
editor. This remains an unresolved verification limitation on this host; no
History implementation or deadline was changed.

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter build bundle --debug --no-pub \
  --target-platform=linux-x64 --asset-dir build/focus-history-assets \
  --depfile build/focus-history.d --target test/support/local_history_store_process.dart
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/local_history_store_test.dart --reporter expanded
```

The superseded `focused-shipping.log` was stopped after it identified the
incorrect zero-offset expectation and root/view-scope integration regression
described above. It is retained for transparency; the corrected complete run
is `focused-complete.log`: all 484 tests passed. The additional beyond-cache
table/finite-JSON/exact-recreation case was then included in the final complete
rerun, `focused-cache-complete.log`: **all 485 tests passed**, with no skipped
new cases. Final analysis also passes in `analyze-final-cache.log`, and
`format-cache-check.log` records 14 files checked with no formatting changes.

The final normal-entry-point release command succeeded (exit 0) in
`linux-release-complete.log`. The normal and instrumentation bundles are retained
separately during native checking; the normal application remains the shipping
artifact, not the alternate probe entry point.

```sh
PATH=/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin:$PATH \
  TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter build linux --release --no-pub \
  -t lib/main.dart
```

```sh
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=2 \
  test/src/wysiwyg_selection_lifecycle_test.dart test/src/wysiwyg_session_test.dart \
  test/src/source_editor_widget_test.dart test/src/busymark_dialogs_test.dart \
  test/src/busymark_design_test.dart --reporter expanded
/home/albert/flutter-sdk/bin/dart format --output=none --set-exit-if-changed \
  lib/src/app/busymark_dialogs.dart lib/src/editor/editor_focus_restoration.dart \
  lib/src/editor/source/source_editor.dart lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart \
  lib/src/editor/wysiwyg/wysiwyg_editor.dart lib/src/editor/wysiwyg/wysiwyg_session_state.dart \
  lib/src/workspace/presentation/workspace_screen.dart test/src/app_smoke_test.dart \
  test/src/busymark_dialogs_test.dart test/src/source_editor_widget_test.dart \
  test/src/wysiwyg_selection_lifecycle_test.dart test/src/wysiwyg_session_test.dart \
  test/support/desktop_focus.dart tools/focus_restoration_smoke.dart
git diff --check
python3 -m py_compile tools/focus_restoration_native.py
```
