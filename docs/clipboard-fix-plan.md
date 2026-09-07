# Editor clipboard fix

Status: implemented for the Linux desktop host.

Editor copy previously published only plain text. Formatting stayed in a private
cache inside one Editor widget, so a fresh Editor or another application could
not retrieve it. Copy now publishes three representations in one GTK clipboard
operation, and ordinary paste uses the richest supported representation.

| Representation | Purpose |
| --- | --- |
| `application/x-busymark-fragment+json` | Preserve BusyMark structure, inline formatting, task states, tables, and Writerside content between instances. |
| `text/html` | Preserve headings, emphasis, links, lists, tables, and code in compatible external applications. Tasks have visible checked/unchecked symbols. |
| Standard GTK text targets | Support text-only destinations and Paste without formatting. |

## Implementation

- `rich_clipboard_service.dart` serializes competing writes and reads the system
  clipboard without a private formatting cache. A native write publishes all
  formats together; it is never followed by a plain write that would erase them.
- `rich_clipboard_host.cc` owns immutable payload bytes independently of the
  originating widget. Reads are asynchronous and reject data from an owner that
  changes during the read. Transfers are limited to 16 MiB. The host advertises
  all formats for clipboard-manager storage using
  [`gtk_clipboard_set_can_store`](https://docs.gtk.org/gtk3/method.Clipboard.set_can_store.html).
  GTK's existing application shutdown performs the storage request.
- `wysiwyg_clipboard_fragment.dart` uses a versioned, bounded, validated JSON
  schema. Block IDs are regenerated during insertion. Relative links are rebased
  and resolved local media paths are carried between documents/projects.
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

- 237 editor/model regression tests pass, including fresh Editor instances,
  same-Editor cut/paste, partial selections, nested lists, blockquotes, tasks,
  tables, code, Writerside, images, RTL, math, undo/redo, malformed fragments,
  serialized writes, failed cut, delayed paste, and a later plain-text copy.
- Both reported files, `issues.md` and `writerside-support.md`, passed a read-only
  codec and insertion probe. Heading, task, table, blockquote, and code content
  survived; exported HTML also imported successfully.
- Separate compiled BusyMark processes exchanged JSON, HTML, and plain text on
  isolated X11 and headless GNOME Wayland displays. A subsequent Flutter plain
  copy cleared the rich formats.
- LibreOffice Writer pasted a Heading 1 paragraph, bold text, and visible checked
  and unchecked task states from the compiled Linux implementation.

The native probe entrypoint is `tools/clipboard_smoke.dart`. Build it with
`flutter build linux --debug -t tools/clipboard_smoke.dart`, then run `write`,
`read`, or `plain` with the same temporary output directory on an isolated display.
Keep `write` running until the reads complete; creating a `stop` file in that
directory closes it. Rebuild with the default entrypoint afterward.

## Interoperability limits

Clipboard persistence after the source process exits depends on the desktop's
clipboard manager and the formats it retains. That exit scenario remains a manual
check. Source-widget disposal does not discard clipboard payloads. External
applications choose which offered format to consume; plain-text applications
will still paste plain text. Writerside-specific structures remain editable
through the BusyMark format and use readable HTML fallbacks externally. Local
media references point to existing files and do not bundle their bytes.

Hosts without the Linux method channel currently fall back to plain text.
