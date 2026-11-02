# Native Git commit metadata remediation — 2026-11-02

This records the focused correction and its actual source, test and native
results. It is not overall release qualification. Independent Commit/Git Log
sidebars, the full history selector, ordinary comparison tabs, documents and
Local History remain intact.

## Root causes and corrected behavior

- Ordinary metadata incorrectly requested `expanded: true`. BusyMark correctly
  mapped that request to its large workflow surface, producing a nearly
  full-window dialog for a short record. `GitCommitDetails` now uses the existing
  compact presenter: the painted surface is bounded by `dialogWide` (560 logical
  pixels) and follows short content height. The native short/root record is
  approximately 494 pixels high; the populated two-parent merge is about 641.
  Long content scrolls through the host surface only. History and three-way
  editors retain their large surfaces.
- The inspector duplicated Copy and Details as permanent icons. It now retains
  the abbreviated identity and one Commit Actions control. That menu contains
  exactly one **Copy commit hash** action, copying the full immutable ID, and
  **View commit details…**. Every pre-existing historical operation remains.
  The previous complete-message Copy Text operation survives once contextually
  as **Copy commit message**, separate from native selected-text Copy. The
  details content has no permanent copy/action button.
- A raw sequence of metadata strings is replaced with labelled, selectable
  message, author, committer, commit hash, parents and references. The exact
  original message, Unicode names, full emails, all actual parents and refs
  remain available. Human-readable full localized dates distinguish author and
  committer; exact timestamps remain in accessible tooltips. A root commit does
  not acquire a fabricated parent. Shallow-boundary information remains.
- Historical rows explicitly request the existing horizontal More Actions glyph,
  without changing unrelated menu defaults. Flat native row actions have
  separate targets; menu activation does not open a tab. Ordinary file activation
  still creates its independent, correctly bound side-by-side comparison.
- The Git branch mapping used Material `Icons.fork_right`. It now uses official
  `YaruIcons.share`, the existing upstream three-node graph glyph. Every icon
  exposed by the BusyMark Git adapter resolves to the Yaru font/package.
  Unrelated document-editor artwork was not changed.

The full rendering-chain mapping is maintained in shared
`docs/native-presentation.md`, and the permanent rules are in both relevant
AGENTS files. The audit inspected Git → shared contract → BusyMark adapter →
underlying Yaru-themed control. Existing `BusyMarkHeaderIconButton`/IconButton,
`BusyMarkPushButton.flat`/TextButton and dialog foundations are accepted only
with their established native theme, shape, geometry and interaction. No broad
wrapper exemption or feature-local Material fallback was introduced.

The resolved-symbol audit now follows constant icon values through imported
catalog aliases and rejects Material artwork. It rejects expanded or dynamic
presentation of typed commit metadata. Positive/negative self-tests cover
aliased icons, typedef metadata, legitimate native constants and compact calls.
Actual host tests measure the painted dialog surface, natural height, complete
long-field reachability, control counts independent of keys, native copying,
all contextual operations, native glyphs, separate hit regions and all five
button interaction states. Existing native audit CI/local entry points already
run these suites; no scanner or assertion was weakened.

## Sources and dependency records

| Repository | Runtime/test source |
| --- | --- |
| BusyMark, feature/git-package | `0b92f501330478e44ffb22db31779c45f10efdf3` |
| Shared Git UI, main | `eefe2b1c54f7c92f5de00f4df4effa8e435357c3` |
| Shared engine, unchanged | `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b` |
| BusyFiles, Release/v0.0.1 | `1d414dc44495428bbe21eb664db924d433042821` |

BusyMark implementation/test commits: `af6b226`, `2d8e1e6`, `e769a39`, `0b92f50`.
Shared implementation commits: `06ea7f8`, `eefe2b1`. BusyFiles adapter/pin commits:
`ec9929a`, `1d414dc`. A later evidence-only commit does not change artifact source.
No reset, history rewrite, push or publication occurred.

Principal shared files: `lib/src/commit_details.dart`, `log_view.dart`,
`historical_change_tree.dart`, `host.dart`, `messages.dart`, localization registry,
native fixture/audit/self-tests and maintained guidance. Principal BusyMark files:
`lib/src/app/busymark_design.dart`, `busymark_glyphs.dart`, the existing catalogs
and generated adapters, `test/src/git/log_comparison_native_test.dart`,
`shared_git_localization_test.dart`, `test/src/app_smoke_test.dart`, AGENTS and
source records. BusyFiles changes are its date formatter, native presenter tests,
English generated labels and matching source records. Its navigation, descendant
Git behavior and authenticated typed daemon boundary are unchanged.

Both consumers pin UI `eefe2b1`; archive SHA256
`f9290243c30539129bf000b82b0b723dde24e5d9cf3f8db3d6d7af52410f9b66`,
tree SHA256 `c9873bd7ad2dc67abe4a41ff1e7aa962742d21c9e2b8f919b238f72e7d333b60`.
The engine and BusyFiles DAV `18f636f` pins remain unchanged. The unrelated
host `busystack_dav` checkout/IDE change was preserved; validation uses the actual
approved materialized source instead of moving its pin.

The affected Commit Details, hash/message-copy and field labels were reviewed
across all 23 BusyMark catalogs. Semantic regressions specifically protect
English, German, Japanese, Arabic, French, Portuguese/pt_BR, Russian and Ukrainian
Git terminology and generated getters. This is a targeted correction, not a
general rewrite of older unrelated Git translations. BusyFiles keeps English
and its existing localization scope. Exact committed localization CI commands,
generation and generated-source consistency remain strict.

## Verification

Final results are recorded in `runtime/test-results.json` and
`runtime/commands.jsonl`; the full transcripts retain failed attempts as well as
final passes.
| Final affected check | Result |
| --- | --- |
| Shared presentation | 399 passed |
| Shared real-repository comparison/staging/commit/conflicts | 8 passed |
| BusyMark app/workspace/settings/localization/Git | 803 passed |
| BusyFiles authenticated Git IPC/daemon | 16 passed |
| BusyFiles Git UI/native adapter | 42 passed |
| Total affected tests | **1,268 passed**, no skips |
| Native CMake/Ninja + accessibility CTest | 1/1 passed |
| Resolved native audit, self-tests and host audit | passed |
| All four production analyses + changed-source formatting | passed |
| Exact localization CI, generation and generated-clean checks | passed |
| Standalone shared + both consumers' pin/source/archive integrity | passed |
| Controlled Git and official Flutter workflow checks | passed |
| BusyMark Linux release | built, exported and ran |
| BusyMark Linux debug | built; ordinary lib/main.dart launch ran |

The native BusyMark suite has 34 cases, including eight additional natural-size
short-record cases. Existing cases now enforce the required absence of duplicate
controls instead of approving them. They also exercise long Unicode/merge data,
metadata completeness, exact copy, actual menu/action geometry and en/de/ja/ar
at scales 1/2 in LTR/RTL and both themes. BusyFiles adds two actual native compact
presenter cases, keeping all prior adapter assertions. Existing safety tests for
drafts, stale staging, parents/renames, late responses, document and Local History
activation, comparison ownership and real dismissal remain enabled.


The first full BusyMark run timed out in the unchanged three-second watcher
regression “external file moves remap the open document buffer”. That test passed
unchanged in isolation. The subsequent complete suite passed all 803 cases;
no timeout, assertion or skip was changed. Earlier source iterations and a
stopped task-owned verification invocation are preserved separately; they do not
substitute for the final-source checks.

## Native inspection and captures

The 49 accepted image hashes, source and per-image locale/theme/window metadata are in
`runtime/native-captures.json`. They are actual final applications on the
established Ubuntu 24.04 QA VM, official Flutter 3.47.5 / Dart 3.13.4,
X11/Xvfb + Openbox, 1440×1000, 96 dpi, DPR 1, text scale 1, Yaru-blue/native dark,
process locale en_US.UTF-8. Normal windows are 1280×720 and narrow 900×740.

- [Merge inspector](captures/merge-inspector-en.png),
  [one Commit Actions control/menu](captures/commit-actions-en.png),
  [complete merge details](captures/merge-details-en.png),
  [short natural-height details](captures/short-details-en.png),
  [narrow short details](captures/short-details-narrow-en.png).
- [Long details](captures/long-details-top-en.png),
  [all lower metadata](captures/long-details-bottom-en.png),
  [native selected-text Copy menu](captures/native-text-copy-menu-en.png),
  [full history selector](captures/history-selector-en.png).
- [Pressed horizontal row action](captures/file-actions-pressed-en.png),
  [file menu alone](captures/historical-file-menu-en.png),
  [secondary-click menu](captures/historical-file-secondary-en.png),
  [ordinary independent comparison](captures/historical-comparison-en.png).
- [German menu](captures/verified-commit-actions-de.png),
  [German details](captures/verified-long-details-de.png),
  [Japanese details](captures/long-details-ja.png),
  [Arabic RTL details](captures/details-bottom-ar.png),
  [native dark Arabic menu](captures/native-dark-commit-actions-ar.png),
  [French](captures/details-bottom-fr.png),
  [Portuguese](captures/details-bottom-pt.png),
  [Russian](captures/details-bottom-ru.png),
  [Ukrainian](captures/details-bottom-uk.png).
- [Exclusive trust screen](captures/untrusted-en.png),
  [accurate existing confirmation](captures/trust-dialog-en.png),
  [native Git branch artwork](captures/commit-native-branch-en.png).

GTK clipboard values were compared with the immutable full Git hash and original
`git cat-file` message bytes. Both contextual complete-message copy and native
Ctrl+A/C preserve line breaks and the terminal newline. The merge message is
148 characters and the long message 1,066. `native-copy-verification.json` retains
those results. The frozen fixture, HEAD/config/refs/index and all 23 recorded
file entries remain byte-identical; no native inspection staged or committed
anything. Trust authorization affected only the task-owned profile.

Early startup/coordinate probes reached Home, a still-open history modal
or an unopened menu. They are not evidence of successful activation; retained
probe images and traces are investigation. Localized final menus/details were captured after checking readiness.
The first dark-menu probes forced the light GTK theme; final dark captures use
the supported per-process Yaru-blue-dark environment and the matching app theme.
The two earlier mixed-theme menu images are excluded in the curated manifest.
No system theme or unrelated application setting was changed.

## Artifacts and independent limitations

Local release archive:
`/home/albert/busystack/.native-git-verification/commit-details-remediation/busymark-0b92f50-linux-release.tar.gz`.
SHA256 `9575aa8f6a4eec195e55f5f5f2383c54b4c17d6bff0315fbf1d271bdc91d9041`.
`runtime/release-runtime-receipt.json` binds its files to source, pins and the
clean official SDK. The mapped official release engine is
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`.
The ordinary `flutter run -d linux --debug --no-pub` launch built and ran
`lib/main.dart`, using the official debug engine
`7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`.
`runtime/debug-runtime-receipt.json` and final debug loading/details captures bind that launch
to the same final source. The installed official vm_service API was used only
for read-only scale diagnostics: actual text scale and DPR were both 1.0,
confirming the private 1.5 request was not applied. Native activation and copy
used real X11 input; no widget state or application content was injected.

Native enlarged/fractional desktop text remains unqualified. A supported GIO
keyfile backend was configured only inside the task profile, including a
private D-Bus-session probe; the portal-backed application did not enlarge.
Those images are retained as investigation and are explicitly excluded from
scale acceptance. No portal, runtime, security or accessibility behavior was
patched or disabled. Rendered actual-host routes test scales 1 and 2 separately.

Existing Flutter body AT-SPI exposure and intermittent native shutdown/mutex
failures remain: native logs retain `FlutterEngineRemoveView`/`g_mutex_clear`
failures on several release closes. They do not explain or excuse ordinary UI
layout, which was inspected separately. Wayland, Windows, strict-Snap
credentials, network/signing and dedicated performance qualification remain
independent. No new BusyFiles production package is claimed; its previously
recorded Ubuntu 26.04 producer-baseline gate is separate from these passing
adapter checks on Ubuntu 24.04.

The earlier disk/VM incident remains separately recorded in the existing
verification organization. This run had no disk failure, used sequential builds,
and preserved unrelated workloads. Task applications exited before the task-owned recorder stopped. Failure journals
were saved before resetting only this task's failed check unit. The guest then
reported zero failed units, a clean SDK, unchanged input sources, empty dpkg audit,
and unchanged default desktop text scale/accessibility settings. About 16 GiB
remained free in the guest and 35 GiB on the host. The QA VM was gracefully restored to its original STOPPED state; BusyData and
BusyNode stayed RUNNING, and BusyMax stayed STOPPED. No VM configuration changed.

`evidence-archive.json` records the checksum of the local raw evidence archive.
Investigation captures and complete interaction traces remain there. Committed
`.log.json` transcripts retain the original decoded bytes and SHA256, including
carriage returns, rather than normalizing terminal output.
