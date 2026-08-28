# Writerside PDF export

BusyMark exports a selected Writerside instance directly with its bundled PDF
toolchain. Docker, Podman, a Writerside installation, and a network connection
are not required.

## Export

Open a Writerside module and select **Main menu → Export as PDF** or press
<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd>. BusyMark first asks you to save or
discard unsaved project changes, then lets you select:

- one non-library Writerside instance;
- A4 or US Letter page size;
- portrait or landscape orientation;
- narrow, normal, or wide margins; and
- whether to include page numbers.

The instance's resolved TOC determines topic order. Hidden and work-in-progress
TOC entries are omitted unless a work-in-progress topic is the configured start
page. Reused TOC sections already resolved by BusyMark participate in the same
ordering. Project variables are substituted in recognized variable tokens.

Writerside Markdown is parsed in Writerside mode, so supported semantic markup,
admonitions, collapsible content, videos, math, Mermaid, PlantUML, and D2 use the
same export semantics as BusyMark's editor and preview. `.topic` XML content is
converted into the corresponding native PDF blocks for headings, paragraphs,
procedures, steps, admonitions, code, lists, images, videos, links, and math.
Malformed XML remains visible as source instead of disappearing.

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

## Verification

Focused tests cover instance selection, TOC ordering, variables, Markdown and
`.topic` XML composition, local asset rebasing, cancellation, failure mapping,
and an end-to-end native PDF build of the repository's Writerside demo.

Run:

```bash
flutter test test/src/writerside_pdf_export_test.dart
flutter test test/src/markdown_pdf_export_test.dart
```
