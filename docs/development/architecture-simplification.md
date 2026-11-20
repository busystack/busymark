# Architecture simplification against the v0.7.2 review

The cleanup removes **6,757 production lines (2.99%) and eight source files**.
It retires alternate native-header, Git, undo and property-panel owners,
redundant workspace state and unnecessary derived work. All nine numbered
findings are resolved below; the broader tab-state deletion is bounded and the
conditional worker merger is rejected with source-based reasons. Native release
and installed-app acceptance remain open as detailed in the verification record.

The complete eleven-page review at
`/home/albert/Downloads/BusyMark-v0.7.2-Architecture-Review.pdf` was checked against
the source, callers, tests, native runner and exact bundled shared packages.
The starting tree was clean at
`fb66d1ca922bc64e8ffe3e9b0f044f8957b8d61b`, the review's own snapshot. The code
changes are committed locally as `0c648f9`, `0137003` (remaining editor-history
fixtures) and `5ad719b` (Files-only linked-worktree invalidation). Nothing was
pushed or published.

Native fixture corrections are committed as `09bb425`, `c81c5c3` and `f6ff558`:
they check restored buffer selections, instrument the existing batch history
reader, and exercise fixed selector mnemonics independently of direct key
assignments. Final test-only corrections are committed as `e17a502`; they await
observable Notes state and check retained search, staging and history behavior.
That first verification phase used production inputs frozen at `5ad719b`.
The bounded follow-up below records the later source revisions and new results.

The official Flutter 3.47.5 / Dart 3.13.4 SDK and all dependency locks remain
unchanged. The shared engine remains pinned to
`7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`; the shared UI remains pinned to
`0a2434964ea44fbd9d8c06e73cc3b0fc7c7642e8`. Their archives were materialized and
checked with `tools/checkout_shared_dependencies.py --check`. No shared source,
third-party software, archive, consumer pin or dependency version was changed.

## Resolution of every finding

| PDF finding | Verified resolution and retained owner | Principal changed files and coverage |
| --- | --- | --- |
| 1. Retired native header protocol | Deleted both protocol/configuration files, app/page publishers, defaults, action/search listeners, service arguments and native modal-depth queue/maps. The Linux runner has no receiver for this protocol. Current Flutter/Yaru headers, command registry, actual modal routes, barriers, shortcut boundaries, focus restoration, GTK menus and native services remain. | Deleted `platform/linux_header_bar_service.dart` and `platform/header_bar_configuration.dart`. Removed wiring from `app/busymark_app.dart`, `app/busymark_dialogs.dart`, workspace/welcome/settings, export and feedback surfaces. Protocol-only suites were deleted; modal/focus tests remain. `app_smoke_test.dart` uses actual search controls and `LinuxPageFrame`. The sidebar and focus smoke entrypoints use current controls and routes. |
| 2. Retired Git ownership | Deleted the unused executable/process/status/log cluster, old history/commit/diff/branch/mutation methods, epochs and models. Narrowed the existing gateway to identity discovery, status projection and staged AI patch access. Removed unused repository metadata, error variants and operation/message state, including the write-only running-state bridge. Discovery no longer performs a status scan solely to populate unused metadata. The empty CLI-gateway re-export was removed. | `git/application/git_controller.dart`, `git_gateway.dart`, `git_use_cases.dart`, `shared_git_integration.dart`, `git/data/git_shared_gateway.dart`, `git/domain/git_models.dart`; deleted five execution/parser files and the two-line re-export. Retained tests use the shared engine and canonical shared fixtures. Root/trust, byte paths, stale repository identities, Files staging and AI fingerprint tests remain. The active document-versus-disk `GitDiffViewer` recovery route remains in `workspace_screen.dart`. |
| 3. Second editor undo owner | Deleted internal undo/redo stacks, deep-copy snapshots, snapshot traversal/restoration, the history-mode flag and discarded snapshot construction. Existing pre-mutation session reporting, Flutter field undo controllers, transaction guards and the authoritative synchronization path remain. | `editor/wysiwyg/wysiwyg_editor.dart` and its host wiring. Existing `DocumentHistoryHarness` / `WysiwygEditableHarness`, structured, clipboard, selection, spelling and native selection fixtures now use real buffer/workspace history. Removed assertions solely about the deleted private stack and the obsolete local/external test dimension. Exact source, undo/redo, grouping, selection, composition, stale edits and field disposal checks remain. |
| 4. Fallback property-panel owner | Deleted the editor's separate property session, draft/snapshot state, panel construction/layout and mutation callbacks. The workspace inspector/session and existing property controls are the sole owner; editor inspection and video/insertion callbacks remain. | `wysiwyg_editor.dart`, `workspace_screen.dart`, `writerside_authoring_ui_test.dart`. Panel cases mount a real disposable Writerside project in `WorkspaceScreen`; retained assertions cover quoted properties, inline links/shortcuts, video cancellation/insertion, code attributes, stale drafts, undo/reopening, RTL and scaled/narrow controls. Standalone native-menu/navigation cases retain their supplied editor contexts. |
| 5. Duplicate workspace state | Deleted `Workspace.activeFileSnapshot` / `activeFileModifiedAt`, propagation and the three byte reads used only to populate them. Deleted legacy text/dirty storage and parameters from `WorkspaceState`. Authoring tab entries require buffers and use buffer IDs; the unused path-only tab fallback was removed. `DocumentBuffer.diskSnapshot`, content loads, save/conflict checks and separate comparison/history lifetimes remain. | `workspace_model.dart`, `workspace_controller.dart`, `workspace_service.dart`, `workspace_tabs.dart`, `workspace_tab_actions.dart`, `workspace_safety.dart`, navigation and host callers. Snapshot assertions now inspect the buffer baseline. Fixtures construct real buffers with the appropriate view mode and retain active document buffers while adding dirty project files. |
| 6. Irrelevant refreshes | Same-owner attachment now returns without scheduling Git status or publishing duplicate state. Files-only updates use the existing shared engine watcher before the lazy shared session exists; binding the session cancels that subscription. Workspace filesystem events detect repositories before discovery. Removed remotes queries and `hasRemote`. References compare content/identity/project inputs, ignore editor state, use existing filesystem/Notes events, and compare retained source strings rather than cache-only hashes. Move destinations are considered. | `git_controller.dart`, `git_gateway.dart`, `shared_git_integration.dart`, `git_shared_gateway.dart`, `git_models.dart`, `references/reference_controller.dart`. A regression fails on the old reference implementation and passes after the change: caret/scroll/folding preserve the index; content and an unopened file edit refresh it. Real ordinary/linked-worktree regressions verify zero repeated-attachment scans, external index-only staging before a shared session opens, and cancellation on trust revocation. |
| 7. Repeated parsing / retrieval | Reference indexing parses once and passes that document to the existing reference extractor. Hidden/unrelated inspector paths check need/visibility/type before obtaining a rich projection. AI accesses the existing shared patch API directly. PDF composition reuses each loaded topic's source and semantic document. | `references/reference_index.dart`, `markdown_references.dart`, `workspace_screen.dart`, `git_shared_gateway.dart`, `export/writerside_pdf_export_service.dart`; deleted the now-unused application `git_diff_parser.dart`. Actual Git command recording verifies staged bytes, no discovery status scan, and no viewer content/remotes commands. Reference, PDF/export and actual-host inspector regressions exercise retained implementations. Navigation digests, useful projection caches, include resolution, limits, cancellation, asset staging and the PDF backend remain. |
| 8. Retired modes / algorithms | Deleted the source highlighter's visual-only mode/helpers, obsolete topic-delete implementation/result/exclusive helpers, unreachable Local History document-browsing mode/list/sort, retired workspace-source search algorithm/model, unused workspace search controller, topic-rename affected-path helper, modification-time helper and path-only history selector. | `editor/source_highlighter.dart`, `source/source_controller.dart`, `source/source_search.dart`, `writerside_topic_file_editor.dart`, `local_history_controller.dart`, `local_history_panel.dart`, `workspace_controller.dart`, `workspace_service.dart`. Only tests unique to deleted implementations were removed. Active highlighting, rename/removal service protections, retained-history search/inspection, current search, comparison and restore tests remain. |
| 9. Search-worker consolidation (conditional) | Retained, with source-based justification below. No replacement worker framework was introduced. | `editor/source/source_search.dart` (`SourceSearchWorker`) and `search/search_replace_service.dart` (`SearchReplacementWorker`) retain their actual production behavior and behavioral suites. |

Paths in the table are relative to `lib/src` unless a test/tool is named.
The accompanying [line inventory](architecture-simplification-lines.csv) gives before/after
physical counts for all 95 changed Dart files, with production, entrypoint, test
and tool scopes separated. Forty-four are production files under `lib/src`.
The entrypoint's direct gateway import changes no line count. Test/tool
reductions are excluded from the production metric.

## Recommendations retained or bounded after checking the source

The wider removal of `Workspace.openFilePaths` / `activeFilePath` was deliberately
bounded. UI tab construction now derives from buffers. `_openActiveFile` and
`_closeOpenFileTab` still coordinate requested path lists across asynchronous
loads, while service results and `resolveWorkspaceDocumentContext` need the
parsed active path before/independently of a loaded buffer. Replacing all of that
with buffer-derived lists would erase pending navigation or require new state.
The PDF itself cautions against unconditional removal. No new tab coordinator
or compatibility fallback was added.

`SourceSearchWorker.search` accepts an already prepared `SourceDocument`.
`SourceDocument` prepares indexes/visible text on the caller isolate. Replacement
prepares raw source inside its worker and also performs direct exact-span
validation. A substitution must retain that background preparation, Unicode and
grapheme boundaries, independent cancellation, and the distinction between
exactly 5,000 replacements and a refused 5,001-match truncated preview. Existing
replacement code already reuses `searchSourceDocument` for literal matching.
No smaller equivalent lifecycle/mapping change was established, so the
conditional recommendation was rejected rather than introducing a generic
worker API or moving preparation back to the UI isolate.

The retained cases in `source_search_test.dart` check sequential reuse, active
and superseded-request cancellation, Unicode/combining boundaries and source
mapping. `search_replace_service_test.dart` checks the 4,999/5,000/5,001 boundary,
asynchronous preview cancellation and stale replacement plans. These behaviors
remain attached to their production workers.

History assertions now reflect the retained production owner. Buffer history
reconstructs authored source through the existing parser; it does not restore
an obsolete private deep copy of temporary empty paragraphs or boundary-space
inline nodes. Tests still check exact whitespace/source bytes, live paste
semantics/carets before traversal, parsed replay semantics and real input after
traversal. Table Undo restores the captured table selection, followed by a real
cell caret when the selection is collapsed. The workspace's final-newline policy
is preserved. Inspector tests use the host's authored Markdown-title target and
logical XML-topic behavior instead of the fallback panel's private state.

The review's explicit retain decisions were respected: recovery and Local
History durability, offline Notes/outbox/attachment ownership, distinct authored
and resolved representations, manual/Save All/autosave policies, native services,
rendering/visualization scheduling, AI provider boundaries, spelling, clipboard,
settings, feedback, active dependencies and acceptance tooling remain. Large
files were not split or moved merely to reduce their apparent size.

Manual Save, Save All and autosave already share `saveFormattedText` and
`_enqueueBufferWrite`; their overwrite review, batch reporting, cadence and
history-record policies differ. The small repetition in saved-buffer updates
does not justify another policy framework. The deliberate focus-primitive
duplication across the app/shared UI boundary also remains: adding a package
solely to share roughly 126 lines is not a demonstrated improvement. Existing
semantic focus controls and their native behavior are preserved.

## Measured code reduction

Counts use `len(file.read_text().splitlines())` for every Dart file in `lib/src`,
including comments and the same generated adapter/data files on both sides.
Translations, tests, assets, tools, shared/third-party packages and moved code are
excluded from the production reduction. No production files were moved.

| Scope | Before | After | Net change |
| --- | ---: | ---: | ---: |
| Dart files under `lib/src` | 361 | 353 | -8 |
| Physical production lines under `lib/src` | 226,164 | 219,407 | **-6,757 (2.99%)** |
| Git controller | 2,439 | 769 | -1,670 |
| Shared Git host gateway | 949 | 204 | -745 |
| Rich editor | 11,291 | 10,824 | -467 |
| Workspace screen | 16,606 | 16,443 | -163 |

The eight deleted files comprise the six unconditional files in the review, the
368-line diff parser unlocked by the AI change and the two-line gateway export.
They account for 2,052 lines. Other reductions remove active alternate owners,
state propagation and execution steps. Reference invalidation adds a small
amount of necessary wiring to the existing filesystem monitor, preserving
external changes while removing editor-state-triggered work. No runtime latency,
CPU, allocation or binary-size improvement is claimed without a benchmark.

| Deleted production file (`lib/src/`) | Before | After |
| --- | ---: | ---: |
| `platform/linux_header_bar_service.dart` | 433 | 0 |
| `platform/header_bar_configuration.dart` | 671 | 0 |
| `git/data/git_executable_locator.dart` | 148 | 0 |
| `git/data/git_process_runner.dart` | 162 | 0 |
| `git/domain/git_status_parser.dart` | 218 | 0 |
| `git/domain/git_log_parser.dart` | 50 | 0 |
| `git/domain/git_diff_parser.dart` | 368 | 0 |
| `git/data/git_cli_gateway.dart` | 2 | 0 |

Deleted test files certify only removed implementations:
`header_bar_configuration_test.dart`, `linux_header_bar_service_test.dart`,
`git/git_process_runner_test.dart`, `git/git_status_parser_test.dart`,
`git/git_log_parser_test.dart` and `git/git_diff_parser_test.dart`. Actual native
headers/modal controls, the shared engine and the narrowed host adapter retain
behavioral coverage. The inventory includes every modified test/support/tool
file and its before/after count; their deleted lines do not inflate the
application-code reduction.

Using only the workspace directory monitor for Git was rejected during
verification: linked worktrees store their index and common metadata outside
that directory. The retained shared engine already implements the required
repository watcher, including metadata coverage and reconciliation. The host
adds one subscription through its narrowed gateway, retires it on owner,
repository or trust changes/disposal, and hands ownership to the existing shared
session when bound. This is necessary invalidation, not a second watcher
implementation or a new coordination framework.

The remaining 16,443-line workspace screen and 9,726-line workspace controller
still concentrate real product responsibilities. Their size is documented,
not presented as solved by deleting unrelated behavior or adding abstractions.

## Verification and acceptance

**BusyMark is not release-qualified.** The architectural deletion and bounded
follow-up are implemented, but native shutdown, two native read-only selection
checks, full focus transitions and installed-application acceptance remain open.
Baseline reproduction and passing unrelated tests do not waive those gates or
prove that the cleanup has no effect on them.

The official Flutter 3.47.5 / Dart 3.13.4 SDK is unchanged at
`6a19cca56475dbfba1478ee68d7bd0c2ef891da1`. The mapped release engine SHA-256 is
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.
All dependency manifests/locks and both exact shared pins/archives are unchanged
from the original reviewed commit. No third-party or shared source was patched.
The raw records below are relative to `build/architecture-review/`.

### Baseline established before changes

The original clean tree's analyzer passed. Its first complete Flutter run had
**5,732 passed, 68 skipped and 37 failed** (`baseline-tests.log`). Thirty-five
failures lacked the native Git supervisor. Two save/reopen timeouts passed on
unchanged code in isolation after prerequisites were supplied. This baseline is
not green. The original release also failed **27 of 100 natural-close runs with
SIGSEGV** (`close-baseline-release/summary.json`). All 444 tracked production/lock
inputs matched the reviewed original commit (`baseline-native-integrity.json`).

Official bundled Typst/D2, fonts, spelling dictionaries, the native Git
supervisor and owned Xvfb/private desktops were prepared with existing tooling.
Incomplete, failed and superseded attempts are retained with their original
logs. The previous report's final source had **5,706 passed, 0 skipped, 1 failed**
across all 243 entry files (`full-corpus-isolated/receipt.json`): Chromium exceeded
its unchanged five-second retirement deadline in the CRLF CSS case. The complete
unchanged HTML-options file subsequently passed all 16 cases on both original
and changed production. That isolated comparison never qualified the failed
full run. Its packaging helper correctly refused it.

### Bounded follow-up changes

`15ac993` requires the file-tab buffer ID and deletes the path-only identity
fallback. The kind prefix and separate comparison/history IDs remain. It also
deletes both empty `if (mounted)` blocks, the empty spelling teardown and both
no-op spelling callback invocations. No replacement callback or compatibility
mechanism was added. All **92 affected safety/spelling cases passed before and
after** (`followup-20261115/remnants-{baseline-ready,after}.log`). The first
mistaken invocation naming a nonexistent test file is retained separately.

`665b105` fixes a verified native host allocation defect. The sidebar preserves
its selected view by workspace ID, while its parent allocation also required
`openedAt`. A same-root refresh changed that timestamp without remounting the
sidebar. The live snapshot showed Git requiring **396 pixels inside a 300-pixel
slot**, with the branch action at x=312 outside the slot. Resizing did not help;
reselecting Commit did (`followup-20261115/layout-state-control/`). Allocation
now uses the sidebar's existing `(workspace ID, view)` identity; initial view
publication also clears stale allocation after a real remount. Document,
repository and asynchronous lifetime timestamps/guards remain unchanged. This
adds six net production lines and no new owner or framework.

The real application regression covers Japanese 1.5x text, same-root refresh,
full unmount/remount and unchanged buffer identity/source. It fails with the
old allocation and passes with the correction (`sidebar-lifetime-{before,green}.log`).
All **299 application smoke cases pass**. Earlier invalid fixture attempts and
the inadequate initial native candidate remain recorded, without qualification.

`6cd76cb` corrects the Files-only watcher's test readiness. The pinned shared
`repository_watch.dart` deliberately invalidates after installing its watches
to close the initial status/watch gap. Under load this legitimate refresh landed
inside the fixture's measurement after a fixed one-second sleep (one status
call became two). The existing counting gateway now observes initial watch
invalidation and its completed status read before measuring editor attachments.
The strict zero-extra-scans assertion for ten repeated attachments, ordinary and
linked-worktree staging checks, trust-revocation assertion and staging deadline
remain. All **21 cases pass** in both an isolated diagnostic and the actual file;
analysis is clean. The first ignored diagnostic's void-event compilation error
is retained separately. No production Git or shared watcher code changed.

### Current source and verification results

The shipping source is production SHA-256
`793dcf728362205bece6bc7dee445dca9c968fa59c0fb9b68d44b0a708b63a56`, with AOT SHA-256
`cd1a1caf26f04c6089ab4b09320b3b1188517c2745bb40a1309f9fb073a52aa1`.
The producer receipt was captured before building at `15ac993` with the explicit
two-file changes later committed as `665b105`; those bytes match that committed
source. The subsequent fixture-only commit changes no production input.
The preserved 1,473-payload shipping bundle is
`followup-20261115/final-sidebar-release/bundle/`; all native matrix receipts
bind to it and the official mapped engine. Probe bundles separately identify
and hash their diagnostic entrypoints; they are not shipping executables.

| Verification | Result and raw evidence |
| --- | --- |
| Complete final Flutter corpus | All **243 entry files exactly once**, 22 complete-file batches: **5,706 passed, 0 skipped, 2 failed**. Autosave-after-branch deadline and RTL template-dialog initial settle timeout; `followup-20261115/complete-corpus/receipt.json`. The existing qualifier rejects it with `Full test corpus has not passed`; no waiver. |
| Official analyzer | Clean after the final fixture change: `followup-20261115/final-fixture-analyze.log`. |
| Maintained Dart formatting | All 665 tracked Dart files pass; verification copies/build outputs excluded. |
| Current archive/consumer/resolved audits | Exact shared trees, host consumer, resolved native audit and adversarial tests, all three host/design/sidebar audits and self-tests pass: `followup-20261115/current-audits.json`. |
| Unchanged shared suites | Engine **142**, shared UI **489**, native spelling **14**, Python **134**, shared native CTest **2** passed in the first verification phase. Their source/pinned inputs remain unchanged; see `shared-engine-serial.log`, `shared-ui-serial.log`, `spellcheck-native-tests-ready.log`, `python-suite-private.log`, `git-accessibility-tests.log`. |
| Localization/native services | Synchronization check and accent, credential policy, shortcut metadata, GTK host and libsecret scripts passed in the first phase; localization/editor/navigation cases are retained in the final corpus. |
| Actual shipping X11 presentation | **All 16** theme/locale/scale cases pass, including both Japanese 1.5x failures from the earlier build: `followup-20261115/final-native-matrix.json`. All **236** retained captures inspected in **30** labelled grids with full-resolution Japanese branches, narrow history, RTL and focused-filter checks; original hashes verified in `followup-20261115/final-native-review/`. |
| Shipping 100-natural-close gate | **Failed:** 76 exit zero, **23 SIGSEGV + 1 abort**; all 100 records/raw logs and zero unresolved descendants: `followup-20261115/final-natural-close/summary.json`. |
| Final-source native selection | **80/82 pass**. `10-drag-with-scroll`: clipboard; `12-cell-local-drag`: local range/clipboard. All editing/composition/retained-buffer Undo/Redo cases complete. Full fresh report, clipboard evidence and captures: `followup-20261115/final-selection-native/`. |
| Final-source actual application selection/history | **All 52 checks pass**, with clean ownership: `followup-20261115/final-application-selection-result.json`. Uses the real `application.main`, workspace buffers, tab restoration, Linux clipboard, composition and Undo/Redo; framework-dispatched keys/input, separately from physical pointer and shipping close gates. All 52 captures inspected in seven labelled grids; original hashes verified. |
| Final-source native focus | Wayland **Alt-Tab all 13 checks pass**, including the owned supervisor without cleanup/survivors: `followup-20261115/final-focus-native/`. X11 readiness fails; full Wayland minimize/restore times out waiting for resumed lifecycle after restore. Both failed gates remain under `followup-20261115/final-focus-x11/` and `followup-20261115/final-focus-full-wayland/`. |
| Installed BusyMark | Older **0.7.1 Snap revision 31**; changed payload not installed or accepted. Administrator authentication is unavailable. No install, push or publication occurred. |

The first follow-up corpus stopped after 14 passing batches when subsequent
source changes superseded it. A later frozen run ended with outer exit 143 after
19 complete batches, one watcher-fixture failure and interrupted batch 20. All
243 entry hashes matched before applying the fixture correction. Its incomplete
receipt remains at `followup-20261115/final-corpus/receipt.json`; the termination
cause was not isolated. The final run uses a new receipt and bounded groups of
complete files. No interrupted or changed-input output is used to qualify it.

The complete final run exposes a three-second autosave-after-history-branch
deadline failure, followed by a teardown/write race. The entire test file and
durable history store are byte-identical to the reviewed original; autosave code
is identical except for removal of the obsolete Workspace snapshot assignment
(`followup-20261115/autosave-source-comparison.json`). All 444 original baseline
production/lock inputs were verified again. The complete unchanged file passes
**178 cases on original and 178 on current production** serially, with the same
assertions and deadline (`history-autosave-comparison.json`). These repeats support
a timing concern, not a resolved root cause or proof of non-regression. The failed
full batch remains failed; no timeout, test or functionality was weakened.

The second full-run failure is the RTL template-creation dialog's initial
`pumpAndSettle` timeout. The test, production dialog and catalog service are all
byte-identical to the reviewed original (`template-dialog-source-comparison.json`).
The fixture advances real I/O for a fixed interval before settling; the exact
cause of this timeout remains unisolated. Complete serial original/current file
comparisons each pass all **14 cases**, with original assertions and timing
(`template-dialog-comparison.json`). They do not qualify the failed full batch.

### What remains unaccepted

The previous shipping build failed 32 natural closes with SIGSEGV and one with
a mutex abort in 100 runs. The original failed 27; the constructor-cleanup build
failed 18. The corrected shipping build still fails 24. A separate unchanged
SDK-template counter also fails one of 100 natural closes on the same official
engine (`followup-20261115/sdk-counter-natural-close/`). Different observed rates
do not establish improvement, non-regression, a common cause or an upstream fault.

Debugger traces on old and changed shipping builds show native rendering/driver
teardown while engine workers remain active: LLVM/Mesa cleanup in one capture
and EGL/NVIDIA loader cleanup in another. No root cause is claimed. Debugger-only
callback-drain, early-disposal and application-hold experiments failed to prove
a safe fix and were rejected (`followup-20261115/gdb-*`). No lifecycle workaround,
forced exit, delay, engine patch or retained closed engine was shipped.

The fresh selection report preserves the two failing assertions. The older
`selection-comparison.json` references two missing `/tmp` reports; those raw old
reports are explicitly missing, not reconstructed. The new complete 82-case
report is included in the handoff. Passing Alt-Tab focus does not qualify X11,
full minimize/restore, the independent official-SDK Wayland multi-engine gate,
or installed behavior. A first full-focus setup closed the ownership supervisor's
required input lease; its cancelled output contains no product assertion.
All recorded follow-up ownership cleanups leave zero unresolved descendants.

Earlier production native WebKit/renderers, large 10,001-note/30-cycle sidebar
workflow, X11 and Wayland spelling/editor-history/PDF/HTML exports passed; their
records remain in `web-render-native.log`, `visualization-native-ready.log`,
`sidebar-native-final.log`, `final-x11/` and `final-wayland/`. They are historical
coverage of that earlier source. The earlier compiled dirty-close/video fixture
still contains readiness failures and a visualization abort; its dependent
reopen was missing. None substitutes for final complete native acceptance.

The remaining failures need causal native investigation and actual payload-bound
installed acceptance. They do not justify restoring deleted implementations or
adding another architecture. This is a BusyMark-only follow-up; shared pins and
archives are unchanged, and no other consumer change is required.

### Portable evidence handoff

The separate local artifact is
`build/architecture-review/busymark-architecture-evidence-20261115.tar.gz`, with
an adjacent `.sha256` checksum. Include this artifact with a source handoff:
ordinary source exports omit the ignored `build/` directory. Its internal
`README.txt` explains path mapping and the historical missing reports.
`followup-20261115/final-evidence-integrity.json` verifies all 243 entry hashes,
all 22 raw-log hashes, current production/shared hashes and all 95 original/current
line rows. That check establishes the integrity of a complete **failed** run.

The separate archive includes raw passed/failed/incomplete logs, receipts,
original captures and inspection records, full debugger stacks, SDK counter
control source, exact source patches, toolchain/pin hashes, this report and the
95-file line inventory. `MANIFEST.json` records original paths, lengths and
SHA-256 for every included file. Private profiles, caches, downloaded
prerequisites, SDK/build binaries and source checkout copies are excluded.

Reading the records and verifying their hashes requires no Flutter/Dart SDK.
Re-executing the checks requires the pinned official toolchain and native
prerequisites. Hash integrity does not qualify failed or incomplete acceptance.
