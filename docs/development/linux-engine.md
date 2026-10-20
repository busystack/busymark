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
flutter test --concurrency=2
```

CI selects the same official version. Snapcraft downloads the checksum-pinned
SDK and packages its unmodified release engine. Follow the README's clean
Snapcraft procedure in a disposable supported environment; do not replace an
installed application for acceptance. The local scaffold repack helper is not
release or confinement validation. Strict-Snap checks use the normal systemd
user-session bus for launcher cgroup tracking, not a private D-Bus session.

`Flutter Linux` automatically checks ordinary application changes, including
bounded GTK/WebKit and compiled visualization/PDF regressions for PRs to `main`
and `release/v0.6.3`. Run `Linux native acceptance`
for compiled document/media checks, natural shutdown, strict Snap, debug/profile,
and X11/Wayland compatibility. See [maintained observers](performance-observers.md).
A widget-suite pass does not validate the GTK embedder.

## Release blockers

The official engine has reproduced a compositor disposal/presentation race.
Synchronous Flutter settings-portal and GTK Inhibit/Properties.GetAll calls can
also block startup when the desktop portal withholds replies. These upstream
runtime failures remain release blockers; removing research tools does not fix
them. Historical patches, reproductions and crash evidence are archived externally.
A disappearing window or forced cleanup is not successful natural shutdown.

Yaru uses the unmodified dependencies in `pubspec.lock` through Flutter's
generated plugin build. No local plugin source preparation is required.
Compiled window, document and media checks exercise the actual application;
upstream runtime shutdown failures still fail native release acceptance.
