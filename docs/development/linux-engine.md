# Linux development with official Flutter

BusyMark uses the official Flutter SDK pinned in `pubspec.yaml` (3.47.5).
Put that SDK on `PATH`; use an independent installation for experiments rather
than changing a shared SDK. No BusyMark engine build, patch, cache, artifact
receipt or local-engine selection is required or supported by the project.

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
official SDK and packages its unmodified release engine. Build/test strict Snaps
only in a disposable supported environment; never replace a user's installation
for acceptance. See the README's clean Snapcraft procedure. The local scaffold
repack helper does not validate dependency or confinement changes.

Build success is separate from release acceptance. The official Linux engine
has reproduced a compositor disposal/presentation race; synchronous portal
initialization can also prevent startup when the service withholds replies.
Removing the private engine does not correct either defect. Native fatal exits
and withheld-portal progress failures keep release blocked. Preserve all failed
samples; a disappearing window or cleanup termination is not natural shutdown.

The [upstream evidence package](../upstream/flutter/README.md) preserves the C6,
ATK and asynchronous local-first portal proposals and deterministic regressions.
They are review material, never production build inputs. Do not apply them to a
shared SDK or silently reinstate a custom engine. A proposed Flutter issue/PR
must be reviewed before publishing.

The pinned Yaru 0.2.2 nullable/retired-window correction remains independent.
Build-local patched plugin sources and its MPL notice ship with the app; neither
the pub cache nor Flutter is patched. Run `tools/test_yaru_window_lifecycle.sh`
and `tools/test_yaru_patch.py`; track an upstream plugin fix separately.

For live acceptance, build `tools/window_close_smoke.dart`, then use
`tools/application_close_smoke.py` on an owned disposable desktop/profile.
`--expected-engine /path/to/official/libflutter_linux_gtk.so` optionally verifies
the actual mapped library without requiring a production receipt. The observer
requires complete child enumeration, PID/start-time identities, natural exits
and verified descendant cleanup. The portal gate in `tools/test_portal_application.py`
retains its five-second progress assertion and independent GTK Inhibit case.
Neither a later timeout nor successful cleanup makes a failed assertion pass.

Keyboard audits cover the owned content window and later-created child windows
using core X11 and XI2 counts. They do not observe global/root keyboard payloads;
events before subscription cannot be reconstructed. Run the live regression
only on a disposable display:

```sh
xvfb-run -a dbus-run-session -- /usr/bin/python3 \
  tools/test_application_input_observer.py --disposable-display
```
