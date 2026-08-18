# Offline visualizations

BusyMark renders Mermaid, PlantUML, D2, and fenced OpenAPI documents locally.
The Markdown parser and serializer still treat every visualizer as an ordinary
fenced code block. A `VisualizationDescriptor` is derived for preview and PDF
export, so the original fence, language spelling, source span, and text remain
authoritative.

## Supported fences

| Renderer | Fence identifiers | Preview | PDF |
| --- | --- | --- | --- |
| Mermaid | `mermaid` | Sanitized SVG | Vector SVG |
| PlantUML | `plantuml`, `puml` | Sanitized SVG | Vector SVG |
| D2 | `d2` | Sanitized SVG, or PNG for `<foreignObject>` output | Vector SVG, or high-resolution PNG |
| OpenAPI | `openapi`, `oas`, `swagger` | Native summary and a BusyMark-owned Scalar window | Static, selectable reference content |

Identifiers are classified case-insensitively. Saving preserves the exact
source fence. History and diff views show source rather than generated output.
Whole-file YAML/JSON OpenAPI editing is not part of this feature.

Demonstrations are available in:

- [`demo/visualizations.md`](../demo/visualizations.md)
- [`demo/openapi-local-reference.md`](../demo/openapi-local-reference.md)
- [`demo/plantuml-conformance.md`](../demo/plantuml-conformance.md)

## Runtime design

`lib/src/visualization/` owns renderer contracts, typed results, diagnostics,
revision cancellation, priority scheduling, memory/disk LRU caches, generated
SVG normalization, D2 execution, and OpenAPI dependency resolution. Cache keys
include the renderer and sanitizer versions, source, theme, preview/PDF profile,
options, and hashes of local dependencies. The disk cache is stored below
`$XDG_CACHE_HOME/busymark/visualizations`; the strict Snap maps that location to
`$SNAP_USER_DATA/.cache`.

The Linux runner provides a first-party Flutter platform-channel host backed by
WebKitGTK 4.1. It uses one reusable hidden render view in an ephemeral WebKit
context and creates BusyMark-owned views only for full Scalar references.
Inline previews are Flutter SVG/PNG widgets, not live browser views.

The host:

- serves an allow-listed bundle through the private `busymark-render:` scheme;
- uses an ephemeral data manager and rejects cookies;
- disables local storage, databases, media, WebRTC, developer tools, popups,
  permissions, context menus, and unapproved navigation;
- applies a CSP with no network, frames, objects, forms, plugins, or remote
  fonts;
- recreates the hidden view after WebKit process termination; and
- treats engine SVG as untrusted input before it reaches Flutter or Typst.

The CSP permits WebAssembly evaluation for the official PlantUML/Viz.js build
and JavaScript evaluation for Scalar's bundled schema validator. Those
permissions are confined to the private, allow-listed, no-network harness.

WebKit's subprocess sandbox remains enabled for ordinary Linux packages. The
strict Snap uses the auto-connected `browser-support` interface with
`allow-sandbox: false`, so WebKit's internal sandbox is disabled there and the
processes remain inside snapd's AppArmor/seccomp confinement.

## Renderer policy

Mermaid uses its programmatic `render` API with automatic scanning disabled,
strict security, HTML labels and error drawings disabled, deterministic IDs,
bounded text/edge counts, and BusyMark light/dark themes.

PlantUML uses the official MIT `@plantuml/core` TeaVM browser engine and its
bundled Viz.js layout runtime. BusyMark's release corpus covers sequence, class,
component, deployment, state, activity, use-case, entity relationship, mind
map, WBS, Gantt, JSON, and YAML diagrams in WebKitGTK. Sudoku is intentionally
absent from the MIT browser build, as documented by PlantUML.

D2 uses the official Linux amd64 executable directly, never through a shell.
Execution has bounded source, time, stdout, stderr, dimensions, and output, and
uses a fresh temporary working directory with a minimal environment. Fenced D2
imports and icon/image assets are disabled in the first release. BusyMark asks
D2 only for SVG: safe CSS is inlined, executable or remote content and
animations are removed, and remaining `<foreignObject>` output is rasterized
by the local WebKit host. The existing external-SVG policy is unchanged.

OpenAPI uses Scalar's parser for OpenAPI 3.2, 3.1, 3.0, and Swagger 2.0,
Scalar's official JSON bundler for local references, and the YAML parser's exact
source locations for diagnostics. Only relative files anchored within the
canonical workspace are accepted. Absolute, remote, traversal, symlink-escape,
oversized, and excessive dependency graphs are rejected. The Scalar window is
given bundled content, not a URL; Agent, telemetry, authentication persistence,
API requests, developer tools, plugins, proxying, remote fonts, and custom
fetches are disabled.

## PDF export

`MarkdownPdfExportService` renders recognized fences before mapping the export
model. Generated assets are stored by SHA-256 under the temporary
`generated-assets` directory and then placed by the existing Typst template.
OpenAPI is mapped to headings, tables, paragraphs, operations, parameters,
request bodies, responses, security schemes, and schemas instead of a Scalar
screenshot. A renderer failure preserves the original fenced source and adds a
warning; it does not abort the document export.

## Pinned dependencies

| Component | Version | Verified artifact SHA-256 |
| --- | --- | --- |
| Mermaid | 11.16.1 | `ebd9885111092c78cefc79a76f6c1dc34ed5b834b02ae8f338227ce79c003de4` |
| `@plantuml/core` | 1.2026.6 | `798f99592eb03a6446519d2becf78e6f1008d0d25c75d60b37a0f46e39e3c413` |
| `@scalar/openapi-parser` | 0.28.14 | `993bb7ebb3480cc574665b0eac52d9cd4a817fdf5b4444894bb70e174880513d` |
| `@scalar/api-reference` | 1.65.1 | `68b6f22ca530ac50e3cd034c5189d89cc5457c3c2d325b44e90db05c9f08c573` |
| `@scalar/json-magic` | 0.13.0 | `f1adefc461f3594afd4ad16974820a5a88b271f7e8051045c2ac7a34eb974d33` |
| YAML | 2.9.0 | `008fa204cb1ba700e0272ba045abbf09a6ffe63456e8146ba97cac6c2ad1ef91` |
| D2 Linux amd64 archive | 0.7.1 | `eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7` |
| D2 Linux amd64 executable | 0.7.1 | `48db68dfb42b76970a6769f038ec60da932adbb058257e07c50f5baaa3046016` |

The web build also pins all transitive packages in
`tools/visualization/package-lock.json` and runs `npm ci --ignore-scripts`.
Build scripts verify the direct upstream archives before installation and copy
package metadata, distributed licenses, and a consolidated notice into the
application bundle. The build requires Node.js 22 or newer; the core24 Snap
recipe uses the official `node/24/stable` build snap. Node.js and npm are build
tools only. Runtime rendering does not require Node.js, Chromium, Java, a
public rendering service, or a first-run download.

D2 is packaged only for Linux amd64. BusyMark must not advertise another
architecture until the Snap platform, upstream artifact, and full corpus are
all added and tested for it.

## Verification

Run the deterministic unit/widget/export suite with:

```bash
flutter analyze
BUSYMARK_D2_PATH=build/linux/x64/debug/d2/linux-x86_64/d2 \
BUSYMARK_TYPST_PATH=build/linux/x64/debug/bundle/libexec/busymark/typst \
  flutter test
```

Run the real offline WebKit/D2 conformance corpus under X11 with:

```bash
xvfb-run -a -s '-screen 0 1280x1024x24' \
  env WEBKIT_DISABLE_COMPOSITING_MODE=1 LIBGL_ALWAYS_SOFTWARE=1 \
  /usr/bin/python3 -u tools/visualization_smoke.py \
  --assets build/linux/x64/debug/visualization/web \
  --d2 build/linux/x64/debug/d2/linux-x86_64/d2
```

Release candidates must additionally run the same demos and PDF cases in the
final strict Snap on both Wayland and X11. Automated suites cover cancellation,
stale-result rejection, timeout wiring, sanitization and external-resource
cases, traversal and symlink escapes, circular OpenAPI references, input
limits, both themes, cache-version invalidation, and PDF output. Release
validation must also exercise live WebKit process termination and recovery.

## Authoritative references

- [Flutter Linux platform channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [WebKitGTK ephemeral contexts](https://webkitgtk.org/reference/webkit2gtk/stable/ctor.WebContext.new_ephemeral.html)
- [WebKitGTK subprocess sandbox](https://webkitgtk.org/reference/webkit2gtk/stable/method.WebContext.set_sandbox_enabled.html)
- [Mermaid programmatic usage and strict security](https://mermaid.js.org/config/usage.html)
- [PlantUML official npm publishing and MIT build](https://github.com/plantuml/plantuml/blob/master/PUBLISHING_NPM.md)
- [D2 SVG and PNG export behavior](https://d2lang.com/tour/exports/)
- [D2 imports](https://d2lang.com/tour/imports/)
- [D2 icons and images](https://d2lang.com/tour/icons/)
- [Scalar OpenAPI parser](https://github.com/scalar/scalar/blob/main/packages/openapi-parser/README.md)
- [Scalar API Reference configuration](https://scalar.com/products/api-references/configuration)
- [Snap browser-support interface](https://snapcraft.io/docs/reference/interfaces/browser-support-interface/)
- [Snapcraft GNOME extension](https://forum.snapcraft.io/t/the-gnome-extension/31449)
