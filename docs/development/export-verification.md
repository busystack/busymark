# Export verification

This is the maintained verification procedure for BusyMark's PDF and HTML
export paths. User-facing settings and limitations are documented in
[PDF export](../pdf-export.md), [HTML export](../html-export.md), and
[Writerside PDF export](../writerside-pdf-export.md).

## Implementation map

- `lib/src/export/export_options.dart` defines validated, serializable options
  shared by the export dialogs.
- `lib/src/export/export_options_editor.dart` provides the Markdown and
  Writerside settings editors.
- `lib/src/export/pdf_title_page.dart` carries immutable, export-owned plain
  text. Only `PdfExportOptions.includeTitlePage` is persisted. Markdown defaults
  and body content share an editor snapshot; Writerside defaults follow the
  selected instance. HTML and shared content options have no cover setting.
- `lib/src/export/typst_payload_builder.dart`,
  `lib/src/export/markdown_export_mapper.dart`, and `assets/export/markdown.typ`
  implement the native PDF model and layout.
- `lib/src/export/html_document_writer.dart`,
  `lib/src/export/html_export_styles.dart`, and
  `lib/src/export/html_export_assets.dart` implement offline HTML output.
- `lib/src/visualization/visualization_release_smoke.dart` exercises the bundled
  visualization, math, PDF, and HTML product paths through the release binary.

## Repository checks

Use the repository-pinned Flutter and Dart versions:

```bash
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build linux --release
```

The tests cover option parsing and persistence, dialog behavior, output bounds,
metadata, TOC hierarchy and numbering, CSS validation, embedded and external
assets, math and diagram rendering, Writerside resolution, cancellation, and
preservation of existing output after failure.

## PDF front matter and actual rendering

Set the bundled compiler path explicitly; skipped rendering tests do **not**
verify pagination. Poppler’s `pdftotext`, `pdftohtml`, `pdfinfo`, and `pdffonts`
provide text, link destinations, geometry, and font inspection:

```bash
export BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst"
export BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2"
flutter test --no-pub test/src/pdf_title_page_test.dart \
  test/src/pdf_title_page_ui_test.dart test/src/pdf_front_matter_render_test.dart \
  test/src/pdf_export_options_render_test.dart
flutter test --no-pub
```

`pdf_title_page_test.dart` covers default-disabled serialization, copying,
metadata precedence, plain-text payloads, clearing fields, validation, and
separation from global settings. `pdf_title_page_ui_test.dart` exercises reset,
cancel, format switching, instance changes, metadata editing, and both direct
and unified export routes. Markdown defaults must reflect unsaved editor text,
and later edits must not change an already captured export request.

`pdf_front_matter_render_test.dart` compiles real Markdown and Writerside PDFs.
For a one-page body and one-page TOC, title-page/TOC combinations off/off,
on/off, off/on, and on/on must yield 1, 2, 2, and 3 pages. Body paragraph
sentinels, not duplicated heading text, locate actual body pages. A 115-heading
fixture requires a multipage native outline and checks every heading link and
displayed page reference against its body paragraph’s physical page. Additional
checks cover nested/depth-limited and numbered headings, excluded Writerside
headings, bookmarks without a printed TOC, both body fonts, portrait/landscape,
custom margins, Unicode, multiline metadata, and unchanged source files.
Unbroken titles and every metadata field are exercised on A4 and narrow custom
pages through the real export service. Success must retain all cover text and
keep text bounds inside the content area; a clear fit failure must preserve the
previous PDF byte for byte. Title and subtitle cases also check their larger
rendered sizes. A constrained Typst paragraph frame width is not evidence that
its glyphs fit.

The title page counts as physical page 1 but never emits running text or its
visible number. Subsequent pages obey configured header/footer placement and
the physical-first-page preference. Logical numbering stays enabled so the TOC
retains destination numbers even with visible numbers off. Oversized cover
content must fail clearly; failure and cancellation must preserve an existing
destination. Keep the existing anchor, list, module-resolution, diagram, and
HTML regression suites enabled.

For visual review, optionally set `BUSYMARK_PDF_ARTIFACTS` to a fresh temporary
directory while running the front-matter tests, then render representative
cover, TOC, and body pages with `pdftoppm -png`. Inspect wrapping, margins,
clipping, overlap, empty optional fields, blank pages, and typography isolation.
Record actual pass/failure/skip counts separately, including the compiler used;
a passing model or template-string test is not a substitute for rendered output.

## Release product-path smoke

The release-only smoke entry point is gated by `BUSYMARK_RELEASE_SMOKE=1`. Write
artifacts to a fresh temporary directory:

```bash
verification_dir="$(mktemp -d)"
report="$verification_dir/report.json"
BUSYMARK_RELEASE_SMOKE=1 \
  xvfb-run -a env WEBKIT_DISABLE_COMPOSITING_MODE=1 \
  LIBGL_ALWAYS_SOFTWARE=1 build/linux/x64/release/bundle/busymark \
  --visualization-release-smoke="$report"
```

Require a successful exit, `"ok": true` in `report.json`, non-empty PDF output,
and the expected Markdown and Writerside HTML directories. Retain artifacts only
when they are needed to diagnose a failure; temporary paths are not release
evidence by themselves.

## Relocated browser verification

`tools/verify_html_export_browser.py` copies the generated HTML away from its
source location, opens it through both `file:` and a local HTTP server, and
checks offline resources, navigation, anchors, print behavior, color schemes,
custom CSS, CSP enforcement, and layout. It requires Selenium, Chromium or
Chrome, Firefox with geckodriver, and `pdftotext`:

```bash
browser_output="$verification_dir/browser"
python3 tools/verify_html_export_browser.py "$verification_dir" \
  --output "$browser_output"
```

Review `browser-report.json` and representative screenshots in the output
directory. No unexpected external request is acceptable. Browser checks do not
replace a manual inspection of representative PDF and HTML documents, and they
do not certify physical-printer or assistive-technology behavior.

## CI environment

The Linux workflow in `.github/workflows/flutter-linux.yml` is authoritative for
native packages, environment flags, browser setup, X11 and Wayland runs, and the
strict Snap verification. Keep ordinary build prerequisites in the main README;
do not copy the larger CI-only dependency set into user installation steps.
