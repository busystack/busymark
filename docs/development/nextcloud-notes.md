# Nextcloud Notes on Linux

BusyMark treats a Nextcloud Notes workspace as the notes in one Nextcloud
account. The SQLite database and managed attachment files are implementation
details for offline editing, recovery and synchronization; they are not another
workspace. Existing local Markdown and Writerside storage paths remain separate.

## Supported API contract

The implementation targets **Notes API 1.4** in major version 1, including
Notes **6.0.x** and **6.1.x**. Attachment deletion additionally requires Notes
**6.1.0** or later. Server compatibility depends on the installed Notes app and
its advertised capabilities.

Upstream contract references:

- [App Store](https://apps.nextcloud.com/apps/notes) and
  [stable release](https://github.com/nextcloud/notes/releases/tag/v6.1.0).
- Stable-tag [API overview](https://github.com/nextcloud/notes/blob/v6.1.0/docs/api/README.md),
  [API v1](https://github.com/nextcloud/notes/blob/v6.1.0/docs/api/v1.md),
  [routes](https://github.com/nextcloud/notes/blob/v6.1.0/appinfo/routes.php),
  `NotesApiController`, `Helper`, `Note`, `NotesService`, `NoteUtil`, `Util`,
  `MetaService`, `Application` and `Capabilities`, API tests and
  `playwright/e2e/attachment-api.spec.ts`.
- [Login Flow v2 and password revocation](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/LoginFlow/index.html),
  [OCS authentication/capabilities](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/OCS/ocs-api-overview.html).
- Notes issues [1940](https://github.com/nextcloud/notes/issues/1940),
  [2037](https://github.com/nextcloud/notes/issues/2037),
  [1955](https://github.com/nextcloud/notes/issues/1955),
  [1999](https://github.com/nextcloud/notes/issues/1999),
  [1990](https://github.com/nextcloud/notes/issues/1990),
  [2046](https://github.com/nextcloud/notes/issues/2046) and
  [2056](https://github.com/nextcloud/notes/issues/2056).

Compatibility is capability-driven: **Notes API major 1, advertised minor >=4**.
There is no Notes application-version minimum for connection. Missing or malformed
`notes.version` does not prevent an API 1.4 account from connecting. Unknown
capability fields are ignored. No API <1.4, deprecated 0.2, or other protocol is
implemented.

The tagged `lib/AppInfo/Capabilities.php` and `appinfo/routes.php` establish
the supported baseline alongside `docs/api/README.md` and `docs/api/v1.md`:

| Tag | Commit | API capability | Attachment endpoints |
| --- | --- | --- | --- |
| v6.0.0 | `91912ec40b05705f5fa714c2f6ef857480e5e91e` | 0.2, 1.3, 1.4 | GET, POST |
| v6.0.1 | `6cb67c3645acad9c5757b47ffc819a6f158646c5` | 0.2, 1.3, 1.4 | GET, POST |
| v6.0.2 | `d2916b499c3c72e323b1a0db6191661178d683a6` | 0.2, 1.3, 1.4 | GET, POST |
| v6.1.0 | `0c3dd46dbd781b780c1ea60a13873198609bb98d` | 0.2, 1.3, 1.4 | GET, POST, DELETE |

Notes 6.0.x is a supported baseline. The documentation's claim that API 1.4
arrived in 6.1 conflicts with the tagged 6.0.x implementation; the advertised
capability and routes establish the contract. Version numbers gate only the
exceptional DELETE feature, whose unversioned addition is recorded in
[upstream #2037](https://github.com/nextcloud/notes/issues/2037).

CRUD uses `index.php/apps/notes/api/v1/notes[/ID]`. Attachments use
`index.php/apps/notes/api/v1.4/attachment/ID`; do not change all CRUD to `v1.4`.
The response `X-Notes-API-Versions` header is understood without selecting legacy
implementations. Attachment deletion requires the Notes 6.1.0 application
baseline as well as API 1.4: deletion was added without an API version bump.
Unknown/malformed/prerelease app versions conservatively disable DELETE. An
unsupported cleanup attempt explains the limitation before queuing any operation;
notes and attachment upload/download remain available.

## Authentication and credential boundary

Anonymous Login Flow v2 opens the returned URL with `url_launcher` in the default
external browser, polls the returned endpoint, accepts documented `404` pending
responses, and supports cancellation/expiry. The returned canonical server URL
and exact `loginName` are used. URI construction preserves an installation
prefix such as `/nextcloud`; unsafe userinfo, query, fragment and malformed URLs
are rejected. HTTPS is required, including for loopback and LAN addresses. HTTP is rejected
before Login Flow or authenticated requests, including persisted HTTP accounts.
Private certificate authorities must be installed in the OS trust configuration;
there is no verification bypass or insecure-setting switch. Redirect following is disabled for credentialed
requests. Neither credentials nor note contents appear in diagnostic errors.

App passwords are stored only in Linux libsecret through BusyMark's existing
native bridge. A separate Nextcloud schema and strict
`busymark.nextcloud.account-password.<UUID>` key
policy preserve the existing AI credential schema/whitelist. The stable random
account UUID, server, login name and nonsecret capability/checkpoint metadata live
in SQLite. A missing/locked keyring fails safely; there is no plaintext fallback.

Disconnect tries the documented `DELETE ocs/v2.php/core/apppassword` with
`OCS-APIRequest: true`, then removes the local keyring entry and account/cache
state. Failed server revocation is reported; the user can revoke the app password
in Nextcloud's security settings. Removal fences active synchronization before
deleting account state. This is ordinary local deletion, not a cryptographic
secure-erasure claim. The confirmation explains that unsynchronized work is
removed. Local history follows the existing retention policy.

## Document and persistence model

`DocumentOrigin` distinguishes untitled, local-file and Nextcloud documents.
`NextcloudNoteReference(accountId, localId)` provides stable logical identity
independent of title, category, server ID or cache location. Remote buffers have
no `filePath`, are not untitled, and remote workspaces have no filesystem root.
Parser labels are logical identifiers only. Remote workspaces install no disk
watchers, discover no Git repository and expose no path/file-manager actions.

`NotesStore` uses direct `sqlite3` 3.7.0 in a dedicated isolate under application
support storage. Schema version 2 includes accounts, notes, a coalesced per-note
outbox and attachment metadata/bytes. The v1 → v2 migration retains existing
records and adds optional creation-attempt metadata in note/outbox JSON; the
version fence prevents older clients from discarding it. Existing uncertain
creations without that metadata remain unresolved. Migrations use transactions and reject
newer unsupported schemas. SQLite uses WAL, `synchronous=FULL`, foreign keys and
a busy timeout. Notes content, revision, base state, outbox and synchronization
checkpoint commit atomically. The Notes directory is mode 0700 and database
0600 on Linux. Managed attachment paths reject traversal and symbolic links.
The database is not encrypted. This is a dedicated Notes integration, with no
general account-provider framework.

An editor revision is saved only after its local transaction succeeds. HTTP
acknowledgment is a separate operation. Save, Save All, autosave, recovery,
history restoration and in-memory editor mutations use the same controller /
repository boundary. Session version 2 persists tabs, remote identifiers and
editor UI state; existing path-based version 1 sessions remain readable. Remote
content and pending operations have one authority, SQLite, rather than a second
copy in session/recovery JSON. A clean shutdown may retain a durable outbox.

## Synchronization and conflicts

`NotesApiClient` takes an injectable HTTP client. `NotesRepository` serializes
local mutations and runs at most one synchronization pass per account. The
controller requests a subsequent pass when another local save commits during
an upload. Transient network/server/lock failures receive six delayed retry
attempts (5, 10, 20, 40, 80, 160 seconds), then explicit Refresh remains available.
Conflicts, uncertain creation, authentication and forbidden errors require
deliberate resolution.

List synchronization sends `If-None-Match`, the **previous server
Last-Modified** as `pruneBefore`, `chunkSize` and the opaque chunk cursor. Header
names are case insensitive. Unchanged/pruned note IDs remain in the complete
set. Only completion of the final chunk permits deletion inference and a new
checkpoint transaction. An interrupted sequence does neither. The workstation
clock is never substituted for the server checkpoint.

Each note retains the complete acknowledged base, raw JSON ETag, current local
state, local revision, acknowledged revision and any conflicting remote state.
PUT sends **a quoted raw ETag**, exactly as stable `Helper.php` expects. A `412`
retains base/local/remote and blocks automatic overwrite. The comparison UI
offers taking remote, deliberately keeping local against a freshly fetched
server state, recovering as a new note, and manual merge. Merge compares content,
title, category and favorite independently against the acknowledged base. It
preserves remote-only and local-only changes and accepts identical changes.
Divergent title/category/favorite values require explicit local/remote choices;
the Merge action remains disabled until they are supplied. Content uses the
existing comparison/editor. A boolean favorite cannot have two different changes
from one known boolean base; a missing base still requires a choice when values
differ. IDs, ETags and read-only flags are never user-merged. Acknowledgment applies
to the revision actually sent; newer local edits stay pending. Canonical
server-returned titles/categories are adopted without overwriting newer edits.
Editor revisions and their content digests are tracked independently of storage
revisions so delayed recovery snapshots cannot undo later saves. Conflict
resolution checks both the displayed local revision and a freshly fetched remote
ETag; another change requires another review.

When the refreshed note is read-only, conflict resolution may still retain or
choose `favorite`, provided resolved content, title and category exactly match
the refreshed server state. Any resolution that would write a protected
attribute remains forbidden.

Each open editor also retains its acknowledged server base and the repository's
server-observation generation. A list response received before the persistence
debounce cannot advance an unsaved editor's base. Saving that editor after an
external change atomically retains its original base, local content and the
downloaded remote state as a conflict. Acknowledgments of BusyMark's own writes
do not advance that generation, so a newer edit made during upload can continue
from the acknowledged write without a false conflict. This provenance is
ephemeral editor state; the resulting durable conflict lives in SQLite.

New notes commit locally before POST. Immediately before the request, one
transaction persists its random attempt ID, captured local revision/content,
**exact JSON wire body** (transformed content, title, category, favorite, explicit
writable `modified` timestamp), and the complete pre-request server ID set.
Staged attachment references remain in local editor content but are stripped
from the recorded wire content. There is no hidden Markdown marker.

There is no documented create idempotency key. A transport failure, malformed
response or 5xx after creation enters `creationUncertain`; restart after an
in-flight create does the same. Reconciliation requests an unpruned collection.
A plausible candidate has an unseen ID and equal wire content, favorite and
modified. Exact and sanitized payload matches only rank possible candidates;
they never establish identity. Every uncertain outcome remains blocked across
refresh, reconnect, autosave and restart, including a single identical nonempty
candidate and an empty result. Discovery persists candidates without binding,
acknowledgment, clearing the attempt or permitting PUT, DELETE or publication.
An independently created identical note cannot be distinguished by its payload.

The comparison presents the selected server ID, title, category, modification
time and content. **Use this server note** explicitly links the draft and then
synchronizes retained local edits. Confirmation supplies an immutable review
containing the draft revision, account, attempt identity and selected state.
The repository fetches that ID through the authenticated account and compares
all state fields, including permissions. Changed, unavailable, missing or
read-only candidates stay unresolved and need another review. Account removal,
new local revisions and repeated confirmation invalidate the decision.

Binding preserves the draft's logical identity and history. The fresh server
ID/base/ETag and outbox commit with removal of a clean downloaded duplicate in
one SQLite transaction. Durable duplicate edits and pending attachment
operations block consolidation. Every workspace controller also registers an
open-tab guard; candidate tabs must be closed after preserving their work.
Reserved candidates cannot be opened during confirmation. The same commit-time
editor guard rejects unsaved draft edits that arrived during the confirmation
GET, requiring another review. Newer draft edits and staged bytes remain
pending through the existing ordered attachment/update pipeline, and subsequent PUTs retain If-Match protection.

**Create a separate note** warns that the first request may already have created
a server note. The explicit decision durably records one replacement identity
and copies recoverable work and attachment bytes atomically. Concurrent clicks
are rejected and repeated confirmation reuses that replacement. The original
uncertain draft remains recoverable and blocked. Cancel and dismissal leave it
untouched. No suspected server duplicate is automatically deleted. Legacy
uncertain records without creation evidence cannot be adopted by guessing;
the existing database migrations and startup recovery remain unchanged.

Read-only notes block content/title/category editing while favorite remains
writable under the documented contract. A note becoming read-only does not
discard edits already captured locally. `error: true` responses carry unavailable
state; their exception-text content never replaces known-good cached content.

Errors are classified as reconnect required (401), forbidden/read-only (403),
missing/deleted (404), conflict (412), locked (423), insufficient storage (507),
transport/offline, server errors and safely reported unknown responses. A locked
note retains its content and outbox and does not prevent unrelated notes from
synchronizing. Issue 1940 describes locks retained by Notes/Text editing sessions;
the client cannot remove those server locks or claim live collaboration.

## Deletion and recovery

Notes DELETE has **no atomic If-Match contract**. Explicit deletion first obtains
fresh remote state and compares it to the acknowledged state; changed notes
require conflict resolution. Failed deletion preserves content. Local history
is captured before loss and tombstones remain recoverable. There is an
unavoidable **refresh → DELETE race** if another actor changes the note between
those requests; BusyMark does not claim a guarantee the server cannot provide.
Destructive offline server deletes are not queued for blind replay.

Remote disappearance without pending work can be reconciled normally. Local
pending work plus remote deletion stays visible for explicit recovery/discard.
History uses the stable logical UUID identity, and restoring a revision is a new
local edit. Deleted-note history can create a new note under the original
account. Save As/export creates a separate local copy without converting or
detaching the live remote note.

## Attachments, media and export

Selected bytes and operations are durable before upload. An offline new note is
created first; uploads then use its acknowledged server ID. The authoritative
multipart response `filename` is retained, including deduplication/renaming.
Publication conditionally replaces namespaced `busymark-attachment:` references
with the returned filename, using the current ETag. API 1.4 on Notes 6.0.x
returns flat randomized filenames; Notes 6.1.x returns `.attachments.ID/filename`.
Both are accepted, while foreign note folders and traversal are rejected. Each significant stage
survives restart. Uncertain upload outcomes require deliberate retry/adoption
and may leave a server orphan; they are not silently repeated. Attachment
deletion operations retain their durable ordering and version gate.
Only actual Markdown/HTML destinations are rewritten; namespace text in prose or
code remains literal. History restoration can restage deleted attachment bytes,
and recovery as a new note clones managed bytes under the new logical identity.
Neither operation reuses another note's attachment ownership.

Attachment downloads have a dedicated streaming path and share the existing local
asset ingestion limit, `maximumManagedAssetBytes` (**100 MiB**). Advertised
Content-Length is checked before consuming the body; actual streamed bytes are
also counted. Missing lengths are supported, mismatched lengths fail, and
zero-byte attachments are allowed. Data goes into a private temporary file,
flushed and atomically renamed only after successful completion. Cancellation,
network failures and oversized responses cancel the stream and remove partials.
No attachment uses the generic buffered JSON response path. Completed bounded
files are imported into SQLite on its worker isolate; materialization likewise
runs there, with streaming hashing outside the UI isolate's synchronous work.
Recovery may read a completed, bounded file into the existing blob model.

Media requests coalesce at the repository boundary by account, note and canonical
destination. The final cache insertion rechecks ownership and tombstones inside
the local mutation queue, after the network request. Successful deletion removes
materialized media files and invalidates existing editor/export contexts; retained
database bytes are available only for explicit recovery. An acknowledged new
upload may reuse a deleted filename. Existing duplicate cache rows are handled
by deletion without issuing multiple remote deletes.

`DocumentMediaContext` and provider ingestion/resolution are shared by source,
WYSIWYG, preview and export. A remote note cannot use local absolute paths,
`file:` URLs or traversal to read Linux files. Provider references resolve only
within account/note-managed storage. External HTTPS images use existing image
privacy policy and receive no Nextcloud authorization. Stored Markdown never
contains private cache paths. Markdown copy exports stage companion attachments;
destination replacements use exact parsed ranges, including reference definitions,
so prefix-sharing filenames remain distinct and literal examples stay unchanged.
HTML packages managed downloadable files as well as images. PDF embeds supported
images and prints downloadable attachment labels; it does not embed binary file
attachments. OpenAPI permits inline/internal references in remote notes;
external filesystem references are rejected before any local file read.
Diagram source attachments use bounded provider-resolved UTF-8 text. Preview,
WYSIWYG, HTML and PDF share this resource boundary. Filesystem/Writerside project exports and
workspace-wide search/replace are explicitly unavailable for Notes; per-note
search/replace uses the normal editor and save pipeline.

## Verification

Focused tests cover authentication/URI/capabilities/keyring failures, mocked
protocol errors, incremental chunk/checkpoint invariants, optimistic conflicts,
revision races, uncertain creation, transactional restart/outbox recovery,
attachment stages/media security and BusyMark save/session/history/export/UI
integration. Native probes cover the credential whitelist and actual libsecret
create/read/delete in an isolated keyring.

Run the existing automated coverage from the repository root:

```bash
flutter test --no-pub test/src/nextcloud_notes test/src/nextcloud*_test.dart
bash tools/test_secure_credential_policy.sh
bash tools/test_nextcloud_libsecret.sh
```

The libsecret probe requires development headers, `pkg-config`, a C++ compiler,
D-Bus, and `gnome-keyring-daemon`; it creates an isolated temporary keyring.
Run `flutter test --no-pub` for the shared editor, session, history, export and
packaging regressions as well.

For live acceptance, use an isolated HTTPS test account and keep credentials
and reports outside the repository. The browser harness requires Python
`requests`, Playwright and Chrome. Its account JSON contains `server`, `user`
and `password`; it writes private app credentials containing `server`,
`loginName` and `appPassword` for the Dart harness:

```bash
acceptance_dir="$(mktemp -d)"
python3 tools/nextcloud_login_live_acceptance.py \
  /path/to/private-test-account.json "$acceptance_dir/app-credentials.json" \
  "$acceptance_dir/login.json"
dart run tools/nextcloud_notes_live_acceptance.dart \
  "$acceptance_dir/app-credentials.json" "$acceptance_dir/notes.json"
```

The Dart harness also accepts a third argument naming a test CA certificate.
It exercises disposable notes and attachments, including conflicts, offline
saves, restart, and explicit adoption after uncertain creation. Repeat against
the supported Notes 6.0.x and 6.1.x baselines when changing the API contract;
mocked tests alone do not establish live server compatibility. Keep the
checkpoint, revision, explicit-adoption and attachment ownership invariants
above covered, and remove temporary acceptance data when finished.

## Explicit non-goals

No Nextcloud Files, WebDAV, automatic protocol fallback, file browsing, embedded
Text/Direct Editing, private Text session/Yjs endpoints or live collaboration.
The current [Text source](https://github.com/nextcloud/text) and
[Direct Editing documentation](https://docs.nextcloud.com/server/stable/developer_manual/digging_deeper/direct_editing.html)
describe web-editor ownership and internal collaborative machinery, not a
documented supported external native collaboration API. A future official
native API would require a separate product decision.
