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
