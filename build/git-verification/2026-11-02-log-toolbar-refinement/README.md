# Git Log and comparison toolbar refinement — 2026-11-02

This records the bounded implementation and its verification. It is not overall
release acceptance. Independent Commit/Git Log sidebars, the full history
selector, ordinary comparison tabs, documents and Local History are retained.

## Sources, pins and changes

| Repository | Final runtime source |
| --- | --- |
| BusyMark, feature/git-package | `23781d8c7a46ddd4a2ba63d1981b3f69888ef6e6` |
| Shared Git UI, main | `b78c2170627b6d60bf8780f44cc79fcc84719fc3` |
| Shared engine, unchanged | `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b` |
| BusyFiles, Release/v0.0.1 | `309a230f59f1e2bd7cc22ab36bd1d65d9353528e` |

BusyMark implementation commits are `59f4240`, `1329831` and `23781d8`.
BusyFiles adapter/pin commits are `e92d214` and `309a230`. The later evidence-only
commit does not change these artifact/runtime revisions. Starting source and
working-tree receipts are retained; no repository was reset or pushed.

- Git Log retains selected commit → information → Changed Files. Its compact
  inspector has no information/file splitter or ordinary upper scrollbar. The
  subject occurs in the flat selected-commit button; the body has a bounded
  preview. Author/committer identity and human-readable host-localized dates are
  compact, with duplicate identities omitted. Native details/copy preserve the
  complete original message, emails, exact timestamps, full immutable IDs,
  references and every parent. The parent menu retains parent-specific review.
- Historical Changed Files use the existing required native tree-row adapter,
  directory grouping, correct status/rename identity and a sibling file-menu
  target. Keyboard hierarchy/navigation, captured immutable actions, per-owner
  state and late-response protection remain. Historical rows have no staging
  callbacks. Normal activation opens the correct ordinary comparison tab.
- One compact Commit Actions control uses the existing shared history actions.
  Repository Actions separates maintenance, remotes, current operation,
  organization, Clone and security. BusyMark omits duplicate branch operations;
  their full arbitrary-revision Merge/Rebase forms now have an Actions entry in
  the complete Branches modal, even when only the current branch exists. Clone
  and current-operation access remain because removing them would lose a
  verified destination. BusyFiles retains its existing repository menu choices.
- BusyMark comparisons omit the duplicate filename header. Required left/right
  identity/path labels remain. One measured native toolbar contains checked
  Side by side/Unified mode selection, navigation, display, search, refresh and
  contextual staging. Secondary actions use native overflow at narrow widths.
  Stage/Unstage file and selected lines remain distinct; hunk staging and the
  existing protected three-way editor are retained. Genuine absence is labelled
  Absent, distinct from an existing empty file; exact mode/bytes remain available.
- Required localized-date/glyph mappings are supplied by both hosts. A native
  inspection caught BusyFiles ignoring the inline button variant; it now maps
  to its existing `BusyFilesPushButton.flat`, as used by non-Git sortable file
  headings. BusyFiles navigation, descendant workspace eligibility and the
  authenticated typed daemon boundary remain unchanged.
- Native keyboard inspection caught global reading-order traversal interleaving
  the source editor with Log metadata. The actual Log inspector now has a
  narrowly scoped widget-order traversal group. Editor Tab authoring remains
  intact. Existing host smoke assertions additionally verify reverse traversal,
  Enter opening the modal, Cancel, and exact document editing-value/draft retention.

Principal shared files: `lib/src/log_view.dart`, `historical_change_tree.dart`,
`diff_view.dart`, `workflow_ui.dart`, `branch_views.dart`, `host.dart`,
`presentation.dart`, messages/localization registry, tests and native audit.
Principal BusyMark files: `lib/src/git/application/shared_git_integration.dart`,
`lib/src/app/busymark_design.dart`, all existing catalogs/generated output,
`test/src/git/log_comparison_native_test.dart`, `test/src/app_smoke_test.dart`,
and `tools/check_git_presentation.sh`. BusyFiles changes are its design adapter,
English catalog/generated adapter, contract tests and dependency records.

The maintained action-to-destination and native mapping checklist is shared
`docs/log-comparison-refinement.md`; both host AGENTS files record permanent
rules. No application-specific imports enter the shared package. No engine,
third-party source, SDK version, security or accessibility setting was changed.

Both consumers pin shared UI `b78c217`, archive SHA256
`f6734c0c8ec5d2b095a78cab15a6c91ba499d50f039796d68eded425ad9f2b30`,
tree SHA256 `da504356a762c52a32b2dfb7213b79eff44079f19d4376cd34bffed1e0c5e650`.
The engine pin and BusyFiles DAV pin `18f636f` are unchanged. The unrelated host
DAV checkout/IDE change was preserved; integrity was checked against the actual
approved materialized DAV source, not by moving its pin.

## Engineering results

| Final affected check | Result |
| --- | --- |
| Shared presentation tests | 399 passed |
| Shared real-repository comparison/staging/commit/conflict tests | 8 passed |
| BusyMark app/workspace/settings/localization/Git tests | 795 passed |
| BusyFiles authenticated Git IPC/daemon tests | 16 passed |
| BusyFiles Git UI/native adapter tests | 40 passed |
| Total affected tests | **1,258 passed** |
| Native CMake/Ninja and accessibility CTest | 1/1 passed |
| Resolved native audits, enforcement self-tests and host audit | passed |
| Production analyses and changed-source formatting | passed |
| Exact localization CI commands, generation/generated-clean checks | passed |
| Standalone shared and both consumers' source/pin/archive integrity | passed |
| Controlled Git and official Flutter workflow checks | passed |
| BusyMark Linux release | built, exported and ran |
| Ordinary BusyMark `flutter run -d linux --debug --no-pub`, lib/main.dart | built and ran |
| BusyFiles final debug UI and separate daemon | built and ran |
| BusyFiles final release wrapper | compiled; production-baseline gate failed |

The shared audit now rejects boolean comparison choice bars, including typedef
constructors/tear-offs; self-tests prove forbidden examples fail and legitimate
three-way integer choices pass. Existing Material/fallback checks remain. The
26 new BusyMark rendered native cases inspect actual host controls, disjoint
targets, geometry, flat shape and hover/pressed/focused/disabled states,
metadata completeness, menu anchors/keyboard behavior and en/de/ja/ar at scales
1/2 in LTR/RTL, light/dark and narrow/wide sizes. Four additional BusyFiles
rendered cases cover its actual inline adapter states, geometry and activation.
Existing staging, draft races, parent/rename, late-selection/menu callbacks,
editing consent, dirty close, Local History and comparison independence tests
remain enabled. Real repository tests use controlled Git and actual mutations.

`runtime/commands.jsonl`, `runtime/test-results.json` and lossless `.log.json`
transcripts retain commands and failed attempts. The initial BusyMark run had
two failures: strict German/Dutch localization rejected the new literal
Committer label (fixed in source), and a 3-second file-watcher timeout. The
unchanged watcher passed in isolation and both subsequent complete suites.
The final suite is `mark-host-tests-attempt3.log`; final BusyFiles suites are
the `attempt2` logs. No assertion was removed and no skip added.

BusyFiles' final release compiled successfully, then its existing producer
gate required Ubuntu 26.04 while this established VM is Ubuntu 24.04. The gate
was not bypassed; no qualified production package is claimed. Debug UI plus
authenticated daemon were verified on the actual final source instead.

## Native inspection and data integrity

Only `captures/accepted-*` and the two final keyboard-proof images are final
runtime evidence. Earlier images remain investigation and must not be cited as
current. Environment and individual SHA256 hashes are in
`runtime/native-captures.json`: established Ubuntu 24.04 VM, official Flutter
3.47.5 / Dart 3.13.4, X11/Xvfb + Openbox, 1440×1000, 96 dpi, DPR 1, default
desktop text scale, Yaru-blue, process locale en_US.UTF-8. Applications use
English/German/Japanese/Arabic RTL, light/dark; normal 1280×720, narrow 900×740
and German 1000×740 windows. Images are real final applications, not mockups.

- [Merge inspector and grouped files](captures/accepted-merge-info.png),
  [long subject/body](captures/accepted-long-info.png),
  [all parents](captures/accepted-parent-menu.png),
  [complete selectable details](captures/accepted-complete-details.png).
- [Commit Actions](captures/accepted-commit-actions.png),
  [file actions](captures/accepted-file-menu.png),
  [full history selector](captures/accepted-history-modal.png),
  [Cancel retains merge](captures/accepted-cancel-keeps-merge.png).
- [Repository Actions](captures/accepted-repository-actions.png),
  [full Branches](captures/accepted-branches.png),
  [general Merge/Rebase destination](captures/accepted-branches-actions.png).
- [Selected-line staging](captures/accepted-selected-lines.png),
  [staging menu](captures/accepted-staging-menu.png),
  [three-way editor](captures/accepted-three-way.png),
  [Unstage](captures/accepted-staged.png),
  [deletion/absence](captures/accepted-deleted-file.png),
  [narrow overflow](captures/accepted-narrow-overflow.png).
- [Independent historical context](captures/accepted-independent-contexts.png),
  [unsaved document with comparison](captures/accepted-unsaved-with-comparison.png),
  [real close guard](captures/accepted-close-guard.png),
  [Cancel retains document](captures/accepted-guard-cancel-keeps-document.png).
- [Native keyboard focus](captures/final-selected-commit-keyboard-focus.png),
  [Enter opens history](captures/final-keyboard-history-selector.png),
  [release trust screen](captures/accepted-release-untrusted.png),
  [accurate confirmation](captures/accepted-release-trust-confirmation.png).
- [German Log](captures/accepted-log-de.png),
  [German narrow comparison](captures/accepted-unstaged-de.png),
  [Japanese dark](captures/accepted-log-ja.png),
  [Arabic RTL](captures/accepted-log-ar.png).
- [BusyFiles descendant workspace](captures/accepted-files-workspace.png),
  [native flat toolbar](captures/accepted-files-toolbar.png),
  [checked mode menu](captures/accepted-files-mode-menu.png),
  [Unified](captures/accepted-files-unified.png).

Native actions confirmed history cancellation/selection, separate file menu and
row targets, selected-line review, existing three-way editor, independent tabs,
trust Cancel/authorize/revoke/restart, mode changes, overflow and keyboard focus.
No native capture staged or committed fixture data. Only a task-owned unsaved
README draft was typed and explicitly discarded through the real close guard.

The initial raw fixture comparison detected a changed index checksum. Exact
mode/blob/flags and all working files/HEAD/config/refs were unchanged. A separate
probe without BusyMark reproduced Git status updating an index stat-cache size
while preserving index contents. Original receipts and the probe are retained;
this is not hidden as a mutation. The later frozen localization receipt remains
byte-identical across all 23 recorded entries, including the index.

Read-only debug diagnostics used the installed official vm_service API to
inspect focus/creator chains; all native keyboard activation used actual X11
input. A capture helper's unnecessary mouse-sync wait was removed through the
supported xdotool API. Early focus probes reached the editor, where Tab correctly
authored text in the own unsaved fixture; that draft was explicitly discarded.
Negative probes remain in the evidence and are not successful focus claims.

## Artifacts and independent limitations

Final local BusyMark archive:
`/home/albert/busystack/.native-git-verification/log-toolbar-refinement/busymark-23781d8-linux-release.tar.gz`.
SHA256 `9e8d7dbfa9b2c1202dde8201d8a8a70ed63c7b5b53cc9f262dea0e6cb3df0a2d`.
`runtime/release-runtime-receipt.json` binds every file to source and pins.
The official mapped release engine hash is
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`;
debug is `7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`.
SDK tracked source is clean. The raw evidence archive and checksum are recorded
in `evidence-archive.json`. The large exploratory widget-tree dumps and complete
interaction trace remain in that local archive and the ignored extracted files;
the committed receipts retain the focused probes, final source bindings and
failed-attempt logs without duplicating those large diagnostic dumps.

Flutter body AT-SPI exposure remains limited; widget semantics and native
accessibility tests still run, and desktop accessibility was not changed.
Existing debug-close FlutterEngineRemoveView warnings/intermittent shutdown
instability remain qualified. Enlarged/fractional actual desktop, Wayland,
Windows, strict Snap credentials, network/signing and dedicated performance
qualification remain incomplete. Passing widget scale tests or Linux builds
does not establish those platform results. The previous disk/VM incident remains
separate under `../2026-11-01-followup/incident`; this run had no disk failure.

Task-owned native applications and the daemon exited before the recorder was
stopped. Failed-attempt journals were copied before resetting only the three
task-owned failed units. The guest then reported running with zero failed units
and an empty dpkg audit. Approximately 16 GiB remained free in the guest and
36 GiB on the host; builds ran sequentially. The QA VM was gracefully returned
to its original STOPPED state. BusyData and BusyNode stayed RUNNING, BusyMax
stayed STOPPED. No VM configuration or unrelated workload was changed.
`runtime/environment-before-closure.json`, `environment-closure.json` and
`host-closure.json` record these results. Nothing was pushed or published.
