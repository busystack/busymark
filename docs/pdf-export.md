# PDF export

Choose **Main menu → Export as PDF…**, use the command palette, or press
**Ctrl+Shift+E**. Markdown exports the active editor text, including unsaved and
untitled documents. Writerside first offers Save, Discard, or Cancel for project
changes, then lets you select a non-library instance.

The export settings are independent of the editor and preview appearance.
Markdown and Writerside offer the same PDF controls:

- **Content:** include a table of contents, choose its heading depth from 1–6,
  and number headings. Numbering does not modify your source. The table of
  contents uses the document’s headings and page numbers.
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

After you confirm the settings, BusyMark remembers them globally for the next
PDF export, including exports from other documents and Writerside modules.
**Reset to defaults** restores the default values in the dialog. Cancel leaves
your remembered settings unchanged. PDF and HTML remember separate settings.

Defaults are A4 portrait, normal margins, 10.5 pt serif body text, 8.4 pt code,
blue links, and centered page numbers on all pages. Generated TOC and heading
numbering are off. Custom page dimensions describe the portrait geometry;
landscape swaps the width and height.

Choose the destination after confirming settings. BusyMark asks before
replacing an existing file. Export can be cancelled, and a failed export keeps
the previous PDF usable.

## Offline content

PDF export works locally with BusyMark’s included PDF, math, and diagram tools.
It does not download remote images, fonts, or other resources. Supported local
images, equations, diagrams, tables, links, and static API documentation remain
part of the exported document. When supported content cannot be rendered,
BusyMark reports a warning and keeps readable alternative text or source where
possible.

For instance ordering and Writerside content behavior, see
[Writerside PDF export](writerside-pdf-export.md).
