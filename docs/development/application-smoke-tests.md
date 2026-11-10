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

## Installed Git workflow verification, 2026-10-30/31

The final strict Snap was built from `a010b03`, with core `07cf4a1` and shared
widgets `29eb348`. Its SHA-256 is
`8ff4ff905043161002df0d7d4504f0cf6c04f6f484c151c903246340de584404`.
All 806 installed native files match the package. The official release engine
remains `d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.
Later documentation commits do not change this runtime-artifact identity.

Evidence is in `build/git-verification/2026-10-30/final-mark-a010b03`, including
commands, final source checks, 256 Git/localization/workspace/document tests and
the additional actual-app Git-search regression. The search correction also
has a paired failing/passing reproduction and 51 related passing cases in
`build/git-verification/2026-10-30/git-search-focus`. It keeps the raw authoring
search handler from competing with the focused Git comparison.

Installed Wayland checks cover populated Commit, merge Log, file history with
parent selection, long-line comparisons, editable Index and conflict Result.
The rapid Unstage attempts were queued 8,138 ns apart. Exact draft/index audits
preserve the final `end` line, unrelated staged entries, working bytes and HEAD.
The actual host Close, repeated Close, Cancel, window close, undo/redo and native
Unicode composition were exercised. Saving and reopening the mixed conflict
result preserves its manual bytes and leaves the unmerged index intact.
German, Japanese and Arabic layouts were inspected, including dark mode,
enlarged text and fractional display scaling. Three final single-window native
sessions exited naturally with status 0, including the populated parent-2
history and directional branch-menu follow-up.

The installed amend race uses the real Git hook as a gate: submitted B produces
exactly one commit, while normal A and newer old-target amend C retain their
exact durable versions. Mode and repository changes preserve both drafts. Its
synthetic repository, saved result and earlier evidence remain available.

The console uses authenticated LXD SPICE and official spice-gtk public APIs in
the existing test VM. `gitfinaladd365` is that guest's account, not the user's
normal desktop. Normal password authentication remains required; no GNOME
Remote Desktop consent or security-policy change is involved. Reconnect the
same console after a display-mode change if pointer coordinates become stale.

These checks do not pass the independent native release gates. AT-SPI geometry
and descriptor lifetime, and Wayland multiple-engine disposal, retain their
SDK-only/official-GTK reproductions. Final-Snap credential controls also show
an AppArmor denial for the normal GCR agent socket, despite successful signing
with the same synthetic key outside confinement. Libsecret reads work after
normal keyring authentication, but confined stores return success without
persisting their value; complete stdin delivery and unconfined stores are
verified. That write failure's cause remains unassigned. Original synthetic
credential values were restored; no identities were enumerated and no values
were logged. Native Windows and the complete signed/network GUI matrix remain
unrun in this Linux environment. Do not infer their acceptance from these
installed Git checks.
