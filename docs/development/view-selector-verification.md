# View selector implementation and verification — 2026-11-12

**Status: the live selector failure is fixed and verified; native acceptance
remains incomplete because of shutdown failures.** The
[dispatch investigation](view-selector-dispatch-investigation.md) records the
actual IDE executable/profile findings, the reproduced Linux menu rejection,
and the additional Num Lock failure missed by the earlier X11 acceptance.
Verification uses the unmodified official toolchain and real native keyboard
input; earlier source-only and socket-blocked results are not acceptance.

Both live shortcut events reached their registered commands and existing menu
controllers, but the controllers waited indefinitely for unrelated Num Lock
state to clear. They now wait only for the effective binding's trigger and
concrete modifiers. No user shortcut overrides were reset. The regression failed
before the correction and passed afterward; the workspace integration regression
also retains Num Lock through hidden-sidebar reveal and remapped commands.

The fully restarted desktop process passed both selectors, all 12 mnemonic
selections, effective Settings rows and tooltips, Source focus/text preservation,
and Shift+F10/Menu behavior. Its native Wayland connection and retained Num Lock
state were inspected. Fresh isolated ordinary and Writerside/Git profiles on
the same Wayland desktop also passed all 12 available/unavailable letter checks
and exited with code 0 under the debugger. Those passing closes do not waive
the failed native matrix or the earlier desktop shutdown crash below.

## Resulting behavior

F9 toggles the sidebar. The configurable Ctrl+Shift+F9 and Ctrl+Shift+F10 commands
open the existing Sidebar View and Content View selectors. Opening Sidebar View
reveals a hidden sidebar. The fixed F/T/O/C/G/L/B/R and E/S/R/D letters appear in
the existing menus and activate immediately. Disabled entries retain their
letters, consume those letters without activating, and are checked again when a
selection returns. Arrow/Enter/Escape navigation and retained editor focus work
through both GTK and the existing Flutter fallback.

The Linux runner now accepts disabled members of a single-choice menu group,
while preserving all packet checks and the at-most-one-selected invariant.
Previously, this first-party validator rejected legitimate contextual entries
before GTK could show either menu. Configuration documents expose Source only;
commands and menu activation share the renderer's document-capability check.
Unrelated fallback menus retain their normal entries without mnemonic wrappers.

Both existing selector buttons use the fixed `YaruIcons.display_layout` icon.
Tooltips and accessible names reflect the effective keymap, including custom
bindings and explicit null overrides. All 23 catalogs use localized Dual labels;
German and Spanish also pass the existing translation-coverage audit. Relevant
mode documentation now says Dual; stored `split` preferences and command IDs
remain compatible.

Numeric sidebar/content defaults and Git-local action bindings are retired.
Existing Git controls, menus, authoring navigation and standard Linux control
behavior remain. The shared host policy also covers comparison/conflict and
rebase-plan action bindings; BusyFiles retains its default policy. The global
Ctrl+Shift+P Command Palette remains available with Git focus. Shift+F10 and Menu
open the focused Source control's existing context menu; Ctrl+Shift+F10 opens
only Content View.

## Verification

| Check | Result |
| --- | --- |
| BusyMark full Flutter suite, unfiltered, no skipped cases | 5,815 passed across 249 files; zero failures/skips; unchanged inputs |
| Focused selector regressions and Num Lock workspace integration | 19 selector tests and the workspace regression passed |
| Shared Git Flutter full suite | 489 passed |
| BusyMark analysis of `lib`, `test`, `tools` | Pass, no issues |
| Linux debug build of production `lib/main.dart` | Pass |
| Sealed source and complete payload verification | Pass |
| Actual Wayland desktop, normal profile and fresh isolated profiles | Both selectors and all 12 letters passed; Settings, focus and standard context keys verified |
| Real native keyboard matrix: ordinary/Writerside × Git/non-Git, plus custom bindings | All five keyboard workflows passed; four accepted cases, Writerside/Git/default fails shutdown |
| Shared native C++ accessibility and sidebar tests | 2 targets passed |
| Native shortcut metadata round trips and rejection checks | 6 round trips, 5 safe rejections passed |
| Native workflow, geometry, build/package receipt and full-corpus verifier contracts | 65 passed |
| Resolved shared Git, BusyMark Git host and sidebar presentation audits | Pass |
| Shared architecture, host, sidebar and design-boundary adversarial self-tests | Pass |
| Official Flutter 3.47.5 / Dart 3.13.4 and reviewed upstream dependency identities | Pass; 1,171 SDK artifact files plus framework source checks |
| Broader design-dependency boundary audit | Seven pre-existing violations; see below |

The native matrix uses actual GTK menus and X11 keyboard events in a private
Xvfb/D-Bus desktop, with separate real workspaces and settings profiles. It
requires checked-state activation for every fixed letter, contextual disabling,
hidden-sidebar reveal, effective tooltips and actual Settings rows, both
selectors' restored Source caret, exact typed/saved/undone text, and standard
Shift+F10/Menu menus. Writerside configuration files retain only Source as an
available view. Custom F6/F8 bindings exercise the same production registry and
menus. Git shortcut checks first verify focus on a real native Git change row;
they retain the application Command Palette and unchanged-repository check.
Each case must exit naturally and satisfy source, complete payload, mapped
engine, credential-service and fixture-integrity gates.

Full-suite failures found during this work were corrected without removing
assertions: view regressions now use retained commands; historical Git reviews
select their actual commit; application versus Git search follows the host
shortcut policy; keymap reset tests retain both editing-alias conflicts and
retired numeric-default coverage. Real-I/O fixtures explicitly settle monitor
notifications, dispose workspace providers before pending-timer invariants, and
run real directory setup in the widget tester's I/O zone. Retention/protection,
undo/redo/save/reopen, draft, focus and lifecycle checks remain intact.

Current evidence is retained in `build/live-selector-investigation/`, including
`full-corpus-{start,result}.json`, `full-corpus.log`, `source-build.json`,
`bundle/`, `native-matrix/`, `cold-process-identity.json`,
`cold-native-socket-peers.json`, the live/cold menu and Settings observations,
and the two completed `wayland-clean-*/result.json` probes. The full run used
the original test timeouts and all native prerequisites. An earlier incomplete
attempt with two Git timeouts during concurrent verification is preserved in
`resource-contention-attempt/`; it is not counted as passing. The final complete
run passed those same tests without changing their timeouts or assertions.

Earlier evidence remains in `build/selector-native-final/`, notably
`full-corpus.log`, `full-corpus-start.json`, `full-corpus-result.json`,
`shared-tests-final.log`, `analyze-complete.log`,
`source-ready.json`, `bundle-ready/`, and `native-complete/`. Native cases
include command logs, accessibility states, screenshots, effective Settings
rows, per-case results and complete lifecycle/integrity receipts. The production
source hash matches the sealed bundle; tests and documentation do not substitute
for that binding.

## Native shutdown blocker

The current `build/live-selector-investigation/native-matrix/matrix-result.json`
remains failed. The Writerside Git default case completed its selector, mnemonic,
availability, focus, context-menu, global-palette and Settings checks, then failed
`naturalExit`. Its repository remained unchanged and its mapped engine matched
the approved SDK. The application logged an invalid implicit-view removal;
the kernel recorded a Flutter I/O-thread segfault in Mesa/libgallium at shutdown.
Four other cases, including custom bindings, passed every gate. No failed case
was replaced with a passing repetition.

An earlier real Wayland desktop process also segfaulted in `gtk_main_do_event`
when closing after its successful keyboard checks. Fresh isolated ordinary and
Writerside/Git Wayland runs subsequently exited normally under GDB. That does
not establish a correction to the intermittent GTK shutdown failure; it remains
recorded separately from the demonstrated Num Lock correction.

The previous `build/selector-native-final/native-complete/matrix-result.json`
also remains failed. Its Writerside Git custom F6/F8 case completed the keyboard
workflow, then aborted on exit with
`g_mutex_clear() called on uninitialised or locked mutex`. Its unchanged-repository
receipt does not excuse the failed `naturalExit` gate.

A debugger repetition of the same complete custom workflow exited normally. It
is diagnostic evidence, not a waiver or a replacement passing acceptance result.
The original failed receipt, log and final frame are preserved. Short focused
shutdown probes and independent controls are retained beside them.

A separate minimal app created by official Flutter, using only MaterialApp,
Scaffold and CircularProgressIndicator, crashed with SIGSEGV in 6 of 40 natural
X11 closes. All 40 mapped-engine checks match the approved official artifact.
The SDK runner and dependencies are unmodified and this control contains no
BusyMark or shared Git code. An additional debugger campaign reproduced 5
SIGSEGV exits in 24 runs. Its captured stacks show Flutter's raster thread in
Mesa/libgallium while the main thread is in process-exit cleanup. This matches
the failure pattern documented in [Flutter issue #189379](https://github.com/flutter/flutter/issues/189379).
That is evidence of an independent upstream exit failure on this toolchain; it
**does not establish a shared cause for BusyMark's mutex abort**. A non-debugger BusyMark repetition then reproduced the exact SIGABRT with core
capture enabled only for its private child. Post-mortem inspection identifies
`FlCompositorOpenGL`; its `frame_mutex` is still contended (value 2) when the SDK
dispose path calls `g_mutex_clear`. The stack and GType/mutex inspection are in
`core-shutdown-probes/2/{core-backtrace,mutex-owner,mutex-type}.log`.

The same exact abort is independently reproducible with a small control app
containing no BusyMark or shared Git code. It uses the official generated runner,
public GTK/libhandy window/overlay APIs, transparent FlView background, animated
CustomPaint, and the same pinned official window packages. Nine of 20 natural
closes abort; 11 exit normally. Its retained core identifies the same
`FlCompositorOpenGL` disposal, with the frame mutex locked (value 1). See
`hdy-control-campaign/9-plain/{result.json,core-backtrace.log,control.core}` and
`hdy-core-evidence.json`. Both controls' mapped engine hashes equal the approved
SDK's `7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`.

The simpler window_manager-only control passed 40 closes, and its Yaru window
state variant passed 30. Those passing controls and debugger repetitions do not
waive either failed matrix or the matching independent compositor abort.
Official publisher archives were hash-checked against BusyMark's lock and every
archived file compared for window_manager, yaru_window_linux, yaru_window and
its platform interface; `native-plugin-integrity.log` records the matching files.

The native blocker therefore remains a demonstrated Flutter/libhandy teardown
failure under the approved dependencies. No supported first-party correction
has been demonstrated. SDK/dependency patching is prohibited by the engineering
policy; acceptance remains incomplete pending a supported upstream correction.
No renderer substitution, engine patch, dependency downgrade, forced successful
exit, or relaxed lifecycle check was applied.

The minimal source, build logs, complete natural-close results, mapped-engine
identities and debugger stacks are under `shutdown-control/`,
`stock-private-campaign/`, `stock-gdb-shutdown/`, `shutdown-window-manager-control/`,
`shutdown-yaru-control/`, `shutdown-hdy-control/` and their campaign directories
within the evidence directory. CPU affinity and per-child core/debugger opt-ins
are diagnostic settings and are recorded separately from the normal native
matrix; no system-wide debugger or coredump setting was changed.

## Existing repository gate

The broader design-boundary audit reports the same seven Files VCS decoration
violations reproduced on untouched baseline `3a6d769`. Evidence is in
`build/view-selector-acceptance/evidence/baseline-design-dependency-audit.log`
and `build/selector-native-final/design-boundary-final.log`. These concern the existing
`gitTreeDecorationStyle`, `busyMarkFileTreeDecorations`, `GitFileTreeDecorations`,
`GitTreeDecoration`, and import ownership. Both this gate and the Files decoration
helpers required by AGENTS.md remain intact. Passing Flutter analysis does not
claim this independent audit is green.

The earlier BusyFiles-wide prerequisite also has an unrelated existing DAV
revision mismatch; no sibling checkout was reset. The shared Git revision/pins
remain local commits `0a24349` and `1cd96cb` in the shared package and BusyFiles.
No application changes were pushed or artifacts published. No SDK, framework,
Yaru package or other third-party source/version was changed.
