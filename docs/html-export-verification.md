# HTML export verification — September 5, 2026

The implementation and reproduction commands are described in
[HTML export](html-export.md). Validation used Flutter 3.47.0 on Linux and the
application's bundled rendering executables; no dependency was added to the
application for HTML serialization or browser-side rendering.

| Check | Executed result |
| --- | --- |
| Dart formatting of changed handwritten sources | Passed; no formatting changes required |
| Repository-wide `flutter analyze --no-pub` | Passed; no issues |
| `flutter gen-l10n` | Passed; new HTML and missing Writerside messages supplied for all shipped regional locales |
| Full `flutter test --no-pub`, with `BUSYMARK_TYPST_PATH` and `BUSYMARK_D2_PATH` pointing to the release bundle | **1,438 passed, no skips** |
| Focused rich-export checks after improving renderer failure messages | Passed; profiles, snapshots, timeout fallback, active cancellation and output preservation |
| `flutter build linux --release --no-pub` | Passed |
| Native release smoke under Xvfb | Passed; real MathJax 4.1.3, Mermaid, PlantUML, D2, static OpenAPI and existing PDF smoke; zero HTML warnings |
| Relocated browser checks | **20 passed**: five pages × two URL modes × two browsers |
| `git diff --check` and Python browser-check syntax compilation | Passed |

The full suite includes the existing PDF exports and native configuration,
localization, source preservation, and editor regression tests. Base `pt` and
`zh` localization templates remain partial as before; the shipped `pt_BR` and
`zh_CN` locales have complete messages and pass the localization audit.

Browser verification used **Chromium/Chrome 151.0.7922.137** and **Firefox
154.0.1**. Each opened the relocated Markdown page and all four Writerside HTML
files directly through `file:` URLs and through a local static HTTP server.
Outbound proxy connections were unavailable, and BiDi observation recorded no
unexpected external request. HTTP-only favicon probes were local 404s and are
not export dependencies.

Checks covered stylesheet/CSP hashing, image loading, internal anchors,
footnote references and return links, current navigation, keyboard focus,
disclosure interaction, horizontal overflow, script blocking, and printing.
PDF text extraction confirmed that collapsed disclosure content and every tab
were printed. Representative Chromium and Firefox screenshots were also
visually inspected. The footnote case crosses a raw HTML disclosure block,
exercising the corrected shared reference context.

Representative outputs from the real release binary:

- `/tmp/busymark-html-final/offline.html` and `offline.assets/`: unsaved-source
  export path, Unicode headings, nested/task lists, tables, disclosure, a local
  SVG, inline/display math, three diagram engines, static API reference, and a
  structured footnote.
- `/tmp/busymark-html-final/writerside/index.html`: selected-instance entry point,
  also preserved as `Welcome.html`; includes with caller variable overrides,
  all tabs, procedure steps, custom filename, hidden-page links and WIP status.
- `/tmp/busymark-html-final/writerside/reference.html`: spanning table,
  collapsible chapter, and a diagram loaded from the configured snippets folder.
- `/tmp/busymark-html-final/writerside/hidden.html`: link-accessible hidden topic.
- `/tmp/busymark-html-final/visualization-smoke.pdf`: existing PDF verification.

Native results are recorded in `/tmp/busymark-html-final/report.json`. Browser
results, screenshots, and printed PDFs are under
`/tmp/busymark-html-browser-final/`; its `browser-report.json` identifies the
separate relocated root. Sources and engine temporary directories were removed
before the relocated copies were opened. These paths are verification artifacts,
not dependencies of the exported documents, and may be removed by temporary-file
cleanup. The committed scripts reproduce them.

No requested automated check remains unavailable. Browser interaction and print
verification ran headlessly; physical-printer output and assistive-technology
certification were not tested. This is behavioral validation of BusyMark's native
export, not an assertion of pixel parity with JetBrains' website builder.
