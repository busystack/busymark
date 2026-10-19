# Performance and shutdown observers

`tools/owned_processes.py` is the shared Linux ownership boundary for the close
observer, portal controls and slow-operation watchdog. Run each case in a
dedicated observer with no pre-existing or concurrent unrelated children.
New descendants need a matching owned parent or adoption by that observer's
subreaper. A child PID list alone does not prove ownership. Ambiguous admission
fails verification and grants no signal authority. Cleanup uses pinned process
identities, waits independently of parent exit and records unresolved survivors;
do not start another case after incomplete observation or unresolved cleanup.
An anchored stat read may observe a reaped `X` task, or stale `Z` state with zero
threads and parent 0. This is retirement, not proof of ownership; it grants no signal authority.
Identity mismatches and live/unverified ancestry still fail observation. A
zombie/dead leader with other threads is kept under observation.

Watchdog snapshots use the same recorded births and an anchored proc-directory
descriptor. Exited/reused processes are snapshot races; inaccessible live
processes and failed publication are verification failures. Neither successful
cleanup nor a disappearing window turns a failed application run into a pass.

Current native, Dart and visualization begin/end records append `pid` and `span`
invocation IDs after `time_us`. Names remain operation filters, not identities.
Native spans use a process-wide atomic counter; Dart uses the existing UUID
generator, independent of isolates and VM timeline support. Official Flutter
release engines can return zero for every `TimelineTask` ID, so those IDs cannot
identify diagnostic invocations. The producer regression exercises JIT and AOT.
The watchdog pairs by producer/process/invocation, including overlapping async
work completing in either order. Capture `operations.json` and `active-at-stop`
records use those keys with explicit name/start/receipt metadata. Historical
untagged records remain readable for nonoverlapping names; ambiguous overlap
fails verification instead of silently retiring the wrong operation. Preserve
the original raw historical logs; IDs cannot be reconstructed retrospectively.

Content recognition has a separate purpose. `tools/application_content_observer.py`
compares a crop of an **already identified owned application window** to a ready
reference. It does not find windows or prove input responsiveness or persistence.
Calibrate the reference outside the measured cohort and define regions containing
the requested document's distinctive text/structure. Coordinates below refer to
the 220×120 comparison image, not desktop coordinates:

```python
from application_content_observer import ContentReference

reference = ContentReference(ready_owned_crop, [(1, 0, 55, 8), (1, 10, 55, 17)])
observation = reference.compare(current_owned_crop)
if observation['matched']:
    # Record detection now; this is not a display-presentation timestamp.
    ...
```

The example regions cover two lines in the restoration fixture; select regions
for each actual fixture. Exclude blinking carets and animations. Blank references
are invalid. Keep the existing global mean-error limit (1.5); small informative
tiles also require matching content (mean channel error at most 12 per tile).
Large empty backgrounds therefore cannot hide missing text or a changed document.
Before reuse, verify the ready positive plus blank, loading, missing-body and
wrong-document negative controls, including a neighboring document with a shared
prefix. Keep those controls and observed scores in external evidence. Do not
change deadlines, interaction probes or durability checkpoints to compensate for
a failed image check. Historical measurements remain immutable; an inadequate
negative control alone does not prove that a historical sample was false.

Run the focused tooling checks with system Python and the test-only Pillow and
PyYAML packages (`python3-pil`, `python3-yaml` on Ubuntu). GDB regressions need
permission to trace their own synthetic children:

```sh
/usr/bin/python3 -m unittest tools/test_owned_processes.py \
  tools/test_application_close_smoke.py tools/test_capture_native_slow_operation.py \
  tools/test_application_content_observer.py tools/test_yaru_patch.py \
  tools/test_official_flutter_workflow.py tools/test_run_owned_fixture.py
```

The ordinary `Flutter Linux` push/PR workflow checks application formatting,
analysis, the complete widget suite, tooling controls and release compilation.
Run `Linux native acceptance` explicitly before a release/runtime decision: it
retains the 100-close standalone and strict-Snap cohorts, debug/profile checks,
compiled document/media tests and X11/Wayland compatibility checks. Run
`Flutter upstream capabilities` separately to exercise the proposed local-first
portal behavior on the selected official engine, including withheld replies.
These capability assertions are unchanged and currently expose upstream
blockers; they are not ordinary widget regressions.

A passing ordinary workflow does **not** establish release readiness. Native
fatal exits and unmet required portal behavior remain release blockers. Neither
explicit workflow permits publishing or deployment. Within native/capability
runs, prerequisite/status conditions let independent checks continue after a
failure, which still fails its job. Fixture and main-target builds have distinct
outcomes, preventing stale-target checks. Local topology/unit checks are not
hosted-CI, GTK-engine or strict-confinement acceptance.

`tools/portal_test_support.py` owns the shared private-bus fixture and protocol;
`tools/portal_test_service.py` supplies the controlled service. Application
capability checks import that support directly. The proposed-engine component
driver is `docs/upstream/flutter/tests/run_portal_initialization.py`; it is not
an application test dependency. No control modifies the host desktop portal.

The Linux History interprocess tests lazily compile their fixture on the first interprocess case, once per test file,
using `flutter build bundle --debug --no-pub` from the official SDK selected by
`.dart_tool/package_config.json`. Filtered local-only cases do not invoke a compiler. Concurrent child starts await
the same preparation result, including failure. This avoids invoking private compiler snapshots
or maintaining frontend-server arguments. They launch the resulting kernel
directly with the same SDK's `flutter_tester` and ICU data; this remaining runtime
coupling is covered by the interprocess tests. Operation readiness
does not include repeated Flutter-tool startup, SDK locking, assets or build
hooks. This is test execution, not a new application build/engine workflow.
Fixture diagnostics separate runtime entry and individual production store/lock
operations. The existing 60-second operation-readiness and 30-second writer
completion bounds remain unchanged; compiler preparation has its own bound.

`tools/run_owned_fixture.py` gives each compiler/runtime a dedicated supervisor
using the same `owned_processes.py` contract. It accepts a command, never a
fixture-provided PID. Parent EOF/cancellation requests verified retirement.
Surviving children are waited for independently of root exit and escalated only
through matching identities. Failed runs remain failures after cleanup; missing
observation or unresolved retirement prevents the Dart fixture from starting
another case. Reports include the actual command and monotonic spawn/exit
boundaries. The fixtures are headless widget-runtime checks, not GTK compositor,
strict-Snap or application performance acceptance.
