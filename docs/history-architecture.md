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
content is retained only after a successful document paste. History insertion
uses the normal Source or WYSIWYG transaction and asset-ingestion paths.

## Local History capture and identity

`LocalHistoryController` observes document buffers and schedules a fixed
checkpoint window per changed buffer. Capture events are baseline, explicit
saved content, automatic checkpoint, before reload, before discard, before
restore, before delete, and observed external change. Pending buffers are
flushed on close, workspace replacement, and awaited shutdown. Autosave writes
do not themselves create Saved entries.

History identity is stable independently of widget and transient buffer IDs.
Known file and directory moves remap current and descendant paths while
retaining historical paths. A first save of an untitled document continues its
lineage. Named-file Save As retains the source lineage separately and starts or
appends to the destination lineage; an overwritten destination is protected
before publication.

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

`SourceComparisonInput` identifies immutable sources by ID, version, label,
and text. The comparison uses unique patience anchors plus bounded local LCS
and intraline refinement in Dart UTF-16 offsets. Separated edits are retained.
When an unanchored comparison exceeds the work bound, the result is labeled
simplified and exact region restore is disabled.

Local History has its own `WorkspaceTabKind.localHistory`. The current side is
the live unsaved buffer when present, then a fresh disk load, or an explicit
missing-file state. Async results remain tied to both source versions. Restore
captures the target identity/path/revision/selection and exact range, persists
a protective snapshot, revalidates after awaits, and applies one
`DocumentBuffer.edited` transaction without replacing format metadata or the
undo stack.

## Verification workflow

Use the repository-pinned Flutter/Dart toolchain:

```bash
flutter gen-l10n
dart format lib test/src
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
```

When a probe is launched through `xvfb-run`, explicitly set
`GDK_BACKEND=x11`; a stale inherited `WAYLAND_DISPLAY` can otherwise make GTK
select Wayland, where clipboard publication requires a compositor input serial
that a headless probe does not have. The visual target writes PNGs and a JSON
report, and exits nonzero if any production clipboard, capture, comparison,
fragment-restore, deletion, or recovery check fails.

The current checkout is pinned to Flutter 3.47.2 / Dart 3.13.2. Available
native validation is Linux-only because the repository contains no Windows
runner or Windows plugin registration path.

Final verification for this implementation used the commands above plus the
cross-process writer/reader sequence on one X11 display. Localization
generation and formatting completed cleanly, `flutter analyze` reported no
issues, all 1,563 executed tests passed (with 12 existing intentional skips),
and the Linux release bundle built successfully. The compiled clipboard probe
reported:

- same-process: text, HTML, and session-owned rich resolution all passed;
- cross-process: text and HTML passed, and the foreign token did not resolve;
- external plain replacement: text passed with no stale HTML or rich payload.

The production-controller visual target completed both its Markdown light/en
scenario and its Writerside dark/ar scenario at 1280×800 and 1920×1080. Its
Markdown run also deleted, compared, and recovered a document. Reports and
captured frames are retained under `test-results/history-runtime/`.
