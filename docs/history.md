# Clipboard History and Local History

BusyMark provides two independent history tools. Clipboard History keeps copied
material for reuse during the current application session. Local History keeps
document revisions on this device for comparison and recovery.

## Clipboard History

Open **Clipboard History** from the sidebar, command palette, or an editor
context menu. Search examines each item's complete text. Select an item and use
**Paste** or **Paste as Plain Text**; Enter and double-click also insert the
selected item at the latest editable selection.

BusyMark collects successful copy and cut operations from its editors. Supported
content copied in another application is added after it is successfully pasted
into BusyMark. Refresh can inspect the current system clipboard without adding
it to the retained list.

Entries can contain Source selections, BusyMark rich fragments, supported HTML,
plain-text alternatives, and images. Rich content retains Markdown structure
for insertion between BusyMark editors. Supported external HTML goes through
the same safe conversion as an ordinary paste. Image bytes are retained and are
added to a document's assets only when you paste them.

Clipboard History is memory-only and disappears when BusyMark exits. It keeps
up to 100 entries and 64 MiB in total, evicting the oldest entries first. An
oversized item can still be copied or pasted but is not retained. Clearing
Clipboard History does not clear the operating-system clipboard. Collection can
be disabled under **Settings → History** without removing existing session
entries.

Clipboard persistence after the source application exits depends on the Linux
desktop's clipboard manager. External applications decide whether to consume
HTML or plain text, and Writerside-specific structures use readable HTML or
plain-text fallbacks outside BusyMark.

## Local History

Open **Local History** from the sidebar, command palette, an editor or document
tab context menu, or a file-tree context menu. The revision list normally follows
the active document.

Use **Find in Local History…** to locate retained closed, renamed, deleted, and
previously untitled documents by name, path, or revision content. Selecting a
result temporarily inspects that document; use Back to return to the active
document.

BusyMark stores complete source text together with its encoding and line-ending
policy. It records:

- a baseline when an eligible existing document is first tracked;
- successful explicit saves;
- automatic checkpoints, every 60 seconds by default; and
- protective revisions before reload, discard, restore, delete, or a known
  external change.

Continued typing does not postpone an active checkpoint window, and ordinary
autosave does not create a revision for every write. Adjacent revisions with
identical content are deduplicated.

Select a revision to compare it with the current unsaved editor buffer, or with
a fresh disk snapshot when the document is not open. You can copy source,
restore the complete revision, or restore an exact changed region when the
comparison is current and precise. A restore is one normal undoable edit and
follows the current autosave setting.

Before restoring content, BusyMark must save a protective revision of the
current document. If Local History recording is disabled, the path is excluded,
or storage fails, BusyMark leaves the document unchanged.

For a deleted file, use **Restore to Original Location** or **Restore to New
Location…**. An existing destination uses the normal overwrite confirmation and
is protected before the retained source is applied. With autosave disabled, the
disk file remains unchanged until you save.

## Retention, failures, and clearing

Local History defaults to 30 days and 512 MiB. Either limit can remove older
entries sooner. Under **Settings → History**, you can change recording, the
checkpoint interval, age and storage limits, and excluded paths. Each exclusion
must be an absolute file or directory path; a directory excludes its descendants.
Blank and relative entries are ignored.

When a history write fails, BusyMark reports the failure and may retry the latest
pending source during the current session. The document itself can still save,
but an operation that requires a protective revision remains blocked until that
revision is safely stored.

Clearing one document or all Local History permanently removes only stored
revisions. It does not delete project files, Git data, crash-recovery data, or
clipboard content. New edits after a clear begin a new checkpoint window.

## Choosing the right recovery tool

- **Undo/redo** is the current document's bounded in-memory edit sequence.
- **Crash recovery** protects recent unsaved buffers after an interrupted
  session; it is not a revision timeline.
- **Local History** is a timestamped, on-device source timeline. It is not
  encrypted, a backup, or an audit log.
- **Git history** is repository history. Local History never creates commits,
  refs, or sidecar repositories.

Clipboard and Local History content is not sent to AI providers, telemetry, or
diagnostic logs by these features. Contributor-facing storage and transaction
details are in [History implementation notes](development/history.md).
