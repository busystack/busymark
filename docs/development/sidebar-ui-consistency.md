# Sidebar consistency: interaction inventory and acceptance

The 2026-11-06 one-Git-UI decision supersedes the earlier host-specific Git
presentation choices recorded here. Both hosts now use the shared Git sidebar,
review, contextual rows and native notification surfaces. See the current
[ownership/action map](../../../busystack_git_flutter/docs/one-git-ui.md) and
[artifact-bound acceptance](../git-ui-acceptance.md). The historical baseline and
the unrelated Files/TOC/Outline/history contracts below remain relevant.

The 2026-11-03 baseline is BusyMark d6e9668, shared Git UI d1978b2,
BusyFiles f6108c3 and engine 7d8e55d. All four working trees were clean.
Original affected sources are retained under build/sidebar-ui/before.
Before-state native captures are unavailable: this session denies socket binding
and GTK cannot connect to display :0. Graphical acceptance remains required.

## Existing entry contracts, recorded before modification

| View | Primary / double activation | Context and keyboard destinations | Selection / navigation / safety |
| --- | --- | --- | --- |
| Files | Open text document; directory click toggles expansion | Existing New File, Rename, Cut, Paste/Move, Delete, Copy Name/Path, Open in Files, Git Add/History and Local History, with existing eligibility | Selected path; existing tree keys/F2/Delete/Menu/Shift+F10; filesystem and dirty-document guards; no new gestures or drag operations |
| TOC | Open topic or toggle structural parent; existing double activation opens topic/source element | Existing topic/source/structure actions and reviewed multi-topic action snapshots, through _showTopicContextMenu | Ctrl/Shift selection, arrow traversal/expansion, home/hidden/included/unresolved indicators, existing drag/reordering and source/tree ownership; Writerside instance selector unchanged |
| Outline | Navigate heading in current buffer | Existing _outlineSectionMenuItems and _runSectionAction retain heading editing/structure operations | Heading badges, current viewport highlighting, selected heading set, keyboard traversal and buffer/source identity guards |
| Commit | File opens independent version-bound comparison; groups/directories toggle | Review/expand, Stage or Unstage reviewed selected files/eligible descendants, History/Blame and applicable discard/delete | Ctrl/Shift selection; tree arrows/Home/End/Enter and existing staging keys; native accessible cell actions; immutable reviewed snapshot, content preconditions, conflicts excluded from bulk staging |
| Git Log Changed Files | Historical file opens independent immutable comparison; directories toggle | Review Difference, History/Blame, Open Snapshot | Existing selected file, focused row, collapsed directories and keyboard context/arrow/Enter handling; immutable commit/parent/old/new paths; no staging |
| Local History | Select revision for comparison; retained-document row changes inspected history document | No revision row menu exists; existing view-level restore/history/document actions remain | Date grouping, timestamp, real event reasons, deleted/retained documents, arrow/Enter traversal, selected document/revision and unsaved-buffer protections |
| Clipboard History | Select payload; existing double activation pastes when allowed | Existing Paste, conditional Paste Plain Text and Remove only; no new Copy operation invented | Current/external identification, text/source/image filename preview, type/time/origin/path, arrows/Enter, session-owned target callbacks and privacy protections |

The shared record component is also used outside these seven views. Its custom
content, disabled entries, optional non-action trailing metadata, caller focus,
selection snapshots, tooltip/semantic label and immediate primary+double-click
contract must be preserved. Only redundant entry action triggers are removed.

The historical Git modal retains graph, filters, reference navigation, explicit
confirmation/cancellation and contextual Git operations. Its previous dense-field,
prefix, palette and obsolete-details corrections are present in this baseline;
entry action placement was a shared-host difference in that historical baseline.
The current shared presentation requires contextual entry actions in both hosts.
BusyFiles retains its authenticated daemon boundary and browser navigation.

## Official guidance consulted

GNOME [List & Column Views](https://developer.gnome.org/hig/patterns/containers/list-column-views.html),
[Menus](https://developer.gnome.org/hig/patterns/controls/menus.html),
[Pointer & Touch](https://developer.gnome.org/hig/guidelines/pointer-touch.html),
[Keyboard](https://developer.gnome.org/hig/guidelines/keyboard.html),
[Sidebars](https://developer.gnome.org/hig/patterns/nav/sidebars.html), and
[Buttons](https://developer.gnome.org/hig/patterns/controls/buttons.html) inform
regular compact rows, secondary menus and equivalent keyboard access. BusyMark's
existing Files geometry and application behavior remain the controlling reference.

Official Flutter references: [focus](https://docs.flutter.dev/ui/interactivity/focus),
[secondary taps](https://api.flutter.dev/flutter/widgets/GestureDetector/onSecondaryTapUp.html),
[semantics](https://api.flutter.dev/flutter/widgets/Semantics-class.html),
[constraints](https://docs.flutter.dev/ui/layout/constraints),
[selection](https://api.flutter.dev/flutter/widgets/SelectableRegion-class.html),
[editing/composition](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html),
and [native channels](https://docs.flutter.dev/platform-integration/platform-channels).
APIs are checked against the approved local Flutter 3.47.5/Dart 3.13.4 sources.
No third-party source, binary or dependency version is changed.

## Implemented changes

`BusyMarkSidebarTreeRow` no longer constructs a selected/hovered/focused menu
button. Its native surface, disclosure target, status metadata, primary/double
activation and contextual callbacks remain. TOC uses Files' disclosure slot and
gap rather than its previous compact override; the obsolete drag hit exclusion
for the removed menu target is gone. Files and Outline retain their original
feature callbacks and their specialized icon/heading content.

`BusyMarkSidebarRecordRow` now renders through the same native row surface.
The direct first-party Material/InkWell/YaruListTile path is removed. Its optional
secondary text has natural height, without forcing timestamp-only revisions to
two lines. Clipboard custom previews, type/time/origin/path and immediate
selection/double activation remain. No new Local History revision menu is
invented. Context menus use the existing GTK service without a Flutter fallback.
Collection-owned Clipboard keyboard focus dispatches Menu/Shift+F10 to the
selected record; arrow/Enter/Delete routing remains owned by the collection.

| View | Applied correction |
| --- | --- |
| Files | Existing tree and geometry retained; automatic row action trigger removed; same native pointer/keyboard action list |
| TOC | Files disclosure spacing and indentation; no topic trigger; original instance selector and all reviewed multi-topic/reordering actions preserved |
| Outline | Same tree surface and geometry, heading badge/navigation preserved; no heading trigger; document Actions remains |
| Commit | Files outer inset and depth geometry; no group/directory/file plus/minus controls; existing staging actions remain contextual; compact neutral branch context opens full Branches modal |
| Git Log | Shared Files geometry from depth zero; no historical-file or reference entry trigger; informational neutral subject, dedicated graph selector beside Actions; parent controls use secondary metadata rows |
| Local History | Compact single-line timestamps or genuine secondary event text, shared row interactions; date headings, document context and view Actions preserved |
| Clipboard History | Shared compact record surface with bounded useful preview/metadata; no trigger; same exact contextual operations, double activation and collection keyboard behavior |

Shared Git's required `entryActionPlacement` is contextual in both hosts.
The common Linux presenter owns row geometry and interaction; hosts bridge their
native menu services. Both forward secondary activation and reject it for disabled rows.
Commit's deferred menu action now rechecks session/snapshot/index identity before
using its reviewed targets. No Git engine source or operation is removed.

The earlier Git selector/diff changes are present at this task's baseline:
dense fields/adornments, compact reference rows, measured filter toolbar,
explicit selection/cancellation, removal of the expanded details route, and
semantic translucent line/word treatments. They remain subject to graphical
acceptance. Both hosts forward Git feedback to the shared `showGitNotification`
surface, including its queue and lifetime guards. BusyFiles' non-Git browser
messages and daemon background-operation notifications remain host-owned.
BusyMark's non-Git feedback retains BusyMarkToastOverlay.

## Regression protection and evidence

The new resolved `check_sidebar.dart` gate audits actual row foundations and
entry construction, aliases/helper references, Files hierarchy usage, retained
context callbacks and shared Git host policy. It rejects automatic native menu
triggers as well as prohibited Material rendering. Its fixtures include both
approved metadata and deliberately prohibited controls. The existing native
constructor audit and mixed-workspace Git audit remain in force.

The original sources in isolated baseline worktrees fail this source gate with
actual Material/InkWell/fallback record paths, compact TOC geometry and unguarded
entry controls. Corrected-source gates pass. This is a failing-before/passing-after
**source** result, not rendered evidence.

New host tests measure tree disclosure gap/depth/insets, compact record height,
hover/pressed/selected/focus/disabled states, absence of entry triggers, secondary
activation, release-safe Menu/Shift+F10, focus restoration and native menu packets.
They exercise English/German/Japanese/Arabic, both themes and enlarged text.
Shared Commit tests cover contextual file/directory/group stage/unstage,
reviewed descendants and stale-index dismissal. Existing Writerside, record and
clipboard campaigns retain their operation assertions while selecting commands
through the native transport. No fake menu widgets or replacement goldens are
used. These tests analyze but cannot execute in this session.

Logs, before sources, exact commands, return codes and build identities are
retained under `build/sidebar-ui`. The final delivery receipt records commits,
pins, official SDK verification, test/build results and remaining acceptance.
