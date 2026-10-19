# Flutter upstream review material

BusyMark builds with the **official Flutter 3.47.5 SDK**. The proposed engine
patches and native controls in this directory are not applied, built, selected
or packaged by the application workflow. The portal controls share the owned-bus
support in `tools/portal_test_support.py` and `tools/portal_test_service.py` with
application capability checks; those helpers do not patch or select an engine.
Do not substitute these experimental libraries into a shared SDK or a release.

The preserved patches are review inputs, not an alternative engine distribution:

* `engine-lifetime.patch` and `engine-lifetime-tests.patch`: reviewed C6 retirement
  correction and deterministic engine tests.
* `adjacent-atk-null-id.patch`: separately identified ATK correction needed by
  the experimental control; it is not part of the compositor diagnosis.
* `settings-portal-async.patch` and `settings-portal-tests.patch`: asynchronous,
  local-first settings initialization, cancellation, coherent publication and
  revision-safe notifications. The approved policy permits a genuine later
  appearance adjustment; it does not wait for portal authority before content.

`engine.lock.json` records the exact historical source/toolchain and patch
hashes. It is **not** a production artifact receipt. `reviewed-sources.json`
records source identities used in the review. The license is retained unchanged.
Tests and complete native/Dart control entry points are under `tests/`.

See [the unpublished upstream follow-up](shutdown-follow-up.md) and
[reproduction instructions](reproduction.md). The
[settings-portal proposal](portal-follow-up.md) and
[separate Yaru proposal](../yaru-window-follow-up.md) are also unpublished.
Do not publish without approval.

The original evidence remains outside Git at:

```
~/busymark-startup-investigation/busymark2-performance/
  20261015T093118Z-91f553/shutdown-20261016T053938Z/
  portal-correction-20261017T212308Z/
  five-repairs-20261018T084929Z-83a017/
/mnt/Media/busymark2-engine-correction-20261016T112258Z/
```

The first directory includes both original stopped-thread archives, matching
process-root libraries, source comparisons, complete managed/native controls,
build arguments and every failed run. The later directories preserve the A/B/C6
experiments and official-engine revalidation. Binaries, full source trees, raw
traces and investigation reports are deliberately excluded from this repository.

Removing the private engine does not fix its upstream defects. Fatal shutdown
reproduction blocks release. A nonresponsive settings portal can again block
official-engine startup; GTK's separate synchronous Inhibit `GetAll` is also
unresolved. No private GTK is built or bundled.
