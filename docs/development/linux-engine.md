# Pinned Linux engine

BusyMark requires the reviewed Linux compositor lifetime correction in every
Linux build. The framework, engine, Dart, depot_tools and Clang revisions,
configuration and patch order are in
[engine.lock.json](../../tools/flutter_engine/engine.lock.json). The patch set is
the lifetime correction, its engine regressions, and a separate ATK null-ID and
returned-string ownership correction. Separate portal-initialization patches
remove synchronous session-bus/proxy/read work from Flutter settings startup and test the
local settings fallback. Keep that composition when reproducing
the validated engine. Flutter's public API and application dependencies are
unchanged.

## Build and run

Run from the project root on Linux x64. Install the application dependencies in
the main README, plus Git, GNU patch, Python 3.12+, unzip, binutils and libepoxy development
headers, `python3-gi`, `gsettings-desktop-schemas`, `dbus-daemon` and a disposable
X11 display for portal tests. Compiled application checks also use `dconf-cli`
to create a synthetic database offline; they never write desktop settings. Engine compilation uses the DEPS-pinned Clang and downloaded Linux
sysroot. Allow substantial disk space and build time. The default cache is
`.build/flutter-engine`; an absolute `BUSYMARK_ENGINE_CACHE` can put it on a
larger disk. This is a private SDK/cache, never a replacement inside another SDK.

```sh
python3 tools/flutter_engine/engine.py prepare
python3 tools/flutter_engine/engine.py build --mode debug profile release --jobs 4
python3 tools/flutter.py pub get --enforce-lockfile
python3 tools/flutter.py run -d linux
python3 tools/flutter.py run -d linux --profile
python3 tools/flutter.py build linux --release --no-pub
```

The wrapper selects `host_debug_unopt`, `host_profile` or `host_release` using
Flutter's supported local-engine flags. Debug keeps JIT/hot reload; profile and
release use their matching snapshot compiler. Each cache contains its own Dart
SDK, patched SDK, headers and ICU. Do not mix official SDK ICU/snapshots with
these inputs. ARM builds are not supported by this reviewed recipe.

Missing, corrupt, mismatched or incomplete inputs fail with a preparation/build
command. CMake also rejects an ordinary official-engine `flutter build/run` and
checks what Flutter actually assembled and installed. An IDE must invoke the
wrapper as a task, or use the same verified local-engine arguments; an IDE's
default official-engine build fails. Do not bypass the guard to get a build.
The wrapper rejects `--use-application-binary`, which bypasses assembly checks.
It also rejects unmanaged `attach`: selecting local artifacts cannot verify an
already-running target's GTK engine. Start with the wrapper's `run` command,
use its hot reload/restart controls, and connect DevTools to its printed URL.
Before launching an existing bundle directly, verify it with the matching cache:

```sh
python3 tools/flutter_engine/engine.py check-bundle --mode release \
  --bundle /absolute/bundle
```

Installation stays in that mode's local `bundle` directory. A stale or custom
CMake install prefix pointing elsewhere fails before assembly; regenerate the
named local CMake cache or configure the bundle prefix shown in the error.

Analysis and widget tests use the pinned framework's stock `flutter_tester`:

```sh
python3 tools/flutter.py analyze --no-pub
python3 tools/flutter.py test --no-pub --concurrency=2
```

The two-worker full-suite command bounds concurrent durable fixture I/O,
matching CI. All tests and their deadlines still apply; this is functional
verification, not a storage or application performance measurement. Explicit
higher concurrency remains available for stress testing.

Widget tests do not execute the Linux GTK embedder. Native acceptance is separate:

```sh
xvfb-run -a dbus-run-session -- \
  python3 tools/flutter_engine/engine.py test --mode release
python3 tools/flutter_engine/engine.py verify --mode release
/usr/bin/python3 tools/application_close_smoke.py --output /absolute/new/evidence \
  --cycles 100 --plain --fresh-profile \
  --engine-manifest build/linux/x64/release/bundle/data/busymark-engine.json -- \
  build/linux/x64/release/bundle/busymark
```

For unattended X11 probes, add `--audit-input`. It observes key-event counts
only in the identified owned window subtree and fails on unexpected input or
incomplete observation. It preserves normal focus and window hints. Actual core
keyboard focus and EWMH activation are recorded separately; activation alone
does not prove keyboard focus. No key values or unrelated input are recorded.
The optional plain-window `--isolate-input` also requests a passive pre-map hint
and requires no activation/focus. That hint is advisory; an ignored hint makes
the probe incomplete, not an application shutdown failure. Never force focus
away from the user's other windows to obtain a passing result.

Use the normal authenticated desktop for production timing. Xvfb/Wayland
headless checks establish compatibility only. The close observer hashes the
owned process's pinned mapped library after exit, preserving timing and rejecting
a wrong engine or incomplete observation. Use the existing compiled
`tools/window_close_smoke.dart` fixture for rendering, media, dirty decisions
and reopening; its build goes through the same wrapper and receipt.

## Asynchronous portal settings

The initial frame uses available local GNOME settings and cached GTK properties.
Valid portal values override their local counterparts when the asynchronous
initial read round settles; missing or malformed keys retain local values.
Portal color-scheme retains precedence over its gtk-theme value. Local animation,
contrast and text-scale preferences remain available while the portal is absent.
Explicit BusyMark appearance preferences still take precedence in the app.
A genuinely different authority may cause one appearance adjustment.

Session-bus acquisition, proxy construction, service activation and all six reads
are asynchronous and cancellable. Subscribe before reading; key revisions reject
stale replies. Publish the initial round as one effective settings snapshot and
coalesce subsequent notifications. Live signals also publish while initial reads
are pending; their key revisions and staged values prevent later rollback.
On service restart, retain the previous
complete authority until the new round is available. Weak callback contexts and
retirement of the single pending publication source allow closure while replies
are withheld. No timeout is shortened and no nested GTK wait is introduced.
BusyMark's accent startup barrier similarly waits only for its local GTK source;
portal accent updates continue with the existing source precedence.
Before `runApp`, read BusyMark's local preferences once and hand their parsed,
acknowledged state to the controller. This keeps an explicit saved theme in the
first frame. The handoff is tied to its store and consumed once; subsequent
initialization reads fresh data. Failed reads retain the existing default policy
without treating defaults as an acknowledged file. This local read is part of
the measured launch, with no new settings write or portal wait.

The normal engine test command also runs the controlled portal regressions on
private session buses. Retain their evidence with `test --mode release --output
/absolute/new/portal-evidence`. The authentication case isolates provider bus
acquisition on GLib's main context: GTK's separate AT-SPI startup can itself wait
for bus authentication, before this provider runs. Other cases use live GTK
windows with normal accessibility enabled. These are functional progress bounds,
not startup performance measurements.

After building `tools/window_close_smoke.dart` with the wrapper, run compiled
settings/close acceptance on a disposable X11 display:

```sh
/usr/bin/python3 tools/test_portal_application.py \
  --output /absolute/new/compiled-portal-evidence \
  --application build/linux/x64/release/bundle/busymark \
  --engine-manifest build/linux/x64/release/bundle/data/busymark-engine.json
```

This reuses the existing natural-close observer and owned portal service. It
requires a real editor and continued frames before releasing withheld replies,
checks initial and authoritative settings, and verifies natural process/child
exit. A separate configured-profile case checks an explicit application theme
on the first rendered frame while portal reads are pending. The default uses
the real DConf backend, with a synthetic private database
whose nondefault scale differs from the schema default; `--settings-backend memory`
retains the simpler component fixture. For strict confinement, use `--snap-instance busymark_portal` instead of
`--application`, output under that disposable instance's common directory, and
`--socket-parent` pointing to a short directory there. The confined launcher uses
its normal session bus; only the application selects the owned fixture bus after
confinement. This changes no host portal or security policy. A denied fixture
connection is a failed/unverified check, never a reason to weaken confinement.
Deliberate service delays are kept separate from natural performance cohorts.

The compiled gate also withholds `Properties.GetAll` for every portal interface
until natural process exit. This checks the complete application, including GTK
startup before Flutter. GTK 3.24.41 and 3.24.50 can synchronously fetch unused Inhibit
properties on this path; the engine settings patch does not correct that GTK
call. A failure here is an application startup acceptance failure even when the
component tests and the other compiled cases pass. Do not omit this case or
claim that engine-only validation proves independence from the portal. A GTK
runtime correction requires separate source, runtime and packaging validation.

## Caching and Snapcraft

The source/patch/configuration key names the cache. Artifact receipts record
every input hash, reviewed source hashes, mode, architecture, compiler, ELF build
ID, code hash and loader dependencies. CI's archive cache also keys the build
tool and regression sources. Cache archives are build inputs from trusted builds,
not a substitute for source provenance or a place to accept arbitrary binaries.

```sh
python3 tools/flutter_engine/engine.py export --mode release \
  --output .build/engine-release.tar.xz
# On another clean checkout using the same recipe:
python3 tools/flutter_engine/engine.py prepare --framework-only
python3 tools/flutter_engine/engine.py import .build/engine-release.tar.xz
```

An existing pinned private source/SDK can seed a new cache with `prepare
--source-seed /absolute/source --framework-seed /absolute/sdk`. The tool copies
them independently, synchronizes locked dependencies, and verifies the exact
patch composition. It never changes the seed. Export/import preserves matching
symbols in `symbols/<mode>` and verifies their hash and ELF build ID. Keep them
for native debugging; they are excluded from the final Snap.

The native suite's GN-generated schema locator is test-only. The recipe makes
it relative to the artifact directory and includes its compiled schemas; the
test command sets that working directory. This prevents cached tests from
silently depending on the source builder's absolute path. Engine runtime code
and the reviewed patch composition are unchanged by this test-data adjustment.

`snap/snapcraft.yaml` has an explicit engine part. A verified
`.build/engine-release.tar.xz` avoids recompiling the engine; without that archive
the part builds the same pinned correction from source. The application part
uses the private staged SDK and artifacts. Its pull excludes generated build
directories and the private engine cache; the engine part reads the archive
directly from the project directory. Source, SDK and tests stay out of the
final Snap. The engine already has `RUNPATH=$ORIGIN`; its dedicated runtime part
excludes further ELF rewriting, which otherwise damages GNU build-ID note
alignment in the supported packager. Application/plugin path adjustments stay
in place. Packaging requires byte-identical engine and ICU inputs before
recording the packaged engine hash. Never
replace an engine manually in a shared SDK or existing installation.
Font and Yaru resource aliases are created in the application part's install
tree before staging. Keep that phase: creating them only during priming leaves
untracked aliases that break a later application/fixture rebuild.

Build the genuine strict package in a clean, disposable Ubuntu 24.04 Snapcraft
environment using the README procedure. Inspect `data/busymark-engine.json` in
the produced artifact and require that receipt in confined close acceptance.
The local scaffold repack helper also uses the wrapper; it remains unsuitable
for validating dependency or packaging changes.

The close observer records `mapDetected_ns` when its owned-window query first
finds the mapped window. Historical `mapped_ns` remains after `/proc/PID/maps`
snapshot publication; neither endpoint measures display presentation. The optional
`run_case(observer_event=...)` diagnostic hook reports observer operation wall/CPU
boundaries to a caller-owned bounded memory buffer. Snapshot observation failures
are incomplete verification, never successful application-close acceptance.

Owned-window keyboard auditing requires XInput2 as well as core X11 events:
GTK can receive XI2 keyboard input that never reaches a core-only observer.
Unavailable selection or event data makes observation incomplete. The observer
selects only the identified window subtree, never root/raw input, and records
counts without key values. Verify actual GTK delivery on a disposable display:
`xvfb-run -a dbus-run-session -- /usr/bin/python3 tools/test_application_input_observer.py --disposable-display`.
The explicit flag authorizes test input only on that private display.

Pre-map input observation requires the normal content window: GTK's hidden
application leader also carries the process ID. The close gate checks that its
audit root is the subsequently mapped window. It tracks later-realized children
through owned subtree notifications and reports subscription times. Input before
a new child's subscription cannot be reconstructed; zero observed keys alone
does not establish the source of an unexpected document edit. The live regression
covers leader selection, late child delivery and widget destruction.

## Maintenance

The build records reviewed Linux source hashes in `busymark-linux-inputs.json`.
Missing or changed hashes invalidate the private build's Linux objects before
Ninja runs, even when copied source files have older timestamps than cached
objects. Other engine objects remain reusable. Publication rechecks source
content after compilation; imported artifacts must include the matching stamp.
Do not certify a source change by updating an artifact receipt alone.

`FlView` retains its renderer through forced GTK disposal. The engine returns
completed presentation references to GTK, preventing the raster callback from
making the final GTK-object release. `fl_view_renderer_present_layers` excludes
retirement across the entire call, including task-runner access after the
compositor's frame mutex unlocks. Renderer disposal closes callback admission
and removes its pending redraw source before releasing that lock.

`fl_engine_shutdown_compositor` fences cleanup on the engine render thread;
OpenGL cleanup makes the owned context current before deleting framebuffers.
GTK finalization releases synchronization objects only after that cleanup.
No renderer/registry lock crosses the fence; the pinned runner unlocks before
executing engine tasks and stop-wait only signals its condition. Failed posting
joins the core before cleanup. Keep software, repeated/partial teardown and
failed-posting coverage; do not replace this ordering with a fixed delay.

The full native suite and four barrier cases run in each engine mode. The
unchanged-engine reference test patch is retained for validating a future
backport; it uses existing embedder APIs and fails the old last-reference thread
ownership. Passing widget tests or vanished windows cannot replace these checks.
Any framework/engine roll or patch change requires matching snapshots, updated
source hashes and native/live application acceptance on supported graphics and
strict confinement. See Flutter's
[pinned compilation instructions](https://github.com/flutter/flutter/blob/af7e796e161ae0bb1ff0758c71a7105418bd9ded/docs/engine/contributing/Compiling-the-engine.md).

The pinned Yaru 0.2.2 plugin has a separate retired-window defect: queued state
requests may outlive the registrar's weak view. Linux CMake requires the narrow
patch in `tools/native_patches/yaru_window_linux`, verifies its source hashes,
and compiles build-local copies in every mode. Neither the pub cache nor C6
engine composition changes. The bundle includes the modified MPL source and
license. Run `bash tools/test_yaru_window_lifecycle.sh` for the native nullable
view/surface and event-retirement regression, then the normal compiled close
gate. A null-view crash in this plugin is distinct from compositor disposal.
