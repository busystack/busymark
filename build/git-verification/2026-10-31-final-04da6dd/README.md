# Native Git sidebars and comparison tabs — final evidence, 2026-10-31

BusyMark now has independent Commit and Git Log sidebars in the existing view
switcher. Git Log shows the selected-commit button, bounded/scrollable commit
information, then independently scrollable Changed files. The button opens the
existing graph, refs, filters, navigation and ordered commit actions in a native
selector. Candidate navigation does not apply a selection. Confirmation does;
cancel/dismissal retains the previous immutable selection.

Staged, Unstaged and historical file activation opens ordinary workspace tabs.
Their identity includes repository/worktree, raw paths, typed endpoints,
immutable revisions/parent and mutable review context. Each mounted comparison
keeps its own renderer state. Existing tab chrome, activation, context actions
and dismissal own the lifecycle; authoring buffers remain mounted and unchanged.
Normal activation starts side by side; Unified remains available. File/hunk/line
transactions, search/navigation, scrolling/correspondence, native undo/composition,
index/conflict editors, draft versions and revision-bound consent remain in place.

The shared required GitPresentation contract supplies the actual approved host
controls and semantic styles. Both hosts implement it in their existing design
modules. Menus require their native services. Git comparison-tab context menus
also use that required service; unavailable service produces native operational
feedback. Native separators are semantic toolkit entries without a Flutter
rendering path. Generic host menus outside Git keep their existing behavior.
The exact control mapping and action-to-destination checklist are in
[the shared contract documentation](../../../../busystack_git_flutter/docs/native-presentation.md).

| Runtime input | Exact revision |
|---|---|
| Shared engine, unchanged | `07cf4a11ae3f0fd3bb97cafc38ea344826c684ef` |
| Shared presentation | `df529b9e35e56a29de1f4addd1223552ad934255` |
| BusyMark runtime | `04da6dd5df5f6c2b4c8031b03867a9394f883600` |
| BusyFiles runtime | `ddc0f9ece11d6a250e33a49362448ae0c9ec03bb` |

The original branches were shared/engine main, BusyMark feature/git-package and
BusyFiles Release/v0.0.1. Reference hashes were inspected, never reset targets.
The runtime revisions above precede this documentation/evidence commit. There
was no push or publication. Original DAV `75bdc14` and its unrelated IDE change
were preserved; BusyFiles keeps pin `18f636f`. Isolated verification materializes
that actual clean pin. The engine archive SHA-256 is `d59d3d326dd7bc381a12f6d9da9c70e8a17e38d802a8224adeb7dccb0f1dea6d`;
the presentation archive is `beb9e9e5ec477fd37dc4621010e9942ca48c016361e214c1e515db47ae20732a`.
Standalone shared and both consumer archive/checksum checks passed against the
sources actually compiled. No third-party source, version, binary or SDK patch
was introduced. Flutter 3.47.5 / Dart 3.13.4 remain the approved baseline.

[verification.json](verification.json) qualifies each test result by source and
records its log hash. The full engine suite passed 140 cases; shared presentation
386; shared real-repository tests 8. BusyMark's complete selected host/workspace/
Git/localization suite passed 735 before the final menu-only follow-up. That
follow-up passed six native contracts, eight dirty-dismissal cases, 44 existing
Git widget cases, all 44 source audits and the actual workspace/tab/native-close
regression. Two structural assertions were updated for the approved native field
and file-history placement, retaining the behavior assertions. The native hook
and real spelling suite passed 14 cases. Shared CTest passed 1 and BusyFiles
CTest 15. Both real host adapters exercised all 26 workflow surfaces and two
prompt kinds in light/dark contract tests. BusyFiles UI passed 676 with one
pre-existing skip; its final daemon/prompt/private-runtime IPC suite passed 16.

Resolved-symbol enforcement and deliberate rejection/approval self-tests passed.
The shared checker audits all Git feature sources in both hosts; BusyMark's
additional pinned-analyzer tool audits Git declarations and resolved Git enum
branches in the mixed workspace screen, including tab menus. Qualified symbols,
aliases, constructor/helper tear-offs, palette use and native-menu fallback paths
are covered. Empty/moved scopes and unresolved sources fail. CI and local
`tools/check_git_presentation.sh` run the checks on materialized pinned sources.
The permanent rule is in all three affected AGENTS.md files. Final shared/all-host
analysis and BusyMark analysis reported no issues; changed Files daemon/IPC
analysis also reported no issues.

The final release bundle built successfully. Its archive is
[busymark-final-04da6dd-linux-release.tar.gz](artifacts/busymark-final-04da6dd-linux-release.tar.gz),
SHA-256 `563d10450e395a72d588257094aace6cad35d396848024b30e50e481a181e8f6`.
[The runtime receipt](logs/final-mark-runtime-receipt.json) hashes the delivered
files and records SDK/GTK/system versions. The actual mapped official release
engine was `d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.
An ordinary source `flutter run -d linux --debug --no-pub` built, rendered an
actual staged comparison, and exited naturally 0. Its mapped official debug
engine was `7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`;
[the receipt](captures-final/debug-04-runtime-receipt.json) records the actual
child PID, executable and mapped library. The BusyStack-owned spelling hook now
accepts the official no-code-assets phase; no upstream hook/runtime modification
was used.

All final captures below came from the running final application. They are raw
X11/Xvfb pixels, 1440×1000 at 96 dpi, Openbox, accessibility enabled, actual
Yaru-blue host controls and official desktop settings portals. Device scale is
1.0. English uses text scale 1.0, German/Arabic 1.25, Japanese dark/narrow 1.5;
these are real text settings, not fractional display-DPR qualification.
[The capture manifest](logs/final-mark-captures.json) records source, locale,
mode and SHA-256 for every final image.

The recorder's legacy queryComponent geometry lookup returns AttributeError
under this GI binding. Those entries are harness errors, not application
geometry results. Semantics names/roles and real keyboard/pointer interaction
were inspected; they do not qualify Flutter text-field geometry.

| Required populated state | Capture |
|---|---|
| Commit, partial change and ordinary comparison tab | [Commit](captures-final/mark-final-04da6dd-commit-comparison.png) |
| Independent Staged and Unstaged tabs | [Working comparisons](captures-final/mark-final-04da6dd-independent-staged-unstaged.png) |
| Information before Changed files, long metadata | [Git Log](captures-final/mark-final-04da6dd-log-information-before-files.png) |
| Real graph selector, refs bounded after subjects | [Modal](captures-final/mark-final-04da6dd-history-selector.png) |
| Historical rename comparison and unsaved document tab | [Historical comparison](captures-final/mark-final-04da6dd-historical-comparison.png) |
| Selection change retains the open historical endpoints | [New sidebar selection](captures-final/mark-final-04da6dd-new-sidebar-keeps-historical-tab.png) |
| Multiple comparisons, genuine root absence | [Multiple tabs](captures-final/mark-final-04da6dd-multiple-comparison-tabs.png) |
| Real GTK tab menu | [Native tab actions](captures-final/mark-final-04da6dd-native-tab-context-menu.png) |
| Unsaved document/caret state and actual close guard | [Document](captures-final/mark-final-04da6dd-document-retained.png), [Guard](captures-final/mark-final-04da6dd-application-close-guard.png) |
| Enlarged, narrow, dark Japanese | [150%](captures-final/mark-final-04da6dd-japanese-narrow-inspector-150.png) |
| German and Arabic/RTL | [German](captures-final/mark-final-04da6dd-german-comparison-125.png), [Arabic](captures-final/mark-final-04da6dd-arabic-rtl-comparison-125.png) |
| Normal developer debug launch | [Debug](captures-final/mark-final-04da6dd-normal-debug-comparison.png) |

The fixture has a real merge/rename, a root commit, 12 refs and a 19-paragraph
message. rapid.md is HEAD 12 bytes / Index 15 / saved Working Tree 24. Historical
notes.md → docs/日本語-長い名前-review.md is parent 3600 / commit 3599 bytes.
Final repository receipts match HEAD, every index entry, status and every working
file hash to the baseline after captures, localization and debug close. An
exploratory script previously typed into the focused Git tree and staged an
untracked fixture file. That run was rejected and its failed receipt retained;
only that task fixture's index entry was restored to its recorded baseline before
final captures. No application data or user repository was reset.

All final English, German, Japanese, Arabic and debug processes exited naturally
0. Two pre-final Japanese runs aborted with g_mutex_clear; their logs remain in
captures/mark-ja*.log. An unchanged official Flutter-only close probe did not
reproduce the abort. A later GDB run and independent normal Japanese runs exited
0. No applicable upstream cause for those earlier aborts was established, and
this evidence does not erase them. The older AT-SPI geometry/descriptor and
multiple-engine Wayland failures recorded in
[BusyFiles' upstream investigations](../../../../busyfiles/engine/UPSTREAM.md)
remain separately unqualified. Full Windows, final hardware Wayland/fractional
DPR, external network/auth/signing and real IME/assistive-technology qualification
are unrun here. Dedicated performance acceptance remains deferred.

The normal Files packaging wrapper reaches its blocked pub.dev advisory lookup
while generating its SBOM. The final production compile/package and every
source/engine/payload gate were completed as retained individual standard stages.
The connected VM generated the supported SBOM from the same 15 exact hashed
inputs and source-date epoch. See [Files evidence](../../../../busyfiles/build/git-verification/2026-10-31-final-ddc0f9e/README.md).

Verification temporarily exhausted disk space and affected two pre-existing
running VMs. Space was reclaimed from task-only caches. At the final audit,
`busydata-installed-20261003` was STOPPED and `busynode-continuation-20261015` was
ERROR; both need operator recovery/consistency checks. No forced restart or
repair was attempted on those workloads. The originally stopped verification
VM `busyfiles-release24-20261005` was returned to STOPPED; the new task-only
container was stopped and removed after artifact/evidence export. Graceful
shutdown exceeded the initial deadline and completed without force. The original
host Flutter installation and unrelated DAV changes were preserved.
