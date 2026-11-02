# Git presentation and lifecycle policy

The parent BusyStack engineering and official-toolchain policy remains binding.

Git production views must use the required `GitPresentation` host contract.
No stock Material controls, constructor tear-offs, palette/icons, invocation
helpers or menu/dialog fallback paths belong in Git feature code. Native
construction stays in the existing approved host design implementations:
`busymark_design.dart` and `busyfiles_design.dart`. A newly named feature wrapper
is not an approved design boundary. See the shared package's
`docs/native-presentation.md` for the exact mappings and action destinations.

Run `tool/check_native_presentation.dart` and its self-test from the shared
package, and audit each consumer's actual Git sources with that tool. Run the
same gate against materialized pinned sources in consumer verification.
Resolve symbols; import prefixes, aliases, re-exports and helper references
cannot be exceptions. Missing native provisioning must fail, never fall back.

BusyMark Commit and Git Log are independent sidebar views. The Git Log order is
selected-commit button, information, then Changed files. Its graph/history is a
native selection modal with explicit confirmation and cancellation. Ordinary
file activation opens a normal comparison tab. Repository/worktree, both paths,
immutable endpoints/parent and mutable review context identify that tab; sidebar
navigation never retargets it. Preserve actual tab/editor dismissal guards and
all transaction, draft, native input, history and comparison regressions.
BusyFiles retains its existing navigation and authenticated daemon boundary.

The mixed workspace screen is additionally covered by
`tools/git_ui_audit`: resolved Git enum branches and Git declarations must
use the native path, including comparison-tab context menus. Run its self-test
and check through `tools/check_git_presentation.sh`. Its analyzer version is
the existing shared audit pin; it does not change application dependencies.
Native menu separators are semantic GTK entries with no Flutter rendering path.

BusyMark Git icon actions must use the flat `BusyMarkHeaderIconButton` native
shape with its rectangular focus border. `BusyMarkCompactIconButton` is not
approved for Git, including Commit stage controls and Branches menus. The
resolved host audit checks the adapter as well as feature call sites. Actual
host tests must check shape, hit geometry and interactive states; wrapper names
or changed goldens cannot bless circular controls. Git change rows reuse
`BusyMarkSidebarTreeRow`. Keep the canonical working-tree-root eligibility at
both session and authoring-command boundaries, and the exclusive Commit trust
screen. BusyFiles keeps descendant browsing and its existing trust placement.

Commit's branch button opens the full Branches modal using the native flat
inline button treatment. Its tooltip describes Manage branches; repository
paths belong to workspace identity. Refresh is secondary in Repository Actions;
that menu excludes the duplicate Branches action only in BusyMark. Native
change rows reserve a sibling trailing-action region outside selection surfaces.
Amend uses the labelled native desktop checkbox and preserves its state/drafts.
Run tools/check_git_presentation.sh, including the rendered native contract tests.
Git status text columns scale from the native tree-control extent; preserve
legible markers and the matching text inset at enlarged scales in LTR and RTL.
