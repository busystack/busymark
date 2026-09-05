# HTML export

Choose **Main menu → Export as HTML…** or use the command palette. HTML has no
default shortcut; **Ctrl+Shift+E** continues to export PDF.

Markdown exports the active document’s current editor text, including unsaved
and untitled content. Writerside first offers Save, Discard, or Cancel for
project changes, then lets you choose a non-library instance and a dedicated
output directory.

## Export settings

Markdown and Writerside share the same HTML settings, independently of your
editor and preview theme:

- **Content:** include a heading-based table of contents, choose a depth from
  1–6, and number headings. The TOC links to the existing heading anchors.
  Numbering changes the export only. The heading outline remains enabled by
  default; heading numbering is off.
- **Appearance:** light, dark, or automatic theme; serif or sans-serif body
  text; a base size from 12–28 px; and an accent/link color. Automatic follows
  the browser’s light/dark preference. Code uses the export’s theme without
  requiring a browser highlighting library.
- **Layout:** a maximum content width from 320–1920 px. Pages still adapt to
  smaller screens; wide code blocks and tables scroll within the page.
- **Output:** a single HTML file or HTML with an assets directory, plus an
  optional custom stylesheet.

Defaults are a light theme, 17 px sans-serif text, a maximum width of 918 px,
blue links, an assets directory when needed, and no custom stylesheet.

BusyMark remembers the last confirmed HTML settings globally, including across
Markdown and Writerside exports. PDF settings are remembered separately.
**Reset to defaults** restores the default values in the dialog. Cancelling
the settings dialog leaves the remembered values unchanged.

## Packaging

**Single HTML file** embeds the local and generated resources needed by a
Markdown document, so you can copy the `.html` file on its own. Remote resources
are not downloaded or embedded.

**HTML + assets directory** places images, media, downloads, and generated
graphics in a companion `<name>.assets` directory using relative links. Keep
the HTML file and that directory together when copying the export. A text-only
document needs just the HTML file.

Writerside always retains separate linked topic pages and an `index.html`
entry point. With an assets directory, pages share `assets/`. In single-file
mode, each topic page embeds its resources; copy the entire instance directory
to preserve navigation. Hidden topics retain pages without navigation entries,
and work-in-progress entries retain their status. Repeated TOC references share
one page. Existing topic filenames and resolved instance order are preserved.

Both modes work offline when opened directly in a browser or served by a static
web server. No BusyMark installation, preview server, or original source folder
is required to read them.

## Custom CSS

Select **Custom stylesheet…** to choose a local UTF-8 `.css` file of up to
256 KiB. Its rules follow BusyMark’s generated stylesheet, allowing intentional
overrides. **Remove custom stylesheet** returns to the built-in appearance.

BusyMark reads CSS directly, without running a preprocessor. Imports, resource
URLs, escaped CSS, HTML, and executable CSS are rejected. No remote fonts or
other resources are fetched. A missing, oversized, or invalid stylesheet must
be corrected or removed before exporting. Browser scripts and template code
are not supported customization mechanisms.

Custom CSS is optional. The generated document already has semantic headings,
links, lists, tables, code, metadata, and accessible navigation. Built-in print
styles hide navigation and expose disclosure bodies and every Writerside tab.
Custom rules can override presentation, including print styling.

## Resources and existing exports

Supported local images, media, equations, diagrams, and static API documentation
are prepared during export. Remote video remains a link. Missing or unsupported
content produces an actionable diagnostic and readable fallback where possible.
HTML does not automatically export other linked Markdown documents or crawl
other Writerside instances.

Choose the destination after confirming settings. BusyMark asks before replacing
existing output. A Writerside destination can replace only an unmodified export
created by BusyMark, protecting unrelated files. Cancellation and ordinary
export failures preserve the previous output.

The result offers **Open**, **Show in Folder**, and source-associated diagnostics.
When replacing an HTML document with an assets directory, old resources may be
retained so earlier copies of that HTML remain usable.
