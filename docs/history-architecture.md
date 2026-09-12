# History implementation notes

## Clipboard ownership and insertion

`RichClipboardService` owns the current BusyMark rich payload for the process
session, independently of `ClipboardHistoryController`. Every publication
creates an opaque UUID token and publishes the token, interoperable text, and
HTML together through the native boundary. Tokens resolve only through the
service's bounded immutable payload map; unknown, malformed, lost, or stale
tokens are external data. Text equality is never proof of ownership, and
clearing retained history does not invalidate the current rich clipboard.

The Linux runner uses `application/x-busymark-token` alongside GTK text and
HTML targets and reports an owner generation for coherent reads. The shared
Dart boundary falls back only to Flutter's interoperable plain text when the
native method is unavailable. This checkout has no `windows/` runner, so no
Windows channel registration or registered-format host can be built or
runtime-verified here; generating a new runner would expand this work into an
unrelated platform-stack rewrite.

Retained `BusyMarkClipboardPayload` objects have UUID identities, acquisition
and origin metadata, exact text/source/HTML/rich/image representations, a
SHA-256 equivalence fingerprint, and UTF-8/image-byte accounting. The policy
defaults are 100 entries, 64 MiB total payload bytes, and 8 MiB for decoded
thumbnails. Deduplication compares every meaningful representation. The
insertion registry holds only the latest mounted editable surface, uses
identity-safe unregistering, and requires each adapter to capture and
revalidate document ID, buffer revision, mode, selection generation, and
target lifetime around asynchronous work.

Copy/cut capture happens only after successful publication. A cut publishes,
then revalidates its selection before one deletion transaction. External
content is retained only after a successful document paste. The transient
current item carries supported external HTML without claiming BusyMark token
ownership and keeps its interoperable text separately. WYSIWYG history
insertion sends that HTML through `WysiwygClipboardHtml`, the same validated
conversion used by ordinary Paste; malformed or unsupported structure uses the
existing text fallback. History insertion uses the normal Source or WYSIWYG
transaction and asset-ingestion paths.

## Local History capture and identity

`LocalHistoryController` observes document buffers and schedules a fixed
checkpoint window per changed buffer. Capture events are baseline, explicit
saved content, automatic checkpoint, before reload, before discard, before
restore, before delete, and observed external change. Pending buffers are
flushed on close, workspace replacement, and awaited shutdown. Autosave writes
do not themselves create Saved entries.

The editor buffer is the source authority. Source and WYSIWYG callbacks,
selected-text formatting, inactive-buffer mutations, Undo, and Redo all report
the before/after buffer transition after one accepted document transaction.
Observation is queued per buffer and replaces that buffer's one pending full
source snapshot. The first edit anchors the checkpoint timer; later edits
replace the pending source without postponing the deadline. A flush is a queue
barrier, so observations accepted before it are captured before settlement is
reported.

Automatic capture retains pending work until storage succeeds or adjacent
source deduplication validly settles it. Transient failure preserves one
bounded latest snapshot per buffer, keeps the capture warning visible, and
schedules a controlled retry using the configured checkpoint interval. Newer
accepted source wins over acknowledgements or failures from older writes.
Unsupported or over-limit content remains visibly failed without a retry loop.
Transient first-save identity-promotion failures use the same retry cadence
before the pending checkpoint is captured. Flush and identity-promotion
results propagate content-capture failure to lifecycle safety callers; a
successful document save remains independent of a failed history write. A
closed editor does not remove unresolved pending work from controller
ownership: its retry continues while the process runs, and shutdown settlement
accounts for pending buffer IDs even when their tabs are no longer open.

History identity is stable independently of widget and transient buffer IDs.
Known file and directory moves remap current and descendant paths while
retaining historical paths. A first save of an untitled document continues its
lineage. Named-file Save As retains the source lineage separately and starts or
appends to the destination lineage; an overwritten destination is protected
before publication. Path transitions explicitly distinguish moves from Save As
so an unresolved first-save association is never retargeted to a later copy.
Pending first-save associations are also matched by destination path when a tab
is reopened, before baseline capture, and promotion refuses a destination
already owned by another history document.

## Store and retention

Production revisions live in `local_history` beneath the platform application
support directory. Tests inject either an isolated directory or the memory
store. Store format version 1 uses a small index, independently recoverable
checksummed full-source JSON revision records, and an independent tombstone
journal. IDs are validated and all record paths are constructed under the
history root.

Writes are serialized in-process and guarded by an exclusive file lock across
processes. A full record is staged and published on the same filesystem before
its index entry. Index recovery scans intact records and observes tombstones so
retention and explicit clears cannot resurrect deleted data. Unknown future
versions fail explicitly. Retention runs only after a successful capture,
counts actual record lengths, protects the new/protective record, and defaults
to 30 days and 512 MiB.

## Comparison and restore safety

Ordinary Local History browsing is scoped to the active document buffer. A
scope generation invalidates outstanding revision reads and searches before a
new scope is displayed, so old results cannot land in the wrong document list.
Store-wide document search is a temporary discovery mode for retained closed,
renamed, deleted, or untitled identities; selecting a normal document resumes
active-tab following. The revision list is timestamp-first and groups the same
localized timestamps by local calendar date.

Normal browsing retains the active buffer as its scope even before that buffer
has a stored history document ID. The first capture, a capture after Clear, or
an identity promotion reconciles the buffer-to-history association and
publishes the corresponding rows without a tab switch, sidebar reconstruction,
or Refresh. Captures for inactive buffers do not steal this scope. Explicit
tab, editor, or Files-context Local History commands leave retained lookup and
establish the requested buffer after guarded activation completes.

Every published snapshot validates document/revision ownership. An active
revision-content query is recomputed against the new scoped snapshot, with
query, scope, and snapshot generations preventing delayed reads from replacing
newer matches. Search completion clears its loading state on success, scope
change, cancellation, and read failure. Explicit clear invalidates affected
queued work at the point it was accepted, before store access, and closes a
comparison it owns. A queued automatic checkpoint cannot become current merely
because it begins executing after Clear. Retention loss instead reports the
existing missing-revision state.

`SourceComparisonInput` identifies immutable sources by ID, version, label,
and text. The comparison uses unique patience anchors plus bounded local LCS
and intraline refinement in Dart UTF-16 offsets. Separated edits are retained.
When an unanchored comparison exceeds the work bound, the result is labeled
simplified and exact region restore is disabled.

Local History has its own `WorkspaceTabKind.localHistory`. The current side is
the live unsaved buffer when present, then a fresh disk load, or an explicit
missing-file state. An immutable comparison request owns the history document,
revision, current buffer, source revision, and source text; sidebar browsing is
not consulted later to redirect a pending comparison or restore. Restore
captures the target identity/path/revision/selection and exact range, persists
a protective snapshot, revalidates after awaits, and applies one
`DocumentBuffer.edited` transaction without replacing format metadata or the
undo stack.

Missing-file recovery keeps the source history identity separate from the
destination buffer. For an approved existing path, the normal guarded open flow
loads the destination's real source and format, protection must succeed, and
the retained source is one ordinary edit whose Undo baseline is the exact
destination content. No empty file is published. New-file recovery retains its
separate no-overwrite creation path.

Workspace refresh records per-buffer request snapshots, then reconciles disk
loads against live membership, path, source revision/text, dirty and disk
state, and the loaded disk snapshot after every asynchronous parse boundary.
Buffers opened meanwhile survive, closed buffers are not resurrected, and
newer editor state and undo/redo history win over stale loads. Derived workspace
and preview content is published only when its active buffer and source still
match; otherwise the normal fresh-parse scheduler takes over.

Ordinary tab activation follows the same live-buffer rule. It avoids reparsing
an already-active unchanged target; after an asynchronous reparse, it
revalidates workspace and target identity and republishes the current buffer
membership, source, editor selection, and undo/redo state rather than an
activation-time list. A stale derived result is discarded in favor of the
normal fresh-parse scheduler. The first-open path likewise appends a newly
loaded document to the live list instead of an earlier captured list. Only
documents that were genuine additions at activation start may be added during
reconciliation, so tabs closed while parsing stay closed. A close that removes
a document is aborted if that document's source or editor state changes during
the final activation await. Refresh reschedules eligible autosaves on both
success and failure because it cancels its incoming timers at the boundary.

## Verification workflow

Use the repository-pinned Flutter/Dart toolchain:

```bash
flutter gen-l10n
dart format <changed Dart files>
flutter analyze
flutter test
flutter build linux --release
flutter build linux --debug -t tools/clipboard_smoke.dart
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  roundtrip OUTPUT_DIRECTORY
# For inter-process ownership, run `write OUTPUT_DIRECTORY` in the background,
# wait for write.ready, then run `read OUTPUT_DIRECTORY` on the same X display.
# Stop the writer by creating OUTPUT_DIRECTORY/stop, then run
# `plain OUTPUT_DIRECTORY` to verify that an external plain-text owner does not
# inherit stale BusyMark formats.

# Native production-controller visual exercise (use disposable workspaces):
flutter build linux --debug -t tools/history_visual_smoke.dart
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  markdown WORKSPACE PRIMARY_FILE DELETE_FILE OUTPUT_DIRECTORY
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  writerside WORKSPACE PRIMARY_FILE - OUTPUT_DIRECTORY
# Omit the smoke timer override and exercise the real 60-second deadline:
BUSYMARK_HISTORY_REAL_POLICY=1 GDK_BACKEND=x11 \
  build/linux/x64/debug/bundle/busymark \
  markdown WORKSPACE PRIMARY_FILE - OUTPUT_DIRECTORY
```

When a probe is launched through `xvfb-run`, explicitly set
`GDK_BACKEND=x11`; a stale inherited `WAYLAND_DISPLAY` can otherwise make GTK
select Wayland, where clipboard publication requires a compositor input serial
that a headless probe does not have. The visual target writes PNGs and a JSON
report, and exits nonzero if any production clipboard, capture, comparison,
fragment-restore, deletion, or recovery check fails.

The current checkout is pinned to Flutter 3.47.2 / Dart 3.13.2. Available
native validation is Linux-only because the repository contains no Windows
runner or Windows plugin registration path. Verification artifacts are written
to the ignored `build/history-ui-evidence/` directory by the runtime
exercise; documentation does not treat an earlier committed test count or
screenshot as proof of the current checkout.
