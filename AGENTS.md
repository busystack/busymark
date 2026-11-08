# BusyMark integration policy

The parent BusyStack engineering policy applies. Keep the official unmodified
Flutter 3.47.5 / Dart 3.13.4 toolchain and locked third-party versions.

Git UI is owned once by busystack_git_flutter. Use GitFeatureSidebar,
GitReview/GitReviewTabs, GitReviewSurface and the common YaruGitPresentation.
BusyMark supplies document-tab integration, native services, localization,
authorization and durable drafts. Do not add app-owned Commit/Log/Branches/diff
widget trees or revive the retired GitSidebarTab cluster. The shared ownership
and action map is ../busystack_git_flutter/docs/one-git-ui.md.

Preserve canonical worktree-root attachment, exclusive untrusted Commit notice,
restricted read-only inspection, document/Local History tabs and dirty-buffer
lifetime guards. A Git view/tab change never saves or replaces a document.
The existing GitDiffViewer call in _showExternalFileComparison serves the
non-Git document-versus-disk recovery flow; it is not a Git file activation route.
Keep that host document responsibility and Files VCS decoration helpers intact.

Run the shared suite, actual-host native and editor/navigation/localization
regressions, resolved native audits and their adversarial self-tests. Refresh
both consumers' exact shared pins/archives together and verify actual installed
Linux applications; a shared revision or a screenshot alone is not acceptance.
Commit authorized first-party changes locally. Do not push or publish.

Git workflow notifications are shared presentation: both hosts forward localized
messages and lifetime guards to `showGitNotification`; do not build a host-owned
Git toast/snackbar. The resolved native audit follows `GitHost.notify` into
helpers and stateful rendering, with adversarial callback ownership tests.

Artifact qualification and private installed-app acceptance are documented in
`docs/git-ui-acceptance.md`. A completed full-corpus receipt may be verified by
the local packaging helper; never accept changed inputs, missing/filtered tests,
skipped/failed cases or changed logs. This does not waive any native gate.

Closing the last authoring document activates a surviving captured Git
comparison when no document, Local History view or comparison is active.
Never select or retarget a comparison created during the close confirmation.

Sidebar identity uses BusyMarkSidebarHeader / shared NativeSidebarHeader:
body-medium view title, secondary body-small context, common directional
insets/action geometry. Files paths and Git branch/commit contexts are
informational; Writerside retains its instance selector. Clipboard has no empty
context line. Preserve all view-level native actions.
Use the shared NativeFocusIndicator/NativeFocusStyle through existing controls:
pointer selection retains focus ownership without keyboard emphasis; keyboard
interaction reveals a restrained semantic outline. Never conceal focus through
global highlight strategy or remove accent roles. Welcome recent resources use
an explicit comfortable record density; history and active search remain compact.
