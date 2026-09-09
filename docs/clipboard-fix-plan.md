# Editor clipboard fix

Status: implemented for the Linux desktop host.

Editor copy previously published only plain text. Formatting stayed in a private
cache inside one Editor widget. Copy now publishes interoperable text and HTML
plus an opaque BusyMark ownership token in one GTK clipboard operation, and
ordinary paste uses the richest safely recognized representation.

| Representation | Purpose |
| --- | --- |
| `application/x-busymark-token` | Resolve immutable structured content only inside the BusyMark process/session that created it. |
| `text/html` | Preserve headings, emphasis, links, lists, tables, and code in compatible external applications. Tasks have visible checked/unchecked symbols. |
| Standard GTK text targets | Support text-only destinations and Paste without formatting. |

## Implementation

- `rich_clipboard_service.dart` serializes competing writes and coherent reads.
  It keeps a bounded, process-session map from opaque tokens to immutable rich
  fragments; unknown tokens never deserialize internal object graphs. A native
  write publishes all formats together and is never followed by a plain write
  that would erase them.
- `rich_clipboard_host.cc` owns immutable payload bytes independently of the
  originating widget. Reads are asynchronous and reject data from an owner that
  changes during the read. Transfers are limited to 16 MiB. The host advertises
  all formats for clipboard-manager storage using
  [`gtk_clipboard_set_can_store`](https://docs.gtk.org/gtk3/method.Clipboard.set_can_store.html).
  GTK's existing application shutdown performs the storage request.
- `wysiwyg_clipboard_fragment.dart` uses a versioned, bounded, validated JSON
  schema inside the owning process. Block IDs are regenerated during insertion.
  Relative links are rebased and retained local media bytes are ingested for the
  destination document when a Clipboard History item is inserted.
- `wysiwyg_clipboard_html.dart` exports semantic HTML directly from the copied
  blocks. On import it normalizes supported CSS emphasis and checkbox state,
  strips executable markup and unsafe URLs, and uses the existing HTML adapter.
  It does not change the document HTML policy or write publication assets.
- Editor copy snapshots the selection before asynchronous work. Cut deletes only
  after a successful write. Paste and cut recheck the file, document generation,
  active block/cell, and selection before changing the document. Nested children
  are copied once; complete blockquotes retain their container.
- Insertion preserves inline nodes, including image references, and supports
  partial selections and one-step undo/redo. Table cells retain supported inline
  styles while block boundaries become spaces. Cells displayed as math source
  retain their existing text insertion behavior.

## Validation

- 238 editor/model regression tests pass, including fresh Editor instances,
  same-Editor cut/paste, partial selections, nested lists, blockquotes, tasks,
  tables, code, Writerside, images, RTL, math, undo/redo, malformed fragments,
  serialized writes, failed cut, delayed paste, and a later plain-text copy.
- A document-wide selection has its own right-click menu for Cut, Copy, Paste,
  Select all, and Refine with AI when available. The selected blocks stay active
  while the menu opens, including when the pointer is over a table cell.
- Both reported files, `issues.md` and `writerside-support.md`, passed a read-only
  codec and insertion probe. Heading, task, table, blockquote, and code content
  survived; exported HTML also imported successfully.
- Separate compiled BusyMark processes exchanged interoperable HTML and plain
  text on isolated X11. The foreign opaque token deliberately did not resolve,
  while a same-process round trip resolved its rich fragment. A subsequent
  Flutter plain copy cleared the rich formats.
- LibreOffice Writer pasted a Heading 1 paragraph, bold text, and visible checked
  and unchecked task states from the compiled Linux implementation.

The native probe entrypoint is `tools/clipboard_smoke.dart`. Build it with
`flutter build linux --debug -t tools/clipboard_smoke.dart`. Run `roundtrip` to
verify same-process token resolution. Then run `write` and, while it owns the
clipboard, run `read` from a second process to verify interoperable HTML plus
non-resolution of the foreign token. Run `plain` afterward to verify stale rich
representations are gone. Use the same temporary output directory on an isolated
display; creating a `stop` file in that directory closes the writer. Rebuild with
the default entrypoint afterward. Under `xvfb-run`, set `GDK_BACKEND=x11`
explicitly so an inherited `WAYLAND_DISPLAY` cannot select an unrelated Wayland
connection. Wayland native behavior requires a compositor-driven run with real
input focus; the isolated automated probe in this checkout verifies X11.

## Interoperability limits

Clipboard persistence after the source process exits depends on the desktop's
clipboard manager and the formats it retains. That exit scenario remains a manual
check. Source-widget disposal does not discard clipboard payloads. External
applications choose which offered format to consume; plain-text applications
will still paste plain text. Writerside-specific structures remain editable
through the owning session's immutable payload and use readable HTML fallbacks
externally. Clipboard History packages supported local media bytes within its
stated budget.

Hosts without the Linux method channel currently fall back to plain text.
