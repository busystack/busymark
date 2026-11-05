# Git Log native navigation correction — final Linux acceptance

2026-11-05. The corrected application is built at
`build/linux/x64/release/bundle/busymark`. The final source passed **186 BusyMark
host tests**, **416 shared Git tests**, **21 BusyFiles adapter tests**, and the
native presentation audits. The shipping release passed **16/16 full native
cases and 16/16 narrow Date Filter cases**, with actual images inspected.

Evidence is in `build/git-verification/2026-11-05-navigation/`.
The [native matrix receipt](../../build/git-verification/2026-11-05-navigation/native-matrix.json)
indexes source/payload-bound runs and image SHA-256 values. Earlier matrices are
retained as superseded evidence; only the final build's hashes count.

## Verified baseline

The clean starting checkouts were BusyMark `a1e4fcfc5e201d1ee2b59f9c6d1270ebee493e52`
on `feature/git-package`, shared UI `494d024d54ef74d83658725d77f4c5ab73a31d74`
on `main`, and BusyFiles `be11c0219378775229a51382e6be8759417298ce` on
`Release/v0.0.1`. The engine was clean at
`7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`. Applicable parent/repository
AGENTS.md files, manifests, archives, lockfiles and Files/sidebar components
were inspected. No repository was reset; unrelated DAV work was preserved.

Flutter **3.47.5**, Dart **3.13.4**, pinned Yaru **10.2.0**, Intl **0.20.3** and
all application dependency versions remain unchanged. No SDK, GTK, Yaru, Git,
engine or build-tool source was patched. GNOME/Flutter official guidance and the
installed pinned APIs were consulted; references and API findings are maintained
in the shared package's `docs/native-presentation.md`.

## Causes, files and final behavior

- Shared `lib/src/log_view.dart` previously put the reference splitter under a
  toolbar spanning both panes, with the sidebar toggle among filters. References
  lacked a common inset and used general `GitExpander`/`YaruExpandable` rounded
  disclosures. The view now requests a real host-owned header/sidebar/main
  layout and explicit reference tree rows.
- Shared `lib/src/presentation.dart` requires `GitLogHeader`,
  `GitHistoryLayout` (including toolbar and footer), and `GitReferenceRow`
  presentation, plus a marker for bodies owning their header. BusyMark's
  `lib/src/app/busymark_design.dart` supplies the approved native components.
  BusyFiles' `apps/busyfiles_ui/lib/src/app/busyfiles_design.dart` implements the
  contract with its existing expander, toolbar, splitter and compact dialog.
  General expanders, including Rebase/repository flows, remain unchanged.
- The inspector retains selected commit, compact metadata, then Changed Files.
  Its neutral subject is noninteractive, truncates and exposes its full value.
  **Select another commit** sits immediately before **Commit Actions**, with
  Files header insets, 34px targets and the native 8px spacing token. The
  duplicate menu route was removed; commit-specific operations remain.
- Historical change rows use the Files tree's fixed 18px icon/status slot,
  native outer padding, 14px hierarchy step, selection extent and context
  regions. A status marker adds no extra indentation. Grouping, context menus,
  parent-aware comparisons and independent immutable comparison tabs remain.
- The history modal uses the approved dialog titlebar, independently centered
  Log title, close action and its own sidebar state. The toggle reuses the
  **actual main-window native control**. An Align prevents AppBar's leading slot
  stretching it from 34×34 to 50×46; its start inset, colors, hit target and
  focus behavior match a rendered main header. It never calls the main sidebar
  toggle. Search, reference selection, expansion and pane width survive hiding.
- Search, All References and the Local/Remote/Tags tree share native sidebar
  insets. Groups use flat Files disclosures with accessible expansion and
  RTL/keyboard behavior. Branch rows retain current-branch identity and
  pointer/keyboard context menus without permanent Actions buttons. Selection
  filters history; it does not check out a branch.
- Filters/navigation remain in the main area. The tested graph, parent
  relationships, columns, object identities, pagination and operations remain.
  Narrow layouts expose the same reference pane temporarily over a readable
  table; its toggle stays in the header.
- The selection action is a real fixed footer outside the scrolling table,
  padded with the approved 16px token. At narrow widths the footer sits below
  the overlay's bounds, keeping the entire affirmative button visible even at
  enlarged text. RTL placement, validation, Enter, Escape and single completion
  remain.
- The old date composition doubled external labels with Yaru's implicit entry
  label and omitted spacing. Pinned Yaru exposes no public label override for
  that arrangement. The corrected compact dialog uses the existing approved
  BusyMark text-entry composition: one localized label above each native input,
  4px label spacing, 16px field/footer spacing, and native Cancel/Save actions
  separated by 8px. Empty/populated inputs reserve the same clear-action slot.
  Locale patterns and strict parsing accept native/ASCII digits, including
  Arabic without typing invisible direction controls. Validation is localized,
  Save requires a valid range, Cancel preserves filters, and inclusive End
  display/exclusive query bounds are unchanged.

Trust/authentication, hooks/signing, staging, commit transactions, branch
management, merges/rebases, stashes/worktrees/recovery, editor guards, Local
History, keyboard editing/IME, complete metadata and existing navigation safety
were preserved. The Git engine and source audit allowlists are unchanged.

## Regression evidence

| Check | Result / log |
| --- | --- |
| Four strengthened tests on original source | Failed: missing selector, rounded disclosures, 0px footer inset, duplicate Enter Date; `failing-before.log` |
| Hidden pane focus before correction | Failed; `hidden-focus-before.log` |
| Narrow overlay covering footer before correction | Failed actual overlap assertion; `overlay-footer-failing-before.log` |
| Modal versus actual main-header toggle before correction | Failed 50×46 versus 34×34; `header-toggle-failing-before.log` |
| Main-header geometry/state/keyboard comparison after correction | Four LTR/RTL light/dark tests passed; `header-reference-passing-after.log` |
| Final six BusyMark host suites, including 58 layout tests | **186 passed**; `final-host-acceptance-current.log` |
| Tabs, dismissal, localization and root eligibility | **16 passed**; `host-safety-provisioned.log` |
| Entire shared Git widget suite | **416 passed**; `git-suite-final-stable.log` |
| BusyFiles real adapter/surface suite | **21 passed**; `busyfiles-shipping.log` |
| Shared/changed host analysis | Passed; `git-analysis-final.log`, `final-source-analysis.log`, `busyfiles-analysis.log` |
| Complete host native audit and adversarial self-test | Passed; `final-busymark-chain-audit.log`, `native-presentation-selftest-accepted.log` |
| Exact final archives materialized with consumer hosts | Passed; `materialized-final-busymark-audit.log`, `materialized-final-busyfiles-audit.log` |
| Official release build and sealed source/payload receipt | Passed; `final-shipping-build.log`, `build/linux/x64/release/git-native-source.json` |
| BusyMark source dependency gate | Passed |

Tests render the actual adapter and native components, measure painted bounds
and compare the main-window control directly. Only widget-test OS-window
channels are provisioned; no substitute host controls were used. Native runs use
the actual GTK service. Golden changes followed geometry correction and native
image inspection. No tests or native-construction rules were weakened.

## Native graphical acceptance

The final release ran on private GTK/X11 desktops using real Git repositories
and native pointer/keyboard input. All 16 combinations of English, German,
Japanese and Arabic RTL × light/dark × text scale 1.0/1.5 passed. Each covers
1290×730 and 600×730 windows, header hover/pressed/focus, sidebar open/closed/
reopened, narrow reference overlay, a different commit before Cancel and
confirmed selection, plus empty/focused/invalid/corrected/saved/reopened dates.
All 16 include narrow date captures. English normal-text runs additionally
cover search, local/remote selection, all group disclosures, pointer/keyboard
menus, state restoration and two independent historical comparison tabs.

Each accepted receipt verifies final compiled-source and payload hashes, the
mapped official engine, natural exit and unchanged worktree/HEAD/branch/refs.
Actual images and contact sheets were inspected directly. A separate dated
repository visibly filters **10 commits to the expected four November 4–5
commits**, including both End-date commits; saved values reopen and Cancel
preserves the filter. See
[native query evidence](../../build/git-verification/2026-11-05-navigation/native-date-query/visual-result.json).

## Commits, archives and limitations

BusyMark implementation commits:
`9d8ebcdc69b1e54d656b79bdbdabfc0f45e3da5a`,
`bba795a33ec664b34470d35a968c2826a48a73f8`,
`4a5580f014c90de1df8ae3344e42f6a2643fe8c8`.
The final evidence/tooling commit is recorded in the
[delivery receipt](../../build/git-verification/2026-11-05-navigation/delivery-receipt.json).

Shared UI commits:
`826725c71154ff3728778d71cf516c3281dd4354`,
`32a1933e74076a6f1da61de7fcaeb596de5d2025`.
BusyFiles adapter/pin commits:
`5ab1f0a01d452052fda710bc786e39804a4f9650`,
`28ecff88669e075a044c080b4f8b3844e2768cbd`.

Both consumers pin shared UI **32a1933e74076a6f1da61de7fcaeb596de5d2025**.
Identical archive SHA-256:
`18319cd3e6b89cf1d573764e62ddb98c5cc14a401189fe69fa9f4eb9361a9347`;
tree SHA-256:
`1792282ab59233c63f14ea20fd69a1e9ed23fc4a9f83c396fd1501b42ae9488f`.
Engine pin **7d8e55d8034aeb85cddac1c0f498b0f3cc33105b** and its archive remain
unchanged. Nothing was pushed, published or installed system-wide.

Acceptance is Linux/X11 only. Other native platforms and compositor fractional
scaling were unavailable; DPR 1.25 was verified in actual-host widget tests only.
Earlier private-Xvfb attempts had frame-size timeouts, failed shutdown or
interruption; they are retained and excluded. Final accepted runs passed the
same strict gates. A plain official Flutter Hello World probe resized/exited
normally, so no upstream cause or engine fix is asserted. No renderer or
dependency workaround was added. AT-SPI geometry can time out here; bounds claims
use measured host layouts and inspected real images.

BusyFiles' complete dependency gate still rejects the pre-existing DAV checkout
`75bdc14ff793a2cf41c0632500dbdfd32d1910a2` against its manifest pin
`18f636f3227e3df8c1406bafd85b45e7f12cf8bd`; the unrelated modified IDE cache
was preserved. Its independent Git archive/adapter checks pass. See
`busyfiles-dependency-gate.log`.

## Reviewed image samples and reproduction

- [Inspector: root and nested files](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/inspector-root-and-nested-files.png).
- [History open](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/history-sidebar-open.png).
- [Sidebar hidden](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/history-sidebar-closed.png).
- [Search and selection restored](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/filtered-sidebar-restored.png).
- [Native branch context menu](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/reference-context-menu.png).
- [Different commit with independent tabs preserved](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-en-1.0/confirmed-selection-by-keyboard.png).
- [Enlarged German narrow overlay and complete footer](../../build/git-verification/2026-11-05-navigation/native-header-verified/dark-de-1.5/history-narrow-reference-overlay.png).
- [Invalid German range and disabled Save](../../build/git-verification/2026-11-05-navigation/native-header-verified/dark-de-1.0/date-invalid-range.png).
- [Japanese narrow dates](../../build/git-verification/2026-11-05-navigation/native-header-verified/light-ja-1.5/date-narrow-reopened-values.png).
- [All 16 narrow Date Filter layouts](../../build/git-verification/2026-11-05-navigation/native-header-verified/final-narrow-dates-all16.png).

Reproduce with the approved SDK and packaged Git helper. Run the six test files
listed in `final-host-acceptance-current.log`. Native verification uses:

```sh
/usr/bin/python3 tools/git_log_navigation_native_smoke.py \
  build/linux/x64/release/bundle/busymark <fresh-evidence-directory>
```

Select a case with `--case=light-ja-1.5`. The driver requires a sealed matching
source receipt and official engine; it retains every attempt separately.
`assemble_native_matrix.py` is retained beside the evidence JSON. Native runs
require a desktop/socket-permitted environment, without application hooks.


## Git control remediation follow-up — 2026-11-05

The baseline was BusyMark `e3e7ea6fcd06514fa26ff1d6d93d2e5a966c7baf`,
shared UI `32a1933e74076a6f1da61de7fcaeb596de5d2025`, and unchanged engine
`7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`. Both consumer UI archives matched
SHA-256 `18319cd3e6b89cf1d573764e62ddb98c5cc14a401189fe69fa9f4eb9361a9347`.
No checkout was reset. BusyFiles' existing generated-catalog formatting is
preserved separately from the new localization entries.

Shared UI `428dac3c6dac2070536e26313948746fc88f1cb0` defines view Actions,
entry-context and choice/display-menu roles. The host maps the view role once to
BusyMark's three horizontal bars; per-entry context artwork remains separate.
Required native metrics measure the actual toolbar buttons. Inline diff actions
and toolbar text controls request their own compact semantics. The host supplies
the Actions caption, preserving BusyFiles' repository wording. No operation,
index, commit/amend, editor guard or comparison-tab semantics changed.

BusyMark retains the approved native shape and state palettes with desktop
vertical button insets, leaving Commit and Commit and Push on one row. Compact
Log metadata/headings share host insets and parent metadata has no second row
inset. The existing Files-tree primitive still owns historical rows. History
now composes the reference surface and main content through their own headers;
the divider reaches the modal top and the toggle moves to the main header when
hidden. The narrow overlay keeps the padded footer outside its covered area.

The full shared suite passed 418 tests. The BusyMark Git/core-workspace run
passed 421 tests and differed only in six expected golden surfaces, which were
updated after inspecting populated native views. The follow-up golden/sidebar/
headerbar suite passed 41 checks. The actual host comparison suite passed 39
checks; modal coverage passed 58. Source analysis and the resolved native host
boundary passed. Both ordinary debug and Linux release builds succeeded with
unmodified official Flutter 3.47.5, Dart 3.13.4 and locked Yaru 10.2.0.

Native framebuffer evidence is under `build/git-remediation-20261105/` and
includes the trusted populated Commit area, actual-index staging comparison,
compact inline hunk/context controls, checked comparison menu, three-bar Actions,
Branches, the aligned Log inspector and corrected history pane composition.
Source/payload receipts bind the captures to the builds. Rejected blank or
incomplete framebuffer attempts and prior golden differences are preserved and
do not count as acceptance. Cross-application release/platform qualification is
reported separately; a BusyMark image alone does not establish BusyFiles support.


An additional rendered review found that the old `menuVertical` catalog entry
uses GTK's three-bar native artwork but Yaru's vertical-dot font glyph. Git's
semantic Actions mapping now explicitly requests `BusyMarkGlyphs.mainMenu`
(`YaruIcons.menu`, verified as three horizontal paths in installed Yaru 10.2.0)
and the same GTK `open-menu-symbolic` artwork. The dedicated regression rejects
both Yaru dot glyphs even without a GTK catalog; all 11 explicit-icon/golden
checks pass. No contextual icon mapping was globally replaced.
