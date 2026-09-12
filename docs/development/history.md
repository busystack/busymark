# History implementation notes

This document records the invariants behind the user-facing
[Clipboard History and Local History](../history.md) features.

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

## Clipboard retention

`ClipboardHistoryController` retains successful BusyMark copy/cut payloads and
supported external content only after a successful paste. Payloads contain their
origin metadata, available representations, a SHA-256 equivalence fingerprint,
and byte accounting. The default policy is 100 entries, 64 MiB total payload,
and 8 MiB of decoded thumbnails. Deduplication compares every meaningful
representation.

The insertion registry exposes only the latest mounted editable surface and uses
identity-safe unregistering. An adapter must capture and revalidate its document,
revision, mode, selection generation, and target lifetime around asynchronous
work.

## Local History capture and identity

`LocalHistoryController` treats each `DocumentBuffer` as the source authority.
Capture events are baseline, explicit save, automatic checkpoint, before reload,
before discard, before restore, before delete, and observed external change.
Autosave writes do not create their own history reason.

Observation is serialized per buffer. The first edit starts a fixed checkpoint
window; later edits replace the one pending full-source snapshot without moving
the deadline. A flush is a queue barrier. Retryable storage failures retain only
the latest pending source for that buffer and retry on the configured checkpoint
cadence. Unsupported or over-limit content fails visibly without a retry loop.

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
new document scope. Store-wide document search is a temporary discovery mode
for retained identities that no longer have an open file.

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
