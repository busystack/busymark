# View selector implementation and verification — 2026-11-11

Status: implemented and built; **acceptance is incomplete**. No passing native
keyboard or full Flutter test result is claimed.

The follow-up [dispatch investigation](view-selector-dispatch-investigation.md)
records the real profile and screenshot findings, reproduced focus/context-menu
defects, corrections, opt-in native tracing, and the remaining acceptance block.

The existing selectors now open through configurable command-registry actions
(Ctrl+Shift+F9 and Ctrl+Shift+F10). Their fixed Latin mnemonics are displayed in
the native menu accelerator column and dispatched only by the open menu. GTK
retains arrow/Enter/Escape behavior. The existing Flutter menu fallback handles
the same letters. Keyboard opening waits for trigger releases before GTK grabs
input; selector dismissal restores the retained focus target.

Sidebar selection reveals a hidden sidebar, including below the responsive
breakpoint. View availability is contextual and checked again on activation.
Both selector buttons use `YaruIcons.display_layout` at their existing locations.
Tooltips and accessible names use the effective keymap. All 23 catalogs and their
generated code use Dual and the updated selector/toggle labels; Writerside's
selector entry is Table of Contents.

The numeric view defaults and the host's Git action dispatcher are removed.
BusyMark also disables shared comparison/conflict and rebase-plan action shortcuts through a
host policy. Standard control navigation/editing/context-menu behavior remains.
The existing Git controls and menus retain their actions. Ctrl+Shift+P reaches
the application Command Palette. The shared policy defaults preserve BusyFiles'
existing behavior. Both consumers carry the same new shared archive.

The additional action audit covers comparison Ctrl+F, F3/Shift+F3, F4,
F7/Shift+F7 and Alt+Left/Right; conflict/review Ctrl+Alt+Left/Right and
Ctrl+Alt+K; and rebase-plan Alt+Up/Down. Standard text editing, list selection,
arrow traversal and menu activation remain control behavior.

Regression coverage includes all 12 letters, reordered menus, unavailable
choices, keyboard focus and dismissal, trigger releases, configured/default
labels, all locales, numeric retirement, the F10 conflict, Git action policy,
and standard Shift+F10/Menu behavior. Existing lifecycle/navigation assertions
now invoke retained view commands instead of retired numeric defaults. Native
acceptance drivers use the existing selectors rather than retired bindings.

| Verification | Result |
| --- | --- |
| BusyMark analysis of `lib`, `test`, `tools` | Pass, no issues |
| Shared Git package static analysis | Pass, no issues |
| Official Flutter 3.47.5 / Dart 3.13.4 integrity, installed SDK and writable test copy | Pass against the reviewed publisher manifest; 1,171 artifact files per SDK plus framework source identity checks |
| Linux debug build | Pass |
| Final binary source/payload receipt | Sealed and verified |
| Shared native presentation audit, including BusyMark host rendering | Pass, working sources and extracted pinned sources |
| BusyMark resolved Git host audit | Pass, working sources and extracted pinned sources |
| Shared native architecture adversarial tests | Pass |
| BusyMark Git host, design-dependency and sidebar audit self-tests | Pass |
| Actual resolved sidebar presentation audit | Pass |
| Receipt, native package receipt and full-corpus evidence Python tests | 18 pass |
| Localization catalog checks | 23 catalogs pass |
| Git source archive/tree validation | Pass for both consumers and materialized archives |
| Focused Flutter tests, including the new mnemonic suite | Blocked during test loading; zero tests executed |
| Full BusyMark and shared Flutter suites | Cannot execute in this session |
| Ordinary/Writerside × Git/non-Git native keyboard matrix, plus custom keymap case | All five blocked before application launch |
| Broader design-dependency boundary audit | Seven existing violations; reproduced on untouched BusyMark baseline `3a6d769` and on pinned sources |
| Official workflow contract tests | 28 pass; two real-X11 scenarios blocked by the sandbox |
| Full BusyFiles dependency prerequisite check | Existing DAV revision mismatch; Git pins separately pass |

Flutter fails to bind its test server at `127.0.0.1:0` with `Operation not
permitted`. Native acceptance fails when the private D-Bus daemon binds its Unix
socket; the X11 geometry tests encounter the same restriction. Automatic
approval review rejected execution outside the sandbox because sandbox
escalation is disabled. A session permitting these local sockets is required
to run the affected and full Flutter suites and actual application acceptance.
The existing native/spelling prerequisites in the Linux CI workflow still apply.

The broader boundary audit rejects `gitTreeDecorationStyle`,
`busyMarkFileTreeDecorations`, `GitFileTreeDecorations`, `GitTreeDecoration`, and
the corresponding existing import. The same seven violations occur in the
untouched baseline. Both the gate and the Files decoration helpers required by
AGENTS.md are preserved; they have not been relaxed or refactored to obtain a
passing result.

BusyFiles' existing DAV prerequisite expects
`18f636f3227e3df8c1406bafd85b45e7f12cf8bd`; its sibling checkout is
`75bdc14ff793a2cf41c0632500dbdfd32d1910a2`. No unrelated checkout was reset.
The shared Git source change is local commit `0a24349`, and the corresponding
BusyFiles pin update is local commit `1cd96cb`.

Evidence is retained under `build/view-selector-acceptance/`, including
`git-native-source.json`, final build/analysis/audit logs, the baseline audit,
Flutter socket failures, and `native-final/matrix-result.json` plus per-case
D-Bus diagnostics. `tools/view_selector_native_acceptance.py` runs the real
keyboard matrix against a sealed build through the existing private desktop
and source/engine/fixture-integrity gates. No third-party source or dependency
version was changed, and nothing was pushed or published.
