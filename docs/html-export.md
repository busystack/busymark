# HTML export

Use **Main menu → Export as HTML…** or the command palette's **Export as HTML…**
command. The GTK header menu and Flutter menu have the same availability. PDF's
Ctrl+Shift+E shortcut is unchanged; HTML has no default shortcut.

An active Markdown document exports its current editor text, including unsaved
and untitled content, to a complete UTF-8 `.html` document. Text-only documents
need just that file. Local images, media, downloadable resources, and generated
graphics use a companion `<name>.assets` directory. Keep that directory beside
the HTML file when copying the export.

For Writerside, resolve unsaved project changes using Save/Discard/Cancel, select
one non-library instance, and choose a dedicated output directory. The export
contains separate topic pages, ordinary navigation links, shared `assets`, and
an `index.html` entry point. Hidden topics retain pages but no navigation entry;
work-in-progress entries retain their status. Repeated TOC references share a
page. Topic titles, TOC labels, module origins, instance title overrides, and
custom web filenames remain distinct. Filename collisions stop publication.
The start page retains its declared filename and also supplies `index.html`.

The result dialog offers **Open**, **Show in Folder**, and individual diagnostics
with source paths and line numbers. Missing required links are diagnostics with
visible labels, rather than fabricated destinations; missing nullable links
become ordinary text. Single-document Markdown export does not export other
linked documents. Unavailable visual content retains alternative text, a safe
link, or escaped source, with a diagnostic.

## Semantic output and offline rendering

The HTML writer consumes BusyDocument and the existing selected Markdown mode.
Writerside first passes through the shared project loader, document resolver,
and document renderer. It does not use Typst, Pandoc, screenshots, or a second
Markdown dialect. Ordinary HTML export does not require a Typst executable.

Headings and explicit IDs, nested lists and task states, tables and cell spans,
code whitespace, footnotes and return links, procedures, definition lists,
admonitions, and supported raw HTML structure remain semantic HTML. Disclosures
use native `details`/`summary`. Every Writerside tab and topic variant is included
as a labeled section. Page-local generated IDs use BusyMark's Unicode-aware slug
rules and disambiguate repeated headings. Duplicate explicit IDs are diagnosed.

An HTML-only projection in the existing Markdown AST adapter preserves raw HTML
structure and cross-block footnote/reference context. Default editor and PDF
projections, original source text, and source serialization are unchanged.

Math uses MathCoordinator with a separate HTML profile and standalone SVG glyphs.
Mermaid, PlantUML, and D2 use VisualizationCoordinator's HTML profile, normalized
SVG, or the existing raster fallback. OpenAPI uses the existing local dependency
resolver and static reference mapper, producing headings, tables and examples.
Renderer dependencies are captured before rendering starts. Jobs use export,
page, and occurrence identity, including repeated includes. No browser-side
renderer, webfont, JavaScript, runtime fetch, or live API client is needed.

The light stylesheet is independent of the editor theme. It includes responsive
media, table/code overflow, focus outlines, navigation landmarks, heading
outlines, language/direction metadata, and print rules that expose disclosure
bodies and every tab.

## Ownership, confinement, and failure handling

Source attributes are never copied wholesale into output. DOM text/attribute
escaping, URL validation, structural raw HTML allowlists, and final output checks
are separate controls. Unsupported or active source markup is shown as escaped
source with a diagnostic. SVG validation rejects active content, unsafe CSS,
and external references before normalization; SVGs are loaded as images.

Local assets must canonicalize inside the document/workspace or configured
Writerside module/resource roots. Symlink escapes, unsupported formats, missing
files, and remote assets produce diagnostics. Remote resources are not fetched.
Validated asset content determines immutable hashed filenames, so identically
named files from different topics do not collide. Internal origin paths remain
available during resolution but are not serialized as HTML attributes or URLs.

The generated meta CSP disables scripts, connections, objects, frames, forms,
base-URL changes, and fonts. Its style hash authorizes only exporter-owned CSS.
Image/media policies allow the generated relative resources over HTTP and
`file:` origins; final URL validation and asset confinement provide the narrower
resource boundary. The meta policy does not claim unsupported `frame-ancestors`
or sandbox protection. CSP complements sanitization.

Assets are staged before a document entry point is atomically replaced. Existing
companion assets are append-only and content-verified; replacing HTML never
removes files used by the previous HTML. A `.busymark-html-export.json` ownership
marker identifies exporter directories. Unowned or modified output directories
are refused. Writerside stages a complete sibling directory and uses Linux atomic
rename/exchange only when supported; the file hard-link fallback is never used
for directories. Publication checks the displaced output too and rolls back a
concurrent change. If rollback itself fails, the retained recovery directory is
reported instead of deleted.

Cancellation and ordinary publication failures clean temporary staging files
and retain an existing export. Default processing limits are 2,000 topics,
64 MiB UTF-8 source, 16 MiB per asset, 128 MiB total assets, 2,048 assets,
512 generated graphics, 64 nesting levels, and 45 seconds per render/preparation.
Generated HTML is bounded to four times the source-byte limit. Oversized output
fails before publication. Unused immutable companion assets can accumulate across
replacements; automatic deletion would risk older HTML copies.

## Implementation map

| Responsibility | Files under `lib/src/export/` |
| --- | --- |
| Requests, results, limits, cancellation | `html_export_models.dart` |
| Input capture and orchestration | `html_export_service.dart`, `html_export_ui.dart` |
| Writerside publication identities and navigation | `html_publication_plan.dart` |
| Link and anchor resolution | `html_export_links.dart` |
| Semantic DOM writer and final safety boundary | `html_document_writer.dart` |
| Confined, validated, content-addressed resources | `html_export_assets.dart` |
| Existing math, diagram, and static API engines | `html_rich_content.dart` |
| Atomic publication and ownership checks | `html_export_publisher.dart` |
| Real-engine release fixture | `html_release_smoke.dart` |

Other integration changes are in `assets/export/html.css`, `pubspec.yaml`, the
Markdown AST adapter/parser, visualization profiles/coordinator, atomic-file
helpers, application command/menu dispatch, the Linux header-bar bridge and GTK
runner, and ARBs/generated localization output. Verification also corrected
Writerside link-summary variable scopes and completed missing Writerside UI
translations and table-sort glyph/localization integration.

## Verification

Structural, asset, publication, renderer, and widget coverage lives in
`test/src/html_export_test.dart`, `html_publication_test.dart`,
`html_rich_export_test.dart`, and `html_export_ui_test.dart`. Header-bar and
localization/source audits cover shared integration. Tests include unsafe URLs,
raw HTML and SVG, metadata injection, duplicate/non-Latin IDs, module-relative
assets, hidden/WIP pages, collisions, dependency snapshots, timeout fallback,
permission failure, overwrite refusal, ownership checks, and staging cleanup.

The existing Linux visualization release smoke also writes a representative
Markdown export (`offline.html` plus assets) and a Writerside instance
(`writerside/index.html`, `Welcome.html`, `reference.html`, and `hidden.html`). It
uses real packaged MathJax, Mermaid, PlantUML, D2, OpenAPI, and the existing PDF
smoke. Run after a release build:

```bash
BUSYMARK_RELEASE_SMOKE=1 xvfb-run -a build/linux/x64/release/bundle/busymark \
  --visualization-release-smoke=/tmp/busymark-html-verification/report.json
```

`tools/verify_html_export_browser.py` copies those exports to a new location,
starts a local static server, and checks both direct file opening and HTTP in
installed Chromium and Firefox. It uses an unavailable outbound proxy and BiDi
request observation, verifies assets, anchors, footnotes, responsive layout,
keyboard disclosure controls and navigation, probes CSP script blocking, saves
screenshots, prints every page, and checks printed disclosure/tab text. It needs
Selenium 4.48+, matching browser drivers, and `pdftotext`:

```bash
python3 tools/verify_html_export_browser.py /tmp/busymark-html-verification \
  --output /tmp/busymark-html-browser-verification
```

The test does not require internet access to render exports. Install browsers,
drivers and Selenium beforehand; explicit browser/driver paths are configurable.
Printed PDF text checks complement screenshot inspection; they do not establish
accessibility conformance or pixel equality with the Writerside website builder.

## Documentation decisions

Separate topic filenames, titles, and start-page behavior follow JetBrains'
[topics documentation](https://www.jetbrains.com/help/writerside/topics.html).
Hidden/WIP handling follows the
[instance documentation](https://www.jetbrains.com/help/writerside/instances.html),
and missing/nullable link behavior follows
[links and references](https://www.jetbrains.com/help/writerside/links-and-references.html).
Native disclosure behavior follows
[MDN details](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details).
Standalone math reuses the approach described by
[MathJax conversion documentation](https://docs.mathjax.org/en/v4.1/web/convert.html).
The final boundary combines controls described in
[OWASP XSS prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
and [OWASP CSP guidance](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html).
