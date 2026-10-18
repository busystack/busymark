# Draft: safely reject queued Yaru requests after window retirement

Unpublished proposal for [ubuntu/yaru_window.dart](https://github.com/ubuntu/yaru_window.dart).
The pinned `yaru_window_linux` 0.2.2 correction is independent of Flutter's
compositor and remains in production pending an upstream resolution.

The registrar exposes a borrowed weak view. A queued method or stream operation
can run after that view/window is destroyed; `get_state` can also run after the
native surface is unrealized. The current code then reaches GDK with a missing
window, including the captured `gdk_window_get_type_hint` crash.

The exact minimal patch, input hashes and MPL license are maintained in
`tools/native_patches/yaru_window_linux`. Preparation writes generated build
copies only, never the dependency cache. The patch rejects missing/destroying
view/top-levels with `window-unavailable`, handles absent state surfaces, and
makes stream cancellation/notifications safe after retirement. It retains no
widget and does not alter engine teardown.

`tools/test_yaru_window_lifecycle.sh` exercises the actual patched source with
a controlled nullable registrar and forced GTK destruction; its `--unpatched`
control demonstrates the original defect. Preparation and input validation are
covered by `tools/test_yaru_patch.py`. Actual application close acceptance is a
separate requirement. Do not remove the correction on a passing widget suite.

The 2026-10-18 repository issue search for `crash` found no matching report;
recheck issues/PRs before submitting. Do not upgrade the plugin or expand the
patch while preparing this upstream contribution.

The checked upstream `main` plugin source on that date is byte-identical to
the pinned plugin (`cd503514302db21aac226b6aa75162d05661a277d7946a7f9e6a657479862a42`).
It still lacks these guards. Preserve the small build-copy correction until a
supported upstream version is separately approved and verified.
