# Writerside Table of Contents implementation record

Status: authoring workflows implemented, including native GTK submenus and the
approved template workflow; exact-original UI coverage remains incomplete.
The two unidentified icon-only toolbar controls are still unimplemented.
This is **not a claim of complete IDE, website, or pixel-perfect Writerside
parity**; retained safety and integration differences are listed below.

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
| S8a | [Import from Markdown](https://www.jetbrains.com/help/writerside/import-markdown.html) |
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
| S8, S8a | **New Topic** and header Add: **Add Local Markdown Files**; dialog **Add Local Markdown Files** | Existing Markdown discovery and `WritersideInstanceService.addMarkdownTopics`; focused selection dialog | Instance service: selected-only/root/sibling ordering, relative layout, media, first home page, ID and concurrency failures; workspace/controller/dialog/menu suites | Context imports are siblings and header imports are roots. **New Child Topic** intentionally has no import action. Imported Markdown bytes are unchanged. |
| S2, P | Context after creation separator: **Duplicate**; **Duplicate Topic**, **Topic Filename:** | `WorkspaceService.duplicateWritersideTopic`, guarded creator | W: new XML ID, unchanged body, basic sibling only; C publication guards | Native duplication passed: source copy opened with its new XML root ID. Filename validation retains BusyMark's conservative identifier restrictions; race errors use existing workspace error presentation. |
| S2, P | Context: **Copy Special** → **Topic File Name '{name}'**, **Topic File Path**, **Topic Title '{title}'**, **TOC Element ID '{id}'** | `WS._showTocTreeMenu`, `_showTopicContextMenu` | App: all four Copy Special clipboard payloads in RTL, including base versus navigation title; M nested keyboard/focus/RTL | Native menu captured. Payloads are raw topic reference, canonical path, base title, explicit ID; unavailable values are disabled. No claim that contextual TOC title is copied. |
| S2, S14, user decision | JetBrains **Preview Topic** is deliberately not exposed | No BusyMark TOC action | Framework and native menu-absence regressions | The removed action only opened the selected topic in BusyMark's ordinary Reading mode, duplicating existing document view controls and incorrectly implying Writerside Preview-tool-window semantics. BusyMark retains its separate Reading and Split document modes. A true Writerside Preview feature is outside this change; no Preview-tool-window or browser-preview parity is claimed. |
| S2, S4–S7, P | Context: **Edit Title...**; dialog **Edit Title** with **Topic title:**, **Advanced Settings**, **Title for '{id}':**, **TOC-only title:**, **Cancel**, **OK** | `Dialogs.WritersideTitleDialog`, `WritersideTitleEditor.prepare`, `WorkspaceService.editWritersideTitles` | A: XML/Markdown escaping, independent overrides, inherited values, clearing, repeated occurrence; W: rollback on second-file guard | Native dialog/advanced fields captured and inspected. Front-matter title editing is rejected rather than silently changing a shadowed H1; edit that BusyMark extension in source. |
| S11–S12, P | Context: **Remove TOC Element**; dialog **Remove TOC Element** | `WS._runWritersideTopicRemoval`, `WritersideTopicRemovalService` | R: project-wide references, `topic`/`ref`/`origin`, redirects, malformed or incomplete semantic discovery, races, file retained/deleted; W: project-wide dirty guard and rollback | The approved sidebar Review Usages flow is instance-aware; Do Refactor reanalyzes and completes directly when all blocking usages are resolved. |
| S1, P | Multi-selection: **Remove TOC Elements...**; compact **Remove {count} TOC Elements** | `WS._removeTocEntries`, guarded batch structural removal | E: source identities and direct-child promotion; App: multi-selection route | Existing direct-child promotion is preserved, as required by handoff. Installed descendant-inclusive count/removal is not cloned; selected-entry count is shown. |
| S11, user decision | Existing sidebar: **Find**, **Do Refactor** | `_WritersideTopicUsageReviewPanel`, usage navigation/reanalysis orchestration | R and controller stale-analysis tests; native review transition | Native surface captured and inspected. Sidebar placement is explicitly user-approved; this is not a general JetBrains tool-window clone. |
| S11 | Files context: **Refactor** → **Safe Delete**; dialog **Delete**, mandatory checked **Safe Delete**, **OK** | Files nested menu, same topic-removal analyzer/apply service | R: project-wide generic-delete bypass prohibited (including unparsed/non-active-module topics), usage checks, orphan choices; W: rollback | Safe Delete is deliberately non-toggleable for Writerside topic files. |
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
removal uses the complete `WritersideProject`: ownership is chosen by exact parsed
topic path or the most-specific configured topic root, so non-active and nested
modules cannot bypass Safe Delete. The reviewed snapshot includes the sorted module
inventory, module inputs, every parsed topic, variables and instance groups, all
semantic `.tree` files, and redirect rules. Hidden, `build`, `target`, `dist`, and
`out` directories participate in semantic discovery; `.git`, `.hg`, and `.svn`
remain hard exclusions. Incomplete module/topic/tree discovery, unparsed topics,
or a changed snapshot fails closed before publication.

Removal combines indexed links, includes, cards and other semantic references with
an exhaustive tree/start-page pass. `topic`, `ref`, `in`, and `origin` resolve
through the owning host and target modules. Current-instance relevance comes from
the resolved navigation tree and resolved topic documents, including filters and
instance conditions; Safe Delete remains project-wide. Unsupported but resolved
references appear in the approved Review Usages sidebar as manual blockers. Orphan
status is asserted only when the complete post-refactor project has no remaining
usage.

Redirect plans retain each host instance's effective web filename plus direct and
rule-based accepted aliases, and validate the resolved instance namespace before
writing. Do Refactor resolves dirty project buffers, reanalyzes from disk, preserves
the reviewed options, and applies immediately when blockers are gone. Cross-module
writes use guarded atomic replacement and rollback, with the topic file deleted
last. Clean tabs refresh; unrelated dirty tabs remain untouched. File-monitor
events are deferred during foreground file operations so an own-write event cannot
invalidate the subsequent open-new-document step.

Structural serialization remains the existing XML pretty-printer: semantic
preservation, not byte-for-byte formatting preservation. Included nodes remain
navigable without enabling unsupported cross-source moves. BusyMark's stricter
mixed-entry sort, safe-delete and front-matter restrictions are explicit above.
The two pictured toolbar chevrons' original tooltips have not been established;
no guessed tooltip names were added.

Existing-instance Markdown import reuses `discoverMarkdownFiles` for source-root
discovery and the shared import planner for selected topic and referenced-media
copies. Topic targets retain source-root-relative directories beneath the first
configured topics root. Media references use the established Markdown, semantic
XML, Writerside video, and preview-source scan; external/absolute references and
intentionally missing local media retain their prior behavior, and duplicate
media targets are staged once.

Before planning, and again immediately before publication, the owning module is
reloaded and complete semantic topic discovery is required. Each source basename
passes the shared topic filename validator. IDs are basenames without extensions;
the selected batch must be unique and must not intersect
`WritersideModule.reservedTopicIds`, which includes parsed and discovered-but-
unparsed topic files across all configured topic roots. The import transaction
stages every selected Markdown file, deduplicated media file, and the updated
tree, verifies all source/target snapshots, then publishes once with conservative
rollback. Consequently a stale TOC identity, target change, or concurrent topic
ID leaves no partial topic/media/tree publication. The shared first-topic helper
sets only the first imported reference as `start-page` when appropriate.

Ordinary empty, template, custom-template, and duplicate creation retains exact
exclusive path creation, then reloads semantic module state after its own topic
exists and before tree publication. A valid final state has exactly one parsed
reservation for the requested ID and that reservation is the candidate path;
another extension, subdirectory, or configured root fails with the existing ID
collision error. Existing owned-file cleanup and final tree snapshot checks remain
independent safeguards.

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

Final verification, including local Markdown topic import, topic removal,
templates, and native menus:

- `flutter gen-l10n`: exit 0; generated localization sources are current.
- Changed Dart sources and tests were formatted with `dart format`.
- `flutter analyze --no-pub`: exit 0, no issues.
- Full `flutter test --no-pub`: exit 0, **2,074 passed, 58 skipped**.
- Required focused import/topic-creator/template/workspace/controller/TOC/UI
  suites, including the focused import dialog: exit 0, **335 passed**.
- `bash tools/validate_writerside_conformance.sh`: exit 0, **181 checks passed**.
  This uses the pinned builder 2026.08.0328, distinct from the selected UI plugin
  2026.07.8925. It checks the semantic fixture, not website or menu parity.
- Linux interaction harness: result artifact reports no failure and **50 checks
  passed**.
  Includes real GTK two-level keyboard traversal in LTR/RTL, disabled headings,
  Escape, focus return, session-scoped dismissal, existing flat radio selectors,
  both Add Local Markdown Files menu locations, the reviewed removal flow,
  mandatory Safe Delete, and the core TOC/template workflows in the action
  matrix.
- Normal `flutter build linux --debug --no-pub --target lib/main.dart`: exit 0;
  the bundle is restored to the normal application, not the acceptance harness.
- `git diff --check`: exit 0.

The 58 full-suite skips are optional Typst/PDF/Poppler and D2 integrations that
require explicit tool-path environment configuration. No unavailable optional
integration is counted as a passing TOC or native-menu check.

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
| Topic creation inherited preview-only mode | Successful `createWritersideTopic` makes only the new preview-only buffer editable, within the controller's file-operation boundary. Existing editable modes, other tabs, and the global preference remain unchanged. | `writerside_toc_regressions_test.dart`: explicitly put the active document and application preference into Reading mode before Empty MD, Empty XML, and template-dialog creation; verify the new topic opens in Source mode while the global preference, existing tab modes, template body, and unrelated dirty content remain unchanged. |

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

## Edit Title and dialog-copy review — 2026-09-14

This follow-up starts from clean commit `7023934`; the five earlier corrections
remain intact. No GTK menu implementation or approved adaptation was replaced.

| Finding | Correction and regression evidence |
| --- | --- |
| Literal newlines inside quoted XML attributes had no source range | `_attributeSpans` now matches multiline values. `WritersideTitleEditor` refuses to treat an existing attribute with a missing range as absent, and validates the resulting full XML topic/tree (including duplicate attribute names) before `WorkspaceService` can stage either write. Generated Markdown title elements are also XML-validated. |
| CRLF attributes differed between raw tree identities and normalized editor buffers | Title editing opts into line-ending-normalized identity comparison. Raw structural mutations retain exact matching, and the original file snapshots are still checked before publication. Changed semantic content remains a conflict. |
| Markdown instance titles exposed and re-escaped entity spellings | `_topicTitleOverrides` reads top-level parsed semantic title elements, not raw-source matches. XML entities are decoded once by the parser; the writer still escapes text. Fenced examples are excluded and single-quoted instance attributes work. |
| Removal and advanced title dialog copy differed | English removal now uses `Set redirect to:`, `{count} usages found.`, and the pictured confirmation paragraph. Advanced title settings show the two inheritance explanations beneath their fields and a working documentation link. All 23 maintained ARBs were updated and localizations regenerated. |

`writerside_title_regressions_test.dart` covers LF/CRLF and both quote styles,
changing and clearing overrides, preserved unrelated attributes/content,
missing/corrupt ranges with neither file published, duplicate XML attributes,
semantic title extraction, and actual save–reopen–edit dialog workflows. It also
checks unchanged OK and documentation-link activation. The live removal dialog
copy and cancellation are checked in `writerside_toc_regressions_test.dart`.

Copy evidence: the official [instance-title screenshot](https://resources.jetbrains.com/help/img/writerside/edit_title_instance_specific.png),
[TOC-title screenshot](https://resources.jetbrains.com/help/img/writerside/edit_title_toc_title.png),
and [removal screenshot](https://resources.jetbrains.com/help/img/writerside/remove_topic_dialog.png),
cross-checked against installed 2026.07.8925 `EditTitleDialog.comment.*` and
`RemoveTocElementDialog.*` bundle entries. The usage-count period follows the
specified screenshot (the installed bundle omits it). The documentation link
opens the current [Topics page](https://www.jetbrains.com/help/writerside/topics.html),
which contains title inheritance and overrides; the installed dialog's older
`changing-topic-title.html` URL was not retrievable.

This corrects the reported functional defects and specified copy gaps, not all
original-product presentation differences. The two unidentified icon-only
toolbar controls remain unimplemented/unverified; no guessed controls or names
were added. The existing removal promotion, mixed-XML sorting restriction,
BusyMark preview renderer, approved template editor/storage and Find sidebar
remain explicitly documented adaptations. Full original-Writerside parity is
not claimed. Translations are BusyMark translations, not verified original
JetBrains locale strings.

Verification for this follow-up (Flutter 3.47.2 / Dart 3.13.2):

- Full `flutter test --no-pub --concurrency=2 --file-reporter json:/tmp/busymark-title-full.json`:
  exit 0, **1,938 passed, 58 optional integration skips**; 17 new regressions.
- Documented Writerside/source/controller/export suite, with `--concurrency=2`:
  exit 0, **433 passed, 1 optional Typst skip**;
  `/tmp/busymark-title-focused-suite.json`.
- `flutter analyze --no-pub`: exit 0, no issues. Localization generation,
  formatting checks on nine non-generated Dart files, and `git diff --check`:
  exit 0.
- `bash tools/validate_writerside_conformance.sh`: exit 0, **181 checks passed**;
  `/tmp/busymark-title-builder.log`.
- Native Linux harness: exit 0, **36 checks passed, 20 captures**;
  [result](/tmp/busymark-title-native-review/result.json). The production
  [advanced title dialog](/tmp/busymark-title-native-review/03-edit-title.png)
  and [removal dialog](/tmp/busymark-title-native-review/06-removal.png) were
  visually inspected. Real GTK menus and their keyboard/focus tests passed.
  The private desktop emitted portal, synthetic-popup and D-Bus teardown
  diagnostics; this is not a warning-free desktop claim. Only the disposable
  `/tmp/busymark-toc-native-ZIOBPT` fixture was mutated.
- `flutter build linux --debug --no-pub --target lib/main.dart`: exit 0;
  `/tmp/busymark-title-linux-build.log`. The bundle was restored to the normal
  application after the harness run.
