# Clipboard History and Local History

BusyMark provides two separate history tools. Clipboard History helps you
reuse copied material during the current application session. Local History
keeps source revisions on this device so that earlier document content can be
compared and restored.

## Clipboard History

Open **Clipboard History** from the sidebar selector, main menu, command
palette, or a document editor's context menu. The panel stays open while you
move between documents and selections. Select an item to preview it, then use
**Paste**, **Paste as Plain Text**, Enter, or double-click to insert it at the
latest visible editable selection. Escape returns focus to the editor.

BusyMark collects successful copy and cut operations from document editors,
plus supported content copied in another application after it is successfully
pasted into a BusyMark document. The current system clipboard can be refreshed
and previewed without adding it to the retained list. Search examines the full
text, not only the row excerpt.

History can contain exact Source selections, BusyMark rich fragments, and
supported clipboard images. An image is retained as bytes; it is added to a
document's assets only when pasted. Rich fragments retain a source form for
cross-mode insertion. Unavailable local references are not silently resolved
against an unrelated destination.

Clipboard History is memory-only and is discarded when BusyMark exits. It
keeps at most 100 entries and 64 MiB in total, evicting the oldest entries
first. An item larger than the total budget can still be copied or pasted but
is not retained. **Clear Clipboard History** clears BusyMark's list, not the
operating-system clipboard. Collection can be disabled under
**Settings → History** without clearing existing session entries.

## Local History

Open **Local History** from the sidebar selector, command palette, document
tab or editor context menu, or a file-tree context menu. **Find in Local
History…** also finds closed, renamed, deleted, and untitled documents by
stored name, path, and revision content, even when their original workspace is
not open.

BusyMark records complete source text and its encoding/line-ending policy. A
baseline is captured when an eligible existing document is first tracked.
Later revisions record successful explicit saves, 60-second automatic
checkpoint windows, and content protected before known reload, discard,
restore, delete, or external-change operations. The checkpoint deadline is
not postponed by continued typing, and the ordinary 1.5-second autosave does
not create a revision per write. Unchanged adjacent content is deduplicated.

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
Cancelling or failing recovery does not remove the retained revision.

Local History defaults to 30-day retention and 512 MiB total storage. Either
limit may remove older entries sooner. Under **Settings → History**, recording,
the checkpoint interval, age, storage limit, and exclusions are configurable.
Each exclusion is one absolute file or directory path; a directory excludes
all descendants using the host platform's path rules. Relative and blank lines
are ignored. Disabling recording stops new automatic and protective captures
but leaves existing revisions available until retention or explicit clearing.

Clearing one document's history or all Local History permanently removes only
stored revisions. It does not delete project files, Git data, recovery data, or
the system clipboard.

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
