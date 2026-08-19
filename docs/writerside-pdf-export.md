# Writerside PDF export

BusyMark exports a complete Writerside output instance, not a concatenation of
its Markdown files. Includes, variables, conditional content, semantic XML,
API documentation, diagrams, reused TOC sections, and cross-module references
must be interpreted by Writerside itself to preserve their documented meaning.

JetBrains documents automated PDF generation through the versioned
`writerside-builder` container running `helpbuilderinspect -pdf`. BusyMark
therefore keeps its bundled Typst pipeline for regular Markdown and uses that
official JetBrains builder for Writerside modules.

## Export

Open a Writerside module and select **Main menu → Export as PDF** or press
<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd>. BusyMark requires unsaved editor
content to be saved or discarded before a project build, then lets you select:

- one non-library Writerside instance;
- settings configured for this export or an existing `<pdf>` XML file from the
  module's configured build directory;
- portrait or landscape orientation;
- a keymap layout declared for that instance in `buildprofiles.xml`;
- table-of-contents title;
- optional cover title, logo, description, and copyright; and
- page header and footer.

The advanced section exposes the source root, module name, builder
version, and network policy for multi-module repositories and version-sensitive
projects. The source root defaults to the module's parent. The builder module
name defaults to `<module name="…">` from `writerside.cfg`, or to the module
directory name when that element is absent, for JetBrains'
`MODULE_INSTANCE=module/instance` contract. If `writerside.cfg` declares
`<wrs-supernova use-version="…"/>`, BusyMark uses that builder version by
default; otherwise it uses the currently tested version
`2026.07.8925`.

Generated settings exist only in a private temporary source facade. BusyMark
does not add or modify a file in the Writerside project. Selecting a project
configuration passes that file through unchanged, so teams can commit and
review a release-specific `PDF.xml`. The example module contains
[`cfg/PDF.xml`](../demo/writerside-instances/cfg/PDF.xml) and a cover-logo
asset for exercising generated settings.

## Builder installation and isolation

Docker must be installed and its daemon available to the current user. BusyMark
checks for `jetbrains/writerside-builder:<version>` locally and never performs a
silent pull. If the image is absent, BusyMark identifies the exact image and
asks before downloading it. JetBrains' builder image is large and remains in
Docker's local image store.

Every build uses direct process arguments rather than a host shell and applies:

- read-only nested mounts for every real project entry;
- a private writable source facade for the builder's transient `.idea`
  metadata;
- a private temporary output directory;
- a private generated PDF configuration when custom settings are selected;
- `--pull=never`, so an export cannot replace the selected builder image;
- `--network none` by default; and
- bounded process time, diagnostic output, and PDF size.

Enable network access only when a reviewed project intentionally needs remote
resources during its build. The builder is still project code processing: use
it only for documentation sources you trust. A cancelled or timed-out build is
terminated and its named container is removed. The validated PDF is published
atomically to the selected destination.

Strictly confined Snap applications cannot normally access the host Docker
socket. Writerside PDF export therefore requires a native/development BusyMark
installation until the distributed Snap has an explicitly reviewed and tested
Docker access mechanism. Regular Markdown-to-PDF export remains available in
the Snap because Typst is bundled.

## Scope

PDF output is per Writerside instance. Library instances are reusable TOC
sources and are not export choices. BusyMark does not offer PDF export for
Writerside build groups because JetBrains' current GitHub publishing workflow
does not support PDF artifacts for groups. Builder errors remain visible with
their diagnostic log; BusyMark does not replace failed Writerside semantics
with an approximate native conversion.

## Verification

Focused tests cover documented XML generation, configuration and keymap
discovery, missing builder handling, cancellation, existing configuration
pass-through, PDF validation, private builder metadata, and read-only project
entries, including a module without an existing `cfg` directory. Release
validation with the real image should export the demo using both generated
settings and `cfg/PDF.xml`.

After the pinned image is installed, run the real project-to-PDF smoke test:

```bash
BUSYMARK_WRITERSIDE_PDF_INTEGRATION=1 \
  flutter test test/src/writerside_pdf_export_test.dart
```

## Authoritative references

- [Export to PDF](https://www.jetbrains.com/help/writerside/export-to-pdf.html)
- [Build with Docker](https://www.jetbrains.com/help/writerside/build-with-docker.html)
- [Modules](https://www.jetbrains.com/help/writerside/help-modules.html)
- [writerside.cfg](https://www.jetbrains.com/help/writerside/writerside-cfg.html)
- [buildprofiles.xml](https://www.jetbrains.com/help/writerside/buildprofiles-xml.html)
- [Writerside GitHub Action](https://github.com/JetBrains/writerside-github-action)
