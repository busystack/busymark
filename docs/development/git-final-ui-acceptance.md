# Git final UI correction — acceptance remains incomplete

2026-11-03. Source changes are committed locally. This is not native graphical
acceptance. No screenshots or failing-before/passing-after widget results were
obtained in this restricted session. Do not treat constructor/audit or build
success as approval of layout, text contrast or interaction.

The initial working trees were clean: BusyMark
`d2247556ed1c34ee50c0169c00387dad4a5ceb99`, shared UI
`ff95462ef1149bfab9506a284e33109f72954e6f`, BusyFiles
`ff5d09c903a3952ff1c6fc56f4bc130df21eb9ac`, engine
`7d8e55d8034aeb85cddac1c0f498b0f3cc33105b`. Parent and repository AGENTS.md
policies were read. These revisions were preserved; no reset was performed.
Original copies of all eight requested source files are retained with the logs
under `build/git-final-ui/before-source`.

## Root causes and source corrections

- BusyMark's adapter discarded `isDense`, prefix icons, content insets, label
  alignment and vertical alignment. Its native entry always stacked the label
  above the editor. The adapter now forwards those requests; compact entries use
  an inline hint and persistent semantic label. Prefix/suffix widgets occupy
  logical start/end slots. Controllers, selection, composing/undo state and
  native editing callbacks retain their owners. Focus uses the public Yaru border.
- Both adapters ignored row density. BusyMark now applies its sidebar metrics;
  BusyFiles uses its existing sidebar YaruMasterTile geometry for dense rows.
  Trailing actions are siblings outside the row activation surface. Selected and
  enabled semantics are explicit. Requested check-row insets reach both hosts.
- The old history command Wrap mixed filters and operations across uncontrolled
  rows. One measured row now shows compact message/author/path fields and date
  where they fit, or the native Filters menu at reduced widths/enlarged text.
  Secondary navigation and multi-commit operations remain in that menu. Selection
  and history generation bind deferred multi-commit actions.
- History-reference menus inherited the vertical default. Those rows now request
  `moreHorizontal`, resolved to the same native artwork as historical file menus.
  Other default menu glyphs are unchanged. Local/Remote/Tags hierarchy remains.
- The selector exposed a Commit Details button that embedded `_detailPane()` at
  height 500 with `expanded: true`. That obsolete route is removed. Commit context
  menus retain compact View Commit Details, exact copying, branch/tag creation,
  comparison, snapshots, cherry-pick, revert, rebase and reset operations.
- Both hosts supplied opaque semantic foregrounds as diff backgrounds. They now
  supply translucent treatments derived from existing Yaru/host semantic colors.
  Shared line backgrounds reduce the word treatment's opacity, and index/conflict
  highlighting consumes host opacity instead of overwriting it. Search uses the
  existing host accent; active matches retain bold/underline. Existing markers,
  staging/conflict labels, text selection and comparison endpoints are preserved.
- The contract audit also found discarded choice expansion and progress stroke
  requests. Both hosts now map them to supported native/Yaru properties. The full
  mapping and explicit native label/underline equivalents are documented in the
  shared package's `docs/native-presentation.md`.

BusyMark feedback continues through BusyMarkToastOverlay. BusyFiles Git uses
`busyFilesMessage`, the same in-window message wrapper as its non-Git browser and
recovery flows. Its daemon desktop-notification service has background-operation
and activation semantics, not this short-message contract. Existing feedback
semantics were retained, and a rendered wrapper regression was added. There is
no Git-only notification constructor or new fallback.

## Verification actually obtained

| Check | Result |
| --- | --- |
| Complete shared lib/test analysis | Passed |
| Complete BusyMark lib/test analysis | Passed |
| Complete BusyFiles UI lib/test analysis | Passed; final density adjustment also analyzed |
| Shared resolved native-construction audit and self-tests | Passed |
| BusyMark complete adapter/dialog roots | Passed |
| BusyMark mixed-workspace audit and self-tests | Passed |
| BusyFiles Git source native audit | Passed |
| Materialized pinned Git sources, both consumers and complete BusyMark roots | Passed |
| Both host localization catalog/adapter checks | Passed |
| Engine real-repository regression subset | 14 passed: discovery, staging/partial index, byte identity, stale review, missing paths and safe historical restoration |
| Official Flutter workflow regressions | 28 passed |
| Approved SDK tracked source and artifact verification | Passed: Flutter 3.47.5/Dart 3.13.4, 1,171 artifact inputs |
| Available publisher archives vs resolved hosted sources | No mismatches: 32 shared, 71 BusyMark, 73 BusyFiles packages; complete graph attestation remains incomplete because other archives are unavailable |
| Linux release builds | Both built during this session; final-source build receipts/logs retained |
| BusyMark shared-source dependency check | Passed |
| BusyFiles complete source-dependency check | Blocked by pre-existing DAV checkout/pin mismatch |
| Widget/rendered, shared real-repository widget and native keyboard checks | Blocked before test loading by local-socket denial |
| Actual final-source BusyMark graphical launch | Failed: GTK cannot open display :0 |
| Private Xvfb graphical session | Failed: sandbox denies listening sockets |
| Actual native screenshots | None |

The new consumer assertions measure field and row density; require prefix/suffix
widgets; preserve composed editing values; exercise read-only/disabled fields,
directional padding and separate trailing actions; inspect actual line/word
rendering; and require light/dark text contrast and distinct search/selection
colors. Shared regressions reject the obsolete selector route, inspect its
initial selected row, retain confirmation/cancellation assertions and historical
context operations, and require the branch contextual glyph. The pre-existing
Material enforcement was neither weakened nor allowlisted. These tests analyze,
but their runtime assertions have not executed here.

The initial rendered regression attempts and final regression attempts both
failed before any test loaded: `Failed to create server socket`, OS error 1,
127.0.0.1. Escalation was automatically rejected because this session disables
sandbox escalation. Therefore there is no valid failing-before/passing-after
rendered claim. Both the original and corrected implementations still require
execution in a permitted test environment.

## Source identities and remaining acceptance

Both consumers pin shared UI `d1978b27d4e482bbdc40f3e6c6ebf65fc3423ff5`.
Their identical source archive SHA-256 is
`b885014e3a6d9f75d4b6b00654b3824b5e66aa7d5334943441ba8db80562c954`;
its validated source-tree digest is
`a0f7773a438cbd3d7a3cd0eadca567ae2b3214215610a087ff1aaa128190e2bb`.
The engine pin remains `7d8e55d8034aeb85cddac1c0f498b0f3cc33105b` in both.
Exact application commits and executable hashes are in the retained delivery
receipt. No changes were pushed and no artifacts were published or installed.

BusyFiles' unrelated existing DAV checkout is
`75bdc14ff793a2cf41c0632500dbdfd32d1910a2`, while its manifest requires
`18f636f3227e3df8c1406bafd85b45e7f12cf8bd`. Its unrelated modified IDE cache was
preserved. The complete dependency gate remains failed; validating Git archives
independently does not waive that failure.

Acceptance still requires executing the new regressions against original and
corrected implementations; the broader widget/localization/native/real-repository
widget suites; complete dependency attestation; and the entire requested native
screenshot/interaction matrix. That matrix includes both themes, normal/enlarged
text, narrow/normal windows, keyboard focus, full history/filter/reference views,
long subjects/multiple refs, confirm/cancel, both comparison modes, added/deleted
and mixed/partially staged changes, text selection/search, and the approved Commit
sidebar. The genuinely absent historical-file pane is intentionally unchanged.
No visual-quality or native-input approval is claimed.
