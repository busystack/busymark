# Writerside PDF export

BusyMark exports a selected Writerside instance directly with its bundled PDF
toolchain. Docker, Podman, a Writerside installation, and a network connection
are not required.

## Export

Open a Writerside module and select **Main menu → Export as PDF** or press
<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd>. BusyMark first asks you to save or
discard unsaved project changes, then lets you select:

- one non-library Writerside instance;
- a generated table of contents with heading depth 1–6 and optional heading numbering;
- A4, US Letter, US Legal, or custom page dimensions in millimetres;
- portrait or landscape and preset or four independent custom margins;
- serif or sans-serif Noto typography, body size, and code size;
- document-title headers and footers, page-number position, and first-page visibility; and
- an accent/link color.

These are the same controls used for Markdown PDF export. Confirmed PDF settings
are remembered globally; instance selection remains specific to the workspace.
**Reset to defaults** restores the default settings in the dialog. Cancelling
keeps the previously remembered settings. The editor theme does not affect PDF
appearance. See [PDF export settings](pdf-export.md) for ranges and defaults.

Generated TOC and heading numbering use the exported heading structure without
changing topic source. Custom typography also controls heading and equation
sizing; custom dimensions and margins determine the available content width.

The instance's resolved TOC determines topic order. Hidden and work-in-progress
TOC entries are omitted unless a work-in-progress topic is the configured start
page. Reused TOC sections already resolved by BusyMark participate in the same
ordering. Project variables are substituted in recognized variable tokens.

Writerside Markdown is parsed in Writerside mode, so supported semantic markup,
admonitions, collapsible content, videos, math, Mermaid, PlantUML, and D2 use the
same export semantics as BusyMark's editor and preview. `.topic` XML content is
converted into the corresponding native PDF blocks for headings, paragraphs,
procedures, steps, admonitions, code, lists, images, videos, links, and math.
Preview and PDF share the Writerside resolver and renderer. XML chapters retain
nested content, and links use unique PDF anchors. Every tab and topic variant is
included as a labeled section. Tables preserve header styles, spans, column
widths and nested cell content. Configured shortcuts, glossary descriptions,
resources and API references participate in the same resolution.

Unsupported markup produces a visible fallback and warning. Malformed XML or
unresolved required content stops export with an explicit error.

## Offline and security behavior

Export uses BusyMark's bundled Typst compiler. Math uses the packaged MathJax
renderer, and diagrams use the packaged visualization engines. No container
image is downloaded and no daemon or system socket is accessed.

Only topics reachable from the selected instance are composed. Local image and
video-poster paths are canonicalized and must resolve inside the Writerside
module. PDF publication is atomic, output size and compilation time are bounded,
and cancellation terminates the active native compiler process.

Remote video URLs remain links in PDF output. Remote images are not downloaded.
When a local asset cannot be staged, the PDF contains a readable fallback and
the export reports a warning.

## Scope

PDF output is per Writerside instance. Library instances are reusable TOC
sources and are not standalone export choices. BusyMark does not execute
arbitrary Writerside build scripts or fetch remote project dependencies during
native export.

BusyMark is not the JetBrains Writerside publication builder. The native export
targets a reliable offline PDF of the syntax BusyMark understands; teams that
need byte-for-byte parity with JetBrains website artifacts can still run
JetBrains' separate CI tooling outside BusyMark.
