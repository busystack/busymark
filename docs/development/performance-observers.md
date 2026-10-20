# Maintained application observers

`tools/application_close_smoke.py` verifies natural process exit and document
results with isolated HOME/XDG profiles. `tools/owned_processes.py` supplies its
Linux ownership boundary and the owned-fixture supervisor. Run each case in a
dedicated observer without unrelated children. Descendant admission requires a
matching parent or subreaper adoption; ambiguous observation fails verification.
Cleanup checks PID/start-time identities, waits independently of parent exit,
and records unresolved survivors. Never start another case after incomplete
observation or unresolved cleanup. Cleanup cannot turn a failed run into a pass.

`--expected-engine /path/to/official/libflutter_linux_gtk.so` verifies the actual
mapped library. The compiled fixture and shipping executable have separate
checks; see [live application closure](visualizations.md#live-application-closure).
Run compiled fixtures on a disposable desktop and never inject input into an
unrelated window. Owned-window keyboard audits count core/XI2 events without
recording global keyboard payloads. Missing observation remains a failure.

The compiled fixture's `window-controls` scenario verifies the rendered Yaru
controls, native state notifications and titlebar dragging. Add
`--scenarios window-controls --disposable-display` to the compiled close command
linked above. This requires a window manager and a desktop owned entirely by
the test; do not run pointer injection on a personal desktop.

```sh
/usr/bin/python3 -m unittest tools/test_owned_processes.py \
  tools/test_application_close_smoke.py tools/test_application_content_observer.py \
  tools/test_official_flutter_workflow.py \
  tools/test_run_owned_fixture.py
xvfb-run -a dbus-run-session -- /usr/bin/python3 \
  tools/test_application_input_observer.py --disposable-display
```

Tooling tests need Clang, system Python, Pillow and PyYAML (`python3-pil`, `python3-yaml`
on Ubuntu). These checks do not establish GTK-engine or strict-Snap acceptance.
`Flutter Linux` checks formatting, analysis, widget tests, tooling and release
compilation, plus the GTK host, WebKit/renderer and compiled visualization/PDF
checks on ordinary PRs to `main` and `release/v0.6.3`. `Linux native acceptance` retains 100-close standalone/strict-Snap,
debug/profile and compiled document/media checks. Failures remain required;
prerequisite conditions allow independent checks to continue without bypassing
failed build/install steps. Neither workflow publishes or deploys.

`tools/application_content_observer.py` compares an already identified owned
application crop to a ready reference. It does not discover windows or prove
interaction, persistence or display-presentation time. Choose regions containing
the requested document, excluding carets/animations. Validate positive and blank,
loading, missing-body and wrong-document controls outside measured cohorts.
Keep existing error limits and preserve failures; do not adjust deadlines to
compensate for mismatched content.

Linux History interprocess tests lazily compile their fixture once per test file
using `flutter build bundle --debug --no-pub` from the official SDK selected by
`.dart_tool/package_config.json`. Concurrent starts await the same preparation
result. `tools/run_owned_fixture.py` supervises compiler/runtime descendants,
handles cancellation with verified cleanup, and prevents subsequent cases when
observation or retirement is incomplete. These headless checks are separate
from native runtime and application performance acceptance.
