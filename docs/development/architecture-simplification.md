# Architecture simplification against the v0.7.2 review

The cleanup removes **6,761 production lines (2.99%) and eight source files**.
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
Production inputs remain frozen at `5ad719b`.

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
| Physical production lines under `lib/src` | 226,164 | 219,403 | **-6,761 (2.99%)** |
| Git controller | 2,439 | 769 | -1,670 |
| Shared Git host gateway | 949 | 204 | -745 |
| Rich editor | 11,291 | 10,824 | -467 |
| Workspace screen | 16,606 | 16,439 | -167 |

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

The remaining 16,439-line workspace screen and 9,726-line workspace controller
still concentrate real product responsibilities. Their size is documented,
not presented as solved by deleting unrelated behavior or adding abstractions.

## Verification record

Evidence lives in `build/architecture-review/` in this checkout. Logs from failed
or incomplete attempts are retained; later passes do not relabel them.

The unchanged baseline analyzer passed. Its first complete test invocation
reported **5,732 passed, 68 skipped and 37 failed**. Thirty-five failures lacked
the required native Git process supervisor; the remaining two were save/reopen
timeouts under load. Both save cases passed on unchanged code in an isolated
repeat after prerequisites were supplied. This baseline is not described as
green.

Official Typst/D2 artifacts, all supported spelling dictionaries, the native Git
supervisor and an owned Xvfb were prepared with the existing tooling. The complete
retained corpus runs without name filters; the six deleted entry files cover
only the deleted implementations listed above. Native/test resource failures
were investigated separately from product regressions.

The first deletion group passed 328 focused cases (six resource-dependent PDF
cases were skipped before Typst was prepared). The reference/input regression
group passed 26 cases. The candidate retained Git suite passed 298 cases; the
additional real AI patch/identity test group passed three cases. The applied
source analyzer is clean. Final complete-corpus and native results follow;
their recorded failures do not qualify release acceptance.

### Final verification

| Check | Result and evidence |
| --- | --- |
| Complete host Flutter corpus | All 243 entry files exercised exactly once: **5,706 passed, 0 skipped, 1 failed**. The failure is the unchanged Chromium retirement deadline in the CRLF CSS case. Full record: `full-corpus-isolated/receipt.json`. This is a complete failed run, not a qualified pass. |
| Full-corpus artifact qualification | The existing packaging helper refuses this receipt with `Full test corpus has not passed`: `final-corpus-qualification.log`. No exception or waiver was added. |
| Evidence integrity | All 243 entry hashes, imported host inputs, exact shared archives, 20 raw-log hashes, 95 line-inventory rows and both copies of the sealed 1,473-payload release bundle verified: `final-evidence-integrity.json`. This verifies the recorded failed execution, not acceptance. |
| Official analyzer | Clean after the last test-only corrections: `final-frozen-analyze-ready.log`. |
| Dart formatter | All 665 tracked Dart files, zero changes: `final-maintained-format.log`. Generated verification copies/build artifacts are excluded from this maintained-source check. |
| Final fixture corrections | All 114 Notes/account/source-audit cases passed: `final-fixture-verification-ready.log`. All 302 structured editor cases passed: `final-structured-fixture.log`. |
| Shared engine complete suite | 142 passed serially: `shared-engine-serial.log`. |
| Shared UI complete suite | 489 passed serially: `shared-ui-serial.log`. |
| Native spelling package | 14 passed after resolving its own locked native-asset graph: `spellcheck-native-tests-ready.log`. |
| Python tools suite | 134 passed with system Python and private native prerequisites: `python-suite-private.log`. |
| Shared native accessibility | Both CTest cases passed: `git-accessibility-tests.log`. |
| Native architecture boundary | Resolved final-source audit passed: `final-native-audit.log`. Adversarial ownership/resolution tests passed: `native-audit-adversarial.log`. |
| Host Git, design and sidebar audits | All three final resolved checks passed: `final-check-resolved.log`, `final-design-resolved.log`, `final-sidebar-resolved.log`. All three corresponding `--self-test` runs passed. |
| Localization synchronization | Existing host synchronization `--check` passed: `localization-sync-check.log`; full host localization regressions are part of the corpus. |
| Native GTK/services | Accent, secure credential policy, shortcut metadata, GTK host and libsecret scripts passed in their `test_*.log` files. |
| Native WebKit/rendering | Production web-render host completed 34 operations: `web-render-native.log`. Complete renderer corpus passed: `visualization-native-ready.log`. |
| Large native search workflow | Passed with 10,001 cached notes, real GTK shortcuts, history cancellation, keymap reassignment/reset, RTL and 30 open/close cycles: `sidebar-native-final.log`. The measured descriptor count was 31 before and 29 after those cycles; this is a single-run lifetime check, not a before/after architecture benchmark. |
| Release export/spelling | Both final-source X11 checks passed with exit 0 and `ok: true`: spelling/editor-history transactions and compiled PDF/HTML export. See `final-x11/results.json`. |
| Wayland | All three final-source checks passed: spelling transactions, full native renderer corpus and compiled PDF/HTML export. See `final-wayland/wayland-results.json` and its spelling/export JSON reports. This does not close the independent SDK multi-engine lifecycle gate. |
| Final release build | Official unmodified SDK build passed: `final-release-build.log`. The preserved bundle and sealed 1,473-file payload receipt are under `final-release/`. Its mapped release engine matches the official SDK artifact SHA-256 `d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`. |

The final complete-corpus run completed with one failure. Its receipt is
`full-corpus-isolated/receipt.json`: all 243 discovered entry files are assigned
exactly once to 20 complete-file batches using the official SDK's
`flutter test --no-pub --concurrency=2 --reporter=expanded`. Entry files,
production inputs and raw output logs are bound by SHA-256; the local committed
test helpers also remain unchanged. No case-name filters were used.

The CRLF custom/built-in CSS case failed during Chromium retirement after its
five-second deadline. The ownership report records no unresolved child
processes after cleanup, but the unchanged strict retirement check still fails
the test (`full-corpus-isolated/09.log`). The test, browser helper, HTML export
service/styles/models and stylesheet are byte-identical to the original
reviewed commit. This failed batch is retained and is not replaced by an
isolated repeat in the complete-corpus receipt.

The complete unchanged HTML options file then passed all 16 cases on original
production and all 16 on final production, sequentially, with the same browser
ownership and five-second retirement checks. See `html-options-comparison.json`
and `html-options-{baseline,current}-isolated.log`. These repeats support the
fixture-timing diagnosis; they do not turn the complete failed corpus into a
qualified pass or establish a Chromium root cause.

The preceding frozen-input attempt stopped after twelve batches with 3,275
passes, no skips and one 30-second real-store content-search timeout. Cleanup
then raced the unfinished capture. That case captures 96 durable revisions
while another complete store file also performs substantial disk work. Its
test body, capture path and content-search algorithm are unchanged from the
reviewed source. The original complete controller file passes in isolation
(130 cases in seven seconds, `history-baseline-isolated.log`). The fresh full
schedule runs the controller and store files separately, preserving every test,
the required command, and all existing deadlines; those final files pass all
130 and 93 cases respectively. The failed incomplete receipt and its logs remain
under `full-corpus-frozen/`; they do not qualify a pass.

Earlier attempts affected by exhausted `/tmp`, a slow secondary-volume temporary
directory or incomplete compiler/font resources are also preserved as failures
or incomplete runs. No failed log is rewritten or reused as a passing record.

The failed first corpus attempt stopped during batch 12 after exposing remaining
editor fixture ownership, a Notes timing failure and an incorrect standalone Typst
path without the bundled fonts. The editor fixtures were corrected in
`0137003`; the entire unchanged Notes workflow file passed its repeat (54
cases); all nine PDF option rendering cases passed using the complete bundle.
Those earlier logs have not been changed or reused to qualify the final corpus.

Later complete-file diagnostics exposed two source-audit anchors for deleted
implementations, a retained-history replay assertion and a pre-existing Notes
fixture race. The source audit now checks the real search header, command map
and Files staging boundary. The editor case retains its initial physical Enter,
publication and focus checks, then verifies exact leading-blank-line source
through Undo/Redo and the production parser's heading result. It no longer
expects a transient empty paragraph object from the removed private stack.

The unchanged original Notes fixture reproduces the Pause failure on the
original production code (`notes-baseline-pair.log`). Its fixed sleeps did not
wait for enabled actions or published pause state, and failure cleanup could
wait for real I/O without advancing Flutter's fake clock. The corrected fixture
uses the existing bounded `pumpUntil` helper for those observations and drains
held work in `finally`. All cache, paused-state, download-count, unrelated-failure
and disposal assertions remain; no production Notes code or test-case timeout
changed. The corrected complete Notes/account files pass on original production
(71 cases, `notes-pumped-ready-candidate.log`) and with the final production and
source audit (114 cases, `final-fixture-verification-ready.log`). An initial
focused command named a nonexistent account test path; its failed invocation is
preserved separately as `final-fixture-verification.log`.

The final shipping release failed the existing 100-natural-close gate: 32/100
runs exited with SIGSEGV and one with a mutex abort
(`close-final-release/summary.json`). An isolated build of the original reviewed
commit failed with SIGSEGV in 27/100 runs (`close-baseline-release/summary.json`).
All 444 tracked baseline production/lock inputs were checked byte for byte
against the original commit; none differed (`baseline-native-integrity.json`).
Both builds use the same official engine. The mutex symptom is also documented
in the earlier [sidebar acceptance record](sidebar-ui-consistency.md). These
comparisons establish pre-existing native failures, not an isolated root cause
or proof of an upstream defect. The gate remains open.

The complete final Git matrix exercised all 16 theme/locale/scale combinations:
14 passed; both Japanese scale-1.5 cases failed to expose the branch-action
target (`native-final-cases/cases.json`). The unchanged original build reproduces
that failure (`native-baseline-ja/`). Earlier menu timeout attempts are retained
under `native-git-final/` and `native-git-final-repeat/`. All 204 retained named
captures/failing checkpoints from this final matrix were inspected in 22 labelled
grids, with additional full-resolution checks of narrow filter focus, RTL history, scaled branches and
the failing Japanese state. Originals and hashes remain intact in
`native-review/original-images.json`; the inspection record states its limits.
Existing cramped/clipped scaled sidebar actions remain visible. A partial
matrix is not presentation or installed-app acceptance.

The compiled close fixture exercised dirty Save/Discard/Cancel, reopening,
initialization and visualization/video lifetimes. Its first 33 records had three
video-readiness failures on Xvfb. The installed WebKit's supported software
renderer made all three video cases pass without changing assertions or
disabling its sandbox (`close-video-software/`). The complete software-rendered
repeat produced 32 records with one visualization mutex abort; its dependent
reopen did not run (`close-live-software-final/`). This remains a failed native
gate, not a qualified complete pass.

The compiled selection probe completed 82 cases: 80 passed, while the same two
read-only drag/clipboard cases fail on the original reviewed build. Every
editing/history/composition case completes against the retained buffer owner;
the unchanged failing checks were preserved (`selection-comparison.json`).
The actual-host editor focus control could not reach readiness on its private
compositor in either attempt; it yields no passing product assertion. Ownership
cleanup reported no unresolved descendants. See `focus-native-editor*.log`.

Native search initially exposed stale fixture assumptions. Its read counter
observed only `readRevision`, although both original and current production
already use `readRevisions`. The existing wrapper now counts those requests and
still delegates to the real file store. The selector also uses fixed E/S/R/D
mnemonics independently of direct command shortcuts
(`workspace_screen.dart`, `_documentViewMnemonic`); the probe now verifies that
the view remains selectable, its bytes remain unchanged, and direct shortcut
metadata is unassigned. No production keymap or cancellation behavior changed.
The complete large-probe result is recorded in `sidebar-native-final.log`.

Installed applications require separate payload-bound acceptance under
`docs/git-ui-acceptance.md`; a build or screenshot is not a substitute. The
installed BusyMark Snap is older than these changes. This checkout has no
BusyFiles consumer/installed application, so final installed acceptance for both
hosts cannot be established here. Shared pins/archives are unchanged and need
no consumer refresh. No package was installed, pushed or published.
