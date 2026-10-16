# Visualization implementation and verification

This note covers the engineering behind [offline visualizations](../visualizations.md).
User syntax, behavior, and limitations belong in that guide.

## Architecture

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
subsequent requests reuse them. Those costs must be measured alongside plain
startup when assessing performance, including preparation that an eager
baseline completed before receiving its first request.

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

Set `BUSYMARK_VISUALIZATION_TRACE=1` for opt-in monotonic timings on stderr:
context construction, view construction, offscreen realization/show, harness
dispatch, and request acceptance, start, JavaScript delivery, and completion. It logs no document source. Moving
construction to first use removes unused startup work; it does not establish
the cause or elimination of a rare WebKit construction stall.

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

For native startup/first-use diagnosis, `BUSYMARK_NATIVE_TRACE=1` records
view realization, host registration, and first-video context/view construction.
`BUSYMARK_VISUALIZATION_TRACE=1` additionally separates scheduled initialization
from callback dispatch, synchronous constructors, harness dispatch, and request
completion. These use GLib's monotonic clock. Registration of either host must
remain lightweight; only a validated video `show` request creates video resources.

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

An external watchdog can stop GDB's inferior and collect native stacks and
process/thread wait evidence while GTK is blocked:

```bash
python3 tools/capture_native_slow_operation.py \
  --output /absolute/new/evidence-directory --threshold-ms 500 --duration 20 \
  -- build/linux/x64/release/bundle/busymark /absolute/disposable/document.md
```

For targeted tail capture with less debugger perturbation before the event, add
`--detach-until-slow`. GDB stops at native `main`, detaches, and remains the
inferior's ancestor so it can attach after the selected operation exceeds the
threshold. This requires no ptrace-policy change. Entry under GDB is still
diagnostic, and attaching perturbs the remainder of a captured operation.
`detached.json` identifies the owned application for a separate interaction
probe. Cleanup checks process identities before signalling it or its children.
Detached runs do not establish a successful natural-exit status.

`--operation` also accepts compiled-in Dart spans, such as
`restore-journal-session`. An active Future can be waiting on worker I/O while
GTK remains responsive; inspect the captured threads instead of treating its
whole duration as main-thread blocking. `--profile-template` copies a disposable
fixture into the isolated profile without modifying the template. Keep graphics
caches out of restoration templates when testing fresh-cache behavior.

The watchdog's blocked-operation and already-completed-operation regressions use
owned synthetic programs, not a reproduction of a historical WebKit stall:

```bash
python3 tools/test_capture_native_slow_operation.py -v
```

The watchdog creates an isolated HOME/XDG profile while retaining the desktop
connection and graphics environment. It inspects only its inferior and children.
`BUSYMARK_NATIVE_SLOW_CAPTURE_DIR=/absolute/new/capture-root` enables the same
watchdog for `test_web_render_host.sh`. The optional `watchdog-delay` operation
injects a 1,500 ms GTK-thread delay to validate capture; it does **not** reproduce
an unexplained WebKit stall. Debugger and syscall-traced runs are diagnostic
cohorts, never headline latency measurements.

`BUSYMARK_NATIVE_SYSCALL_TRACE_DIR=/absolute/evidence-directory` records each
native case with `strace -f -ttt -T`, including file discovery, child creation,
futex/poll waits, and flush durations. Correlate its wall-clock timestamps with
the monotonic application events using a clock calibration captured for that
run; keep these traces separate from the uninstrumented cohort.

For Dart timelines, build with
`--profile --dart-define=BUSYMARK_PERFORMANCE_TRACE=true`. The opt-in spans await
future completion, use CLOCK_MONOTONIC on Linux, and log FrameTiming build/raster
durations without treating callback delivery as presentation. Ordinary release
builds compile out these diagnostics. For CPU sampling when launching a profile
bundle directly, the pinned Linux embedder accepts `FLUTTER_ENGINE_SWITCHES=1`
and `FLUTTER_ENGINE_SWITCH_1=enable-dart-profiling` (the embedder adds `--`).

Restoration spans distinguish recovery readiness, authoritative history,
journal publication, workspace/file loading, active-document preparation,
editor publication and required final persistence. Numbered settings, recovery,
history and controller transactions log queue admission separately from
execution; history also logs instance dispatch and root-queue admission.
Lock spans include the asynchronous lock request; explicit contention events
distinguish retries from I/O-service or event-loop scheduling delays.

Render results are delivered before optional disk-cache publication completes.
Cache publication still occupies a bounded rendering slot, including the awaited
write, atomic rename and LRU maintenance. Derived images do not request `fsync`:
their disk cache is disposable, and invalid or incomplete entries are rejected
and recomputed after interruption. Document, session, recovery and Local History
durability use their separate stores. Full-directory metadata scans run in one short-lived
maintenance isolate at a time per cache, using only its path and numeric limits.
This avoids one main-isolate asynchronous round trip per cached file. The caller
still awaits maintenance: no unlimited background writes or maintenance queue
are introduced. `cache-maintenance-N` separates admission, execution and worker
completion; `cache-maintenance-worker` measures the scan itself. These spans
overlap and must not be summed.

## Live application closure

A disappearing GTK window is insufficient shutdown acceptance. Run the release
binary through the normal window-manager close request and require natural exit
status zero, no hang, and no surviving identified children:

```bash
/usr/bin/python3 tools/application_close_smoke.py \
  --output /absolute/new/close-evidence --cycles 100 --plain -- \
  build/linux/x64/release/bundle/busymark
```

The observer uses only the PID-owned X11 window. It supplies disposable home,
settings, history, session, recovery, cache, and fixture directories while
preserving the authenticated desktop connection. A failed run is retained and
any necessary cleanup is recorded as failure. Linux `/proc` task-child reads and
an observer-only child subreaper track descendants after their parent exits,
including helpers that create another session. Missing or inaccessible observation
is incomplete verification, not an empty child list; ordinary process/thread exit
races are distinguished. A zombie thread-group leader with remaining threads is
still a running process: cleanup waits for its workers as well. The observer
requires no pre-existing children so
adoption has unambiguous ownership. Cleanup pins and rechecks process identities,
waits for all identified children independently of the parent, escalates from
TERM to KILL when necessary, and records verified termination or unresolved
survivors. Cleanup success preserves the failed-run classification. A cohort
stops if child observation is incomplete or survivors remain unresolved.
An empty task snapshot is rechecked against the child's identity and exit state;
an empty or inaccessible snapshot of a still-live process remains incomplete.
It never treats a Dart checkpoint
as successful process exit. This is a functional close test, not a startup
content observer or a presentation-time benchmark.

To exercise rendered frames, an actual diagram, pending native initialization,
decoded moving video, dirty-document save/discard/cancel, durable clean shutdown,
and subsequent reopening through the application controllers:

```bash
flutter build linux --release -t tools/window_close_smoke.dart
/usr/bin/python3 tools/application_close_smoke.py \
  --output /absolute/new/close-live-evidence --cycles 3 --fresh-profile \
  --scenarios plain visualization pending-initialization \
    dirty-save dirty-discard dirty-cancel video \
  --video test/fixtures/media/close-testsrc.mp4 -- \
  build/linux/x64/release/bundle/busymark
flutter build linux --release -t lib/main.dart
```

The alternate entry point calls the real application and its close listener. It
is test-only and is not the distributable entry point. `FrameTiming` confirms
live build/raster execution; it does not claim display presentation timing.
Document checks wait for the requested path and text in the mounted editor and
two subsequent timed frames. Cancel checks retain the exact unsaved text.
Video confirmation samples the identified application drawable. Record missing
video prerequisites separately from completed normal-close attempts.
Native tracing checks that the pending case actually reaches shutdown before
initialization completes. That case uses an isolated test harness with the same
content security policy that deliberately withholds readiness. This prevents a
fast harness from finishing during required close persistence; it is a lifecycle
test, not a reproduction or timing measurement of the historical WebKit stall.
The ordinary shipping-executable cohort does not
require tracing. Cleanup warnings are retained separately from fatal signals.

For strict confinement, use an explicitly owned disposable parallel instance
in a disposable machine. `--snap-instance busymark_close` enters the normal
Snap launcher, isolates application paths inside that instance's common directory,
and verifies its enforced AppArmor label. Do not use this procedure to replace a
user's installed application. The workflow requires 100 shipping-executable
natural closes in both standalone and strict-Snap environments and retains
failure evidence. Headless compositor checks remain functional compatibility
checks; they establish no physical-desktop performance result.
Use `--fresh-profile` for a new isolated application and graphics cache for each
case; its reopen check reuses that case's profile. Previous profiles are retained,
and no system cache is cleared.
