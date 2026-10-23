# Structural Enter, split and merge repair

## Baseline and execution paths

Reviewed the clean `0c55c7f` checkout on 2026-10-22. No applicable `AGENTS.md`
was found. The README and Linux/application/Writerside development verification
instructions apply. The official `/home/albert/flutter-sdk` is Flutter 3.47.5,
framework `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, engine revision
`af7e796e16`. `flutter pub get --enforce-lockfile` succeeded; dependency/runtime
pins are unchanged. No engine, SDK, native UI or source-editor patch is used.

The supplied attachment itself is not present in this checkout. The tracked
`test/fixtures/structural_editing/header_test_text.md` is the requested minimal
`## About the job` reproduction, not a claimed copy of an unavailable attachment.

Production `MarkdownParser` / `MarkdownAstAdapter` create the editing document.
`BusyMarkWysiwygEditor` handles physical Enter with `applyEnterAt`; field text
input and plain-text paste reach `replaceBlockTextWithParagraphs`. Document-range
replacement uses `replaceTextSelectionWithText`. The controller's Markdown
serializer publishes source; the editor then calls `rebaseCommittedSource` and
the workspace updates its real buffer/preview. Local editor history stores
semantic snapshots; workspace history stores source and session state. Real-file
workspace tests exercise external history, view changes, saving and reopening.

Evidence is retained locally under ignored `build/structural-evidence/`. The
separate `build/structural-baseline/` is an archive of the original commit with
only the new tests overlaid. Its production controller blob is exactly
`0159079dd431b301ce7548954ec713d57c2b856f`, matching the original commit. It uses
the same locked dependencies and official SDK. Neither artifacts nor fixtures
contain private document content.

## Findings and disposition

| Finding | Independently observed failure | Repair / regression |
| --- | --- | --- |
| Heading-start Enter | The original H1–H6 becomes an empty heading and a new paragraph receives its text/identity. Controller and actual key-event widget failures. | Shared position-aware split ownership; the original heading stays on the right, with its complete inline tree, attributes and editing ID. `structural boundaries … retains heading identity`, workspace/native cases. |
| Leading newline through text input/paste | Same corruption through the independent reconstruction path. | Both routes use the shared fragment policy; clipboard tests exercise real text input and plain-paste handlers, focus, subsequent typing and undo/redo. |
| Prefix versus entire selection | Prefix deletion should leave the remaining heading intact; whole-heading replacement must not preserve an untouched heading. A newline followed by identical text has the same string diff as an insertion. | Staged selection Enter and actual pre-edit field selection distinguish these cases. The accepted-selection cache is updated after ordinary edits, cleared/pruned with its controllers, and is not an IME replay mechanism. `range replacement newline`, `identical suffix`, `stale full-heading selection context`. |
| Empty preceding paragraph / nested owner | Backspace adopts the empty paragraph's kind, dropping heading semantics. Inside a quote it cannot find the sibling at all. | Only genuinely empty, unauthored text paragraphs with no objects/children are removable. Keep the current heading intact; resolve real structural siblings, not the synthetic outline path. Inverse H1–H6, nested quote and authored/semantic-empty controls. |
| Writerside heading attribute leak | `collapsible`, `default-state` and the authored-attribute snapshot reach the new paragraph and serializer. | New paragraphs get fresh paragraph-owned attributes; all heading attributes remain with the retained heading. No blanket removal of metadata from other block kinds. Start/middle/end, serialization/rebase/reparse coverage. |
| Empty list parent loses descendants | Clearing just the parent caption and pressing Enter or supplying a newline replaces the item with an empty paragraph, discarding children and grandchildren. Empty-alt inline content can also disappear. | List exit requires safely discardable content: no subtree, semantic objects or authored item properties. Otherwise split into valid list items, retaining the original subtree exactly once. Existing `allowListExit: false` whitespace-paste protection remains covered. |
| Leading list split misowns children | The new empty left item takes the old subtree while the parent text moves right. | Original parent ID, authored state and children stay together on the right; new left item owns no subtree. Ordered markers advance according to the existing increment rule. CommonMark/GFM-style lists and Writerside native ownership/rebinding regressions. |
| Zero-width objects lost | Newline reconstruction, Insert Hard Break and Insert Blank Line drop embedded empty-alt images. | Rebuild text with semantic anchors once, then partition the actual inline tree. Preserve destinations, attributes, wrapper formatting, ordering, and boundary offsets, including multiple anchors at one offset. Leading heading objects stay with that heading. |
| Non-atomic local Enter | A full selection in the sole member of an attributed native list is deleted before list exit returns null; the field/model diverge and history changes. | Stage deletion plus Enter, publish once on success, and record history only after acceptance. Consume rejected physical Enter without a text-input fallback. |
| Rejected input fallback | The field's newline path returns null for protected list exit, then publishes the same input as an ordinary local edit. | Explicitly distinguish “no structural newline” from rejection; restore the last valid model selection/text, with no publication or undo entry. |
| Empty task serialization | End-of-item Enter emits `- [ ]` without required whitespace. The pinned parser reparses the empty task as an ordinary list item and Writerside rebinding can lose editing IDs. | Emit and preserve the required trailing space for an empty task, without adding visible or semantic filler. Parser/save/rebase and native-list owner tests. No parser/dependency patch. |
| Nested checkbox ownership | Native saved source lost the checked/unchecked markers on children when a task parent was edited. The original AST adapter recursively extracted/removed checkboxes from descendant lists; it could also promote an unmarked parent to a task. | Extract/remove only the owning item's direct/caption-paragraph checkbox, matching the pinned package AST. All 18 tight/loose, unordered/ordered/task-parent cases fail against the original adapter. Descendant kinds and checked states survive publication and reopening. |
| Formatted semantic anchors | Ordinary typing already retained zero-width images but split their strong wrapper into adjacent runs. Serialization emitted invalid repeated delimiters, losing formatting and inserting literal asterisks on reopen. | Rejoin equivalent adjacent wrappers after anchor restoration using the existing normalization helper. A genuinely parsed formatted-image fixture establishes this independently of newline operations. |
| Read-only history mutation | Physical Enter and the hard/blank-line toolbar callbacks record history before source publication rejects the mutation. | Reject these operations before modifying the model or history. Copy/selection and arrow navigation remain available. Independent original-code keyboard and toolbar failures. |
| Protected/generated endpoints | Direct controller calls report structural success for protected content (or change generated/source-only projections). | Validate structural endpoints and owners before mutation; reject table-cell block splitting/merging, which has a dedicated editing path. This is controller-level evidence, not a claim that the UI exposed every direct call. |

### Leads not adopted as production defects

- Changing `_splitKindFor()` globally to return headings would break correct
  middle/end behavior. It still maps headings to paragraphs. The full matrix
  explicitly preserves middle/end splitting and the existing empty-heading
  end-split behavior in all three Markdown modes.
- The proposed stale-property-source failure did **not** reproduce through the
  normal property publication → `rebaseCommittedSource` → nested structural edit
  sequence. `rebaseCommittedSource` clears property-only edit records and binds
  current source metadata. The passing quote/property regression is retained;
  `_replaceBlockWithMany` was not broadly rewritten to fit that diagnosis.
- A zero visible-text length alone is not proof of an empty block. Semantic-only
  paragraph/list and authored-paragraph controls explicitly prevent that shortcut.
- Blank-only paragraphs still intentionally disappear as distinct semantic
  paragraphs when reparsed. The existing document tests remain unchanged.

## Repair boundaries

Only the existing WYSIWYG split/merge/input handlers, semantic-anchor restoration,
empty-task serializer and Markdown AST checkbox ownership are changed. New
fragment ownership is shared between physical and text-input
splits. The original owner receives its children and authored attributes; a newly
inserted ordinary paragraph does not inherit heading identity, collapsibility,
or a stale authored source record. Source spans/raw fragments are not copied onto
new structural blocks. Required whitespace/session metadata is still generated
through the existing helpers.

An inserted hard break is still a hard break inside one block, not a paragraph
split. Explicit navigation, typing and clipboard routes remain the existing
production routes. No changes to the focus-restoration repair, editor architecture,
virtualization, native UI, save format, dependency pins or blank-paragraph policy
were introduced.

Native validation also caught an implementation omission in the new empty-
paragraph removal branch: after Writerside publication the retained heading was
clean, so source patching retained the old blank gap. The final branch reuses
`_withoutSourceSpan(..., dirty: true)` to invalidate that structural boundary.
`repair-inverse-publication-before.log` fails before that correction;
`after-inverse-publication.log` passes 199 tests afterward. This is recorded as
validation of the repair, not as a pre-existing review finding.

## Automated evidence

The unmodified baseline's existing document/structured suites passed **203 tests**
(`baseline.log`). Initial new boundary tests failed 84 cases while the original
middle/end controls passed (`before-boundaries.log`). Corrected key-based widget
finders then independently reproduced the physical/selection/rejection failures
(`before-integration.log`); the early bad-finder runs are not keyboard evidence.

The isolated original checkout ran the completed early regressions: **111 failed,
8 passed** (`before-original-checkout.log`). The complete first/later H1–H6 matrix
plus the identical-suffix cases then yielded **151 failures, 38 passing controls**
(`before-original-full-heading-matrix.log`). Original read-only toolbar commands
failed both cases (`before-original-readonly-toolbar.log`). These are intentional
failing-before results, not skips or relaxed assertions.

Additional focused before logs include `before-input-rejection.log`,
`before-range-replacement.log`, `before-empty-task-serialization.log`, and
`before-identical-suffix.log`. The 711-test affected run passed in
`affected-final.log` before the final explicit-selection-context refinement;
the refinement's full targeted matrix passed **197 tests** in
`after-final-selection-context.log`. The workspace/reparse control passed in
`workspace-transient-redo.log`; the final full checks are recorded below.

The nested-checkbox addition fails all 18 cases in the original archive
(`before-original-nested-checkboxes.log`). With that repair the complete affected
set passed **736 tests** (`affected-complete.log`). Native image setup then exposed
an invalid emphasis fixture: the mid-word delimiter was literal, not bold. The
final fixture asserts `plainText == 'abc'` and actual strong ranges before any
edit. Its ordinary-edit/newline/hard-break/blank-line cases fail all 13 original
tests (`before-original-valid-formatted-objects.log`); all 13 pass with wrapper
coalescing (`after-valid-formatted-objects.log`). Earlier passing image runs must
not be used as evidence of genuine enclosing-format preservation.

Commands use `/home/albert/flutter-sdk/bin/flutter` and its adjacent `dart`:

```sh
flutter pub get --enforce-lockfile
TMPDIR=/tmp flutter test --no-pub --concurrency=2 \
  test/src/busymark_document_test.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  test/src/wysiwyg_clipboard_test.dart \
  test/src/writerside_authoring_test.dart \
  test/src/writerside_native_list_inspector_test.dart \
  test/src/writerside_inspector_session_test.dart --reporter expanded
TMPDIR=/tmp flutter test --no-pub --concurrency=1 test/src/app_smoke_test.dart \
  --name 'heading boundary survives workspace' --reporter expanded
```

The isolated original matrix command was:

```sh
cd build/structural-baseline
TMPDIR=/tmp /home/albert/flutter-sdk/bin/flutter test --no-pub --concurrency=1 \
  test/src/wysiwyg_structured_regression_test.dart \
  test/src/wysiwyg_clipboard_test.dart \
  --name 'structural boundaries|identical suffix' --reporter expanded
```

## Native Linux acceptance

`tools/structural_editing_smoke.dart` opens the production application and its
workspace, not a substitute editor. `tools/structural_editing_native.py` creates
an owned X11/Xvfb display and private XDG profile *before* starting a private
D-Bus broker. Input uses XTest against only the caller's PID-owned window;
profiles, documents and saved-source captures are disposable. The existing
owned-process supervisor retains shutdown/cleanup observations. This campaign
does not claim Wayland coverage.

The original native exploratory sequence failed its Backspace inverse check
**after external undo/redo** (`native-x-initial`). A new production-workspace
widget measurement established that external history reparses source and has
already removed the transient blank paragraph (`workspace-transient-redo.log`).
There is no preceding paragraph left to remove. The native check was corrected
to test the direct inverse immediately, and to test source/heading restoration
separately across undo/redo. The failed attempt is retained; it was interrupted
through its owned supervisor, with no unresolved survivors. No production
change was made to force blank paragraphs to survive reparsing.

Two subsequent attempts correctly rejected their Writerside-mode prerequisite:
the harness was calling `openPath(file)`, which selects a standalone workspace.
The final harness explicitly opens the project directory, then opens its topic
using the production `openActiveFile` workflow. No production mode-routing
change was made. Native close can reject a captured immutable buffer when a
session report replaces it during History flush; the harness records that
observation and retries only if ID, revision, saved bytes and clean state still
agree. `native-x-close/probe/markdown-close.json` records exactly that case, not
a source edit or an ignored protection.

`native-x-inverse` verified the corrected Writerside inverse and saved heading
properties, then discovered the actual nested-checkbox source loss. After the
adapter repair `native-x-checkbox` passed both heading scenarios and all six
list scenarios, including subtree order, identities and checkbox counts. It
stopped at the invalid image fixture prerequisite; no image success is claimed
for that attempt. Every failed attempt and its ownership outcome is retained.

### Final native result

`native-x-formatted/probe/result.json` records **all 130 checks passed** across
nine scenarios: the minimal Markdown heading, the actual Writerside Markdown
project/topic, six unordered/ordered/task parent boundary cases (nonempty and
caption-cleared), and genuinely formatted embedded empty-alt images.

Real GTK keyboard input exercises Enter, immediate Backspace, typing without
refocusing, Undo/Redo, default Shift+Enter, a configured F8 hard-break shortcut,
and Ctrl+S. A real native pointer click invokes Insert Blank Line. Focus and
caret assertions accompany editing. View transitions, actual saved bytes,
reopened semantic trees, subtree order, checkbox states, and image destinations/
formatting are checked. The nine `*-saved.md` files are actual saved-source
captures; PNGs show rendered results and do not substitute for those checks.

The final native app is the pinned official **debug** GTK build of the production
application with an acceptance driver. It exited naturally with status 0;
`native-x-formatted/ownership.json` has `ok: true`, `cleanupRequired: false`, and
no unresolved survivors. No natural-close success is claimed for failed attempts.
The final retained bundle is `build/structural-native-formatted-bundle/`.

Run from the repository root, with the existing Node installation on PATH:

```sh
TMPDIR=/tmp flutter build linux --debug --no-pub \
  -t tools/structural_editing_smoke.dart
cp -a build/linux/x64/debug/bundle build/structural-native-formatted-bundle
/usr/bin/python3 tools/structural_editing_native.py \
  build/structural-native-formatted-bundle/busymark NEW_OUTPUT_DIRECTORY
TMPDIR=/tmp flutter build linux --release --no-pub -t lib/main.dart
```

This verifies X11/Xvfb, not Wayland, Writerside XML native interaction, or a
separate uninstrumented release-desktop campaign. The normal release is built
separately, not left pointing at the driver. The native executable's RUNPATH is
`$ORIGIN/lib`; no `LD_LIBRARY_PATH`/`LD_PRELOAD` override was set. Its bundled
debug engine matches the SDK artifact byte-for-byte (SHA-256
`7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`).

## Final verification

- `affected-shipping.log`: **737 tests passed**, including all final parser,
  publication-boundary and genuine-formatting cases, no new skips.
- `analyze-complete.log`: `flutter analyze --no-pub`, **no issues**, 44.7 seconds.
- `format-shipping.log`: formatter check over all **10 changed Dart files**, zero
  changes. `python3 -m py_compile tools/structural_editing_native.py` succeeds;
  `git diff --check` is clean.
- `owned-tooling-tests.log`: the existing process ownership/supervisor tests pass
  **19 tests** without modifications.
- `linux-release-shipping.log`: the normal
  `flutter build linux --release --no-pub -t lib/main.dart` succeeds. Node is the
  already installed 24.13.0 executable under
  `/home/albert/.cache/JetBrains/Air/node-24.13.0/node-v24.13.0-linux-x64/bin`;
  no installation or version/pin change was made.

The shipping `libapp.so` SHA-256 is
`654afa080a96db8445b8777af0a55ed6da22697475b9ece1a1e8af689f615c9b`.
Its official release engine and the pinned SDK artifact both have SHA-256
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.

The first broader run (`full-suite.log`, before the last parser/formatting
refinements) completed **5,013 passes, 62 existing skips and one failure**:
`general Markdown fixture finishes automatic rich spelling` exceeded its existing
deadline while still checking. The exact unchanged test passes in isolation
(`spelling-retry.log`, one pass in 15 seconds); no assertion/deadline was weakened.
The complete final-source rerun in `full-suite-shipping.log` passes **5,034 tests
with 62 existing skips and no failures**, in 15 minutes 9 seconds. The earlier
spelling deadline failure did not recur. No new regression was skipped.

Final-source full-suite command:

```sh
TMPDIR=/tmp flutter test --no-pub --concurrency=4 --reporter expanded
```

Final-source affected suites use the six-file command above. Additional checks:

```sh
TMPDIR=/tmp flutter analyze --no-pub
python3 -m py_compile tools/structural_editing_native.py
python3 -m unittest tools/test_owned_processes.py tools/test_run_owned_fixture.py
git diff --check
```

The formatter command lists the four changed production Dart files, five changed
test files and `tools/structural_editing_smoke.dart`, using
`dart format --output=none --set-exit-if-changed`. SDK tracked files and
`pubspec.yaml`/`pubspec.lock` remain unchanged. Only this repair's files are
committed locally; nothing is pushed or published.

Exact formatter command:

```sh
/home/albert/flutter-sdk/bin/dart format --output=none --set-exit-if-changed \
  lib/src/editor/wysiwyg/wysiwyg_document_controller.dart \
  lib/src/editor/wysiwyg/wysiwyg_editor.dart \
  lib/src/markdown/busymark_markdown_serializer.dart \
  lib/src/markdown/markdown_ast_adapter.dart \
  test/src/app_smoke_test.dart test/src/busymark_document_test.dart \
  test/src/writerside_native_list_inspector_test.dart \
  test/src/wysiwyg_clipboard_test.dart \
  test/src/wysiwyg_structured_regression_test.dart \
  tools/structural_editing_smoke.dart
```
