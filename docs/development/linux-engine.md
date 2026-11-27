# Linux development with official Flutter

Use the official Flutter 3.50.1 SDK with Dart 3.14.0, as pinned in
`pubspec.yaml`, on `PATH`. The framework revision is
`ae9b586f34a8443573f82ef57c3bf914a908cbf7` and the engine revision is
`4d35714800b9266b6693a58e1225ecd7e9e45ed7`.
The Flutter pin selects the bundled Dart toolchain. The minimum Dart constraint
in `pubspec.yaml` preserves BusyMark's Dart 3.12 language version.
BusyMark does not build or select a custom engine or GTK runtime.

```sh
flutter pub get --enforce-lockfile
flutter run -d linux
flutter run -d linux --profile
flutter run -d linux --release
flutter build linux --debug
flutter build linux --profile
flutter build linux --release
flutter analyze
flutter test
```

In Android Studio, open the repository root, configure the official Flutter SDK
pinned above, select the shared **BusyMark (Linux)** run configuration, and select
the **Linux (desktop)** device. The configuration runs `lib/main.dart` with
`--device-id=linux`. BusyMark has no Android application module; Android entries
in Flutter's transitive plugin dependencies do not add an Android target.

If Flutter imports produce many missing-type errors after using a temporary SDK,
run `flutter pub get --enforce-lockfile` with the configured SDK, then reload the
project so the IDE refreshes its package roots. Generated `.dart_tool` and IDE
package metadata can otherwise retain paths to an SDK that has been removed.

Ubuntu 26.04 amd64 is the primary build and acceptance environment.
CI selects the same official Flutter version. Snapcraft downloads the checksum-pinned
SDK and packages its unmodified release engine. Follow the README's clean
Snapcraft procedure in a disposable supported environment; do not replace an
installed application for acceptance. The local scaffold repack helper is not
release or confinement validation. Strict-Snap checks use the normal systemd
user-session bus for launcher cgroup tracking, not a private D-Bus session.
Standalone smoke checks use disposable D-Bus sessions to retire desktop helpers.

`Flutter Linux` automatically runs bounded GTK/WebKit, compiled visualization/PDF,
dictionary installation/offline restart, Wayland and strict-Snap build/install
checks for PRs and pushes to `main` and `release/v0.8.0`. A push to the
release branch also runs the full `Linux native acceptance` stress campaign
for the exact pushed commit. The workflow can be dispatched with stress
enabled for hundred-close, compiled document/media and debug/profile campaigns.
See [compiled application checks](application-smoke-tests.md).
A widget-suite pass does not validate the GTK embedder.

Yaru uses the unmodified dependencies in `pubspec.lock` through Flutter's
generated plugin build. No local plugin source preparation is required.
Compiled window, document and media checks exercise the actual application;
the native runners report PASS, XFAIL and FAIL separately.

The v0.7.4 release investigation reproduced
`g_mutex_clear() called on uninitialised or locked mutex` on the official
Flutter 3.50.1 Linux release engine under X11. The debugger captured `SIGABRT`
from the engine's call to `g_mutex_clear()`. The mapped engine SHA-256 was
`8fc5c4ee6a20215f54c332c7b8910c482434247e451f24cfd7d3225f0a28066b`.
See the [related Linux shutdown report in Flutter issue #189379](https://github.com/flutter/flutter/issues/189379).

BusyMark Linux x64 acceptance can explicitly enable
`--xfail-flutter-3.50.1-shutdown` for this release engine. XFAIL requires a
verified BusyMark process, all scenario assertions, a normal close request,
a fresh durable clean-shutdown checkpoint, and the exact diagnostic in the
case's application log. The process must report SIGABRT with wait status
`-6`. Integrity, confinement where applicable, process observation, and
cleanup must all succeed without a timeout or forced termination. The receipt
preserves the exit status and sets `naturalExit` to false. The matrix continues,
including required document-reopen runs. Missing evidence, other signals, and
other diagnostics fail the gate.

Debug and profile builds, BusyFiles, and the product probes that use Dart
`exit()` retain their strict checks. CI checks the version pin and the exact
engine hash. On every Flutter upgrade, explicitly reassess the exception using
the affected native shutdown cases with the flag disabled. Remove the flag and
policy when the official replacement passes those cases. Any exception for a
different artifact requires separate evidence and review.

Startup resolves the GTK accent or its portal fallback before building the UI,
using the existing readiness deadline. A valid GTK accent does not wait for the
portal. Saved preferences are read once before `runApp()` and handed to the
settings controller; failed reads use defaults without acknowledging them as a
persisted snapshot.
