# Git native navigation remediation — 2026-11-04

This supersedes earlier acceptance descriptions of a clickable Git Log subject
and hidden primary history filters. Acceptance includes the running GTK host,
not just constructor scanning.

## Baseline

| Repository | Actual branch | Initial revision | Initial state |
| --- | --- | --- | --- |
| BusyMark | feature/git-package | 8df65c91019b206f37716ac76b7a9cb44bd0c7d8 | Clean |
| Shared Git Flutter | main | c3208729f15f51cc3f950ac81eaca0736db4b10a | Clean, ahead 3 |
| BusyFiles | Release/v0.0.1 | f6108c3fff3ef2bb80078ba5772764ddae552b56 | Native adapter and generated English catalogs already edited |
| Git engine | main | 7d8e55d8034aeb85cddac1c0f498b0f3cc33105b | Clean; unchanged by this work |

Both consumers initially declared UI revision
`d1978b27d4e482bbdc40f3e6c6ebf65fc3423ff5`, rather than the actual sibling HEAD.
The original archive SHA-256 was
`b885014e3a6d9f75d4b6b00654b3824b5e66aa7d5334943441ba8db80562c954`.
The source was inspected before editing; no repository was reset or cleaned.
BusyFiles' pre-existing entry-placement/secondary-click adapter corrections are
retained as prerequisites of the shared presentation contract. Its pre-existing
generated-file formatting is kept separate from the new localization getter.

Flutter 3.47.5 (`6a19cca56475dbfba1478ee68d7bd0c2ef891da1`), Dart 3.13.4,
engine `af7e796e161ae0bb1ff0758c71a7105418bd9ded` and locked Yaru 10.2.0 are
unchanged. No SDK, engine, GTK, Yaru, Git or vendored dependency was modified.

## Rendering causes and corrections

The shared dense-field request reached the adapter, but its standard surface
still produced a tall, rounded field with competing focus treatments. BusyMark's
existing Files/search entry is the visual reference. The corrected dense entry
uses the installed theme's surface, input border, disabled border, focus border
and four-pixel Yaru radius, with a 34-logical-pixel minimum and natural scaled
text height. One inline placeholder accompanies one persistent accessible name.
EditableText retains controller, selection, undo, IME and native editing behavior;
the public selection-gesture builder supplies actual desktop pointer selection.
Cursor and selection colors also come from the established text-selection theme.
The old Git-only 25% highlight differed from BusyMark's approved 32% selection;
rendered EditableText selection-box tests compare the actual search controls in
both themes, and native captures include selected search text.

The inline action adapter inherited accent-colored text-button foregrounds.
Inline metadata now uses BusyMark's neutral flat-action foreground. Compact
standard actions and suggested dialog actions retain distinct native roles.
The shared `compact` request changes toolbar/dialog insets independently of the
approved Commit footer. Both real host adapters implement and test it.

A further test exposed focus flags that did not produce a painted border when
the application had no inherited Yaru settings. The official Yaru focus border
now surrounds the interactive focus scope and owns its normal focus lifecycle.
This uses Yaru 10.2.0's public API without altering the library. The test measures
its painted border, including the case without an inherited Yaru settings widget.

The shared toolbar depended on incidental padding. Branches now reserves the
flexible width for search, uses explicit host spacing before New branch… and
Actions, and measures localized/scaled command widths before wrapping them below
search. A stable keyed editor preserves focus, selection and composing text.
The concise title is Branches; repository basename and full-path tooltip preserve
identity. Natural list height replaces the fixed 62% allocation, with a 68%
available-screen maximum and scrolling for long lists. Branch names and metadata
truncate independently, with complete tooltips.

Branch/reference rows have no permanent menu buttons in either host. One shared
context wrapper handles secondary click, Menu and Shift+F10, direction-aware
anchoring, focus restoration, and result traversal. Existing action models,
validation, worktree restrictions, trust checks and repository/session ownership
remain authoritative. Selecting a row does not check out, merge or delete it.

Git Log's subject is now neutral information. A separate view-level Actions
control owns Select another commit… and all applicable commit operations, grouped
with native separators. There is no duplicate selector or metadata Actions icon.
The abbreviated hash appears in commit information. The host row primitive also
stops registering a no-op tap action and button-hover treatment for informational
rows; testing only `onTap == null` on the shared request had missed that defect.
The existing selection workflow still owns initial selection, explicit confirm,
cancel, stale-response checks and repository binding.

History keeps its full graph, table, references, pagination and operation models.
Message/Author/Path use the same compact entry, remain visible at narrow widths,
and wrap coherently above the command group. Keyed editor subtrees retain the
actual focus node, selection, undo state and IME composition across wrapping;
controller text alone did not preserve the editing session. Date is a compact
standard action;
navigation and reset commands use the native overflow menu. Search in the
reference pane matches Branches. Select this commit is a compact suggested action.
Parent navigation remains neutral metadata; merge comparisons retain explicit
parent choice and independent immutable comparison-tab identities.

## Automated evidence

Evidence is under `build/git-native-remediation/` unless otherwise stated.

* `baseline/visual-contract-tests.log`: the exact production-view contract is
  run in isolated original BusyMark/shared-UI worktrees. The 19 original defect cases, enlarged German hint and missing-editor cases
  fail (21 failures, one passing Japanese-width case):
  oversized Branches entry/action, missing two toolbar gaps, wrong painted action
  surface/foreground, permanent row actions, activating subject, misplaced menu,
  duplicate hash/missing selector command, hidden or oversized history filters,
  and oversized selection action. The corrected 22 layout cases and six image
  goldens pass. No allowlist is expanded.
* `baseline/field-semantics-test.log`, `baseline/header-semantics-test.log`,
  `baseline/focus-border-test.log`, `baseline/focus-paint-test.log`,
  `baseline/selection-theme-test.log`, `baseline/history-focus-resize-test.log`: actual
  accessible-name, semantic tap and painted-focus failures caught below adapters.
* `application-final-tests.log`: 337 passing Git integration, host-contract,
  production-view geometry, localization, sidebar, real-repository and
  comparison-tab tests, including six image goldens using official Yaru fonts.
* Shared full suite: 416 passing tests, `shared-final-tests.log`; native audit
  adversarial self-tests: `native-audit-selftests.log`.
* BusyFiles integration: all 55 Git tests pass, `busyfiles-git-tests.log` and
  `busyfiles-analyze.log`.
* `native-audit-final.log`, `sidebar-audit.log`, `sidebar-audit-selftest.log`,
  `analyze-source.log`, `localization-sync.log`, `toolchain-policy-tests.log`,
  `debug-build.log`, `release-build.log` record their individual gates.

Real Git tests use the approved bundled Git 2.56 and native helper. The system
Git 2.53 is outside the engine's supported runtime and is not acceptance evidence.
The engine itself stays at its existing approved pin.

The permanent presentation gate includes measured production-view tests in
`tools/check_git_presentation.sh`. The Linux CI workflow captures all native
theme/locale/scale combinations after building the release and uploads PNGs,
commands and receipts. `git_native_build_receipt.py` captures source fingerprints
before building and refuses to seal if they change during the build. The desktop
driver checks the sealed payload against the executable, checks current source
fingerprints, and verifies the actually mapped engine against the unmodified SDK
artifact. The desktop uses XGetImage for actual framebuffer captures, including
GTK menus, and rejects blank or incomplete captures. Native exposure requests
precede framebuffer reads. A bounded retry waits for GTK to paint a resized GL
frame; incomplete frames are never saved. Pagination is also captured after a real narrow-window resize,
so graph continuity and the next page are inspected together.

## Native acceptance procedure

Private X11/Xvfb desktops use the real final-source executable and official GTK
host. Xvfb is 1600×1100, device scale 1; application windows are 1290×730 and
600×730. The official GNOME settings portal supplies text scales 1.0/1.5.
Isolated profiles cover light/dark, English/German/Japanese/Arabic RTL, normal
and narrow windows, and native mouse/keyboard menus. No mock application widgets
or generated acceptance images are used. Each receipt records actual sizes,
portal scale, locale, theme, source fingerprints and binary/engine hashes.
The final capture driver reads geometry from XGetWindowAttributes, rather than
GDK's cached dimensions. A real Xvfb resize regression checks 1290→600→1290
without a GDK event loop. Earlier captures with cached size receipts are
diagnostic evidence only; `delivery/` contains the repeated final matrix.

The harness creates its own known-safe real repository and trusts only that
fixture. Before/after working-tree and reference snapshots must match, and the
application must exit normally. A wrong initial timing-only driver sent input
before Git content loaded; its disposable fixture integrity check rejected the
run. Those images are excluded from acceptance. Rendered-state guards now wait
for the sidebar/modal before dependent input, and measure sidebar width under
enlarged text. GDK visible-region copies during grabs also produced incomplete
images; direct X11 framebuffer capture replaces that capture mechanism.

Run the maintained native capture entry point with:

```sh
/usr/bin/python3 tools/git_native_smoke.py \
  build/linux/x64/release/bundle/busymark build/git-native-acceptance
```

Inspect the images, including menus, focus, candidate cancellation/confirmation,
and independent historical comparisons, before accepting a run. A zero harness
exit status establishes lifecycle/source/fixture integrity, not aesthetic approval.

## Graphical evaluation and extracted-source verification

The final review index is `build/git-native-remediation/delivery-review/README.md`.
The six theme/locale/scale sheets and three interaction sheets were inspected,
with original full-size PNG checks for focus, menus, historical comparisons and
large repositories. `delivery/` contains the release matrix, `delivery-many/` the
221-commit/166-reference repository, `delivery-reference/` the native mouse and
keyboard reference menus plus remote/tag filtering, and `delivery-debug/` the
debug run. Each
application closes normally and its real repository status and references match
the initial snapshot.

Branches has a single native input border, aligned search icon/text, explicit
gaps, neutral compact New branch action, no permanent row menus, and natural
height that shrinks further for search results. Enlarged/localized controls wrap
without overlap. Long metadata truncates rather than becoming a paragraph;
large/scaled lists scroll within the maximum.

The inspector keeps subject information neutral, aligns Actions at the outside
edge (mirrored in RTL), offers Select another commit as the first grouped menu
item, and keeps parents and Changed Files below metadata. Native captures show
cancel retaining the original subject/hash, confirmation changing them, and
independent comparisons for both merge parents.

History retains visible primary filters, spacing, reference hierarchy and the
actual graph. Narrow widths preserve the subject and object identity while
adapting secondary columns and reference-pane access. The selection action uses
the approved suggested treatment. A native resize round trip retains the focused
filter and its entered text. Detailed filtering capture waits for stable results
and explicitly refocuses editors before clearing text; obsolete timing-only
images are retained separately as diagnostics.

Both pinned Git source archives were extracted and verified independently of
the sibling checkout. The extracted UI and actual BusyMark rendering chain pass
the strict audit and all 74 host, layout and golden cases
(`materialized-verification.log`). Official offline resolution uses a private
cache containing byte-identical copies of the locked packages because the
existing shared cache has an unwritable active-root registry. No dependency
source, version or shared cache permissions are changed.

## Boundaries

BusyMark root eligibility, workspace trust, Commit footer, transaction/index
rules, drafts, authentication, cancellation, document guards, Local History and
BusyFiles authenticated daemon IPC are unchanged. No additional sidebar, editor
tab system, framework or Git engine is introduced. Performance qualification and
previous unrelated platform/packaging qualification remain separate.

BusyFiles' DAV sibling is at `75bdc14ff793a2cf41c0632500dbdfd32d1910a2`, while its
pre-existing manifest declares `18f636f3227e3df8c1406bafd85b45e7f12cf8bd`.
Do not retarget or modify DAV to conceal that unrelated dependency discrepancy;
verify the Git archives separately and report the full closure check faithfully.

References: [GNOME HIG](https://developer.gnome.org/hig/), including Buttons,
Text Fields, Search, Menus, Header Bars, Dialogs, List and Column Views, Keyboard,
and Scaling/Adaptiveness; installed Yaru 10.2.0 public widget/theme source;
pinned Flutter EditableText, TextSelectionGestureDetectorBuilder, Focus,
Shortcuts/Actions, Semantics and route-lifecycle APIs.


## Final source pins and remaining consumer qualification

Both consumer manifests/archive checksums identify shared UI
`494d024d54ef74d83658725d77f4c5ab73a31d74`, following the main implementation
commit `044e1aabe06236c65fa4fbd4d12ccad7a67e8cdf`. Archive SHA-256:
`8be97c20aef974d15be09df39e848178c25268235865781f18728d12e8ff4819`;
extracted tree SHA-256:
`ae058ea6d95bbffee84b8572e84e80d35475a06cb4df5c0dec6c4e59b47c0473`.
The Git engine archive/pin is unchanged. BusyFiles commits are `79ca0b9`,
`b26d5f2` and final pin commit `2c021ea`; its two pre-existing generated formatting
changes remain uncommitted.

The required strict transitive BusyMark host audit passes, including its real
rendering controls; shared/BusyFiles feature-source audits pass. An additional
full transitive audit of BusyFiles' entire existing native host fails on its
pre-existing Material-based implementations (InputDecoration, first-party push
buttons, tooltips, separators and selection controls). These are outside the
BusyMark rendering chain and this assignment's BusyFiles integration changes.
`build/git-native-remediation/busyfiles-native-audit.log` retains the failures;
no scanner allowlist or constructor rule is relaxed. This is not a claim that
BusyFiles' whole host passes BusyMark's stricter construction policy.

Physical IME input methods and a physical accessibility client are not qualified
by these captures. Deterministic editor/semantics tests verify composing ranges,
selection, undo, accessible names, focus and cancellation; the native runs use
real mouse/keyboard events. This distinction does not waive any visible BusyMark
UI defect. Earlier unrelated OS/package performance qualification is unchanged.

The final native evidence contains 236 verified original PNGs across 19 native
application runs (16 matrix cases plus debug, large-repository and reference
interaction cases). The inspected review index links the individual results;
frame hashes and source receipts preserve their provenance.
