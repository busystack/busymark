# Shared Git UI acceptance

The 2026-11-06 decision requires one Git interface in BusyMark and BusyFiles.
The maintained [shared ownership and action map](../../busystack_git_flutter/docs/one-git-ui.md)
and [native contract](../../busystack_git_flutter/docs/native-presentation.md)
define that implementation. Their intermediate verification observations retain
historical evidence; current acceptance is bound to the source and artifacts in
[the local evidence directory](../build/git-unification-20261106/).

`GitFeatureController`, `GitFeatureSidebar`, `GitReviewTabs`, `GitReviewSurface`
and `YaruGitPresentation` own Git state, composition, comparisons and controls.
Hosts own their shell slots, document/browser lifetimes, localization, native
services and execution adapters. BusyFiles keeps authenticated daemon IPC and
containing-worktree discovery. BusyMark keeps root-only authoring attachment and
its actual document/Local History tab strip. Neither host owns a second Git
Commit/Log/Branches/comparison widget tree. Git notifications use the shared
native presenter, including its queue and window lifetime.

The retired workspace switcher, split staging interface and compact single
preview are recorded in the shared action map with their canonical destinations.
No legacy route or Material fallback may be restored. Git row actions are
contextual; ordinary file comparisons are independent content tabs.

## Evidence rules

The artifact directory contains `current-work-state.json` while work is active,
full test coverage manifests, source/payload receipts, producer manifests and
actual native screenshots. An incomplete progress record is never acceptance.
The final report must identify each actual source revision, archive/tree hash,
compiled production hash and installed payload. Source-only and relocated-package
runs cannot stand in for installed acceptance.

`tools/git_native_snap_receipt.py` checks every sealed Flutter-bundle file in
the development Snap root, compares the complete root with the actual packed
SquashFS, and then requires the installed Snap mount to match that filesystem.
Symlinks are bound by their targets without following external package paths.
This qualifies a local development repack, not a clean Snapcraft release.

The native harness reads status, refs, raw index and Git-visible file bytes
before startup and after exit. It captures real X11 pixels, verifies the mapped
official engine, keeps accessibility enabled and restricts AT-SPI inspection to
the owned application PID. Native theme/scale, dialog/row geometry, independent
review contexts, staging results and host restoration need observable evidence.
Every accepted image must be inspected; generated images are not evidence.

Installed BusyMark tests use the documented confined `snap run --shell` path
and normal command-chain, with private application configuration and a private
standard session bus. Snapd's launcher retains its real desktop scope setup.
The harness verifies the actual executable, enforced confinement and application
profile. It does not use developer mode, alter policy or expose personal SSH
agents. These controls do not establish signing/network/credential acceptance.
See the official [Snap debugging](https://snapcraft.io/docs/how-to-guides/snap-development/debug-snaps/)
and [environment documentation](https://snapcraft.io/docs/reference/development/environment-variables/).

## Complete test corpus and packaging

Every discovered Flutter test file runs, including the native GTK conditional
case on an owned Xvfb. Bounded full-file invocations prevent compiler-retention
pressure from requiring exclusions. The coverage manifest records all inputs,
commands, results and log hashes. Production and imported test-fixture changes
invalidate qualification.

The local Snap helper can consume that completed corpus with
`--test-corpus-receipt FILE`. It still runs analysis and independently verifies
all current test/production inputs, every complete command, zero failed/skipped
cases and unaltered output. It rejects filters, missing/duplicated files and
changed fixtures/logs. This is verified completed work, not skipped verification;
it cannot be combined with `--skip-tests`. New packaging-tool changes also need
their own adversarial and affected source-audit tests.

## Independent platform observations

The pinned official Flutter Wayland multi-engine lifecycle failure remains a
separate gate. The current standalone counter probe reproduces implicit-view
removal/EGL failures after closing the first native window and ends with
SIGSEGV. It contains no BusyFiles runner, plugins or Git UI. Preserve the failed
full-verifier result, run unaffected tail checks separately and consult the
[existing upstream investigation](../../busyfiles/engine/UPSTREAM.md).
Never patch the engine, retain closed engines indefinitely or weaken the gate.
X11 results do not prove Wayland, Windows or strict-Snap credential acceptance.

The user identified a small black rectangle after selecting `Add .idea directory`
(`136293701b4f9d531214c716492a66701a237f43`) in `dev-notes`. Inspect selection,
commit-row hover and reference-label tooltips in the disposable reproduction
copy. Do not assume its cause. Per the user's clarification, an unreproduced
observation is documented as unverified and does not block the project. The
separately reproduced tooltip pointer obstruction has its own regression and
must not be presented as the rectangle's established cause.

No application push, publication, release or upstream modification is authorized
by local verification or artifact production.

The ordinary workspace header accepts workspace/document identity and typed
application sidebar navigation. It has no repository model, Git view state,
branch loader or workflow callback. Its source ownership regression rejects
those dependencies even in unreachable code; Commit, Log and Branches remain
shared feature content. Files contextual Git actions and VCS decorations retain
their existing host adapters.

The resolved workspace audit requires both live shared sidebar/review mounts
and rejects the retired host Git menu orchestration. Its adversarial checks
include aliased shared imports, missing mounts and a revived host menu. Audit
updates must follow the current ownership boundary rather than demand deleted
host rendering functions.

Native SDK flavor verification follows the pinned public FlDartProject AOT
library contract (`lib/libapp.so`), then the JIT kernel when no AOT library is
present. A kernel asset alone cannot identify an AOT bundle as debug. Missing
application artifacts fail closed. This classification never replaces the
mapped-library hash check against the exact official SDK artifact or the
sealed whole-payload verification.

Closing the last authoring document must leave an existing comparison visible
when it is the only remaining content. The host tab coordinator activates a
captured surviving review only when all remaining tabs are inactive comparisons
and their identities still match the close request. Cancel preserves the dirty
document; a newly selected comparison during confirmation stays selected.
