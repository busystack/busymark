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
