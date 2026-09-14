# Writerside Table of Contents implementation record

Status: implemented, including native GTK submenus and the approved template
workflow. This is **not a claim of complete IDE, website, or pixel-perfect
Writerside parity**; retained safety and integration differences are listed below.

## Baseline and decisions

The receiving checkout was clean at `c3b53ff` (BusyMark 0.4.2). The named handoff
implementation points matched the receiving source; no archive was copied over it.
Flutter 3.47.2 and Dart 3.13.2 were used without upgrading dependencies.

User decisions: retain BusyMark AI, Git, clipboard, and file commands **after** the
Writerside actions; use installed Writerside **2026.07.8925** for undocumented
behavior; reuse the existing usage-review sidebar, titled **Find**.

The user approved application-support user-template storage and a dedicated
**File and Code Templates** editor, without project metadata. The installed
**Create Topic from Template** dialog takes precedence over the obsolete submenu
screenshot. The user also explicitly required BusyMark's existing native Linux
menus, not Material dropdowns.

## Evidence

The handoff's source identifiers are retained:

| Ref | Official source |
| --- | --- |
| S1 | [Table of contents](https://www.jetbrains.com/help/writerside/table-of-contents.html) |
| S2 | [Context menu](https://resources.jetbrains.com/help/img/writerside/go-to-toc-element.png) |
| S3 | [Row presentation](https://resources.jetbrains.com/help/img/writerside/toc-elements-toc-view.png) |
| S4 | [Topics and titles](https://www.jetbrains.com/help/writerside/topics.html) |
| S5–S7 | [Basic title dialog](https://resources.jetbrains.com/help/img/writerside/edit-title-action.png), [instance title](https://resources.jetbrains.com/help/img/writerside/edit_title_instance_specific.png), [TOC title](https://resources.jetbrains.com/help/img/writerside/edit_title_toc_title.png) |
| S8 | [Add topics](https://www.jetbrains.com/help/writerside/add-a-topic.html) |
| S9–S10 | [Reuse topics](https://www.jetbrains.com/help/writerside/reuse-topics.html), [creation menu](https://resources.jetbrains.com/help/img/writerside/reuse-from-another.png) |
| S11–S12 | [Remove topics](https://www.jetbrains.com/help/writerside/delete-a-topic.html), [removal dialog](https://resources.jetbrains.com/help/img/writerside/remove_topic_dialog.png) |
| S13 | [Save topic as template](https://www.jetbrains.com/help/writerside/save-as-template.html) |
| S14 | [Preview topics](https://www.jetbrains.com/help/writerside/preview-topics.html) |
| S15 | [Instances and tree format](https://www.jetbrains.com/help/writerside/instances.html) |

Installed-build evidence (**P**) is bytecode/resource inspection, not an interactive
JetBrains UI observation. Source artifact:
`/home/albert/.local/share/JetBrains/PyCharm2026.2/writerside/lib/writerside-2026.07.8925.jar`.
SHA-256: `0493a38ac6f09840302b150641fab8b91697955896572c7bf4367bbf7a08f810`.
Reproduce with `unzip -p` for resources and `javap -c -p -classpath <jar> <class>`
using the installed JDK. Relevant classes/resources:

- `stardust.ui.tocTree.TocTreePopupKt`: context order, Group and Sort positions.
- `stardust.ui.views.dom.tree.actions.NewArticleActionGroup`: creation order.
- `stardust.ui.views.dom.tree.actions.DuplicateTopicAction`: source duplication,
  new XML root ID, basic sibling reference rather than copied TOC descendants.
- `stardust.actions.CopySpecialAction` and `stardust.ui.tocTree.CopyTopicFileNameAction`,
  `CopyTopicFilePathAction`, `CopyTopicTitleAction`, `CopyTocOwnIdAction`: labels,
  order, availability, raw reference/canonical path/base title/explicit ID payloads.
- `stardust.ui.changes.EditTitleDialog`: collapsed advanced fields, blank override
  removal and required base title.
- `stardust.ui.views.dom.tree.actions.GroupAction`: two or more siblings, source
  ordering, New Group/Group Name/Enter interaction.
- `com.intellij.writerside.intentions.SortChildrenAlphabeticallyAction`: shallow,
  case-sensitive natural string comparison of resolved tree-node names.
- `stardust.ui.views.dom.tree.actions.LinkTopicFileToTocAction`: single selection,
  name filtering, picker caption and current-instance exclusion.
- `stardust.ui.changes.RemoveElementDialog`, `TocRemoveDialogData`, and
  `RemoveTocElementIntention`: compact versus full removal and automatic-update default.
- `stardust.ui.views.dom.tree.actions.ScrollProductTreeToFileAction`,
  `stardust.ui.tocTree.TocTreeImpl`, `TocElementKey`, `TocTreeAsyncView`:
  explicit synchronization and breadth-first first topic match.
- `stardust.ui.views.dom.tree.TopicFromTemplate`, `actions.newtopic.NewTopicDialog`,
  `actions.TemplateFromTopicAction`, `fileTemplates/internal/`, and
  `tgdpTemplates/`: real template resources and modern creation/settings entry points.
  `LocalFileTemplateProvider` and `FileTemplateUtilKt` establish simultaneous
  literal `${TITLE}`/`${ID}` substitution, not Velocity execution.
  `NewTopicDialog.Companion` establishes XML-only title escaping and filename
  conversion; `TGDPFilesImporter.Companion` establishes brace adaptation,
  first top-level H1 replacement, and relative-link resolution.
- `i18n/StardustBundle.properties`: installed English strings/defaults.

## Action acceptance matrix

Implementation paths below abbreviate `workspace_screen.dart` as **WS**,
`writerside_toc_dialogs.dart` as **Dialogs**, and the controller/service by class.
Test abbreviations: **A** = `writerside_toc_actions_test.dart`; **W** =
`writerside_toc_workspace_test.dart`; **M** = `writerside_toc_menu_test.dart`;
**E** = `writerside_toc_editor_test.dart`; **C** = `writerside_topic_creator_test.dart`;
**R** = `writerside_topic_removal_service_test.dart`; **App** = `app_smoke_test.dart`;
**TS/TD** = `writerside_template_service_test.dart` / `writerside_template_dialogs_test.dart`.

“Native” means the production Flutter Linux application driven by the disposable
fixture harness, with source-file assertions and actual rendered captures. GTK
menus are activated through Linux accessibility and X11 keyboard events, not a
Flutter menu substitute. It is not a human manual run or an original Writerside
screenshot comparison.

| Evidence | Final location / exact English label | Implementation | Behavioral verification | Linux/manual result / differences |
| --- | --- | --- | --- | --- |
| S1, S3, S4 | Sidebar: **Table of Contents** | `WritersideTocPresenter`, `WS._TocTabState` | W: contextual titles, instances, markers, included ownership; App: Files/TOC and RTL regressions | Native pane captured and inspected. Ordinary rows have no document icon; hidden rows remain muted. Existing glyphs are not JetBrains artwork. |
| S1, S2, P | Context: **New Topic** → choices; toolbar + uses current selection | `WS._showTocTreeMenu`, `_createTocItem`, `_TocHeader` | App: selected sibling path/identity; C: creation guards | Native sibling Markdown and template creation passed. |
| S1, S2, P | Context: **New Child Topic** → choices | Same dispatch with child placement | App: XML format and child source identity; C | Native XML child creation passed. |
| S8, P | Either creation menu: **Empty MD Topic**, **Empty XML Topic**; dialog **New Topic** | `WS._CreateWritersideTopicDialog`, `WritersideTopicCreator.create` | C: formats, roots, collisions, races, first home page; controller monitor-race and dirty inactive-tree tests | Native both formats passed; new documents opened with other tabs retained. Existing BusyMark empty-body content retained; not a claim of identical installed template bytes. |
| S1, P | Creation menu: **Empty Group**; dialog **New Empty Group**, **TOC title:**, **Cancel**, **OK** | `Dialogs.WritersideTocTextDialog`, `WritersideTocEditor.insertElement` | E/A structural paths; guarded insertion service | Native creation passed: a titled element without a topic reference. |
| S9–S10, P | Creation menu after separator: **Link Topic Files to TOC...**; picker **Select Topic to Add to the Current Instance** | `Dialogs.WritersideExistingTopicPicker`, `WorkspaceService.insertWritersideTocElement` | M: filter/arrows/submit/cancel; W: unchanged bytes and stale eligibility | Native linking passed, including unchanged source bytes. Candidates use canonical resolved membership, including includes. |
| S2, P | Context after creation separator: **Duplicate**; **Duplicate Topic**, **Topic Filename:** | `WorkspaceService.duplicateWritersideTopic`, guarded creator | W: new XML ID, unchanged body, basic sibling only; C publication guards | Native duplication passed: source copy opened with its new XML root ID. Filename validation retains BusyMark's conservative identifier restrictions; race errors use existing workspace error presentation. |
| S2, P | Context: **Copy Special** → **Topic File Name '{name}'**, **Topic File Path**, **Topic Title '{title}'**, **TOC Element ID '{id}'** | `WS._showTocTreeMenu`, `_showTopicContextMenu` | App: all four Copy Special clipboard payloads in RTL, including base versus navigation title; M nested keyboard/focus/RTL | Native menu captured. Payloads are raw topic reference, canonical path, base title, explicit ID; unavailable values are disabled. No claim that contextual TOC title is copied. |
| S2, S14 | Context: **Preview Topic** | `WS._showTopicContextMenu` preview case, existing view-mode/preview controller | Existing preview/view-mode suites; native selected-topic assertion | Native selected-topic preview passed and was captured. Uses BusyMark renderer, not the Writerside website renderer. |
| S2, S4–S7, P | Context: **Edit Title...**; dialog **Edit Title** with **Topic title:**, **Advanced Settings**, **Title for '{id}':**, **TOC-only title:**, **Cancel**, **OK** | `Dialogs.WritersideTitleDialog`, `WritersideTitleEditor.prepare`, `WorkspaceService.editWritersideTitles` | A: XML/Markdown escaping, independent overrides, inherited values, clearing, repeated occurrence; W: rollback on second-file guard | Native dialog/advanced fields captured and inspected. Front-matter title editing is rejected rather than silently changing a shadowed H1; edit that BusyMark extension in source. |
| S11–S12, P | Context: **Remove TOC Element...**; dialog **Remove TOC Element** | `WS._runWritersideTopicRemoval`, `WritersideTopicRemovalService` | R: references, redirect, malformed source, races, file retained/deleted; W: dirty guard rollback | Native ordinary removal and Find transition captured. Redirect precedes automatic-update checkbox; automatic update defaults on when analysis permits. Safety diagnostics are BusyMark-specific. |
| S1, P | Multi-selection: **Remove TOC Elements...**; compact **Remove {count} TOC Elements** | `WS._removeTocEntries`, guarded batch structural removal | E: source identities and direct-child promotion; App: multi-selection route | Existing direct-child promotion is preserved, as required by handoff. Installed descendant-inclusive count/removal is not cloned; selected-entry count is shown. |
| S11, user decision | Existing sidebar: **Find**, **Do Refactor** | `_WritersideTopicUsageReviewPanel`, usage navigation/reanalysis orchestration | R and controller stale-analysis tests; native review transition | Native surface captured and inspected. Sidebar placement is explicitly user-approved; this is not a general JetBrains tool-window clone. |
| S11 | Files context: **Refactor** → **Safe Delete**; dialog **Delete**, **Safe Delete**, **OK** | Files nested menu, same topic-removal analyzer/apply service | R: generic delete bypass prohibited, usage checks, orphan choices; W: rollback | Native Files → Refactor → Safe Delete passed; Delete dialog captured and inspected. Unchecking Safe Delete does not bypass BusyMark reference safety checks. |
| S2, S15, P | Context: **Set as Home Page** | `WritersideTocEditor.setHomePage`, controller/service | W: root attributes and other instance unchanged; C: first-topic initialization retained | Native reassignment passed and marker inspected. No home action for groups, URLs or library instances; included structural mutation remains restricted. |
| S1, P | Multi-selection after Duplicate: **Group**; **New Group**, **Group Name**, Enter | `WritersideTocEditor.groupElements`, `Dialogs.WritersideTocTextDialog` | A: source order, full nodes, cross-parent rejection; E guards | Native Group/Enter passed, wrapping the two selected source subtrees. Same-parent selections only, preserving complete XML subtrees. |
| S1, P | Context after source navigation: **Sort Child Topics Alphabetically** | `WorkspaceService.sortWritersideTocChildren`, `WritersideTocEditor.reorderChildren` | W: concurrent resolved-title dependency change rejected; native expected order | Native shallow contextual-title order passed. Deliberately rejects mixed XML child entries instead of reproducing the installed action's loss of includes/non-TOC tags. |
| S1 | Pointer: before/after/child drop, single/multiple selection | `WS._TocTabState` drag handlers, `WritersideTocEditor.moveSubtrees` | App: actual recognizers, child/before zones, multi-payload, ancestor rejection; A/E: full subtrees and identities | Native multi-item child drop passed; moved entries remained selected and descendants visible. Widget checks pass for collapsed-hover expansion and autoscroll to a distant destination in a 42-entry tree. |
| S1, S2 | Context: **Go to TOC Element in '{tree filename}'** | `WS._goToTocElement`, `writersideTocSourceSpan`, `SourceEditorState.scrollToOffset` | A: repeated references on one line and fresh offsets; source widget: folded destination; W: snippet owner | Native active and included owner source navigation passed; captures inspected. Native preview-only → source navigation also passed. |
| S1 | Topic/group double-click | TOC `WS._SidebarTreeRow` and `_SidebarRowSurface` callbacks | App: empty-group double-click/source-open assertion; exact-source helper tests | Production callbacks implemented; dedicated native double-click check not yet recorded. Existing single-click semantics retained. |
| S1, P | Toolbar: **Synchronize TOC and Editor** | `WS._rememberSyncFocus`, `_synchronizeToc`, `writersideTocBreadthFirstPath` | A: installed breadth-first duplicate match and tree-editor key behavior | Native both synchronization directions passed, including pre-toolbar focus tracking. Installed `.tree` editor action unusually passes explicit element ID as a topic key: no ID, or no matching topic reference, yields no selection. This limitation is retained, not described as arbitrary group synchronization. |
| S1 | Instance control context: **Open TOC File** | `WS._WritersideInstanceSelector`, `_openInstanceTree` | App: instance-context Open TOC File assertion; native source opening | Implemented; retained additionally in existing overflow. Native instance-context activation not yet recorded. |
| S1 | Tree source: Ctrl+Shift+Home / Ctrl+Shift+End | `source_commands.dart` line movement, source editor, command registry | A: CRLF, boundaries, reversed selection; source widget: folds, one edit, undo/redo | Implemented only in tree-editor context. Multi-line block behavior is conventional BusyMark behavior, not yet observed in original IDE. |
| S1, S15 | Source authoring: `hidden`, `href`, `toc-title`, nesting | Existing parser plus contextual presentation/refresh | Existing parser/resolver/source/controller suites; W row fixture | Native hidden/external rows captured. No invented Hide/Add External Link menus or search-index parity claim. |
| S8, S13, P | Creation menus: **Topic from Template...**; **Create Topic from Template** dialog | `WritersideTemplateDialog`, `WritersideTemplateService.generate`, guarded `WritersideTopicCreator.create` | TS: resource hashes, six families/10 variants, 22 TGDP topics, literal substitution, XML escaping, safe publication/rollback; TD: RTL/LTR format, validation and creation | Native XML template preview and creation passed; new tab and actual template body verified. BusyMark's preview renderer and conservative filenames are retained. Bundled TGDP collection is pinned, not automatically downloaded. |
| S2, S13, P, user decision | Context: **Save as Template**; toast/dialog: **Edit templates...**; **File and Code Templates**, **Files**, **Internal**, **OK** | `WS._showTopicContextMenu`, `WritersideTemplateService.saveTopic`, `WritersideTemplatesEditor` | TS: original extraction/naming, restart, stale-store rejection, serialized writes, source preservation, built-in reset; TD: staged edits, duplicate/delete, Cancel/OK, conflict recovery | Native save/edit/reuse passed with original topic unchanged. Application-support storage and dedicated editor are user-approved adaptations, not an IDE-wide settings clone. |
| S2, user decision | BusyMark AI, Git, clipboard and file extras follow Writerside actions | `WS._showTocTreeMenu` | App preserves copy/cut/paste, history and applicable Git/AI routes | User-approved layout difference. TOC, Files → Refactor, and flat menus use the existing GTK backend, now with real submenus. A framework fallback is retained only for an unavailable native host; no forced Material path remains on Linux. |

## Safety and retained differences

New mutations validate raw source identities and expected content, use guarded
publication, and inspect inactive affected buffers as well as the active document.
Title changes are prepared before a multi-file transaction; dirty-buffer and disk
guards are rechecked at publication, with rollback on partial failure. Topic
deletion uses the existing analyzer and rollback machinery. Clean tabs refresh;
unrelated dirty tabs remain untouched. File-monitor events are deferred during
foreground file operations so an own-write event cannot invalidate the subsequent
open-new-document step.

Structural serialization remains the existing XML pretty-printer: semantic
preservation, not byte-for-byte formatting preservation. Included nodes remain
navigable without enabling unsupported cross-source moves. BusyMark's stricter
mixed-entry sort, safe-delete and front-matter restrictions are explicit above.
The two pictured toolbar chevrons' original tooltips have not been established;
no guessed tooltip names were added.

## Template implementation and resource provenance

`assets/writerside/templates.json` contains the installed resources, with each
original archive path and SHA-256 recorded alongside the unmodified source.
It includes six default families (10 Markdown/XML variants) and the 22 Markdown
TGDP entries in the bundled catalog. The bundled TGDP license is retained in
`assets/writerside/TGDP-LICENSE`. No six-name placeholder collection was invented.

Custom templates and built-in overrides are stored at
`<application-support>/writerside/templates.json`, not in the documentation
project. Reads create nothing. Writes are serialized with a process file lock
and an isolate queue, compare the editor's original snapshot, reject corrupt or
non-regular stores, and use atomic publication. Cancel does not publish staged
edits or deletions. Save as Template reads the current topic buffer when open,
derives the installed `Writerside_<basename>` unique name, substitutes the
installed source patterns, and leaves the topic file unchanged.

The creation dialog uses the installed Default/Custom/The Good Docs Project
categories, search, title/filename, available Markdown/XML variants, rendered
preview, source link, and template-editing entry points. The editor provides
Files/Internal, new/duplicate/delete/reset, editable source, Cancel, and OK.
GTK owns dropdown presentation; Yaru owns the desktop format radio controls and
editor tabs. The editor is intentionally a scoped application-support editor,
not a clone of every IntelliJ settings component.

Generation preserves the installed literal substitution contract; unknown tokens,
Velocity directives, and tokens inside replacement values are not evaluated.
XML titles use XML 1.0 escaping. TGDP generation adapts braces, replaces the first
top-level H1, and resolves relative inline link/image destinations against the
bundled v1.2.0 source URL. Repeated destinations are edited once each; code and
prose are not rewritten as links. Exotic/reference-style link source forms are
left unchanged when no unambiguous inline destination is available. There is no
remote TGDP updater or automatic image-file download. Customized malformed XML
and duplicate root IDs are rejected before any topic/tree publication.

## Native menu integration

`NativeMenuEntry.submenu` sends a recursive semantic model to the existing
`busymark/native_menus` channel. GTK constructs genuine `GMenu`/`GtkMenu`
submenus; separators and selection IDs retain a shared preorder, including
headings. Only enabled leaf actions can dispatch, and disabled ancestors remain
disabled. GTK 3 does not apply an action's sensitivity to submenu headings, so
heading availability is explicitly applied to the generated GTK widgets in
model order. Limits protect the host from excessive depth/entry counts.

The existing popup anchoring, session-scoped dismissal, radio groups, and focus
return remain in place. Text direction is carried to each GTK submenu and its
anchor. The Linux menu hierarchy uses the host's keyboard/hover behavior
([GTK MenuShell](https://docs.gtk.org/gtk3/class.MenuShell.html)); it is not a
new Material dropdown implementation. Unit tests assert native-first dispatch,
nested payloads, exact leaf selection, disabled ancestors, and cancellation.
The existing main application menu remains flat.

## Verification log

Final verification, including templates and native menus:

- `flutter gen-l10n`: exit 0, all 23 ARBs regenerated.
- Formatting checks: exit 0, 22 changed and 13 new non-generated Dart files.
- `flutter analyze --no-pub`: exit 0, no issues.
- Full `flutter test --no-pub --file-reporter json:/tmp/busymark-final-tests.json`:
  exit 0, **1,905 passed, 58 skipped**.
- Documented focused Writerside/source/controller/export suite: exit 0,
  **400 passed, 1 skipped**, report `/tmp/busymark-gtk-focused-verified.json`.
- `bash tools/validate_writerside_conformance.sh`: exit 0, **181 checks passed**.
  This uses the pinned builder 2026.08.0328, distinct from the selected UI plugin
  2026.07.8925. It checks the semantic fixture, not website or menu parity.
- Linux interaction harness: exit 0, **35 checks passed**, **20 captures**.
  Includes real GTK two-level keyboard traversal in LTR/RTL, disabled headings,
  Escape, focus return, session-scoped dismissal, existing flat radio selectors,
  and the core TOC/template workflows in the action matrix.
- Normal `flutter build linux --debug --no-pub --target lib/main.dart`: exit 0;
  the bundle is restored to the normal application, not the acceptance harness.
- `git diff --check`: exit 0.

The 58 full-suite skips are optional Typst/PDF/Poppler and D2 integrations that
require explicit tool-path environment configuration. The focused skip is a
Typst integration. No unavailable optional integration is counted as a passing
TOC or native-menu check.

The first template full run exposed three test-contract problems: reviewed
technical strings in localization audits, the Chinese locale inheritance
contract, and an offscreen RTL clipboard item after adding Save as Template.
These were corrected and focused checks passed. The native menu run exposed
GTK's submenu-heading sensitivity behavior; an actual disabled-heading assertion
now covers it. A headerbar source audit was narrowed to its real scope (the main
menu stays flat, while TOC context menus may be nested). Existing popup cleanup
and native lifecycle contracts were retained.

Native fixture: `test/fixtures/writerside/toc_ui/` includes Markdown/XML,
guide/API/library instances, reused titles, groups, hidden/external/included
nodes, and usage references. The harness copies it into a disposable directory
and isolates settings/session/recovery/history/template storage. Only its own
fixture documents are modified; its Safe Delete check deletes only a generated
duplicate, while the original fixture remains untouched.

Reproduce in an isolated X11 desktop, then restore the normal target:

```bash
flutter build linux --debug --no-pub --target tools/writerside_toc_visual_smoke.dart
BUSYMARK_NATIVE_PROBE=1 GDK_BACKEND=x11 NO_AT_BRIDGE=0 \
  /usr/bin/dbus-run-session -- /usr/bin/xvfb-run -a -s '-screen 0 1440x1000x24' \
  build/linux/x64/debug/bundle/busymark \
  test/fixtures/writerside/toc_ui /tmp/busymark-gtk-toc-final-acceptance
flutter build linux --debug --no-pub --target lib/main.dart
```

The driver requires `/usr/bin/python3`, GTK/AT-SPI introspection, XTest, Xvfb,
and a private D-Bus session. It targets only the probe process. Screen captures
include the actual GTK popup windows, not only Flutter's repaint boundary.
The virtual desktop emits missing portal/GPU and synthetic-trigger warnings,
and AT-SPI/GTK teardown diagnostics were observed during accessibility-driven
menu replacement. All recorded actions completed; this is not a claim of a
warning-free desktop or comprehensive assistive-technology validation. Original IDE
multi-line movement and pictured toolbar-chevron semantics remain unverified
as noted in the matrix.

Inspected Linux evidence:
[results](/tmp/busymark-gtk-toc-final-acceptance/result.json),
[context menu](/tmp/busymark-gtk-toc-final-acceptance/02-context-and-creation-menu.png),
[creation submenu](/tmp/busymark-gtk-toc-final-acceptance/08-creation-menu.png),
[RTL keyboard submenus](/tmp/busymark-gtk-toc-final-acceptance/19-native-keyboard-rtl.png),
[title dialog](/tmp/busymark-gtk-toc-final-acceptance/03-edit-title.png),
[removal](/tmp/busymark-gtk-toc-final-acceptance/06-removal.png),
[Find](/tmp/busymark-gtk-toc-final-acceptance/07-find-review.png),
[template dialog](/tmp/busymark-gtk-toc-final-acceptance/15-template-dialog.png),
[XML preview](/tmp/busymark-gtk-toc-final-acceptance/16-template-xml-preview.png),
[template editor](/tmp/busymark-gtk-toc-final-acceptance/17-file-and-code-templates.png),
[custom template reuse](/tmp/busymark-gtk-toc-final-acceptance/18-custom-template-preview.png).
The disposable source results remain in `/tmp/busymark-toc-native-SZKSLU`.

## Review corrections — 2026-09-14

Applied to the clean implementation commit `f0ef33f`, without changing GTK
menus or the approved Writerside build/template-storage decisions:

| Reported defect | Correction | Regression coverage |
| --- | --- | --- |
| Tree-to-editor synchronization depended on the previous document's extension | `_synchronizeToc` opens the selected entry's resolved topic; only topic-less entries use element-source navigation. | `writerside_toc_regressions_test.dart`: open a `.tree` editor, right-select a topic, dismiss the menu, synchronize; then synchronize a topic-less group. |
| Qualified topic references did not synchronize | Resolve each occurrence through the existing module-aware presenter and compare its topic file path with the active file, keeping breadth-first selection. The separately documented `.tree` ID rule is unchanged. | Same widget suite: `guides/install.md`, another `elsewhere/install.md`, a deeper occurrence, and two root occurrences; the first breadth-first matching file wins. |
| Linking the first existing topic omitted `start-page` | Creation and linking share `initializeWritersideFirstTopicHomePage`, applied before insertion within the guarded tree mutation. | `writerside_toc_workspace_test.dart`: empty instance, groups only, existing home, library, empty-group insertion, existing nested topic, and concurrent publication; linked source bytes remain unchanged. |
| Template editor and storage disagreed on uniqueness | Storage validates category/name/extension, matching the editor. Same-category duplicates remain invalid. | `writerside_template_service_test.dart` and `writerside_template_dialogs_test.dart`: custom `Starter.md` and Internal override saved in both orders, persisted and reloaded. |
| Topic creation inherited preview-only mode | Successful `createWritersideTopic` makes only the new preview-only buffer editable, within the controller's file-operation boundary. Existing editable modes, other tabs, and the global preference remain unchanged. | `writerside_toc_regressions_test.dart`: actual Preview Topic followed by Empty MD, Empty XML, and template-dialog creation; verify source editor, template body, retained dirty content, and all existing tab modes. |

The new full-workspace widget tests use real temporary project files and the
production controller/services. Only desktop host/theme and persistence services
are isolated. Their framework menu fallback is test-only; these checks do not
replace or claim a new recording of the native GTK evidence above.

Review verification (Flutter 3.47.2 / Dart 3.13.2):

- Full `flutter test --no-pub --concurrency=2 --file-reporter
  json:/tmp/busymark-toc-review-full.json`: exit 0, **1,921 passed, 58 optional
  integration skips**. This includes all 16 new regressions.
- Documented focused suite: exit 0, **416 passed, 1 optional Typst skip**;
  `/tmp/busymark-toc-review-focused.json`.
- `flutter analyze --no-pub`: exit 0, no issues.
- `dart format --output=none --set-exit-if-changed` on all nine changed/new Dart
  files: exit 0, no changes. `flutter gen-l10n` and `git diff --check`: exit 0.
- `bash tools/validate_writerside_conformance.sh`: exit 0, **181 checks passed**;
  `/tmp/busymark-toc-review-builder.log`.
- `flutter build linux --debug --no-pub --target lib/main.dart`: exit 0;
  `/tmp/busymark-toc-review-linux-build.log`. The bundle targets the normal app.

An earlier full-suite attempt emitted an asynchronous local-history file-monitor
teardown error before the user interrupted verification. The isolated
`workspace rename settles a failed first-save promotion` test passed on rerun;
the completed full-suite rerun above also passed. No unrelated local-history or
monitoring behavior was changed to hide that failure. Interrupted processes and
temporary logs were lost, so completed verification was rerun after resuming.
