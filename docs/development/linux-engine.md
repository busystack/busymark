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

`Flutter Linux` checks ordinary application changes. Run `Linux native acceptance`
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

The production Yaru 0.2.2 retired-window correction remains required by the current
plugin integration. CMake patches build-local sources, never the pub cache, and
ships the MPL notice. Its implementation is unchanged. A supported unmodified
replacement must pass the same native lifecycle tests before dependency changes
are approved; patch-free dependency acceptance remains unresolved.

```sh
/usr/bin/python3 -m unittest tools/test_yaru_patch.py
xvfb-run -a dbus-run-session -- bash tools/test_yaru_window_lifecycle.sh
```
