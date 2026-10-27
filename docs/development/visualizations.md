# Visualization implementation and verification

This note covers the engineering behind [offline visualizations](../visualizations.md).
User syntax, behavior, and limitations belong in that guide.

## Architecture

The web build consumes the published Mermaid 11.16.1 package through its public
entry point. Its parser, defaults and KaTeX dependency remain upstream code;
BusyMark does not substitute modules or rebuild a modified Mermaid source tree.
The fetch script checks the publisher archive hash and compares installed Mermaid
files with that archive before bundling. `npm ci --ignore-scripts` uses the locked
dependency graph. Mermaid math labels use upstream MathML through the supported HTML-label
configuration and retain strict security mode. Ordinary document equations
continue through MathJax.

Run `python3 -m unittest tools/test_visualization_dependency_policy.py` for the
package integrity controls, then the normal visualization smoke to verify the
actual engines. The smoke includes Mermaid math labels as well as MathJax output.

`lib/src/visualization/` owns renderer contracts, typed results, diagnostics,
revision cancellation, scheduling, generated-SVG normalization, OpenAPI
dependency resolution, and bounded memory and disk caches. Cache keys include
the engine and sanitizer versions, source, theme, render profile, options, and
hashes of local dependencies.

Successful renders are published before optional disk-cache persistence finishes.
The cache warms memory before its first I/O await; the coordinator retains the
render's concurrency slot until persistence settles, bounding pending writes
without putting disk flushes on the visible-result path.

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

## Linux host lifecycle

Startup registers the channel and a lightweight host. A launch without a
visualization request creates no visualization WebKit context, hidden view, or
harness. There is no idle preloading or first-frame gate; the release smoke can
still render before `runApp()`.

The first accepted render operation queues initialization on the GTK main
context. Requests share one ephemeral context, view, and harness load. The
renderer moves through dormant, scheduled, loading, ready, failed, and stopped
states. Loading includes the harness's asynchronous ready event and its existing
15-second deadline. Dart's existing request deadlines include initialization.
Malformed, oversized, unsupported, cancellation, and PNG clipboard operations
do not start WebKit. Cancelling all scheduled requests avoids construction.

The harness registers its dispatcher without evaluating an engine. The first
operation imports a fixed, offline bundle for Mermaid, PlantUML, MathJax, or
OpenAPI. SVG rasterization needs only the harness. PlantUML alone loads the
bundled Graphviz script. Module evaluation is reused within the view, and
concurrent imports share the browser's module registry. Engine load failures
reject their request with `visualization.hostUnavailable` and retire the failed
view and its module registry. Queued work and retries use a fresh restricted
view in the same ephemeral context. Process recovery also creates a fresh
registry. Each engine retains its existing validation,
configuration, and dependencies. Math includes all offline NewCM font tables.
First use still pays for the WebKit process, harness, and requested engine;
subsequent requests reuse them. Measure complete launch-to-output and
request-to-output paths separately.

Opening an interactive reference first creates the shared context and its
visible view, without loading the offscreen harness. A later render uses that
context. Reference windows retain their normal acceleration policy.

Initialization failure fails the queue and releases the failed view; later
requests can retry. Renderer-process termination recreates the hidden view with
the same restrictions and offscreen acceleration policy. Cancellation marks
active work as responded before cancelling its callback, preventing a late
success. Shutdown removes scheduled work, cancels initialization and rendering,
fails queued calls, closes reference windows, and disconnects view callbacks.
Late channel calls return `visualization.hostUnavailable` until host disposal,
which detaches the channel handler. Async
callbacks retain the host until completion, check its state and view identity,
and cannot recreate resources after shutdown. Private resource callbacks own
their resource path independently of the host.

Demand-driven construction avoids initializing unused hosts. Constructor stalls
remain a separate runtime issue from the application's startup and lifecycle
contracts.

## Dependencies and packaging

Do not duplicate pinned versions or hashes in documentation. The authoritative
sources are:

- `tools/visualization/package.json` and `package-lock.json` for web engines and
  transitive packages;
- `tools/fetch_d2.sh` for the D2 release, architecture, and verified hashes;
- `tools/fetch_typst.sh` for Typst release artifacts and hashes;
- `linux/CMakeLists.txt` and `snap/snapcraft.yaml` for bundle layout; and
- `.github/workflows/flutter-linux.yml` for automatic native and compiled PDF checks;
- `.github/workflows/flutter-linux-native.yml` for automatic Wayland/Snap checks and opt-in release stress campaigns.

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
  bash tools/test_web_render_host.sh

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

Host registration remains lightweight; only a validated video `show` request
creates video resources.

Local video passes its single validated file through WebKit's File API and an
allowed `blob:` URL. This lets WebKit broker the file into the existing media
pipeline; GStreamer's direct `file:` reader cannot see arbitrary local paths
inside the WebProcess sandbox. The fixed local-player shell alone can select
that file. No chooser is shown, no video copy is staged, and the sandbox, CSP,
network restrictions, and separate visualization/video contexts are retained.
Each video player owns its WebKit widget until host cleanup. Closing the parent
window can destroy the overlay first; host cleanup must still disconnect player
callbacks and release that widget safely. The native `video-parent-destroy`
regression exercises this order and observes ownership through shutdown.

The native regression script accepts individual operations and an optional
repeat count, with a fresh isolated profile for each process:

```bash
BUSYMARK_NATIVE_PROBE_REPETITIONS=100 \
  bash tools/test_web_render_host.sh renderMermaid
bash tools/test_web_render_host.sh video-no-init video-first video-failure video-view-failure
bash tools/test_web_render_host.sh video-playback video-mini-playback
```

Render results are delivered before optional disk-cache publication completes.
Cache publication still occupies a bounded rendering slot, including the awaited
write, atomic rename and LRU maintenance. Derived images do not request `fsync`:
their disk cache is disposable, and invalid or incomplete entries are rejected
and recomputed after interruption. Document, session, recovery and Local History
durability use their separate stores. Full-directory metadata scans run in one short-lived
maintenance isolate at a time per cache, using only its path and numeric limits.
This avoids one main-isolate asynchronous round trip per cached file. The caller
still awaits maintenance: no unlimited background writes or maintenance queue
are introduced.

## Compiled application lifecycle checks

See [compiled application checks](application-smoke-tests.md) for natural closure,
Save/Discard/Cancel, reopening, native window controls and video verification.
Keep these product assertions separate from startup measurements.

Widget tests that perform real filesystem work must start and await that work
with `tester.runAsync`, pumping UI transitions outside that callback. Readiness
helpers advance both real I/O and the widget clock within their existing
budgets. Focused History double-click tests retain pointer-gesture coverage
alongside keyboard navigation.
