# Clipboard History and Local History

BusyMark provides two separate history tools. Clipboard History helps you
reuse copied material during the current application session. Local History
keeps source revisions on this device so that earlier document content can be
compared and restored.

## Clipboard History

Open **Clipboard History** from the sidebar selector, command palette, or a
document editor's context menu. The panel stays open while you move between
documents and selections. Each row preserves up to three lines of the item's
source preview; its type, capture time, and origin are available in the row
tooltip. Use its action menu for **Paste** or **Paste as Plain Text**; Enter and
double-click insert the selected item at the latest visible editable selection.
Escape returns focus to the editor.

The panel toolbar keeps the search field first and the contextual **Actions**
menu on its physical right. That menu owns **Refresh** and **Clear Clipboard
History**; these commands are not application Main-menu entries.

BusyMark collects successful copy and cut operations from document editors,
plus supported content copied in another application after it is successfully
pasted into a BusyMark document. The current system clipboard can be refreshed
and previewed without adding it to the retained list. Search examines the full
text, not only the row excerpt.

History can contain exact Source selections, BusyMark rich fragments, and
supported clipboard images. Supported HTML copied from another application is
kept with its plain-text alternative before the first paste; normal WYSIWYG
insertion uses the same validated HTML conversion as ordinary Paste, while
**Paste as Plain Text** uses only the text alternative. An image is retained as
bytes; it is added to a document's assets only when pasted. Rich fragments
retain a source form for cross-mode insertion. Unavailable local references are
not silently resolved against an unrelated destination.

Clipboard History is memory-only and is discarded when BusyMark exits. It
keeps at most 100 entries and 64 MiB in total, evicting the oldest entries
first. An item larger than the total budget can still be copied or pasted but
is not retained. **Clear Clipboard History** clears BusyMark's list, not the
operating-system clipboard. Collection can be disabled under
**Settings → History** without clearing existing session entries.

## Local History

Open **Local History** from the sidebar selector, command palette, document
tab or editor context menu, or a file-tree context menu. In ordinary use its
plain filename header and revision list follow the active document tab; moving
focus to search, a revision, the comparison, or an action does not change that
scope. The header tooltip contains the full path when one exists.

Its toolbar likewise places the contextual **Actions** menu to the physical
right of the search field. **Refresh**, **Find in Local History…**, and clear
commands stay in that menu rather than the application Main menu.

Use **Find in Local History…** from Local History's header action menu or the
command palette to find closed, renamed, deleted, and previously untitled
documents by stored name, path, and revision content, even when their original
workspace is not open. Selecting a result temporarily inspects that retained
document in the same sidebar. Its missing/deleted state is explicit, and the
local Back action returns to the active document. There is no store-wide
document selector in the ordinary history view.

BusyMark records complete source text and its encoding/line-ending policy. A
baseline is captured when an eligible existing document is first tracked.
Later revisions record successful explicit saves, 60-second automatic
checkpoint windows, and content protected before known reload, discard,
restore, delete, or external-change operations. The checkpoint deadline is
not postponed by continued typing, and the ordinary 1.5-second autosave does
not create a revision per write. Unchanged adjacent content is deduplicated.

Typing, deletion, paste, selected-text formatting, Undo, Redo, and source
changes made to an inactive open document update the authoritative editor
buffer immediately. Local History observes the complete serialized source and
keeps only the latest eligible source pending for that document's current
checkpoint window. Pending work is not presented as a stored revision. When a
checkpoint or explicit-save capture succeeds, the already-open revision list
and any active content filter reconcile automatically; **Refresh** only rereads
stored history and never forces a capture or document save.

If storage fails, the panel reports the failure and keeps the latest eligible
source pending in memory for a controlled retry. A newer edit replaces an
older pending source. The revision is not durable and is not described as
saved until storage actually succeeds. A document file can still save
successfully when this separate history write fails; destructive history
restore operations that require a protective revision remain blocked by such
a failure.

Revisions are grouped by local calendar date and use the localized time,
including seconds, as the primary row label. Distinct events such as Saved,
Before restore, or External change appear as secondary metadata. Automatic and
baseline capture reasons remain available in the row's tooltip and accessible
description without becoming a repeated visible title.

Selecting a revision opens a read-only source comparison against the unsaved
editor buffer when available, otherwise a fresh disk snapshot. Missing files
are identified explicitly. You can copy selected source, restore the whole
revision, or restore an exact change when the comparison is current and exact.
Each restore is one ordinary undoable document edit and follows the existing
autosave setting. Before a restore, BusyMark must persist a protective snapshot
of the current content. If recording is disabled, the path is excluded, or the
capture fails, the restore leaves the document unchanged.

For a deleted file, use **Restore to Original Location** or **Restore to New
Location…**. Existing destinations require the normal overwrite decision.
After approval, BusyMark opens and protects the destination's real current
content, then applies the retained source as one edit. With autosave disabled,
the existing disk file is untouched until Save, and Undo returns to the
destination's original editor content. Autosave may publish the recovered edit
through the ordinary save path, but recovery never publishes an intermediate
empty file. Cancelling or failing recovery changes neither destination nor the
retained revision.

Local History defaults to 30-day retention and 512 MiB total storage. Either
limit may remove older entries sooner. Under **Settings → History**, recording,
the checkpoint interval, age, storage limit, and exclusions are configurable.
Each exclusion is one absolute file or directory path; a directory excludes
all descendants using the host platform's path rules. Relative and blank lines
are ignored. Disabling recording stops new automatic and protective captures
but leaves existing revisions available until retention or explicit clearing.

Clearing one document's history or all Local History permanently removes only
stored revisions. It does not delete project files, Git data, recovery data, or
the system clipboard. Clearing the revision currently being compared closes
that transient comparison and returns to the unchanged editor. Scheduled or
in-flight work accepted before the clear cannot recreate the erased history;
new edits after the clear begin a normal checkpoint window and automatically
reattach the active document's list.

## What each recovery tool means

- **Undo/redo** is the current document's bounded in-memory edit sequence.
- **Crash recovery** protects the newest unsaved buffers after an interrupted
  session; it is not a revision timeline.
- **Local History** is a timestamped, on-device source revision timeline. It is
  not encrypted, a backup, or an audit log.
- **Git File History and Project History** remain repository history. Local
  History never creates commits, refs, or sidecar repositories.

Clipboard and Local History content is not sent to AI providers, telemetry, or
diagnostic logs by these features.
