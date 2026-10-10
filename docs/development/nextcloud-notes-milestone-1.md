# Nextcloud Notes Milestone 1 implementation and evidence

## Baseline

- Branch `feature/nextcloud-notes-workspace`; initial HEAD `82590bf71abe89123185ba46ebdf754b2d62de02`; initial working tree clean. No applicable ancestor/repository `AGENTS.md`.
- Flutter **3.47.5**, framework `6a19cca564`, Dart **3.13.4**. Project/dependency/native pins retained. Initial locked resolution passed; no upgrade/reset.
- Existing invariants read in `nextcloud-notes.md`. Required tagged Notes v6.1.0 files fetched once to `/tmp/busymark-m1/upstream`, outside the checkout; relevant protocol/controller/settings/service/capability sections reviewed. Flutter lifecycle documentation and RFC 6585 §4 / RFC 9110 §10.2.3 reviewed before implementation.
- Prerequisites checked before implementation: no supplied authorized fixture credentials/CA; Docker available, cached `nextcloud:35-apache`, Linux X11 displays `:1` and isolated `:97`. Dedicated HTTPS fixtures provisioned rather than using ordinary accounts.

## Work packages and decisions

| Package | Implementation / evidence |
| --- | --- |
| Scoped errors and retries | Request scope distinguishes collection/settings/capability/note/attachment. Only note evidence establishes deletion. Rejections/permissions/quota block automatic writes; transient retry count and not-before deadlines persist. Delta/date Retry-After never shortened. Creates/uploads keep conservative uncertain outcomes for transport/5xx/invalid responses/locks. |
| Stranded work | Complete restoration listing reconciles poisoned server edits by ETag, with normal conflicts for divergence and no artificial acknowledgment. Drafts require positive durable never-sent evidence for automatic repair; ambiguous legacy histories retain bytes/outbox and expose deliberate separate-note recovery. Genuine complete-list/individual-note/deliberate deletion evidence remains protected. |
| Attachment paths/publication | Raw API filenames remain opaque; Markdown decodes once/encodes segments once. Query construction performs its own encoding. Authoritative upload path commits before reference replacement/conditional PUT, preventing duplicate upload after a local failure/restart. |
| Media freshness | Both byte cache and document context refresh. Remote note changes invalidate freshness; explicit Refresh revalidates active-note cached references even on 304; ordinary freshness is five minutes. Coalesced streaming waits remain outside mutation queue. Failed refresh keeps old bytes/validation time; generations fence removal/disposal/deletion/ownership and newer refreshes. Content-identity materialization removes superseded files. |
| Metadata/time/category | Immutable properties snapshot, changed-field patches, serialized three-way metadata merge, dirty editor saved normally, convergent/no-op changes create no revision. Accepted human edit time persists in microseconds; API modified uses seconds, staging publication retains it, exact uncertain wire body unchanged. Missing historical times use acknowledged server modified only. Activity ordering has UUID ties. Sidebar creates directly in selected parent/category. |
| Coordination/status | One coordinator uses existing repository synchronization: opening/local/manual/focus/resume, 60s visible active polling and authenticated recovery reads. Hidden/inactive workspace polling suspends; visible loss of focus does not. Six retries 5/10/20/40/80/160s, durable budgets; healthy reads cannot release failed writes, but can publish fresh unattempted durable edits. Manual future includes coalesced follow-up. Separate successful complete GET/304 server-check time; local/pending upload/sync/conflict/account failure states. |
| Settings/capabilities | Typed v1 GET/PUT settings; changed fields, custom suffix, normalization, explicit Save/Cancel and preserved dirty forms. Buffers save before serialized transitions; pending/conflicted/attachment work blocks collection changes. Durable lost-PUT reconciliation; checkpoint reset/full refresh. Existing OCS credential boundary refreshes first use/manual/reconnect/hourly. API headers case-insensitive on errors/streams; API/application evidence separate, conservative DELETE gate. Current-record merging and account/epoch fences preserve checkpoint/capability races. |
| Persistence/localization | Schema **3** transactional older-client fence; exact note/outbox/attempt/attachment preservation, rollback and newer-schema rejection. Editor provenance and Local History/session boundaries preserved. All 23 ARB catalogs updated; outputs generated, not edited manually. UI uses existing BusyMark/Yaru components. |

Routes remain **v1** for notes/settings and **v1.4** for attachments. Supported advertisement remains major **1**, minor **≥4**. Notes 6.0.2 tagged behavior advertises 1.4 despite documentation's 6.1 introduction wording; preserve tested 6.0 upload/download and verified 6.1 attachment DELETE gate. Attachment responses have no assumed validators. No WebDAV/Files/provider framework or Milestone 2 features added.

## Regression coverage

Initial collection/path regressions failed on the baseline (2 passed, 5 failed), retained in the private iteration log. New tests are enabled; strict protocol fixtures assert routes, authorization, conditional ETags and payloads.

- `notes_milestone_test`: collection 404 clean/edit/draft/restart/restoration; Unicode/percent/space/#/parentheses/escape-like filename boundaries; encoded traversal/malformed URI; version headers on settings errors and streamed media.
- `notes_milestone_repository_test`: permanent rejection/edit recovery; 429 date/long deadline/restart; poisoned server records, positive draft evidence, ambiguous history, genuine absence; local timestamp/no-op/delay/newer acknowledgment/restart; metadata remote category/divergent same field/convergence/permission/removal; unchanged-ETag open-context media replacement/failure retention/cleanup/concurrency/deletion/removal/disposal; attachment-only 404/rejected creation endpoint; durable 429/503 download deadlines and cached-byte retention; upload recorded before injected local transaction failure/exactly once after restart; settings partial/normalization/blocker/checkpoint/lost response/restart; capability freshness/deletion gate/checkpoint/unsupported/malformed/removal; v2 fixture preservation/migration rollback/v4 fence.
- `notes_sync_coordinator_test`: controlled clocks/timers, idle/focus/visible-hidden/disposal, awaitable manual/coalesced save follow-up, six exhausted lock retries unaffected by healthy reads, fresh work without releasing exhausted writes, throttling, authenticated connectivity recovery with uncertain operations blocked/removal.
- `notes_settings_test`: settings-only first connected use refreshes capabilities once and adopts a changed application version; dirty reload/Cancel; actual localized production controls, partial suffix Save and normalization. The first-use regression failed before the controller correction. Widget I/O drains before disposing its isolate in the widget's fake-async zone.
- Controller no-op properties Save preserves revision/time and starts no request. Existing uncertain creation/upload, pagination, read-only favorite payload, workspace/editor/history/media/export/UI regressions retained and run.

## Live fixtures and acceptance

Private credentials, app passwords, test CA/key, raw reports and upstream copies stay under `/tmp/busymark-m1`, outside Git. Two loopback containers: Nextcloud **35.0.1** / Notes **6.0.2** and **6.1.0**, both advertised **API 1.4**, separate SQLite stores/accounts. CA-signed localhost HTTPS ports 18444/18443 with hostname/certificate verification retained. Existing browser Login Flow harness passed for both; dedicated app passwords used.

Extended `tools/nextcloud_notes_live_acceptance.dart` passed on each baseline: **19 scenario checks plus two verified version entries** in each report. Coverage includes existing CRUD/conditional conflicts/offline/restart/304/uncertain creation/attachments/version DELETE gate; server settings/custom suffix/normalization/partial updates; maintained capabilities/server check; delayed edit-time fidelity; complete Unicode/literal-percent/escape-like attachment round trips; uncertain upload preservation. Settings restored and only owned notes removed.

Collection 404/429/nondelivery/lost successful PUT/upload responses are explicitly simulated at the transport boundary around real authenticated requests. They are distinguished from actual server behavior. Reports: `notes-6.0-final.json`, `notes-6.1-final.json`; Login reports `login-6.0.json`, `login.json` in the private live directory.

After acceptance, both owned containers and their anonymous volumes were removed with `docker rm -fv busymark-m1-nextcloud busymark-m1-nextcloud-6-0` (exit 0), and both owned HTTPS proxies stopped. Private reports and screenshots are retained; the disposable account credentials no longer identify a running server.

## Validation record

| Command / environment | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | PASS; initial and final locked runs, pins unchanged |
| `flutter gen-l10n` | PASS; all catalogs regenerated |
| `flutter test --no-pub test/src/localization_audit_test.dart` | PASS, 21 tests |
| `dart format --set-exit-if-changed .` | PASS, 560 files, zero changes |
| `flutter analyze` | PASS, no issues |
| `git diff --check` | PASS |
| `flutter test --no-pub test/src/nextcloud_notes test/src/nextcloud*_test.dart` (includes new scheduler/settings suites) | PASS, 258 tests, zero skips |
| `bash tools/test_secure_credential_policy.sh` | PASS, exit 0 |
| `bash tools/test_nextcloud_libsecret.sh` | PASS, exit 0, isolated Secret Service/keyring |
| Browser Login Flow / real Notes API | PASS on both versions; four Login Flow assertions and 19 Notes scenarios each, with application/API versions verified |
| Native Linux desktop | PASS, 24 checks on Notes 6.1.0/API 1.4. Release application, isolated X11/disposable XDG profile, actual widgets/controllers. Category/offline ordering/properties concurrency+dirty buffer/settings normalization, native focus/resume/hidden suspension, 60s idle discovery/authenticated connectivity recovery, actual Editor/Source/Reading/Split saves and same-path replacement in open preview/editor. Process uses `WEBKIT_DISABLE_DMABUF_RENDERER=1` for unavailable WebKit GBM; no runtime downgrade. |
| Normal `flutter build linux --release` and full bundled-tool suite | PASS, production `lib/main.dart` target; final complete suite **4,141 passed, 0 failed, 0 skipped**, with bundled D2/Typst, prepared spelling resources and isolated native display |
| `BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 flutter test --no-pub test/src/native_writerside_dialog_source_test.dart` | PASS, 2 tests, zero skips; explicitly covers the existing isolated-display test omitted by the ordinary CI environment |
| Post-commit `flutter gen-l10n`, `flutter pub get --enforce-lockfile`, `git diff --exit-code` and clean status | PASS after implementation commit `9f99e8738805e3e75db198df57c58d8f7290a796`; zero generated/dependency/staged changes |

Native evidence uses `tools/nextcloud_notes_desktop_acceptance.dart`; final private report `/tmp/busymark-m1/desktop7/report.json` and before/after media screenshots. Visual inspection confirms red → blue replacement in the actual Split preview and editor, with unchanged path and note ETag. Early attempts exposed harness waits/button-label ambiguity and a WebKit environment prerequisite; those attempts are failures, not acceptance passes. All work packages are implemented, integrated and acceptance-tested. No remaining acceptance blocker.

The final full suite uses `env BUSYMARK_D2_PATH=$PWD/build/linux/x64/release/bundle/libexec/busymark/d2 BUSYMARK_TYPST_PATH=$PWD/build/linux/x64/release/bundle/libexec/busymark/typst BUSYMARK_TEST_SPELLING_ROOT=$PWD/build/spelling-test BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 flutter test --no-pub --concurrency=4`, matching the bundled-tool configuration in `.github/workflows/flutter-linux.yml` and enabling the isolated native check. Live harness invocations follow `nextcloud-notes.md` → Verification, with the dedicated CA supplied as the Dart harness's third argument. Python Requests uses `REQUESTS_CA_BUNDLE` for CA/hostname verification; the existing browser harness uses `BUSYMARK_TEST_TLS_SPKI` to pin the dedicated test certificate. Native acceptance uses the documented target, isolated display `:97` and disposable XDG directories.

One final default-concurrency attempt finished with 4,139 passed, 1 failed, 1 skipped: the existing `first-save pre-promotion cancellation: clear all, failed pending capture` Local History test's three-second workspace-state wait timed out. The exact case rerun passed (1 test, zero skips); two preceding complete runs also passed. The final complete suite passed with bounded concurrency, preserving every test and the same bundled tools. No Local History implementation or existing test was changed to suppress this failure.
