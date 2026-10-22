# Linux development with official Flutter

Use the official Flutter SDK pinned in `pubspec.yaml` (3.47.5) on `PATH`.
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

CI selects the same official version. Snapcraft downloads the checksum-pinned
SDK and packages its unmodified release engine. Follow the README's clean
Snapcraft procedure in a disposable supported environment; do not replace an
installed application for acceptance. The local scaffold repack helper is not
release or confinement validation. Strict-Snap checks use the normal systemd
user-session bus for launcher cgroup tracking, not a private D-Bus session.
Standalone smoke checks use disposable D-Bus sessions to retire desktop helpers.

`Flutter Linux` automatically runs bounded GTK/WebKit, compiled visualization/PDF,
dictionary installation/offline restart, Wayland and strict-Snap build/install
checks for PRs to `main` and `release/v0.7.0`, and pushes to `main`. It reuses
`Linux native acceptance` with `run-stress: false`. Run that workflow manually
with `run-stress` enabled for hundred-close, compiled document/media and
debug/profile campaigns. See [compiled application checks](application-smoke-tests.md).
A widget-suite pass does not validate the GTK embedder.

Yaru uses the unmodified dependencies in `pubspec.lock` through Flutter's
generated plugin build. No local plugin source preparation is required.
Compiled window, document and media checks exercise the actual application;
runtime shutdown failures still fail native release acceptance. A disappearing
window or forced cleanup is not successful natural shutdown.

Startup resolves the GTK accent or its portal fallback before building the UI,
using the existing readiness deadline. A valid GTK accent does not wait for the
portal. Saved preferences are read once before `runApp()` and handed to the
settings controller; failed reads use defaults without acknowledging them as a
persisted snapshot.
