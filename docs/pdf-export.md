# PDF export

Choose **Main menu → Export**, use the command palette, or press
**Ctrl+Shift+E**. The contextual action also remains under
**Outline → Actions** for Markdown and **Topics → Actions** for Writerside.
Markdown exports the active editor text, including unsaved and untitled
documents. For Writerside, BusyMark first offers Save, Discard, or Cancel for
project changes, then lets you select a non-library instance. Every route uses
the same document-versus-instance scope.

The export settings are independent of the editor and preview appearance.
Markdown and Writerside offer the same PDF controls:

- **Content:** include a table of contents, choose its heading depth from 1–6,
  and number headings. Numbering does not modify your source. The table of
  contents uses the document’s headings, links, and destination page numbers.
  It starts on a separate page, can span multiple pages, and is always followed
  by a page break before the document body.
- **Title page:** optionally include a generated title page. Enabling it shows
  editable Title, Subtitle, Author, Organization, Version, and Date fields.
  Title is required; empty optional fields are omitted. This page never shows
  a running header, footer, or visible page number.
- **Page:** A4, US Letter, US Legal, or custom dimensions in millimetres;
  portrait or landscape; narrow, normal, wide, or four independent custom
  margins. Custom dimensions are 50–1200 mm. Margins must leave at least 20 mm
  of content width and height.
- **Typography:** serif or sans-serif body text, body size from 8–24 pt, and
  code size from 6–20 pt. BusyMark includes Noto fonts for consistent PDF
  typography. Heading sizes scale with the body size, and equations use the
  selected typography and available page width.
- **Header & Footer:** no text or the resolved document title in either area;
  page numbers off, bottom left, bottom center, or bottom right; and whether
  headers, footers, and page numbers appear on the first page.
- **Appearance:** an accent/link color, chosen from the palette or entered as
  `#RRGGBB`.

After you confirm the settings, BusyMark remembers reusable PDF preferences
globally, including the title-page toggle. **Title-page text belongs only to
the current export** and is never saved as a default for other documents.
**Reset to defaults** disables the title page and restores its text fields to
the current document’s metadata defaults. Toggling the title page off and back
on retains your edits within that dialog. Cancel leaves remembered settings
unchanged and discards the dialog’s text edits. PDF and HTML remember separate
settings; HTML has no title-page option.

Defaults are A4 portrait, normal margins, 10.5 pt serif body text, 8.4 pt code,
blue links, and centered page numbers on all pages. Generated title page, TOC,
and heading numbering are off. Custom page dimensions describe the portrait geometry;
landscape swaps the width and height.

Choose the destination after confirming settings. BusyMark asks before
replacing an existing file. Export can be cancelled, and a failed export keeps
the previous PDF usable.

## Title-page defaults and pagination

Markdown uses the same captured editor text for metadata and document content,
including unsaved changes. Title defaults follow the existing precedence:
explicit title override, front-matter title, document title, filename, then
“Untitled”. Author accepts `author` or `authors` metadata. Optional `subtitle`,
`organization`, `version`, and `date` come from source metadata when present.
For a Writerside instance, the default title is the selected instance’s display
name, not the open topic’s title. An existing instance or inherited project
version supplies Version; unavailable metadata stays empty. Selecting another
instance refreshes untouched fields without overwriting edited text.

You can override any field for this export. Explicitly clearing an optional
field keeps it omitted. Date and Version are plain display text: BusyMark does
not infer them from your account, Git, application version, or file timestamps.
All fields remain plain text, never executable Typst or Markdown. The cover
uses your selected body font, accent color, page geometry, and margins. Text
wraps; if it cannot fit one page, export fails with a message asking you to
shorten it or enlarge the content area. It is not clipped or spilled into the TOC.

Sections appear in this order: optional title page, optional TOC, then the
unchanged document body. Each enabled front-matter section starts on a new
page. A long TOC continues naturally, and the body never shares its last page.
No odd-page alignment or empty separator pages are added. The generated title
and TOC heading do not become numbered body sections or TOC entries. The
original first source heading, body anchors, and PDF bookmarks are retained.

Page numbers remain continuous Arabic numbers, including the hidden title-page
number. With one title page and one TOC page, the body begins on physical page
3. Turning visible page numbers off does not remove the TOC’s destination page
references. **Show on first page** still means physical page 1, not the first
body page; a title page always suppresses running text regardless of that setting.

## Intentional blank lines

Use **Insert blank line** in Editor view when a specific one-line gap is part of
the document. BusyMark stores the gap as two explicit `<br>` elements, so it is
visible in Editor and Reading views and preserved by Markdown PDF and HTML
exports. Source view places each generated `<br>` on a marker-only line instead
of appending the tags to document text.

Additional empty source lines are still ordinary Markdown block separators;
repeating them does not create additional vertical space.

## Offline content

PDF export works locally with BusyMark’s included PDF, math, and diagram tools.
It does not download remote images, fonts, or other resources. Supported local
images, equations, diagrams, tables, links, and static API documentation remain
part of the exported document. When supported content cannot be rendered,
BusyMark reports a warning and keeps readable alternative text or source where
possible.

For instance ordering and Writerside content behavior, see
[Writerside PDF export](writerside-pdf-export.md).
