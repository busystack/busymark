# References and links

Open **References** from the sidebar menu or Command Palette. The panel follows
the current document and shows its workspace/account scope. Switch between
Incoming and Outgoing, or choose a parsed heading, topic element, or reusable
fragment. Rows show the authored context, destination, and resolution status.
Writerside rows retain their module and origin; **Unavailable in this context**
can mean an instance condition rather than a missing topic. **Show more results**
continues through the complete result set.

Select a row to follow its reference. The row menu also provides **Source
location** and **Target location**. These actions check the current source
revision; stale positions refresh instead of selecting unrelated text. The
normal navigation keeps your view where it can show the target. Use Source
location for syntax that Editor or Reading cannot represent.

The index includes unopened workspace documents and unsaved buffer content.
It is derived data: rebuilding it does not save files or alter Notes history or
synchronization. Unreadable files, unsafe paths, and documents larger than 2 MiB
are unavailable for inspection. Code examples and escaped link syntax do not
create references. External destinations without a supported internal target
are marked Unsupported; normal external-link navigation remains available.

## Insert or edit a link

Select text in Source or Editor and use the existing Link action (Ctrl+K).
Search the target chooser for a document/topic or an actual parsed heading ID.
Unicode heading and explicit IDs use ordinary percent-encoded URL fragments;
References resolves them to the actual parsed ID without changing authored bytes.
Manual URL entry remains available. XML topics receive semantic Writerside
links through the existing adapter, including namespace and module origin.
Reading follows links; it does not insert them. Cancelling restores focus and
makes no edit. A changed document, selection, workspace, or edit permission
invalidates the pending selection.

## Rename and move local Markdown

Use the ordinary Files sidebar **Rename**, or **Cut** and **Paste** to move a
file or folder. Resolve unsaved affected buffers through the save review first.
BusyMark then shows the files and exact destination edits before Apply.
Incoming document links and outgoing relative links/media are reviewed together.
Reference definitions are edited once; link labels, text, titles, queries,
fragments, formatting, encoding and line endings are preserved. Code and prose
are not globally replaced. Writerside topic operations retain their established
Rename Preview workflow.

If files, folder membership, filesystem identity or the destination change
between review and Apply, prepare and review the operation again. Unsafe paths,
uninspectable Markdown, mixed line endings and unavailable Local History
protection block the operation with an explanation. Cancellation before Apply
makes no refactoring changes. After an interrupted publication, References
exposes Recovery. Review the pending recovery before applying it; newer external
content prevents automatic restoration and the recovery evidence remains.
Recovery also verifies the moved file/folder identity, including entries that had
no reference edits. Recreated original paths or replaced destinations require
manual review and retain the journal. Older journals without identity evidence
are retained for manual review rather than inferred from path existence.

## Portable Nextcloud note links

Choose a synchronized note to insert its ordinary HTTPS Notes web URL.
BusyMark first observes the installation's public routing configuration and uses
`https://server/installation/index.php/apps/notes/note/123` or its configured
pretty form, `https://server/installation/apps/notes/note/123`. This observation
is cached for offline authoring. If the route cannot be confirmed, the chooser
explains the failure and manual URL entry remains available. The real server ID
survives title/category changes. Both forms are recognized when pasted from a
browser. BusyMark intercepts only the exact connected
installation; other URLs retain external navigation. Account removal disables
that account's internal link resolution.

Cached targets open offline, including after a process restart. An uncached
recognized target uses authenticated individual-note retrieval. Deleted,
forbidden, unavailable and offline targets produce explicit errors. Recovery or
import creates a new identity and does not redirect an old note ID to it.

A never-synchronized note has no confirmed server ID and cannot supply a
portable target URL. The chooser explains this rather than creating another
note. Note heading targets are disabled: the verified Notes browser view does
not expose BusyMark's parsed Markdown heading IDs. BusyMark does not
invent a persistent link syntax for this limitation.
