# Visualization implementation and verification

This note covers the engineering behind [offline visualizations](../visualizations.md).
User syntax, behavior, and limitations belong in that guide.

## Architecture

`lib/src/visualization/` owns renderer contracts, typed results, diagnostics,
revision cancellation, scheduling, generated-SVG normalization, OpenAPI
dependency resolution, and bounded memory and disk caches. Cache keys include
the engine and sanitizer versions, source, theme, render profile, options, and
hashes of local dependencies.

The Linux runner exposes a first-party platform channel backed by WebKitGTK 4.1.
One reusable hidden render view handles Mermaid, PlantUML, OpenAPI parsing, SVG
rasterization, and MathJax. BusyMark-owned windows are created only for the full
interactive OpenAPI reference. Inline previews are Flutter SVG or PNG widgets,
not embedded live browser views.

The WebKit host uses an ephemeral context and an allow-listed private resource
scheme. It disables storage, cookies, media, WebRTC, developer tools, popups,
permissions, context menus, and unapproved navigation. Its content security
policy blocks networking, frames, objects, forms, plugins, and remote fonts.
Engine SVG is treated as untrusted and normalized before Flutter or Typst sees
it. The WebKit subprocess sandbox remains enabled for ordinary Linux packages
and the strict Snap.

D2 runs its pinned Linux executable directly, never through a shell. Source,
time, output, dimensions, and environment are bounded, and each execution uses
a fresh temporary directory. Safe SVG remains vector output; unsupported CSS,
embedded fonts, conflicting cascade behavior, animation, or `foreignObject`
content is sanitized and rasterized locally.

OpenAPI parsing accepts only bounded local references anchored to the canonical
workspace. The interactive Scalar view receives bundled content with agent,
telemetry, authentication persistence, proxying, API requests, remote fonts,
and custom fetches disabled.

## Dependencies and packaging

Do not duplicate pinned versions or hashes in documentation. The authoritative
sources are:

- `tools/visualization/package.json` and `package-lock.json` for web engines and
  transitive packages;
- `tools/fetch_d2.sh` for the D2 release, architecture, and verified hashes;
- `tools/fetch_typst.sh` for Typst release artifacts and hashes;
- `linux/CMakeLists.txt` and `snap/snapcraft.yaml` for bundle layout; and
- `.github/workflows/flutter-linux.yml` for release and Snap verification.

The web bundle is built with `npm ci --ignore-scripts`. Build steps verify direct
upstream artifacts and stage package metadata, licenses, and notices. Node.js is
a build dependency only.

## Verification

Run the deterministic Dart suite with the bundled executables after building:

```bash
flutter analyze
BUSYMARK_D2_PATH=build/linux/x64/debug/bundle/libexec/busymark/d2 \
BUSYMARK_TYPST_PATH=build/linux/x64/debug/bundle/libexec/busymark/typst \
  flutter test
```

Run the real WebKit and D2 corpus under X11:

```bash
xvfb-run -a -s '-screen 0 1280x1024x24' \
  env GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 \
  /usr/bin/python3 -u tools/visualization_smoke.py \
  --assets build/linux/x64/debug/visualization/web \
  --d2 build/linux/x64/debug/d2/linux-x86_64/d2 \
  --demo test/fixtures/markdown/basic.md \
  --plantuml-corpus test/fixtures/visualization/plantuml-conformance.md
```

The release binary has a gated product-path smoke entry point:

```bash
verification_dir="$(mktemp -d)"
BUSYMARK_RELEASE_SMOKE=1 \
  build/linux/x64/release/bundle/busymark \
  --visualization-release-smoke="$verification_dir/report.json"
```

The report must contain `"ok": true`; the same directory receives the generated
PDF and HTML fixtures. The Linux workflow is authoritative for compositor setup,
X11 and Wayland coverage, the strict Snap run, and required environment flags.

The native host and Python corpus harness disable hardware compositing only for
their offscreen WebKit views, before realization and after process recovery.
GTK offscreen windows cannot provide the GL context that accelerated compositing
requires. Normal startup does not require a WebKit environment override, and
Flutter and visible API-reference windows retain their normal rendering settings.
Smoke tests must not globally disable WebKit compositing; `LIBGL_ALWAYS_SOFTWARE`
is only used to provide Mesa rendering on headless CI displays.
