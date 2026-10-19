# Draft: Linux renderer retirement still races forced GTK child destruction

**Unpublished; submission requires review.** Follow up on
[issue 188659](https://github.com/flutter/flutter/issues/188659) and
[PR 188702](https://github.com/flutter/flutter/pull/188702), rather than submitting
an unrelated duplicate. PR merge `c2e79e16c95f81fc832abdbcc1652e0ccfe5a16c`
moved compositor release from renderer `dispose` to `finalize`. That change is
already present in the pinned source.

The duplicate check also found open
[PR 193533](https://github.com/flutter/flutter/pull/193533), which explicitly
adds a strong view-to-renderer reference and synchronizes newer OpenGL/subsurface
renderer disposal. It belongs to stack 193534.
[PR 193126](https://github.com/flutter/flutter/pull/193126) concerns the Linux
windowing test environment and GLX/EGL context selection; the earlier draft's
attribution of frame-wait cancellation to that PR was incorrect.
Contribute the pinned-release captures, deterministic tests and ownership
analysis to the renderer review instead of opening a duplicate claim.
Its newer renderer implementation differs from
the pinned compositor code; the open PR is not a validated official-release fix
or an approved application workaround. In particular, review GTK cleanup-thread
ownership and post-unlock task-runner use alongside the child-reference repair.

## Affected source and ownership violation

Flutter 3.47.5 framework `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, engine
`af7e796e161ae0bb1ff0758c71a7105418bd9ded`, Dart 3.13.4. In the official
3.47.7 framework `abaf9c523780a608bd46686fd5e53740a07077f8`, the checked
`fl_view.cc`, `fl_view_renderer.cc`, `fl_compositor_opengl.cc`, `fl_engine.cc`
and `fl_settings_portal.cc` are byte-identical to 3.47.5. This source comparison
does not substitute for testing the later official binary.

The 2026-10-18 matched strict-runtime check used 20 interleaved closes per
official release with identical control source, GTK/libhandy providers, desktop
and first-owned-map close timing. 3.47.5 had 15 natural zero exits, four SIGABRT
and one SIGSEGV; 3.47.7 had 18 natural zero exits and two SIGABRT. Neither had
incomplete child observation or unresolved survivors. Aborts include
`g_mutex_clear() called on uninitialised or locked mutex`. These new failures
are not assigned individual native stacks without a stopped-process capture;
the same-object mechanism above is established by the preserved original stacks.

Actual mapped official release libraries were SHA256
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`
(3.47.5) and
`f16d6efcacd3d2419cda30ac6e2ac30b7c760b0653b434de6449d629a917a948`
(3.47.7, engine `deb287481e3ce9468f3434937ced4240a70539ca`). Every accepted
mapping had `snap.busymark_portcheck.busymark (enforce)`. An earlier fixture
loaded the old packaged custom library; provenance verification rejected it,
and it is excluded from this official-engine comparison, with evidence retained.

The raster callback obtains a strong `FlRenderable`/`FlView` reference from the
engine registry. `fl_view_present_layers` uses the raw `self->renderer` child.
GTK owns that child's sunk floating reference. Forced parent destruction can
destroy/finalize the child while the view reference still exists. Consequently,
moving compositor cleanup to renderer finalization does not establish the
transitive ownership assumed by PR 188702.

Two original stopped-process captures establish concurrent access to the same
object, rather than merely locating a crash inside engine disposal:

```
GTK thread 85824:
 g_mutex_clear
 engine+0x4fcf73 = fl_compositor_opengl_dispose+0xc3
 g_object_unref
 engine+0x523439 = fl_view_renderer_finalize+0x59
 GTK forced widget disposal
 compositor=0x567220d7d000 frame_mutex=0x567220d7d048 value=1

Raster thread 85913:
 engine+0x4fc767 = fl_compositor_opengl_present_layers
 compositor=0x567220d7d000 frame_mutex=0x567220d7d048 value=1
```

These private offsets were matched using exact source, disassembly and GType
vtables; public frames were symbol-resolved. Original official release DWARF
was unavailable, so this is not represented as a complete DWARF stack. The
second capture shows presentation continuing through `fl_task_runner_stop_wait`
after frame-mutex unlock while compositor disposal is active. Clearing only an
unlocked mutex, or locking only around that clear, cannot protect this access.
Full original stacks and runtime identities are in the external evidence listed
in the README; retain those archives when preparing the submission attachment.

## Proposed correction for upstream review

The actual patch is [engine-lifetime.patch](patches/engine-lifetime.patch).
Its corresponding [tests](patches/engine-lifetime-tests.patch) enforce:

* Engine registry admission and per-view in-flight accounting: removal first
  rejects new work, then waits for admitted presentations. Presentations never
  wait for GTK, and the condition wait releases the registry mutex.
* Explicit renderer ownership and retirement: GTK parent destruction cannot
  invalidate an admitted presentation. Pending redraw sources are canceled;
  draw callbacks retain their compositor and task runner across reentrant work.
* Compositor retirement on the render thread: GL resources are released with
  the proper current context, which is then restored. A failed render-task post
  first shuts down/joins the engine before GTK can clean resources.
* Strong ownership through post-unlock task-runner signaling. Mutexes survive
  until finalization; repeated/partial retirement is safe and wakes waiters.
* Completed presentation references return to GTK, bounded to one per view;
  the final GTK unref does not occur on the raster thread. Engine shutdown
  cancels the borrowed-pointer release source and drains after raster shutdown.

The deterministic cases are `PresentationLastReferenceReturnsToGtk`,
`CompletedPresentationReferencesAreBoundedAndDrained`,
`CompositorRetirementRunsOnRenderThreadAndRejectsNewFrames`, and
`FailedRetirementPostJoinsEngineBeforeResourceRelease`. The first fails its finalization/thread assertions on the unchanged
source-built control using the preserved reference-test adaptation; all four
pass C6. The latter cases exercise new retirement APIs and are not claimed
to be executable unchanged on the old implementation. The separate renderer translation-unit barrier test
also fails unchanged cleanup during an admitted presentation and passes C6.
See original per-test logs for exact control adaptation and assertion output.

Historical equal-source A/B/C comparisons reproduced failures with the official
and unchanged source-built engines, while C6 passed the preserved cohorts.
This supports review of the correction, not distribution of a private engine.

## Application-level mitigation assessment

No supported public shutdown operation has been shown to fence this internal
renderer lifetime safely. A withdrawn application retention proposal passed
ordinary closes but failed dirty-cancel controls and had a later EGL crash;
its causality remains distinct. It is not reinstated. Delays, leaked objects,
software rendering, altered security and forced process exits are unacceptable.

Keep release blocked until an official engine passes native acceptance, or a
supported, independently validated application mitigation exists. Widget tests
execute `flutter_tester`, not this GTK embedder, and cannot close this blocker.
