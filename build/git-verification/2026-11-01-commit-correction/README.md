# BusyMark Commit / Branches correction — 2026-11-01

This records the bounded Commit correction. It is not overall release acceptance.
The existing independent Commit/Git Log sidebars and ordinary comparison tabs
are retained.

## Runtime and pinned sources

| Owned source | Artifact/source revision |
| --- | --- |
| BusyMark, feature/git-package | `b396f876aaa1d113d04bdb27f2481c7ff8c8f406` |
| Shared presentation | `8be750c7a76f98d547c7835653162af6935137e4` |
| Shared engine | `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b` |
| BusyFiles, Release/v0.0.1 | `fc462114014efb478bde0c2cc1eaf3848b108eee` |

The host tests ran at BusyMark `3c566f078c384bc0f8eb55ddad6a490c1a5eda46`.
The final tooling commit changes only the standalone audit's lint resolution
and formatting. `production-source-equivalence` verifies no runtime differences
in `lib`, `linux`, or the application pubspec/lock. Release/debug artifacts use
`b396f87`; later evidence commits are separate and do not move consumer pins.

Both consumers and the shared package materialize the exact source archives.
Engine archive SHA256: `e3069f64edd7e5dfad7919c7338119f1246f1595c3bc962bfa0e393a4e479453`.
Presentation archive SHA256: `82b450a7f3d3a2c1e65cbd56c1bd7acdb3fda92276a0a7f9b4af86c452ddda14`.
BusyFiles' DAV pin remains `18f636f3227e3df8c1406bafd85b45e7f12cf8bd`.
The unrelated host DAV checkout/work is preserved.

The engine change is one read-only status bit, `trackingCountsKnown`: absent
porcelain `branch.ab` is distinguished from measured zero. Existing discovery,
Git invocations, transaction/index semantics and operation preconditions are
unchanged. Old serialized snapshots honestly report counts as unknown.

## Implemented and exercised behavior

- BusyMark canonical workspace identity must equal the discovered working-tree
  root at session and command boundaries. Descendants get a distinct explanation,
  without nested-init offers. Linked worktrees, submodules and equivalent safe
  path spellings remain eligible. Normal file navigation does not change owner.
- Untrusted Commit displays only the native explanation/Trust action. Loading
  precedes attachment. Explicit authorization reveals the retained form;
  revocation excludes it from focus/commands while preserving drafts. Delayed
  discovery/trust responses cannot attach or authorize a different workspace.
- Trusted Commit has branch/path tooltip, flat Refresh/Repository actions,
  token spacing, and compact locally known tracking values. No Log shortcut,
  permanent path/scope/hooks commentary, or deleted-line height reservation.
- Native file/group/folder rows share BusyMark's existing Files tree treatment.
  Git icon actions use the existing Writerside header's flat native control,
  including its rectangular focus shape. Disabled actions consume row taps.
- Commit and Commit and Push… occupy one measured Row with the spacing-token
  gap. Captions omit staged counts. The existing Commit-only sidebar allocation
  grows for full localized labels; other sidebar widths/breakpoints stay intact.
- No staging, commit, draft, editing, comparison, branch or workflow destination
  was removed. Reviewed index scope, message-only amend and Commit-and-Push
  completion/version guards remain covered by the retained behavioral suites.
- BusyFiles supplies the required native row adapter and preserves path tooltips,
  its workspace/history/trust placement, authenticated daemon IPC and descendant
  repository navigation. No BusyMark policy is imported into it.

The maintained mapping/rule is in `AGENTS.md` and the shared package's
`docs/native-presentation.md`. Resolved-symbol enforcement now also rejects
compact circular Git controls and aliases in the actual host adapter. Host
regressions inspect native shape/hit geometry, hover/pressed/focus/disabled
states, keyboard activation, disabled-action/disclosure isolation and tree
metrics. Wrapper names/golden changes do not grant approval.

## Checks

| Check | Result |
| --- | --- |
| Engine tests including actual missing-upstream/equal/ahead/detached repositories | 142 passed |
| Shared presentation tests | 388 passed |
| Shared real-repository comparison/commit/conflict suites | 8 passed |
| BusyMark affected app/workspace/settings/localization/Git suites | 762 passed |
| BusyFiles authenticated Git IPC/daemon suites | 16 passed |
| BusyFiles Git UI/native adapter suites | 36 passed |
| Shared native C++ configure/build/CTest | passed |
| Production analysis, final formatting, resolved native audits/self-tests | passed |
| Both strict localization generation/CI checks and generated-clean checks | passed |
| Shared standalone and consumer source/pin integrity gates | passed |
| Actual adapter en/de/ja/ar × text scale 1/1.5/2 action-row geometry | 12 cases passed |
| BusyMark final Linux release and ordinary main.dart developer debug startup | passed |

Commands, return codes, machine test counts, source receipts and lossless raw
transcripts are retained with this evidence. Earlier failures are retained:
initial Mark assertions expected the superseded toolbar Log or did not await
canonical attachment; final tests preserve behavior and use explicit readiness.
The initial globally widened sidebar was corrected to Commit-only allocation.
A missing helper environment in an early real-repository run was corrected;
the complete actual pinned suites above subsequently passed.

## Native evidence and limits

Final BusyMark captures come from the actual `b396f87` release/debug applications,
not widget stand-ins. Environment: established Ubuntu 24.04 verification VM,
X11/Xvfb + Openbox, 1440×1000 at 96 dpi, DPR 1, default desktop text scaling,
`en_US.UTF-8`, native Yaru-blue accent, app locales en/de/ja/ar, light/dark.
No security, accessibility, GPU or dependency settings were changed.

Native input exercised exclusive trust, Cancel then explicit Trust, persisted
trust/message draft after restart, populated partial staging, independent
staged/unstaged/historical tabs alongside an unsaved document, Local History
reactivation by mouse and Ctrl+Tab, history modal cancellation, Branches/context
menus, flat hover/held-press/keyboard focus, keyboard menu activation, document
close Cancel/Discard, and independently opened descendant rejection.
All fixture working-file bytes, HEAD, index, config and refs remain identical
before/after (40 tracked receipt entries). No capture operation staged/committed.

The official release engine SHA256 is
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`;
the mapped ordinary debug engine is
`7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`.
SDK tracked sources are clean; Flutter 3.47.5 / Dart 3.13.4 pins are unchanged.

Independent limitations: AT-SPI exposed the application/frame but not the
Flutter body tree (the existing accessibility setting was left unchanged).
Fractional Wayland and enlarged desktop text were unavailable in this Xvfb
session; actual adapter geometry at 1.5/2 text scale passed separately. Windows,
remote credentials/network acceptance and dedicated performance remain unrun.
A descendant-window close reproduced the previously observed
`FlutterEngineRemoveView` / `g_mutex_clear()` SIGABRT; other root release runs
and ordinary debug exited 0. This prevents claiming universal native-close
acceptance. No upstream component was patched or substituted.

The prior disk/VM disruption remains separately documented in
`../2026-11-01-followup/incident`. This run preflighted host/guest capacity,
expanded the existing QA disk through supported LXD configuration, and ran
storage-heavy builds sequentially. Protected VM workloads were untouched.

## Capture index and artifacts

- [Exclusive untrusted Commit](captures/untrusted-en-light.png),
  [native trust confirmation](captures/trust-confirmation.png),
  [Cancel leaves it untrusted](captures/trust-cancelled.png).
- [Trusted partial change and comparison tab beside an unsaved document](captures/trusted-staged-comparison.png),
  [disabled bottom actions before a message](captures/trusted-en-light.png).
- [Branches](captures/branches-en-light.png),
  [all applicable branch context actions](captures/branches-context-menu.png).
- [Flat held press](captures/header-refresh-pressed-final.png),
  [keyboard focus](captures/flat-options-keyboard-focus.png),
  [Enter activates its native menu](captures/keyboard-activated-options-menu.png),
  [existing non-Git Files tree reference](captures/approved-files-tree-reference.png).
- [German after restart, retained trust/draft](captures/commit-de-light-restart.png),
  [Japanese dark](captures/commit-ja-dark.png),
  [Japanese dark Branches](captures/branches-ja-dark.png),
  [Arabic RTL](captures/commit-ar-light-rtl.png),
  [Arabic Branches](captures/branches-ar-rtl.png).
- [Descendant workspace rejected](captures/descendant-workspace-root-required.png),
  [ordinary developer debug startup](captures/ordinary-debug-commit.png).
- [Git Log order](captures/git-log-inspector.png),
  [history selection modal](captures/history-selection-modal.png),
  [independent comparisons after content loaded](captures/commit-option-keyboard-focus.png),
  [Local History mouse](captures/local-history-mouse-reactivation.png),
  [Local History keyboard](captures/local-history-keyboard-reactivation.png).
- BusyFiles [descendant browser](captures/files-correction-browser-descendant.png),
  [existing Git layout and comparison](captures/files-correction-commit-descendant.png),
  [Branches](captures/files-correction-branches.png).

The BusyMark release artifact is retained locally at
`/home/albert/busystack/.native-git-verification/busymark-b396f87-linux-release.tar.gz`,
SHA256 `513b4dabc79913b8d24d714d96bb1fb1cbd74e527db6d047afa579d40502705f`.
`runtime/release-runtime-receipt.json` binds its complete bundle hashes to the
source/pins/official SDK. `runtime/debug-runtime-receipt.json` binds the ordinary
main.dart launch and mapped official debug engine.

BusyFiles' normal production pipeline was rerun on the Ubuntu 26.04.1 host with
the exact final source archives, correct unchanged DAV pin and official SDK.
Release UI, daemon/native compilation, source/engine/payload verification and
DEB validation passed. The later dependency-inventory invocation failed (69):
`dart pub deps --json` could not resolve pub.dev's package-advisory endpoint.
The normal script then removed its temporary layout/DEB. No production DEB is
claimed or delivered for this revision. Both full command transcripts and
return codes are in `host-production`; an initial offline-cache path error is
also retained. No network/security/integrity check was disabled or replaced.

The native BusyFiles captures use the actual final `fc46211` developer sources
compiled on Ubuntu 24.04 with the same byte-verified official release engine.
The separate final-source daemon and native GIO library served authenticated
typed IPC over its private runtime socket. The UI/daemon both exited 0.
`runtime/files-native-runtime.json` records the executable/library hashes. This
is source-level/native behavior verification, not production-package acceptance.
The Ubuntu 24.04 production/wrapper gate rejections remain recorded independently.

All raw transcripts are retained locally in the evidence archive; `.log.json`
files preserve their exact text and SHA256 without whitespace reinterpretation.
`evidence-archive.json` and `runtime/native-captures.json` identify the captured
files and environment. Only inspected, relevant images are included; native
input logs retain exploratory navigation. No screenshots were generated/edited.

`capture-inspection.json` records a later populated comparison capture matched
to its original native input event and hash. The early inspector-order frame
has a pending file read; the early multiple-tab frame precedes diff painting.
The later populated frame is the comparison-content evidence.
