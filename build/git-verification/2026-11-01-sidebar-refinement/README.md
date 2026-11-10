# Commit sidebar refinement — 2026-11-01

This is the bounded graphical-review correction, not overall release acceptance.
The independent Commit/Git Log sidebars, history selector, ordinary comparison
tabs and Local History remain intact. Dates use Vancouver time; the native run
crossed into November 2 UTC.

## Sources and implementation

| Repository | Final runtime revision |
| --- | --- |
| BusyMark, feature/git-package | `bad4554005bec134b52e2b83b7721ee776767876` |
| Shared Git UI | `5745a3951cf01c07aa9ceb5bceb7d0332ba54cef` |
| Shared engine, unchanged | `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b` |
| BusyFiles, narrow adapter/pin update | `827a44b4bc8713f01b95dc89121fd7afd2a2bf45` |

BusyMark source commits are `5bce11b` (integration/native controls/localization),
`fa95f9c` (enlarged RTL tree regression), and `bad4554` (scaled status-marker
extent). A later evidence-only commit does not change these runtime revisions.

- The exclusive trust screen has one concise localized statement. Its native
  confirmation identifies the repository and distinguishes limited passive
  metadata inspection from operations that can execute hooks, filters,
  credential helpers and signing tools. Trust remains explicit and identity
  scoped. The Trust action is keyboard reachable; the old outer focus exclusion
  incorrectly included that action, and now excludes only inactive views.
- The current-branch button uses BusyMark's existing neutral flat action style
  and branch glyph. It still opens the complete Branches modal. Its localized
  tooltip is Manage branches. Workspace identity owns the full-path tooltip.
- BusyMark's Repository Actions includes Refresh and omits duplicate Branches.
  The dedicated Refresh icon is absent. F5 and existing refresh/operation guards
  remain. Shared defaults preserve BusyFiles' navigation and actions.
- Git rows reuse the Files tree presentation, with a sibling trailing-action
  region outside the row selection/activation surface. Native flat +/− actions,
  disclosure alignment, hierarchy and status markers remain separate. Enlarged
  rendered tests exposed a real 24-pixel status glyph in an 18-pixel slot; its
  native extent and matching text inset now scale together in LTR/RTL.
- Amend uses the approved labelled Yaru checkbox through BusyMark's existing
  design boundary, including label activation, keyboard focus and semantics.
  No upstream source changed. Independent drafts and reviewed HEAD logic remain.
- Commit and Commit and Push… retain the existing measured horizontal Row and
  spacing-token gap. No automatic staging or staged-count captions were added.

Principal files are `lib/src/app/busymark_design.dart`,
`lib/src/git/application/shared_git_integration.dart`,
`lib/src/workspace/presentation/workspace_screen.dart`, all existing localization
catalogs/generated output, `test/src/git/native_presentation_contract_test.dart`,
and `tools/git_ui_audit/bin/check.dart`. Shared changes are confined to the
existing presentation/Commit/workflow contract, fixture/tests and guidance.
BusyFiles supplies the optional labelled/tristate native choice and updates its
source archive; its workspace, trust, descendant browsing and daemon boundary
are unchanged.

The maintained mapping is in BusyMark `AGENTS.md` and shared
`docs/native-presentation.md`. Resolved-symbol enforcement now checks required
button/checkbox/change-row adapter outputs as well as icon actions, aliases and
feature call sites. Missing mappings fail closed. No allowlist was expanded to
accept circles or Material fallback. The existing local verification command
also runs the actual host native contract tests; CI retains the full app suite.

## Checks against final materialized pins

| Check | Result |
| --- | --- |
| Shared presentation | 388 passed |
| Shared real-repository staging/commit/conflict regressions | 8 passed |
| BusyMark app/workspace/settings/localization/Git | 769 passed |
| BusyFiles authenticated Git IPC/daemon | 16 passed |
| BusyFiles Git UI/native adapter | 36 passed |
| Total affected tests | **1,217 passed** |
| Shared/host resolved native audits and enforcement self-tests | passed |
| Production analysis; final changed-source formatting | passed |
| Both exact localization CI commands, generation and generated-clean checks | passed |
| Standalone shared and both consumer source/pin integrity | passed |
| Controlled Git runtime and official Flutter workflow checks | passed |
| BusyMark Linux release build | passed |
| Ordinary `flutter run -d linux --debug --no-pub`, `lib/main.dart` | built and ran |

The 26 actual BusyMark native contract tests cover branch/modal/menu destinations,
flat shape and hit geometry, hover/pressed/focused/disabled states, native
labelled checkbox interactions/semantics, separate tree targets and scaled
markers. Existing localized footer tests exercise en/de/ja/ar at text scales
1/1.5/2; tree target/marker cases cover enlarged LTR and RTL. Existing real host
and deterministic-delay regressions retain root/worktree/submodule eligibility,
pending trust/workspace cancellation, draft races, reviewed index operations,
message-only amend, comparison identity, dirty close/reload consent and Local
History mouse/keyboard activation.

`runtime/commands.jsonl`, machine test results and lossless `.log.json` files
record commands, outcomes and exact transcript hashes. Initial failures remain:
the normal Files `dart test` invocation stalled before the runner, in tool/hook
startup with an external TCP/443 connection. Only that task process was stopped.
The existing `tool/run_package_executable.dart` launched the same 16 tests and
arguments using the existing resolved graph; all passed. No dependency, SQLite
configuration, network/security setting or test assertion was changed. The
original failed wait units and subsequent successful completion are recorded.

## Native captures and limits

These 38 inspected images are from the final actual release/debug applications.
Environment: established Ubuntu 24.04 QA VM, official Flutter 3.47.5 / Dart
3.13.4, X11/Xvfb + Openbox, 1440×1000 at 96 dpi, DPR 1, default desktop text
scale, `en_US.UTF-8`, Yaru-blue, application en/de/ja/ar and light/dark themes.
The German narrow capture uses the visible application at 900×740; normal
captures use 1280×720. Early capture-tool resize/focus commands targeted a hidden
GTK window. The helper now selects only visible windows, and misleading
exploratory images are excluded. Native input logs preserve that investigation.

- [Exclusive untrusted screen](captures/untrusted-en-light.png),
  [repository-specific confirmation](captures/trust-confirmation-en.png),
  [Cancel](captures/trust-cancelled.png),
  [revocation in Arabic](captures/trust-revoked-ar.png).
- [Compact trusted Commit](captures/trusted-commit-en-normal.png),
  [Manage branches tooltip](captures/manage-branches-tooltip-en-settled.png),
  [held branch press](captures/branch-pressed-en.png),
  [Repository Actions: Refresh, no duplicate Branches](captures/repository-actions-en.png).
- [Full Branches modal](captures/branches-modal-en-settled.png),
  [branch context actions](captures/branch-row-menu-en.png),
  [remote search and Tags section](captures/branches-search-remote-en.png).
- [Separate unstage held-press target](captures/unstage-pressed-en.png),
  [Amend checked](captures/amend-checked-en.png),
  [native checkbox keyboard focus](captures/amend-keyboard-focus-debug.png),
  [Space toggles back to the retained normal draft](captures/amend-keyboard-toggle-debug.png).
- [Partial change with independent tabs and unsaved document](captures/comparisons-draft-en.png),
  [Local History mouse reactivation](captures/git-to-local-history-mouse.png),
  [keyboard Git activation](captures/local-history-to-git-keyboard.png),
  [keyboard Local History reactivation](captures/git-to-local-history-keyboard.png),
  [real document-close guard](captures/dirty-close-guard-en.png).
- [German narrow window after restart](captures/commit-de-light-narrow-visible.png),
  [Japanese dark](captures/commit-ja-dark.png),
  [Japanese Branches](captures/branches-ja-dark.png),
  [Arabic RTL](captures/commit-ar-light-rtl.png),
  [Arabic Branches](captures/branches-ar-rtl.png).
- [Ordinary debug startup](captures/ordinary-debug-untrusted.png),
  [Git Log information before files](captures/debug-git-log-inspector.png),
  [history selection modal](captures/debug-history-selector.png),
  [descendant workspace rejected](captures/descendant-root-required.png).
- [Different root does not inherit trust](captures/separate-root-untrusted.png),
  [long branch truncation](captures/long-branch-flat-header.png),
  [workspace path tooltip](captures/workspace-path-tooltip.png),
  [complete long-branch identity in modal](captures/long-branch-full-modal.png).

Native checks exercised Cancel/Trust/restart/revoke, Refresh, full modal/search/
context menus, held press and canceled staging, label/Space Amend activation,
independent staged/unstaged tabs, unsaved text, Local History mouse/Ctrl+Tab,
history modal cancellation and descendant rejection. The original fixture's
working files, HEAD, index, config and refs are byte-identical (40 receipt
entries). Its actual local tracking result is ↑2 ↓1. The separate long-branch
fixture retains its working bytes/HEAD. No native capture staged or committed.

AT-SPI exposed only application/frame, not Flutter body; the existing desktop
accessibility setting was not changed. Enlarged/fractional desktop and Wayland,
Windows, remote credentials/network, strict Snap qualification and dedicated
performance remain separate, uncompleted acceptance. Widget semantics/scaled
geometry checks remain enabled. The existing shutdown problem reproduced:
one release exit was SIGABRT and debug close logged `FlutterEngineRemoveView`.
The ordinary Flutter debug runner exited 0, and the final long-root release
exited 0. These results do not establish universal clean shutdown.

## Artifacts and environment closure

The local final release archive is
`/home/albert/busystack/.native-git-verification/busymark-bad4554-linux-release.tar.gz`,
SHA256 `37af91727c974fb7dba1d0fd37c3731b3dfbfb4dbca8d17bc75c93f1cbc193c5`.
`runtime/release-runtime-receipt.json` binds all bundle hashes to source/pins.
The official release engine hash is
`d57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1`;
the mapped ordinary debug engine is
`7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3`.
The SDK tracked tree is clean. No third-party pin/source was modified.

Both consumers pin shared UI `5745a39`, archive SHA256
`6aa00dfa36d47d251a4bd39d3b84884f39301296a9b002d2e38c6e923d1f5f15`,
tree SHA256 `2e40cf8569313942c9cb69acc4d22909ca0b494b7fc1634787414a7f7efd442d`.
Engine and approved BusyFiles DAV pins are unchanged. No new BusyFiles
production-package/native matrix acceptance is claimed by this adapter update.

Capacity was checked before heavy work; builds ran sequentially and about
18 GiB remained in the guest. Task-owned native processes were closed and their
logs copied. Only the two recorded failed task units were reset after preserving
their journals; the guest reported running, no failed units and an empty dpkg
audit. The QA VM was gracefully returned to its original STOPPED state. BusyData
and BusyNode stayed RUNNING, BusyMax stayed STOPPED. No VM resize, security,
accessibility, GPU or unrelated environment change was made in this correction.
The earlier disk/VM incident remains separately documented under
`../2026-11-01-followup/incident`.

`runtime/native-captures.json` binds the images and environment. The original
raw transcript archive remains local with the hash in `evidence-archive.json`;
tooling used to reproduce the checks is included. Nothing was pushed/published.
