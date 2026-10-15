# Notes API coverage

Contract: Notes API **1.4**, verified Notes **6.0.2** and **6.1.0**. Direct Notes
API integration, one account, schema **6**, existing outbox/coordinator retained.

| Operation | Coverage | State boundary |
| --- | --- | --- |
| GET full `/api/v1/notes` | Chunk cursors, pruneBefore, collection If-None-Match, final ID-only entries | Only a completed authoritative collection advances checkpoints or infers deletion |
| GET `/api/v1/notes/{id}` | Complete 200 and conditional 304; quoted ETag; unconditional retry path when cache is absent | 304 reuses the captured server base, never acknowledges local edits/conflicts |
| GET filtered/reduced collection | Optional exact category and exclude parameters retained on every chunk; omitted fields represented by presence | Query-scoped projections, no full-account checkpoint/validator/deletion inference |
| GET reduced single note | Server-supported exclude projection; identity checked when included | Projection object, no fabricated NoteState defaults |
| POST/PUT/DELETE note | Existing durable outbox, optimistic conflict handling, uncertainty/retry evidence | Existing accepted synchronization strategy |
| GET/PUT settings | Existing conditional/concurrent settings handling and suffix normalization | Existing settings boundary |
| GET/POST attachment | Existing authenticated API 1.4 retrieval/upload and safe managed-reference publication | Existing ownership, generation and uncertainty protections |
| DELETE attachment | Notes 6.1.0 application capability gate retained | Existing unsupported-version explanation |
| Browser `/note/{id}` | Ordinary HTTPS web navigation, installation prefix, real server ID; public routing observation selects the configured pretty/front-controller form | Existing connected-account opening; cached offline or authenticated repository retrieval |

A category filter is exact on the supported servers; it is not a descendant
category synchronization strategy. Exclude can omit ID; ID-only entries repeated
by the final server chunk are continuation evidence, not complete projected
notes. Optional reads do not feed the full-account synchronization checkpoint.
The tagged helper always adds ETag and some internal server fields; projections
retain present fields rather than promising that every excluded server field
will disappear.

The public installation login page's explicit `modRewriteWorking` configuration
selects the web URL form. This anonymous, bounded request never sends account
credentials or follows redirects. A successful HTTP response from the other
form does not prove navigation: on a pretty-URL installation the Notes SPA can
open its most recent note instead. Browser acceptance verifies the intended
note ID and unique content. The optional cached route observation is stored in
the existing account JSON; schema 6 and synchronization checkpoints are unchanged.
BusyMark recognizes both pasted forms internally. Portable heading insertion
is disabled because the verified browser view does not expose BusyMark's heading IDs.

Deterministic retrieval tests are in
`test/src/nextcloud_notes/notes_retrieval_test.dart`; authenticated fixture checks
are in `tools/nextcloud_notes_live_acceptance.dart`. See the
[verification instructions](nextcloud-notes.md#verification) for running them
against isolated HTTPS fixtures.
