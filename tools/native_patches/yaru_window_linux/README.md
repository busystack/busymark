BusyMark's pinned `yaru_window_linux` 0.2.2 can receive a queued state request
after its registrar's weak view has disappeared. Passing that missing window
to GDK crashes in `gdk_window_get_type_hint`. GTK notifications can also arrive
after the native surface has been unrealized.

The patch checks the borrowed view/window on the GTK thread, returns the
`window-unavailable` channel error for a retired window or absent state surface,
and makes event cancellation safe after destruction. It neither retains widgets
nor changes engine shutdown. Valid window operations keep their original behavior.

`prepare.py` verifies every source input and the patch, then patches generated
copies inside the build tree. It never writes to the dependency cache. CMake
compiles these copies for every Linux mode and installs the modified source,
patch, and upstream MPL 2.0 license in
`share/busymark/third-party/yaru_window_linux`.

Run `bash tools/test_yaru_window_lifecycle.sh` after preparing the corrected
engine. The probe exercises the actual patched source with a controlled nullable
registrar view and GTK destruction; compiled-application natural-close checks
remain a separate acceptance gate. To verify the original regression, pass
`--unpatched` and the source directory to that script.
