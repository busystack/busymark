# Nextcloud Notes Milestone 3

Baseline: `feature/nextcloud-notes-workspace`, HEAD
`9002549b024f0cbd072115e4198d74a216c16093`, clean working tree. No applicable ancestor
or repository `AGENTS.md`. Accepted Milestone 1 and 2 records read; existing schema
**6**, pins and synchronization invariants retained.

Toolchain: Flutter **3.47.5** (`6a19cca564`), Dart **3.13.4**, Docker **29.8.2**, Node
**24.15.0**, Python **3.13.5**. Flutter needs managed SDK-cache write access. Snapcraft
is initially absent. README clean Snap procedure, confinement contract and the Linux
workflow Snap job read. No scaffold repack is acceptance evidence.

Required upstream copies fetched once with HTTPS verification into
`/tmp/busymark-m3/upstream` outside Git: CommonMark 0.31.2, Writerside links/reuse,
Notes 6.1.0 API/controller/helper, and Notes 6.0.2/6.1.0 browser router/routes. Private
fixture materials and raw reports remain outside Git.

## Implementation and verification

Initial implementation commits: `55c62dd`, `e9f5ab3` and `138c92b`; acceptance was
recorded in `4c3306e`. Post-review corrections below supersede that completion claim.
Historical release results and artifact identity in this record apply to `138c92b`;
they must not be reused as acceptance of the corrected production payload.

| Work package | Delivered behavior |
| --- | --- |
| References | Shared revision/identity/occurrence/target model, supported-parser Markdown extraction and existing Writerside index/resolver adapter. Reference occurrences retain their definition destination spans; code, escapes and losing definitions are excluded. Actual parsed heading/element IDs, module origins and instance availability are retained. Incoming/outgoing queries and chooser results have explicit continuation. |
| Index lifecycle | Unopened files, dirty overlays and connected cached notes; debounced generation-fenced workers, batches of 16 documents, digest reuse, completed-batch reuse across superseding edits and cached incoming/outgoing lookup. Known deleted server IDs remain missing; uncached IDs are unavailable. Workspace/file/repository changes invalidate derived data. Unsafe/unreadable sources are unavailable, not inferred missing. No source/history/sync writes during indexing. |
| Production UI | Optional References sidebar and command, document/heading/fragment selection, visible scope/status/context, exact source and target actions, stale revision refresh, existing view/navigation reuse. Source and Editor target chooser preserves manual URLs, selection, permissions, cancellation and XML namespace behavior. Localized strings regenerated. |
| Local maintenance | Ordinary Rename and Cut/Paste prepare immutable reviewed file/folder mappings, incoming/outgoing Markdown and relative media destination edits, including hidden sources and folder descendants. Dirty-file review, identity/revision/inventory/path/symlink/collision revalidation, atomic files, staged history/path remapping and durable interrupted-operation journals. Recovery refuses to overwrite newer external content. Writerside retains its existing structured Preview/Refactor workflow. |
| Portable Notes links | Real server IDs in ordinary installation-scoped HTTPS web URLs. Anonymous bounded public routing observation selects the installation's configured pretty/front-controller form; cached observation permits offline authoring. Exact account/installation matching precedes attachment/external handling; cached offline opening and authenticated repository refresh. Unsynchronized targets and browser-incompatible headings remain explicitly unavailable in the chooser. |
| Retrieval | Distinct complete 200/304 results, validators only with matching cached server bases; 304 never acknowledges edits or clears conflict/checkpoint state. Category/exclude projections preserve omitted fields and pagination parameters, with isolated query scopes and no authoritative collection deletion inference. |

The native local journey exposed a real FileLocalHistoryStore queue deadlock: history
protection now occurs before its staged remap queue. The controller regression uses the
real file store. Writerside URI components preserve raw Unicode and unresolved variables
while decoding valid percent destinations; accepted rename/removal regressions remain
intact. Schema **6** is unchanged: the optional routing observation uses the existing
account JSON, round-trips older records and preserves checkpoints. No database reset or
migration is needed.

## Automated verification

| Gate | Result |
| --- | --- |
| Locked dependency resolution / localization generation | PASS, `flutter pub get --enforce-lockfile`, `flutter gen-l10n`; pins unchanged |
| Analysis | PASS, `flutter analyze --no-pub`, no issues |
| Formatting / localization audit | PASS: 584 Dart files, 0 changes; localization audit included in exhaustive manifest |
| Credential/security scripts | PASS: credential policy and isolated libsecret scripts, both exit 0 |
| Official Writerside conformance | PASS: pinned **2026.08.0328**, original **181** checks and extended fixture **181** checks; authored links/reference definitions/explicit IDs/includes/code assertions passed. Original compatibility baseline unchanged |
| Exhaustive Local History group | PASS: **50**, exit **0**, `test/src/local_history_store_test.dart`, 1m19s |
| Exhaustive remaining group | PASS: **4,241**, **0 failures, 0 skips**, exit **0**; all **207** other current test files exactly once, concurrency 1, 23m23s |
| Linux release / installed clean Snap | Normal `lib/main.dart` Linux release and clean Snap build PASS, exit 0; exact installed artifact **25/25** UI/artifact checks PASS under strict confinement |

The generated manifest contains **208** current test files. SHA-256:
`a920523a5249056df24e915f5f012a953fbac3f8540f4f1159adcd8d99fe8260`. These are **two
exhaustive groups**, not a clean single-invocation run. Private final logs:
`release-history.log`, `release-remaining.log` and exit files under `/tmp/busymark-m3`.
Earlier exhaustive attempts are retained: first **4,228 passed / 1 failed / 1 skipped**
(a test edited while its compiled suite was running; missing native GTK display); second
**4,232 passed / 2 failed / 0 skipped** (raw Unicode/unresolved-variable decoding). Both
issues were corrected before the final clean groups. The prior `e9f5ab3` run also passed
4,236 remaining tests; the final source adds five deterministic cases. Local History
passed all 50 in every attempt.

New regressions cover actual/reference-style repeated links, duplicate/explicit heading
IDs, Unicode/percent paths, code exclusions, include origin/ambiguity and instance
changes, dirty overlays, external changes/deletion/recovery, stale navigation and
continuation. Move tests cover incoming/outgoing definitions and media, file/folder
moves, preserved bytes/formatting, review races, collisions, write failures and restart
recovery. Retrieval tests cover omitted IDs/fields, conditional cache availability and
races, account removal and checkpoint isolation. Existing accepted Milestone 1/2 suites
remain in the exhaustive manifest.

## Live and production desktop acceptance

Owned disposable HTTPS fixtures: Nextcloud **35.0.1**, Notes **6.0.2** / **6.1.0**, both
**API 1.4**. Separate private profiles/stores, dedicated Login Flow app passwords and
CA-signed localhost certificates; hostname/certificate verification retained. Ports
18448/18447, owned Docker labels `busymark.acceptance=m3`. Real browser Login Flow and
stored-link navigation pass on both root baselines: the authored link's real **Open
link** action opens the intended ID and unique body marker, not merely a successful HTTP
page. Actual browser-copied URL internal navigation after restart is verified on both
baselines, including `/cloud`.

| Journey | Verified result |
| --- | --- |
| Full live API journey | **41** checks per baseline (including version entries), all passed; conditional 200/304, scoped projections, pending/checkpoint preservation and stored portable URL, plus accepted everyday and uncertainty/conflict/recovery/import/media checks. Omitted-ID category pagination and reduced single-note retrieval passed |
| Local Markdown native UI | **2** checks plus **1** real-process restart check passed, including hidden-source updates through the real History transaction: Source heading chooser, References, ordinary reviewed Rename and Cut/Paste Move, incoming/outgoing media paths; Editor/Source/Reading/Split and restarted links/media |
| Writerside native UI | **3** checks passed: XML semantic chooser, established reviewed topic rename with source preservation; main/shared module navigation, guide/beta instance controls, ambiguous destination and conditional include becoming available, navigation to its origin |
| Notes native UI, each baseline | **6** checks and **2** separate offline-process restart checks passed: Source/Editor chooser, outgoing/incoming panel, real rendered internal URL navigation, title/category identity, pasted URL and missing-target error preserving dirty source |
| Everyday Notes, each baseline | **3** offline-start checks + **13** resumed-process checks passed: Quick Open/search, batch actions, retained offline media, recovery, export/import and real synchronization in all four views |
| Subdirectory installation | `/cloud` front-controller configuration: native/browser/restart PASS; pretty configuration: final native/browser/restart PASS, intended IDs and unique body markers verified |

Screenshots inspected: References, target chooser, local exact-edit review, Writerside
guide ambiguity/unavailability and beta include resolution. Missing target and final
prefix/browser screenshots inspected; exact edits include the hidden source.
Installed-package References, chooser, exact rename/move reviews, rejected-operation,
missing-target/offline failures and restarted Reading/Split/media screenshots inspected.
Private artifacts remain in
`desktop-local-hidden`, `desktop-writerside-release`, `desktop-notes-final-6.0.2`,
`desktop-notes-verified-6.1.0`, `desktop-6.*-everyday` and `live` under
`/tmp/busymark-m3`. Acceptance tooling corrections retained: asynchronous GTK cut
completion, full refactoring publication wait, fresh collision-free fixtures, missing
Ctrl+2 XTest binding, delayed Nextcloud first-run modal, unique body marker instead of a
browser-hidden first heading, modal dismissal between performance samples, and faithful
browser-required HTTP method/HEAD forwarding in the private proxy. A transient
capability timeout and pre-correction browser/dirty-flag failures are retained
privately; final reruns passed. The dirty-source assertion now verifies exact content
and identity whether still unsaved or durably saved with pending synchronization.

Browser limits: a mismatched front-controller URL on a pretty installation can open the
most recent note; URL generation observes the installation rather than assuming HTTP 200
proves identity. Root browser views accept `#heading` in the address bar but do not
expose BusyMark's heading ID in the rendered headings. Portable heading insertion is
disabled; no cross-client heading equivalence is claimed. Recovery/import identities
never redirect old ID-based links.

## Performance

Dart **3.13.4** native AOT, SQLite **3.53.4**, Intel i9-9900K / 16 logical CPUs, 48 GiB
host RAM, Ubuntu 24.04.5 / Linux 7.0.0-38. Exhaustive tests and fixture/build
preparation were running concurrently; these are not idle-host timings. Original corpus:
**10,000** notes, **1,279** categories, **250** duplicate titles, **21,785,692** UTF-8
bytes, **2,000** attachments / **4,096,000** bytes. Added reference corpus: **10,000**
documents, **32,000** occurrences, **23,683,480** UTF-8 bytes. Built with `dart build
cli` in AOT mode; reports/binary outside Git.

| Measurement | Result |
| --- | --- |
| Reference initial index / one-document incremental index | **200,500 ms / 36.229 ms** |
| Reference query median / p95 | Below measurement timer resolution (reported 0.0 ms) |
| Search during reference indexing | **76.004 ms** |
| Save during reference indexing median / p95 | **10.941 / 19.140 ms** |
| Warm search medians / largest p95 | **47.980–52.854 / 70.295 ms** |
| Save during full search rebuild median / p95 / max | **45.126 / 156.669 / 292.230 ms** |
| Save during query / import median and p95 | **76.428 / 33.837 and 170.795 ms** |
| AOT RSS before/after reference workload / maximum overall | **219,435,008 / 177,504,256 / 219,095,040 bytes** |
| Database size | **118,718,464 bytes** |

Native release UI: private copied **10,020**-record benchmark store, never uploaded to
real fixtures; Impeller OpenGLES/software rendering on Xvfb `:98`, 100 ms timing polls.
Five Quick Open samples before indexing: **210,233,233,131,223 ms**; during initial
indexing: **526,215,211,118,221 ms** (medians **223 / 215 ms**, initial burst visible).
Save during search **146 ms**; RSS **615,677,952**, maximum **636,846,080** bytes. The
added workload preserves responsive save/search and steady Quick Open; initial indexing
remains a substantial background operation. Private evidence:
`performance-candidate/report.json` and `ui-performance-final/ui-performance.json`.

## Clean release and installed-package gate

Candidate source: **`138c92b8714b5bcbf6df6260a371461df8c0c959`**, clean Git archive.
Official Ubuntu 24.04 Snapcraft **8.11.1**: version → expand-extensions → clean →
destructive-mode build using unchanged `snap/snapcraft.yaml`, **PASS, exit 0**.
Final Snapcraft pack with official `SNAPCRAFT_BUILD_INFO=1` from those fresh parts
also **PASS, exit 0**. This embeds the original recipe and package manifest;
embedded recipe SHA-256 matches the checkout. README now makes that flag explicit.
No installed scaffold, older payload or `build_install_snap_local.sh` used.

Final artifact: `busymark_0.6.2_amd64.snap`, **310,149,120 bytes**, SHA-256:
`2150b0e2a65139eecdabfef502a5308fa0914760725fbb2235542436f9fb823a`.
Recipe SHA-256: `ba4745fc25a3b9e4485b878b3b0c1086a996a11628b38f5b8abadd69fa814af7`.
Private artifact, source, identity report and full logs remain under
`/tmp/busymark-m3` (`snap-final-source`, `snap-artifact.json`,
`snap-helper-provisioned-build.log`, `snap-manifest-build.log`).

Failed attempts retained: missing extension data/apt metadata, build-package
installation, incorrect image entrypoint, Python module search path after OS
upgrades, Ubuntu iso-codes transfer, missing Node/craftctl on the Docker PATH.
Exact Snapcraft 8.11.1 extension resources and modules are restored. Recipe-declared
SDK/runtime/build snaps use official Store payloads with hash verification;
iso-codes cache repair matches signed apt SHA-256 metadata. Standard links expose
Node **24.21.0** (24/stable revision **12007**) and the matching craftctl helper.
Pins and recipe unchanged; superseded source builds were stopped without accepting
an obsolete artifact. The first successful package lacked optional build info;
the final package adds it without replacing the clean-built application payload.

Isolated Ubuntu 24.04 VM: official cloud-image SHA-256
`6a81c37564db9b1ee84e141922625e1d7c5b389b99bb3c572e0243607d5bb4d2`;
TCG software virtualization because `/dev/kvm` is absent; private SSH/profile/keyring.
Snapd **2.77.1**, **strict** confinement with full AppArmor. Core24 **2124**, GNOME
**168**, Mesa **1839**, GTK themes **1535** installed with normal Store assertions.
Interrupted Store transfers are repaired through verified snapd cache payloads,
without weakening confinement. Fixture CA trust retains TLS/hostname verification.

The exact final snap is installed as **x2** in this VM; root-owned installed-file
SHA-256 matches above, process executable is `/snap/busymark/x2/busymark`, AppArmor
profile is `snap.busymark.busymark (enforce)`. The documented
`password-manager-service` interface is manually connected. No candidate installed
on the user's ordinary host. GUI input drives normal `lib/main.dart`, no acceptance
controller/test entrypoint. Source chooser, incoming/outgoing navigation, exact
reviewed Rename and Cut/Paste Move, preserved link/media bytes, Reading image and
real-process restart with remapped tabs and Split media **PASS**. Input automation
requires explicit focus and current row coordinates after modal/tree changes;
rejected unchanged-name operations leave files intact. Software rendering makes
first-launch/redraw initialization slower than native host runs.

Installed external HTTPS navigation **PASS** through the real desktop portal and
WebKitGTK browser with verified TLS. Initial missing browser MIME registration
was corrected by installing standard desktop MIME utilities in the VM; initial
tunnel connection refusal was corrected by restoring the private SSH forwarding.
Writerside References/element/include navigation, XML semantic chooser and the
established reviewed topic refactor **PASS**, with source definitions, includes,
TOC, explicit IDs and code exclusions verified.

Production Settings recognizes Notes **6.0.2 / API 1.4**. Keyring-backed
authenticated publication, a newly authored portable URL in server note **483**,
internal navigation to intended target **482** and its unique marker, native
file-picker media ingestion/upload and durable cache bytes **PASS**. Target title
and category changes retain server ID **482**; offline status reports **1/1**.
The copied profile's older pending edit was resolved through the real conflict
comparison; stale browser-owned locks on these two fixture files were released
using Nextcloud's supported `files:lock --unlock` command. BusyMark preserved
pending edits and displayed its scoped server-lock error before successful retry.

Installed missing-target failure **PASS**: the explicit missing note error leaves
source identity and its exact edited content intact. The retained requirement is
verified in schema 6 and managed media bytes are durable. Real offline process
restart **PASS**: fixture tunnel disconnected and unreachability verified; previous
PID **32321** exited, new PID **38387** runs the same x2 executable under enforced
confinement. Welcome → connected account Open → Quick Open cached source → stored
portable link opens target **482**, its changed metadata and unique marker; retained
image renders in Reading and Split. Offline capability/refresh errors are explicit
while cached content remains available. Installed report: **25/25 checks PASS**;
screenshots inspected, private in `snap-vm`.

Final formatting and analysis repeated after the acceptance-tool corrections:
**584 files / 0 changes**, **no issues**, exit 0. The application lockfile SHA-256
remains `6062c9287c8030d89989584d023b649c990ed5ca7bb40cb5941d6a48d1bcc9a7`.
The source candidate above is the clean release artifact's commit; the final
documentation/tooling handoff adds no production payload changes. No required
acceptance environment or workflow remains unverified. Verified limitations are
the browser heading behavior and substantial initial background indexing described
above. Only owned acceptance processes/fixtures are stopped; private artifact,
VM disk and raw evidence remain outside Git. No merge, push, publication or ordinary
host installation replacement performed. Locked resolution and localization are
repeated after committing the handoff; final Git status is reported with that commit.

## Post-review corrections — 2026-10-11

Correction baseline: branch `feature/nextcloud-notes-workspace`, HEAD
`4c3306e6161229f4319be6e147536fef646a8b9c`, clean tree, no applicable `AGENTS.md`.
Flutter **3.47.5**, Dart **3.13.4**, dependency pins and Notes schema **6** unchanged.
Required CommonMark link/code rules reread from the retained private reference copy.

* Successful PUT acknowledgments now advance a separate linked-read fence. Older
  individual responses cannot replace acknowledged content/base/ETag/revisions.
  Editor base generations remain reserved for external observations, so pending
  local edits still reconcile correctly. Held GET B → acknowledged PUT B/C →
  released GET B verifies content, base, ETag, revision/ack, synchronized state and
  SQLite restart persistence; the original implementation failed with content B.
* Refactoring journals now persist phase and complete moved-entry device/inode
  identity (birth time where available), type, content hashes and membership.
  Identities are recaptured after owned atomic writes and persisted before moving.
  Recovery checks paths and identities before restoring anything, uses a no-replace
  reverse rename, guards rollback publication and verifies identity again before
  deleting evidence. Recreated sources, replaced/identical-byte destinations,
  folder replacement/membership and publication races retain evidence. Unedited
  moved documents are covered; legacy identity-free journals require manual review.
* The supported parser determines genuine link structure; a literal mask excludes
  links starting in code/comments without rejecting code formatting within labels.
  Inline, full/collapsed/shortcut reference labels are covered through extraction,
  incoming queries and real rename/move; code examples/comments remain unchanged.
* Fragment lookup decodes once against parsed IDs, preserving authored destination
  bytes. Real chooser → index → target navigation tests cover `café` and the explicit
  ID `élément%20id`, including exact UTF-16 spans, incoming heading queries and a
  double-decoding negative case. The fixture uses the supported `{id="…"}` syntax.

Focused reference/retrieval checks and static analysis pass. Complete two-group
tests, normal Linux build, pinned conformance/security and corrected clean Snap
acceptance are being rerun; final results will be recorded here. Private correction
logs use `corrections-*` under `/tmp/busymark-m3`, preserving the original reports.
