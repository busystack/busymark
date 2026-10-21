# Compiled application checks

Use the official pinned Flutter SDK and a disposable desktop with isolated
profiles. Never install test builds over an existing application.

`tools/application_close_smoke.py` requires natural process exit, durable clean
shutdown and verified descendant retirement. A Dart checkpoint, disappearing
window or forced cleanup does not pass. It identifies only the launched
application's window and records failed prerequisites and native exits.
`--expected-engine` accepts the actual official `libflutter_linux_gtk.so` and
verifies its mapped inode, device and bytes through retained descriptors.

```sh
python3 tools/application_close_smoke.py \
  --output /absolute/new/shipping-close --cycles 3 --plain \
  --expected-engine /path/to/official/libflutter_linux_gtk.so -- \
  build/linux/x64/release/bundle/busymark

flutter build linux --release -t tools/window_close_smoke.dart
python3 tools/application_close_smoke.py \
  --output /absolute/new/document-close --cycles 1 --fresh-profile \
  --scenarios plain visualization pending-initialization \
    dirty-save dirty-discard dirty-cancel video \
  --video test/fixtures/media/close-testsrc.mp4 -- \
  build/linux/x64/release/bundle/busymark
flutter build linux --release -t lib/main.dart
```

The alternate entry point exercises the real application, editors and close
listener. It verifies Save/Discard/Cancel, saved-file reopening and rendered
content before closing. Frame callbacks confirm raster activity; video checks
require changing decoded frames. The pending-initialization case requires
`visualization-shutdown initPending=1`, using a harness that withholds readiness.

The `window-controls` scenario also tests Yaru maximize, restore, minimize, close
and titlebar dragging. It requires a window manager and the explicit
`--disposable-display` option because it injects pointer input.

`--snap-instance busymark_close` tests an owned parallel instance in a disposable
machine through its ordinary strict launcher and enforced AppArmor label. Use
the normal systemd user-session bus. Standalone checks can use a private D-Bus
session. Keep WebKit sandboxing and ordinary graphics settings enabled.

`tools/owned_processes.py` and `tools/run_owned_fixture.py` are also used by
History and browser regressions. Each supervisor owns a dedicated child tree;
PID/start-time checks and held descriptors prevent signalling reused or unrelated
processes. Incomplete observation or unresolved cleanup fails verification and
prevents another case. History fixtures compile once per test file before their
operation deadlines, preserving interprocess lock and cancellation checks.

```sh
python3 -m unittest tools/test_owned_processes.py \
  tools/test_application_close_smoke.py tools/test_run_owned_fixture.py \
  tools/test_official_flutter_workflow.py
```

These tooling tests require Clang and PyYAML in addition to system Python.
Automatic CI runs bounded native, X11/Wayland, dictionary/offline restart and
strict-Snap product checks. Hundred-close and debug/profile campaigns remain
explicitly selected release checks; see the existing workflows.
