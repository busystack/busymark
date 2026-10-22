# History implementation notes

This document records the invariants behind the user-facing
[Clipboard History and Local History](../history.md) features.

## Document Undo/Redo

`DocumentBuffer` owns application document history across Source, Editor and
Split. Flutter field history remains available for auxiliary inputs. Document
fields override Flutter's overridable `UndoTextIntent` and `RedoTextIntent`
actions, including rich table cells and the hidden table-selection IME client.
A configured shortcut or action is consumed even when its document stack is
exhausted. Exhaustion changes no source, revision, dirty flag, stack or checkpoint.
The field controllers are retained; removing an explicit Flutter undo controller
would create another implicit one.

Both editors use `DocumentUndoGrouping`: a monotonic `Stopwatch` in production
and an injected `Duration` clock in deterministic tests. A group accepts edits
less than two seconds apart, lasts strictly less than ten seconds from its
first edit, and contains at most 64 inserted/deleted UTF-16 code units. The
next edit at the age/idle boundary, beyond the size budget, or after a reversed
test clock starts a new group. The ten-second/64-unit bounds retain short
phrases while limiting continuous-work loss independently of the 100-entry
history limit. Group IDs include a process-wide editor-session sequence.

Typing, backspace and forward deletion have separate groups. A single-unit
operation is validated at its actual old/new carets, including ambiguous runs
of repeated characters. A selection replacement, caret relocation,
line/paragraph change, explicit Source command,
paste, cut, formatting, search replacement, spelling correction and inspector
transaction close continuous typing. Structural rich operations already publish
discrete transactions. Source observes caret moves as they happen, so leaving
and returning to the same offset cannot reconnect a typing group. IME
composition retains its existing input and command
guards.

Each editor tracks its last accepted source/revision independently of parent
frames. Live shared-history identity distinguishes same-content save metadata
from traversal. Closing a group at the same revision preserves the accepted
content while starting a fresh transaction, including Source-to-Split input
before a parent frame. Controller publications also carry expected source/revision
preconditions. Consecutive edits advance that accepted base synchronously;
Undo/Redo or a different authoritative source invalidates it. The rich editor
reconciles after keyboard traversal immediately and on authoritative rebuilds,
including an A → B → A cycle that never rendered B in the parent. Rejected
publications reconcile the editor, and only accepted structured documents enter
the workspace cache. Uncontrolled rich widgets can change navigation properties
while retaining the same document object. Save As also updates the mounted rich
editor's publication path.
Source also applies the live readers' text and caret during reconciliation: an
unrelated rebuild carrying older properties cannot roll back an accepted edit
or restore a retired selection.
Its document-keyed field owns a matching focus-node lifetime. Reusing the old
focused node after field disposal leaves its keyboard token consumed and its
native text-input client cleared; document changes create a fresh node while
ordinary edits retain it.

Rich edits publish their live pre-edit caret or document range before opening
the transaction. Stable text inputs also publish their resulting position
synchronously. Traversal restores selections immediately, including table-cell
ownership; deferred mounting and scroll restoration may proceed only while that
selection is still current. A later caret move or edit supersedes that callback.
This keeps no-frame Undo/Redo bursts and formatting ranges independent of the
normal post-frame session publication.

Source clipboard and link operations retain an editing-epoch token as well as
their origin value. Content, selection, composition and controller lifetime
changes retire the token, even when Undo/Redo returns to the same value before
a rebuild. A supplied live document reader also validates the accepted version
after asynchronous work. Metadata-only acknowledgements do not retire an origin.

`DocumentBuffer.replaced` makes an actual whole-source replacement one undoable
boundary. It preserves displaced source, selection, rich session and text-format
metadata, closes grouping and clears the displaced redo branch. Reload, clean
file-monitor replacement, workspace refresh, remote replacement and discard use
that boundary. Workspace refresh reconciles the replacement with the live editor
state rather than reattaching its old history. Same-content refresh/save and
derived rendering retain valid history. Traversal restores BOM, line endings and
final-newline metadata together with source and caret.

## Recovery before traversal

Before observing a successful Undo or Redo, Local History stages a separate
`beforeHistoryTraversal` protection for the source being left. Each unresolved
source has a distinct retained-work owner; subsequent traversal, a branching
edit, or another protective operation cannot replace it. The ordinary pending
checkpoint still follows the latest source on its fixed `putIfAbsent` timer.
The checkpoint window is not a debounce.

A bounded set deduplicates repeated source/format protections per document
identity and recording epoch. That set contains metadata only: unresolved full
sources remain independently owned even if a deduplication key ages out.
Under its existing capture lock, the store also lets traversal protection reuse
any exact source/format revision in the same lineage. Ordinary checkpoints keep
their adjacent-only deduplication rule and timeline semantics.
If committed revisions share a timestamp, adjacency chooses the later appended
revision; the clock tie must not select an older baseline and duplicate a
checkpoint that protection already stored.
Recording-disabled and excluded documents create no traversal captures. Existing
failure banners, checkpoint-cadence retries, retained-work journals and startup
policy hydration remain in use.

The first Undo after typing into an empty untitled buffer establishes its normal
baseline before binding the independent protection. It retains the single
history lineage that this case already had before the traversal repair.

Undo/Redo is synchronous. Staging a protection in memory does **not** establish
crash durability. A recoverable boundary is reached after a successful retained
session-journal publication or Local History record publication. Required close
and shutdown settlement still drain that work and retain failures. A process
terminated before either publication completes can lose the newest in-memory
protection. The restart regression reads a fresh on-disk session journal before
retiring its original controller, then verifies both unresolved pre-traversal
sources in Local History and the latest branch in dirty-document recovery.

## Document-history regression cases

The maintained suites exercise these state transitions through production
editors/controllers and real keyboard or action dispatch:

| Trigger | Required result |
| --- | --- |
| Fifteen minutes of one-second typing, including Source line breaks | Multiple finite groups; one Undo removes only the latest group. The injected clock is actually read by grouping. |
| Editor recreation, mode and tab return | A new typing transaction preserves earlier work. |
| Focused Source switches documents and returns | Native text input remains registered; raw keys reach the shared source. |
| Repeated exhausted shortcuts and platform actions | Source, revision, dirty status, stacks and pending checkpoint remain unchanged. |
| Type then Undo before a frame; immediately type again | Visible controller, rich projection/cache and shared source agree; restored content is not overwritten. |
| Source traversal invoked outside its keyboard handler | Historical caret is restored on the authoritative rebuild. |
| Caret moves away and back between two characters | The second character belongs to a new transaction. |
| Rich traversal before a frame, including table cells and formatting ranges | The live position, serialized model and shared session agree; a deferred restore cannot overwrite a newer caret. |
| Delayed Source paste, cut or link choice across Undo then Redo | The retired completion makes no edit, even when text, selection and widget revision match again. |
| Reload, monitor, workspace or remote replacement with both stacks populated | Replacement is undoable, the inappropriate redo branch is gone, displaced content survives. |
| Undo before checkpoint, then a new branch, with autosave on/off | The original pre-Undo work survives close/reopen. |
| Delayed/failed captures and multiple protections | Each obligation survives independently; a fresh disk-backed restart can finish recovery. |
| Same-content save/reload, composition and pending inspector draft | Existing editing, redo and ownership contracts remain intact. |

The Source remount regression predates these repairs. WYSIWYG's exhausted
**keyboard** route already consumed no-ops; its Flutter action routes still
needed ownership overrides. Clipboard origin/selection checks, AI
proposal identity/revision checks, inspector draft guards, the fixed checkpoint
window and settings-before-pruning startup protection remain authoritative.

A native acceptance target boots the production application and injects XTest
keys through GTK. It verifies content in the shared buffer, visible field, live
rich serialization, saved files and actual Local History records. It also exercises
mode/tab return, autosave, close/reopen, Local History restore and conflict-aware
reload. Use a disposable X11 display and isolated XDG directories:

```sh
flutter build linux --release --no-pub -t tools/document_history_smoke.dart
# Create OUTPUT/data, config, cache, state, run and tmp first; chmod 700 OUTPUT/run.
# Set each XDG_*_HOME and XDG_RUNTIME_DIR beneath the absolute OUTPUT directory.
BUSYMARK_HISTORY_DISPOSABLE=1 GDK_BACKEND=x11 WAYLAND_DISPLAY= \
  dbus-run-session -- xvfb-run -a -s '-screen 0 1440x1000x24' \
  build/linux/x64/release/bundle/busymark /absolute/OUTPUT
flutter build linux --release --no-pub -t lib/main.dart
```

Keep the resulting logs and `result.json` outside the repository. A widget pass,
a generated report before all assertions finish, or a controller-only call is
not native acceptance.

## Clipboard publication and ownership

`RichClipboardService` serializes clipboard reads and writes and owns the
current BusyMark rich payload independently of `ClipboardHistoryController`.
Each publication sends three interoperable representations in one Linux host
operation:

| Representation | Contract |
| --- | --- |
| `application/x-busymark-token` | Resolves immutable structured content only in the originating BusyMark process and session. |
| `text/html` | Preserves supported semantic formatting for other applications. |
| Standard GTK text targets | Supports text-only destinations and paste without formatting. |

The token maps to a bounded in-memory payload; unknown or stale tokens are
external data, and matching text is never proof of ownership. Clearing retained
history does not invalidate the current rich clipboard.

The GTK host owns immutable payload bytes, rejects a read if the clipboard owner
changes during transfer, and limits transfers to 16 MiB. It advertises formats
for clipboard-manager persistence. Hosts without the Linux method channel fall
back to Flutter's plain-text clipboard.

`WysiwygClipboardFragment` uses a bounded, versioned, validated JSON schema.
Insertion regenerates block IDs, rebases relative links, and ingests retained
local media through the destination document's asset path. `WysiwygClipboardHtml`
exports semantic HTML and imports only supported structure, safe URLs, emphasis,
and task state; executable markup is discarded. Unsupported input follows the
existing plain-text fallback.

Copy and cut snapshot the selection before asynchronous publication. Cut deletes
only after a successful write and after revalidating the document, active target,
and selection. Paste uses the same revalidation and normal one-step undo path.

Live clipboard paste and Clipboard History use one ordered resolver. Editor and
Markdown Source share the same semantic interpretation; only the final inserted
representation differs. Plain-text mode consumes only interoperable text, never
source markup, HTML, rich fragments, or media. Paste revalidates both its target
and, when native image acquisition crosses a second platform boundary, clipboard
identity around asynchronous work.

Source fragment insertion uses the Markdown serializer's inline entry point,
including block-start and table-cell escaping, without document-level trimming.
Destination source is parsed after modeling the captured replacement: complete
non-paragraph fragments remain blocks, enclosing inline styles are reconciled
within the smallest changed source range, and table-cell serialization is used
only for a selection contained by one cell. Raw/code protection and list or
blockquote continuation apply only to structure that survives the replacement.

The Source widget is the asynchronous execution shell: it captures and
revalidates the target, prepares assets, commits one edit, restores focus, and
reports Undo and retention. `SourcePasteEngine` is pure planning over an
immutable source snapshot and returns one of ready, try-next, or stop; its ready
result includes the expected source identity, exact replacement bounds, and
final caret. `MarkdownSourceMapper` owns source/logical/semantic projections,
while `MarkdownAstAdapter` remains the ordinary semantic converter. Raw HTML is
converted as one safe parser fragment and gains optional occurrence metadata at
that conversion boundary. Position probes are operation-local and never define
HTML, links, attributes, references, or whitespace classification.

Inline serialization has one syntax-emission path. Ordinary serialization and
serialization with caret or break provenance differ only in requested output
bookkeeping, so identical content and options must produce byte-identical
source. Standalone HTML-break layout is indexed once per snapshot; retained
breaks keep their own source occurrence, line ending, and container prefix.

Paste outcomes distinguish insertion, cancellation, stale targets, unsupported
representations, and unavailable targets. Cancellation and staleness terminate
candidate processing. All paste mutations are discrete external-history
transactions and invalidate continuous-typing groups; active IME composition is
checked at entry and again immediately before mutation. Newly published assets
are removed after cancellation or invalidation, while reused assets are kept.

## Clipboard retention

`ClipboardHistoryController` retains successful BusyMark copy/cut payloads and
supported external content only after a successful paste. Payloads contain their
origin metadata, available representations, a SHA-256 equivalence fingerprint,
and byte accounting. The default policy is 100 entries, 64 MiB total payload,
and 8 MiB of decoded thumbnails. Deduplication compares every meaningful
representation.

The editor adapter that completes a successful paste is the sole retention
owner. Candidate helpers return capture data but never retain it, the history
panel never performs a second write, and the insertion registry only restores
focus. Image-path captures use the immutable bytes returned by ingestion rather
than reopening the original file. Plain-text paste may retain the original
external snapshot after success but never probes richer fields for insertion or
acquires image bytes to enrich it.

The insertion registry exposes only the latest mounted editable surface and uses
identity-safe unregistering. An adapter must capture and revalidate its document,
revision, mode, selection generation, and target lifetime around asynchronous
work.

## Local History capture and identity

`LocalHistoryController` treats each `DocumentBuffer` as the source authority.
Capture events are baseline, explicit save, automatic checkpoint, before reload,
before discard, before restore, before delete, before Undo/Redo, and observed
external change.
Autosave writes do not create their own history reason.

Observation is serialized per buffer. The first edit starts a fixed checkpoint
window; later edits replace the one pending full-source snapshot without moving
the deadline. A flush is a queue barrier. Retryable ordinary checkpoint failures retain the latest pending source for
that buffer. Independent protective sources also remain retained; retries use
the configured checkpoint cadence. Unsupported or over-limit content fails visibly without a retry loop.

History identity is independent of widgets and temporary buffer IDs. Known file
and directory moves remap paths while preserving earlier paths. The first save
of an untitled document continues its lineage. Save As keeps the source lineage
separate and starts or appends to the destination lineage, protecting an
existing destination before publication.

## Store and retention

Production revisions live under `local_history` in the platform application
support directory. Store format 1 uses an index, independently recoverable and
checksummed full-source JSON records, and a tombstone journal. Record identifiers
and paths are validated beneath the history root.

Writes are serialized in process and protected by an exclusive cross-process
file lock. A complete record is published on the same filesystem before its
index entry. Recovery scans intact records and observes tombstones so retention
and explicit clearing cannot resurrect removed content. Unknown future store
versions fail explicitly. Retention runs after successful capture and protects
the newly written or protective record.

## Comparison and restore safety

Local History scopes ordinary browsing to the active buffer. Scope, snapshot,
and query generations prevent a delayed read or search from publishing into a
new document scope. Shared Local History search discovers retained identities independently of
ordinary browsing, including identities that no longer have an open file.

`SourceComparisonInput` identifies immutable source versions. Comparison uses
patience anchors, bounded local LCS, and intraline refinement in Dart UTF-16
offsets. When an unanchored region exceeds the work bound, the comparison is
marked simplified and exact region restore is disabled.

A restore request owns the history document, revision, current buffer, source
revision, source text, and selected range. It first persists a protective
snapshot, then revalidates those values after every await and applies one
`DocumentBuffer.edited` transaction. Cancellation of a required protective
capture is a failed restore, not successful protection.

Lifecycle operations flush accepted history work before close, workspace
replacement, or shutdown. Clear invalidates affected queued work when the clear
is accepted, so an older checkpoint cannot recreate erased revisions.

## Verification

Keep manual-probe outputs outside the repository, for example in directories
created with `mktemp -d`. Use disposable workspaces for probes that edit files,
and remove their temporary data after inspection.

Run the standard checks with the repository-pinned toolchain:

```bash
flutter analyze
flutter test
```

The native clipboard probe verifies same-process rich-token resolution and
cross-process HTML/plain-text interoperability:

```bash
flutter build linux --debug -t tools/clipboard_smoke.dart
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  roundtrip OUTPUT_DIRECTORY
```

For the inter-process case, run `write OUTPUT_DIRECTORY`, keep it running, and
run `read OUTPUT_DIRECTORY` from a second process on the same display. Create
`OUTPUT_DIRECTORY/stop` to close the writer, then run `plain OUTPUT_DIRECTORY`
to confirm that an external plain-text owner does not inherit stale rich
formats. Rebuild the default entry point afterward.

The production-controller visual probe uses disposable workspaces:

```bash
flutter build linux --debug -t tools/history_visual_smoke.dart
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  markdown WORKSPACE PRIMARY_FILE DELETE_FILE OUTPUT_DIRECTORY
GDK_BACKEND=x11 build/linux/x64/debug/bundle/busymark \
  writerside WORKSPACE PRIMARY_FILE - OUTPUT_DIRECTORY
```

Under `xvfb-run`, set `GDK_BACKEND=x11` explicitly so an inherited
`WAYLAND_DISPLAY` cannot select an unrelated Wayland connection. Clipboard
behavior under Wayland requires a compositor-driven run with real input focus.

The native selection probe covers pointer/keyboard selection, highlight
geometry, rich/plain clipboard content, table boundaries, editing, undo and
restored selection. It copies the maintained fixture before use and exercises
the production editor and Linux clipboard:

```bash
selection_output="$(mktemp -d)"
flutter build linux --debug --no-pub --target tools/wysiwyg_selection_smoke.dart
GDK_BACKEND=x11 dbus-run-session -- \
  xvfb-run -a -s '-screen 0 1440x1000x24' \
  build/linux/x64/debug/bundle/busymark \
  test/fixtures/wysiwyg/selection_boundaries.md "$selection_output"
flutter build linux --debug --no-pub --target lib/main.dart
```

The probe exits nonzero on failed assertions and writes temporary captures and
JSON reports for inspection. Its optional `--application` mode opens a supplied
file in the full application and requires the exact synthetic table fixture
checked by the driver; use an isolated application profile and disposable files
for that mode.

Session and recovery JSON publication protects each staged inode before its
atomic rename. Linux performs permission changes off the UI isolate through a
held descriptor. Configured directory links are followed and their targets
pinned; final state-file links are rejected. Retargeting a pathname cannot
redirect an admitted permission change. Unreadable inodes use the same held
identity through procfs. Permission or inspection failures fail the transaction;
private modes, lock ownership, flush and recovery ordering remain mandatory.

Startup capture and pruning wait for the saved History policy. Restoration
reads at most four files concurrently, preserves session order and drains
admitted reads after a failure. Adopted recovery remains protected until
restoration and required persistence finish, including when close is requested
before an editor is published.

Opening can display validated content while Recent persistence completes. A
failed Recent update remains a warning after a successful open or save. Settings
writes retain ordered completion and retry failed publications; shutdown drains
the queue before retiring recovery ownership.

## Shared Local History search

`SearchCategory.localHistory` owns the header query and optional retained-document
ID. `findRetained()` reads the existing store and returns bounded document or
revision metadata without changing browsing, comparison, recording or buffer
ownership. Each request checks cancellation and the retained snapshot generation;
clear and account removal invalidate affected results. Revision bodies are read
sequentially and discarded after matching, rather than kept in widget state.

Activation revalidates stable document/revision IDs and checksum before the
existing comparison workflow reads a revision. Its selection callback also checks
the originating search request after the read. Ordinary History navigation keeps
the complete timeline and has no search entry points or private query controller.
The shared coordinator retains explicit removable document scopes independently
of the browsing panel.
