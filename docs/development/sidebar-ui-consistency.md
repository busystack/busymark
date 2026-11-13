# Sidebar consistency: interaction inventory and acceptance

## Final sidebar corrections (2026-11-08)

A subsequent Local History correction uses `BusyMarkGlyphs.mainMenu` for its
Actions trigger, so both GTK artwork and the catalog glyph show three bars.
The 190 affected Local History/native header tests and source analysis passed.
The package/corpus receipts below predate that source change and require fresh
qualification before they can be used for the updated application.

The four approved corrections are implemented and committed. **Acceptance is
incomplete:** both qualified packages still require local administrator
authentication, installed-payload binding and actual installed-app inspection.
The final evidence is in [`build/sidebar-final`](../../build/sidebar-final/);
`current-work-state.json` and `visual-inspection.json` distinguish qualified
development-bundle evidence from rejected captures and pending installed gates.

The source-level causes and corrections are:

| Area | Cause | Correction |
| --- | --- | --- |
| View selector | The fixed catalog glyph used list artwork. | `BusyMarkGlyphs.sidebarViews` uses existing `YaruIcons.app_grid`, with the localized **Select sidebar view** tooltip/accessible name and unchanged native trigger/menu. |
| References | A direction tab selected one query; a permanent scope trigger occupied result space. | Both existing direction-keyed queries feed independent hierarchical Incoming/Outgoing sections. Scope choices are checked native Actions menu items; only a heading filter adds muted informational scope text. |
| Commit | Tracking occupied a separate composition and always printed measured zero counters. | Shared `GitLogHeader.contextDetail` composes title, branch and localized `Tracks origin/main`. Standard title/context spacing is 4px, subordinate context spacing uses `GitSpacing.xxs` (2px), with the same leading inset and standard header-to-content space. Both known-zero counters are omitted; meaningful known divergence remains. |
| Git Log toggle | The canonical modal action did not receive visibility selection; the upstream button theme also supplied an accent icon color. | Actual modal sidebar visibility drives `NativeGitIconAction.selected`. Its native style explicitly resolves neutral foreground **and icon color**, with filled visible/flat hidden states, native hover/press and restrained keyboard outline. Both hosts use this implementation. |

References continues to use the existing index and generation/revision guards.
The two requests share active identity and anchor but retain direction and page
limits separately. Disclosure state survives view remounts and resets for a new
workspace. Query errors retain Retry independently of the other section;
loading has no fabricated count. Existing contextual navigation, Link Chooser,
source/target metadata and dirty-document guards remain. Actual heading-scope
inspection exposed an existing Writerside Markdown adapter defect: heading-line
spans excluded their following content. The adapter now delegates Markdown
section ranges to the existing index's neighboring-heading logic; XML element
ranges are unchanged. No second index or engine change was introduced.

Tracking remains local snapshot information: unknown counts do not become zero,
no upstream implies no tracking relationship, and detached/unborn branch
identity retains its existing semantics. No network refresh was added. Commit
operations, the footer and modal architecture remain unchanged.

Regression evidence includes six failures against the old shared source in
`failing-before.log`, followed by passing corrected header/state tests; the
Markdown scope regression fails with expected 1 / actual 0 in
`scope-failing-before.log` and passes after correction. The complete BusyMark
corpus passed **5,775 cases in all 245 files**, zero failures/skips, with its
receipt independently reverified. The shared suite passed **470** and BusyFiles
Git tests **100**. Analysis, formatting, localization consistency, resolved native
audits for both materialized hosts, ownership audits and adversarial checks,
exact dependency materialization, BusyMark debug/release builds and the BusyFiles
release/package build passed. Packaging/corpus receipt adversarial tests passed
25 cases. Earlier failed attempts remain in their original logs.

Actual X11 screenshots were inspected, including:

- The 32-case release-bundle matrix in `frozen-native-matrix`: both themes,
  English/German/Japanese/Arabic RTL, 1.0/1.5 text and normal/narrow widths.
  Files/Commit/Log/References show a constant selector; expanded/collapsed
  References, checked Actions scopes, contextual menus and real heading-filtered
  results were inspected. A separate run covers all eight view-menu entries.
- All 16 corrected empty-state cases in `immutable-reference-empty`, asserting
  the actual `staged.md` identity, both zero counts and both empty notices.
  The older matrix's incorrectly targeted empty-document frames are rejected.
- `qualified-reference-states` shows real loading, unavailable and missing
  destinations. Independent query-error/ready combinations and recovery have
  widget regression coverage; these native unavailable rows are not claimed as
  an injected query-failure test.
- `qualified-native-tracking` shows real local upstream snapshots with measured
  0/0 and 3/2 divergence. `verified-mark-modal-light-repeat` and
  `verified-mark-modal-dark-rtl` show populated modal hide/show, hover, press,
  keyboard focus and narrow restoration, preserving search/reference/filter/
  candidate state and the main sidebar. BusyFiles parity is in
  `verified-native-files-light` and `final-native-files-dark`.

Accepted native receipts require natural exit, unchanged repository bytes and
runtime cleanup. Images are original native captures; inspection sheets contain
only crops/resizes. An earlier empty-state run overlapped a package rebuild and
failed sealed-payload validation during file replacement. It is rejected; final
payloads compare byte-for-byte equal, and the completed empty matrix uses a
separate immutable bundle. Wrong-target modal/navigation attempts and stale
empty frames are also explicitly rejected, without rewriting logs.

Shared commits are `15a81c5` and
`460f1256ae9aa4d85bb1eca929c500bb76c661b9`; BusyFiles consumers are through
`d6b456192c26794f9db5ef46865bb6684b9d8ea5`. BusyMark implementation commits run
from `5e4b7c9` through `58990d7`, with reviewed goldens/archive packaging at
`edcad83` and native harness qualification through `ada1653`. Both consumers pin
the exact shared revision above, archive SHA-256
`fd64b765176ecee67bfa2b578c574cc39b28f43478a227e28d7391fc6b6eb951`
and tree SHA-256
`564103f0b558943c5668ee1c2664e1befd9d51e66608b24541e1f5ef93907087`.
The engine remains `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`.

Compiled production SHA-256 receipts bind BusyMark
`ee234ae779f989c49119272a59520cfcc8a0903f2334f0f9776626911df60b40`,
shared UI `c599a9a0ab2a76d569ad2d0415541a14c5a41231175b79920f3748e0c9f0489d`
and engine `a91a6a6c8464aba7cb9bc910484960e179edfdffb17e9c983b5bac45681a189c`.
Later host documentation/tool commits do not change those compiled inputs.
The official unmodified Flutter 3.47.5 / Dart 3.13.4 toolchain and locked
third-party versions remain intact. No push, tag or publication occurred.

Both final packages are on the mounted build volume identified by
`packaging-volume.txt`, with qualified complete-payload receipts:

| Artifact | SHA-256 |
| --- | --- |
| `busymark.snap` (local development repack) | `268448ca956792c33f2930b87e42ee7b7f03d588ea1699790bdff38d12149ea5` |
| `busyfiles/busyfiles_0.0.1-1_amd64.deb` | `0a5146b260bc199103ec107f9abe5628d42555005d867a0e9f2b3570012ceb97` |

Both standard install attempts stopped at
`sudo: interactive authentication is required`. No installed application was
changed. The reviewable checksum-bound
[`install-qualified-packages.sh`](../../build/sidebar-final/install-qualified-packages.sh)
uses ordinary `dpkg -i` and `snap refresh --dangerous` without purging application
data. After local authentication, actual installed payloads and both installed
native applications still need verification. The historical platform/lifecycle
observations below remain independent; X11 development-bundle success does not
waive Wayland, Windows, fractional scaling, accessibility-lifetime or strict-Snap
credential gates. Full acceptance must not be reported yet.

## Earlier sidebar correction (2026-11-08; superseded above)

BusyMark owns `BusyMarkFocusStyle`, `BusyMarkFocusIndicator`, context-menu key
handling and `BusyMarkSidebarHeader`. General theme/design code imports no Git
UI. The canonical Git adapter, dialog aliases and width calculation live in
`lib/src/git/application/shared_git_presentation.dart`. Git Commit, Log,
Branches and comparisons remain owned by the shared package.

All eight sidebars use a 16px title icon, body-medium title, 32px native actions,
4px title-to-context gap, neutral body-small context and 12/8 directional
horizontal/vertical insets. Context lines contain no icon or selection button.
Instance/branch/commit selection precedes other actions and uses Yaru selection
artwork. The workspace view chooser keeps one list icon in every view. TOC
module selection remains a separate optional control after the common header.
Each header owns a semantic container: informational context cannot merge into
an adjacent commit-details action. The native scope selector announces its
label once, retaining its button and expanded states.

References retains its active-document incoming/outgoing queries and heading
anchors. It uses the pinned Yaru tab bar, the existing native menu transport,
BusyMark record rows, native text entry, dialog actions, notices and progress.
Source/Target location actions are contextual; stale-revision navigation,
workspace identity and recovery/save guards remain authoritative. Native record
menus dismiss their tooltips while retaining focus. Full metadata remains in
accessible labels/tooltips without empty module/origin separators.
The native direction bar uses body-medium labels and compact public theme
padding. Its width and height follow measured localized text, so enlarged
German labels remain complete and double-size text keeps indicator clearance.

`tools/git_ui_audit/bin/check_design_boundary.dart` resolves all ordinary host
libraries, typedefs, import aliases, re-exports and helpers. Exact mounting/tab
and lifetime contracts are permitted; general Git UI primitives and renamed
presentation wrappers are rejected. Its deliberate violating fixtures belong
under test, outside production source receipts. `check_sidebar.dart` also
follows both complete References rendering chains through their real native
controls and recovery dialogs. Git keeps the mandatory full service audit.

Native evidence for this correction is under `build/sidebar-correction`.
`before-qualified` preserves all eight actual baseline views from archived
sources. `native-delivery-matrix` contains the final 32 release-bundle cases:
light/dark, English/German/Japanese/Arabic RTL, 1.0/1.5 text scale and normal/narrow
windows. Every case covers all eight views and a References context menu, verifies
the constant selector pixels, mapped official engine, unchanged fixture and
natural exit. All 16 sheets in `delivery-native-inspection` were inspected;
`delivery-visual-inspection.json` binds their source and individual receipts.
Native TOC instance/actions, Branches/history selection, reference scope/direction,
link chooser, empty/recovery and dirty-document guards have separate captures.
These release-bundle results do not establish installed-application acceptance.
The independent gates in [git-ui-acceptance.md](../git-ui-acceptance.md) remain.
The synchronized semantic-header revision is
`570fadcdde31507b5b1c2f1f27610f72cb519b37`; the engine remains
`7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`. Both exact file-only archives
must also pass fresh materialization, rather than only sibling-tree checks.

The final production correction is `89267a9`; tool-only audit hardening follows
at `f62dd3c`. General libraries and Git engine/service helpers are audited;
only the actual Git presentation libraries are exempt. The complete BusyMark
corpus passed 5,772 cases in all 245 discovered files with zero skips. The strict
receipt verifies production/test fixtures, complete commands and unchanged logs.
Shared Git passed 466 tests and BusyFiles passed 743 UI/integration tests.
Analysis, formatting, localization generation, resolved native audits and their
adversarial checks passed. Both hosts built Linux debug and release artifacts.

BusyFiles `306323e` also ran its actual final debug UI with the exact daemon
extracted from its qualified final DEB. Commit, Branches, Log, history selection,
historical comparison and return to Files were inspected. Trust required the
normal explicit confirmation. Its receipt records unchanged Git/content,
official engine, daemon exit 0 and natural application exit. This additional
development-bundle run does not replace installed DEB acceptance.

The local BusyMark development Snap passed sealed bundle and complete 43,429-entry
packed-filesystem verification. It is a scaffold-based development repack, not
a clean Snapcraft release. Final artifacts and checksums are:

| Artifact | SHA-256 |
| --- | --- |
| `build/sidebar-correction/busymark-sidebar-89267a9.snap` | `2f73e55fd9c6a4e68cc6bdcc642e66479308f2a3f82e83d7ee8dcfab38d72daa` |
| `../busyfiles/dist/sidebar-semantic-qualified/busyfiles_0.0.1-1_amd64.deb` | `0bf5b490adc1b84486444b8d83d0102ea731bbac1916aafb2b5782420a87fd0b` |

**Acceptance remains open.** Both final installation attempts stopped with
`sudo: interactive authentication is required`; neither installed application
matches the final artifacts. System authentication, installed payload receipts
and actual installed-app inspection remain required. Install the local Snap
over the existing application without purging its data:

```sh
sudo dpkg -i /home/albert/busystack/busyfiles/dist/sidebar-semantic-qualified/busyfiles_0.0.1-1_amd64.deb
sudo snap install --dangerous /home/albert/busystack/busymark/build/sidebar-correction/busymark-sidebar-89267a9.snap
```

The reviewable post-authentication recipe is
[`complete_installed_acceptance.sh`](../../build/sidebar-correction/complete_installed_acceptance.sh).
It checks the complete corpus and artifact hashes, installs through the standard
system tools, verifies actual installed payloads and runs both native hosts,
including the full installed BusyMark matrix. The prepared scripts pass syntax
checks; installation and their installed-host execution remain unperformed.

One separate X11 recovery/empty-state run failed natural exit with
`g_mutex_clear() called on uninitialised or locked mutex`. The exact repeated
sequence passed. Both receipts and logs remain under `delivery-native-empty-recovery`
and `delivery-native-empty-recovery-recheck`. Its cause has not been isolated;
the passing repeat does not waive the failed lifecycle observation or establish
an upstream attribution. A further diagnostic with core capture enabled only
for the private process also exited naturally, so it yielded no crash backtrace.
Its receipt is `delivery-recovery-core-diagnostic/receipt.json`.
Existing Wayland, Windows, accessibility-lifetime,
strict-Snap credential and fractional-scaling limits remain separate.


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

## Application consistency correction (2026-11-07)

The current correction keeps the approved row surface. Welcome recent resources
use the comfortable record density: 54 px minimum content extent, 8 px vertical
and 12 px horizontal padding, existing 18 px icon slot and 12 px label gap.
The minimum extent and padding follow the pinned YaruListTile.square reference without restoring its
Material-backed rendering. Compact search, Local History and Clipboard remain
separate density consumers with their existing information and activation model.

BusyMarkSidebarHeader delegates to the shared NativeSidebarHeader layout used
by Commit and Git Log. Every view has a body-medium identity and, when meaningful,
a secondary body-small context. Files retains informational path/context menus;
Outline retains its document icon/actions; TOC retains Writerside instance and
module switching plus New Topic/TOC Actions. Clipboard has no fabricated context.
Git branch and selected-commit labels are informational, with independent
selection actions immediately before Actions. Log metadata still precedes files.

The defect was full-primary YaruFocusBorder paint coupled to unconditional row
focus acquisition on pointer activation. Flutter traditional mode includes both
mouse and keyboard; changing global highlight strategy cannot distinguish them.
Shared NativeFocusIndicator observes supported input events without consuming
keys or changing focus requests. Pointer selection and context menus retain focus
without keyboard emphasis. Subsequent keyboard interaction reveals the focus
indicator. NativeFocusStyle owns foreground-role 65% opacity, two-pixel Yaru
outlines, with opaque high-contrast focus; inputs keep an editing-focus border.
Accent selection, links and affirmative actions retain their original colors.

Official references were consulted: GNOME Sidebars, List & Column Views, Text
Fields, Buttons, UI Styling and Keyboard; Flutter focus, FocusManager,
FocusHighlightMode/Strategy, FocusNode, FocusableActionDetector and Actions/
Shortcuts; and the pinned official Yaru 10.2.0 implementation. No supplied image
attachments were available in this conversation. Official GNOME guidance and
the actual pinned row geometry are the available reference evidence.

Native captures and execution logs for this correction are under
`build/native-consistency/`. A passing source/property check is not native
acceptance. The final evidence record must distinguish inspected native frames,
installed application qualification and independent platform limitations.


Grouped Yaru rows, navigation tiles, toggles, Git icon actions and native modal
close controls also delegate focus decoration to NativeFocusIndicator. Public
`hasFocusBorder: false` transfers only that decoration to the common first-party
owner; upstream controls, geometry, accessible actions and values remain intact.
Grouped entry rows keep pointer editing focus; ordinary rows use keyboard emphasis.
A normal text field with its own themed border does not gain a second row border.
Rendered tests exercise each control family and reject full-accent borders and
pointer-induced outlines. Direct focus-capable Yaru construction in feature views
is rejected; approved upstream calls remain confined to the existing design boundary.

The context container uses Yaru's native title-bar item minimum extent. It
centers both informational text and the Writerside selector's text on the same
line while retaining the selector's full hit target. The heading-to-container
gap stays 2 logical pixels. Clipboard History omits the container entirely.
