# Nextcloud Notes implementation validation

The sections dated October 4–5, 2026 are historical records. Their automatic
creation-adoption behavior and incomplete acceptance results are superseded by
the **Explicit-adoption validation, 7 October 2026** section at the end of this
file. See [the integration contract](nextcloud-notes.md) for the current policy,
architecture, security boundaries and server limitations.

## Historical capability and synchronization follow-up (October 5, 2026)

This follow-up addresses only API 1.4 compatibility, uncertain creation,
attribute-wise merging, HTTPS enforcement and bounded attachment downloads. The
working tree was clean before editing. The earlier review and implementation
results below are historical, not substitutes for the checks in this section.

The current App Store stable release was **Notes 6.1.0** (Nextcloud 33–35).
Re-read the API README/v1, Application/Capabilities and routes at **v6.0.0,
v6.0.1, v6.0.2 and v6.1.0**, plus issue #2037. Exact commit IDs and the route
matrix are in [the contract](nextcloud-notes.md). All advertise API 1.4. The
connection gate now requires major 1/minor >=4; missing or malformed app versions
are accepted. App version controls only attachment deletion (known stable
>=6.1.0). Notes 6.0.x flat attachment upload filenames and 6.1.x scoped filenames
are both supported.

No dependency or toolchain changes. SQLite user_version **1 → 2** fences the new
optional durable creation-attempt JSON in notes/outbox, preserving existing
records. The shared asset limit remains **100 MiB**. New scalar conflict UI text
was translated in all 23 ARB catalogs and generated using `flutter gen-l10n`.

### Commands and results

All Flutter/Dart commands use `/home/albert/flutter/bin/` (Flutter 3.47.5,
Dart 3.13.4). Logs and ephemeral reports use `/tmp/busymark-compat-*`.

| Command/check | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | Exit 0; lockfile unchanged |
| `flutter gen-l10n` | Exit 0 |
| `dart format --set-exit-if-changed .` | Exit 0; 542 files, zero changes |
| `flutter analyze` | Exit 0; no issues |
| Focused command below, including localization audit | Exit 0; **195 passed**, zero failed/skipped |
| Full Flutter suite below | Exit 1; **3,406 passed, 1 failed**, zero skipped; 15m20s. The same routing failure reproduces on untouched HEAD. |
| `(cd packages/busymark_spellcheck_native && dart pub get && dart test)` | Exit 0; **13 passed** |
| `tools/validate_writerside_conformance.sh` | Exit 0; **181 checks passed** |
| `flutter build linux --release` | Exit 0 |
| `DISPLAY=:97 GDK_BACKEND=x11 bash tools/test_gtk_accent.sh` | Exit 0 |
| `DISPLAY=:97 GDK_BACKEND=x11 bash tools/test_gtk_accent_host.sh` | Exit 0 |
| `bash tools/test_secure_credential_policy.sh` | Exit 0 |
| `bash tools/test_nextcloud_libsecret.sh` | Exit 0; isolated Secret Service create/read/delete |
| Release `--visualization-release-smoke` under X11 and Wayland | Both exit 0; both reports `ok: true`, including HTML/PDF |
| Release `--spelling-release-smoke` under X11 then Wayland | Both exit 0; install then restart with retained personal word; source/WYSIWYG/table edits passed |
| `tools/visualization_smoke.py` under X11 and Wayland | Both exit 0; real WebKit, PlantUML, Mermaid, OpenAPI, Scalar and D2 coverage |
| Exact-recipe Snapcraft build | Exit 0; strict core24 amd64 package, exact recipe/manifest, 8 artifact checks and unpacked dependency/resource probe passed |
| `git diff --check` | Exit 0 |

```sh
flutter test --no-pub \
  test/src/nextcloud_notes \
  test/src/nextcloud_capabilities_test.dart \
  test/src/nextcloud_connection_test.dart \
  test/src/nextcloud_login_flow_test.dart \
  test/src/nextcloud_workspace_test.dart \
  test/src/nextcloud_notes_ui_test.dart \
  test/src/nextcloud_media_export_test.dart \
  test/src/localization_audit_test.dart --reporter expanded

BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 \
BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" \
flutter test --no-pub --concurrency=1 --reporter expanded
```

The first full run was interrupted after two PDF tests failed while a concurrent
release build replaced their bundled Typst executable. The final full run used
stable build output. Its sole failure was `app_router_test.dart: returning to
Welcome does not restore the session again` (line 168: missing Welcome tooltip).
An isolated rerun failed identically. A `git archive HEAD` snapshot of
`366e303` under `/tmp`,
with fresh `.dart_tool`, `flutter pub get --enforce-lockfile`, and the same pinned
SDK, also failed the identical test (4 passed, 1 failed). This pre-existing
failure was left unchanged because this task explicitly excludes unrelated
fixes; the full suite is **not reported as passing**. Initial focused compile/fixture errors and brace diagnostics
were corrected before the final runs; no failing tests were suppressed.

Native smoke checks used private Xvfb displays and unpacked Weston 13.0.0 with a
headless backend. The Python smoke script initially lacked `gi._gi_cairo`; the
matching Ubuntu Python Cairo packages were unpacked under `/tmp`, then the script
passed with that temporary PYTHONPATH. No installed packages or project pins were
changed. A minimal private D-Bus session avoided desktop portal interference.

### Snap packaging evidence

Built from a separate source copy with **official Snapcraft 8.11.1**:

```sh
SNAPCRAFT_BUILD_INFO=1 CMAKE_BUILD_PARALLEL_LEVEL=4 snapcraft pack --destructive-mode --verbosity=brief
```

The official container needed its matching upstream extension resources and
`craftctl` entry point restored, an apt index refresh, the declared Node 24 snap
on PATH, and `/lib/python3.12/site-packages` on PYTHONPATH after apt installed the
system Python. Those were container-only infrastructure corrections. The exact
repository recipe, Flutter 3.47.5, dependencies and pins were unchanged. All 334
Dart/pin/recipe files in the build source matched the working tree. Snapcraft
reported unused-library warnings; packing exited 0.

- Artifact: `/tmp/busymark-compat-snap/source/busymark_0.5.1_amd64.snap`
- Size: **309,592,064 bytes**
- SHA-256: `648f854d7af18853bc49ff0837c2b64f53d64d57c74b6977aab2ea9259e96378`
- Exact recipe SHA-256: `af358e17aadbd4f816069eccd6d4656818d489443b17345cbe0ad78e481dc590`
- Native SQLite loaded successfully: **3.53.4**.
- Existing network/browser/keyring plugs and native plugins were present.
- The unpacked CI-equivalent dependency/resource probe passed for GNOME/Mesa
  resolution, Git/OpenSSH, GStreamer, SVG loading, fonts/themes and RUNPATH.
- Artifact report: `/tmp/busymark-compat-snap/validation.json`; build and probe
  logs are retained beside it. This proves packaging, not installed confinement.

### Live acceptance

The live harness uses verified **HTTPS** with a localhost certificate trusted by
an explicitly injected test-only SecurityContext. It does not disable certificate
or hostname verification, and does not add any production HTTP exception.

```sh
dart run tools/nextcloud_notes_live_acceptance.dart \
  /tmp/busymark-compat-live/credentials.json \
  /tmp/busymark-compat-live/notes-VERSION-report.json \
  /tmp/busymark-compat-live/cert.pem
```

Two isolated **Nextcloud 35.0.1** installations used the official App Store release
packages for **Notes 6.0.1 and 6.1.0**. Both completed **13 checks successfully**. Both exercised:

- OCS compatibility acceptance and API 1.4, with no obsolete-app rejection.
- Durable creation, list/chunks/Last-Modified, ETags/304, edit, category, favorite,
  server title sanitization, and a second actor's conflict plus merge.
- Attachment upload, authoritative renamed filename and streamed download.
- Offline new note plus attachment, database close/reopen, reconnect/publication.
- Remote deletion with pending work and explicit fresh-state-checked deletion.
- A deliberately lost successful POST response, durable wire metadata and staged
  attachment across restart, another local edit, automatic candidate adoption
  (historical behavior, superseded by mandatory confirmation),
  sanitized title/category adoption, attachment publication and **one note POST**.

On 6.0.1, invoking attachment DELETE produced `unsupported` without issuing the
request and the other operations continued. On 6.1.0, DELETE succeeded. The
harness's original 304 assertion mixed ETags from different list pages; it was
corrected to use a consistent unchunked representation for 304, while separately
checking real multi-chunk behavior.

Production HTTP rejection, known/unknown/incorrect attachment Content-Length,
100 MiB boundary enforcement, interrupted/cancelled streams, traversal and
cross-origin redirects were exercised by deterministic injected-client tests.
The local/private server URL supplied in the original failure was not available;
6.0.1 was tested in a fresh disposable installation instead. Browser Login Flow
and installed strict-Snap account setup were not repeated against a user's server.
The existing injected Login Flow tests passed; earlier browser/keyring acceptance
is recorded separately below. No real credentials were committed.

The host rejects unprivileged network namespaces (`unshare --user --map-root-user
--net`: `Operation not permitted`), so this follow-up's spelling restart was not
network-isolated. Nextcloud offline/reconnect was explicitly simulated through
the live harness transport and verified against the real server. Installed strict
Snap runtime/interface tests still require host administration and remain
unverified here. Packaging and unpacked dependency checks are reported separately;
neither is claimed to prove installed confinement behavior.


### Historical follow-up changed files

- `docs/development/nextcloud-notes-validation.md`
- `docs/development/nextcloud-notes.md`
- `lib/l10n/app_ar.arb`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_et.arb`
- `lib/l10n/app_fa.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_id.arb`
- `lib/l10n/app_it.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`
- `lib/l10n/app_nb.arb`
- `lib/l10n/app_nl.arb`
- `lib/l10n/app_pl.arb`
- `lib/l10n/app_pt.arb`
- `lib/l10n/app_pt_BR.arb`
- `lib/l10n/app_ru.arb`
- `lib/l10n/app_tr.arb`
- `lib/l10n/app_uk.arb`
- `lib/l10n/app_vi.arb`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_zh_CN.arb`
- `lib/l10n/generated/app_localizations.dart`
- `lib/l10n/generated/app_localizations_ar.dart`
- `lib/l10n/generated/app_localizations_de.dart`
- `lib/l10n/generated/app_localizations_en.dart`
- `lib/l10n/generated/app_localizations_es.dart`
- `lib/l10n/generated/app_localizations_et.dart`
- `lib/l10n/generated/app_localizations_fa.dart`
- `lib/l10n/generated/app_localizations_fr.dart`
- `lib/l10n/generated/app_localizations_hi.dart`
- `lib/l10n/generated/app_localizations_id.dart`
- `lib/l10n/generated/app_localizations_it.dart`
- `lib/l10n/generated/app_localizations_ja.dart`
- `lib/l10n/generated/app_localizations_ko.dart`
- `lib/l10n/generated/app_localizations_nb.dart`
- `lib/l10n/generated/app_localizations_nl.dart`
- `lib/l10n/generated/app_localizations_pl.dart`
- `lib/l10n/generated/app_localizations_pt.dart`
- `lib/l10n/generated/app_localizations_ru.dart`
- `lib/l10n/generated/app_localizations_tr.dart`
- `lib/l10n/generated/app_localizations_uk.dart`
- `lib/l10n/generated/app_localizations_vi.dart`
- `lib/l10n/generated/app_localizations_zh.dart`
- `lib/src/assets/asset_ingestion_service.dart`
- `lib/src/assets/asset_limits.dart`
- `lib/src/nextcloud_notes/application/notes_repository.dart`
- `lib/src/nextcloud_notes/data/notes_api_client.dart`
- `lib/src/nextcloud_notes/data/notes_capabilities.dart`
- `lib/src/nextcloud_notes/data/notes_store.dart`
- `lib/src/nextcloud_notes/data/server_uri.dart`
- `lib/src/nextcloud_notes/domain/notes_conflict.dart`
- `lib/src/nextcloud_notes/domain/notes_models.dart`
- `lib/src/nextcloud_notes/presentation/notes_sidebar.dart`
- `lib/src/workspace/workspace_controller.dart`
- `test/src/nextcloud_capabilities_test.dart`
- `test/src/nextcloud_connection_test.dart`
- `test/src/nextcloud_login_flow_test.dart`
- `test/src/nextcloud_notes/notes_api_test.dart`
- `test/src/nextcloud_notes/notes_attachment_stream_test.dart`
- `test/src/nextcloud_notes/notes_conflict_test.dart`
- `test/src/nextcloud_notes/notes_repository_test.dart`
- `test/src/nextcloud_notes_ui_test.dart`
- `tools/nextcloud_notes_live_acceptance.dart`

## Review corrections

The review follow-up fixes all eight reported cases: unsaved-editor base
preservation across Refresh; exact Markdown export destination ranges;
uncertain-attachment controls with fetched remote state; replacement-tab
activation and clearing the final tab's derived content; consistent source and
WYSIWYG AI identities; deletion tombstones and media invalidation; concurrent
cache ownership (including previously duplicated rows); and disappearing
category filters.

Thirteen regression tests were added. The race tests explicitly hold the
persistence debounce, which the ordinary test configuration previously bypassed.
They exercise edits before and during Refresh, verify base/local/remote
preservation in SQLite and assert that no PUT occurs. Additional cases exercise
own-write acknowledgments, both tab deletion paths, actual editor AI proposals
and stale-tab rejection, prefix-sharing export filenames, existing/fresh/restarted
media resolvers, retained history bytes, deliberate filename reuse after deletion,
uncertain-upload recovery controls and removal of the final category.

The initial implementation's live-server and Snap results below predate these
review corrections. They are not claims that the updated Dart source was
retested against a live account or rebuilt as a Snap. No database schema,
dependency, native credential or packaging changes were needed for these fixes.

Review follow-up validation:

| Command/check | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | Exit 0; no dependency changes |
| `flutter gen-l10n` | Exit 0; all 22 generated catalog files unchanged |
| `dart format --set-exit-if-changed .` | Exit 0; 538 files, zero changes |
| `flutter analyze --no-pub` | Exit 0; no issues |
| `flutter test --no-pub --concurrency=1 --reporter expanded test/src/nextcloud*_test.dart test/src/nextcloud_notes test/src/ai_edit_ui_test.dart test/src/wysiwyg_ai_test.dart test/src/source_audit_test.dart test/src/localization_audit_test.dart` | Exit 0; 216 passed, zero failed/skipped |
| Full suite: `flutter test --no-pub --concurrency=1 --reporter expanded` | Exit 0; 3,355 passed, zero failed/skipped, 12 minutes 59 seconds |
| `flutter build linux --release --no-pub` | Exit 0 |
| Updated release `--visualization-release-smoke` on isolated X11 | Exit 0; report `ok: true`, including HTML and PDF |
| `git diff --check` | Exit 0 |

The full follow-up run used the resource environment shown below:

```sh
BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 \
BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" \
flutter test --no-pub --concurrency=1 --reporter expanded
```

The application/test/native source hash snapshot remained unchanged throughout
the full run. The isolated Xvfb displays and release smoke private bus were
stopped afterward.

Logs use the `/tmp/busymark-notes-review-` prefix. The X11 release report is
`/tmp/busymark-notes-review-visualization.json`. The first targeted test run had
four test-setup failures: two race tests inherited immediate test persistence,
and two AI tests had not selected a model. After correcting those setups, the
targeted suite above passed.

## Environment and changes

Validation used Linux x86_64, Flutter **3.47.5**, Dart **3.13.4**, GTK **3.24.41**,
libsecret **0.21.4** and WebKitGTK **2.52.6**. Existing SDK, build and package pins
were retained. Direct `sqlite3` **3.7.0** supplies the transactional store and its
bundled native library; the release library reports SQLite **3.53.4**. Required
transitive native-asset tooling changed to `hooks` **2.2.0** and `record_use`
**1.1.1**. No Snap interfaces or additional production native dependencies were
added.

The focused database starts at schema **1** with transactional migration from an
empty store and rejection of unsupported newer schemas. Application sessions
advance to version **2**, retaining version-1 local-session decoding. No old
Notes API compatibility or generic provider framework was added.

Changes cover the Notes domain/API/login/capability/credential/repository/store
module; explicit workspace/document origins and all save/session/recovery
paths; logical local-history identities; provider media and editor/export
integration; Notes settings/welcome/sidebar/tab/status/recovery UI; Git/path
and workspace-replacement guards; 23 localization catalogs and their generated
sources; native credential namespace policy; tests and acceptance tools. A
complete path manifest follows the validation results.

## Live Nextcloud acceptance

The disposable server was **Nextcloud 35.0.1** (internal version 35.0.1.1), with
the stable Notes **6.1.0** release. Notes tag `v6.1.0` resolves to
`0c3dd46dbd781b780c1ea60a13873198609bb98d`. The Docker image digest was
`sha256:b1ae671e9815401b0e837b19b9c778e89887721d67f0c8f9d34aa1d27a9a208f`.

`tools/nextcloud_notes_live_acceptance.dart` was run against this real server.
The final report returned `ok: true` for all eleven checks:

1. Notes version 6.1.0.
2. API capability 1.4.
3. Local durability before remote creation.
4. Content, category, favorite and canonical title updates.
5. Server title sanitization.
6. Attachment upload, fetch, deletion and authoritative renamed filename.
7. A second actor's ETag conflict and deliberate manual merge.
8. An offline new note with an attachment, SQLite close/reopen and reconnection.
9. Chunked listing, server Last-Modified and ETag/304 behavior.
10. Remote deletion preserving locally pending work.
11. Explicit fresh-state-checked deletion.

The offline Notes scenario injected a transport failure into the genuine
repository, reopened its persistent SQLite store, then resumed real HTTP. It
was not a physical network cut or a full GUI/installed-Snap restart.

Login Flow v2 used a real anonymous start and pending `404` poll. The system
default Firefox browser opened through `xdg-open` successfully. An automated
browser granted the real server authorization; polling then returned one-time
`200` credentials. The app password was revoked with HTTP `200` afterward. The
disposable account credentials, container and anonymous volume were removed.

With Text **9.0.0** open in its real web editor, an otherwise valid conditional
Notes update returned **423 Locked**. The lock subsequently expired before a
repository-level unrelated-note isolation probe, so live per-note isolation
was not established. Deterministic tests cover preservation of the locked
note's pending work and continued synchronization of unrelated notes.

No unsupported/private Text session protocol was used by the application. A
final check of current Text source and developer documentation found no
documented supported external native collaboration API.

The live command was:

```sh
dart run tools/nextcloud_notes_live_acceptance.dart <private-credentials.json> <report.json>
```

Sanitized reports are retained under `/tmp/busymark-notes-live/`: the final
eleven-scenario report, browser authorization report and lock report. The
private credential input was removed.

## Initial repository validation commands

These follow `.github/workflows/flutter-linux.yml`; display, dictionary and
bundled-tool environment variables provide the workflow's required resources.

| Check | Result |
| --- | --- |
| `flutter pub get` and `flutter pub get --enforce-lockfile` | Exit 0; lockfile updated for the intentional SQLite dependency |
| `tools/validate_writerside_conformance.sh` | Exit 0; 181 checks from the official pinned builder |
| `flutter gen-l10n` | Exit 0; generated-file hashes unchanged by final regeneration |
| `dart format --set-exit-if-changed .` | Exit 0; 538 files, zero formatting changes |
| `flutter analyze --no-pub` | Exit 0; no issues found |
| Focused Notes tests, `flutter test --no-pub --concurrency=2 --reporter expanded test/src/nextcloud*_test.dart test/src/nextcloud_notes` | Exit 0; 122 passed, zero failed/skipped, 28 seconds |
| Full Flutter suite, `flutter test --no-pub --concurrency=1 --reporter expanded` | Exit 0; 3,342 passed, zero failed/skipped, 17 minutes 49 seconds |
| Final source and localization audits, `flutter test --no-pub --reporter expanded test/src/source_audit_test.dart test/src/localization_audit_test.dart` | Exit 0; 70 passed |
| Native spelling package: `dart pub get`, `dart test` | Exit 0; 13 tests passed |
| `tools/fetch_spelling_dictionaries.sh build/spelling-test` | Exit 0 |
| `flutter test test/src/spelling_bundle_integration_test.dart` with prepared resources | Exit 0; 3 tests passed |
| `flutter build linux --release --no-pub` | Exit 0; final Linux release and native SQLite asset built |
| `tools/test_gtk_accent.sh` and `tools/test_gtk_accent_host.sh` on X11 | Exit 0 |
| `tools/test_secure_credential_policy.sh` | Exit 0 |
| `tools/test_nextcloud_libsecret.sh` with an isolated keyring | Exit 0; actual create/read/delete |
| Native Writerside dialog tests with isolated Xvfb | Exit 0; 2 tests passed, zero skipped |
| `tools/visualization_smoke.py` on X11 and Wayland | Exit 0 for both |
| Final release `--visualization-release-smoke` on X11 and Wayland | Exit 0; both reports `ok: true`, HTML and PDF exercised |
| Release `--spelling-release-smoke`, install/restart and network-disabled restart | Exit 0; reports `ok: true` |
| Ordinary release Welcome → Nextcloud Notes setup with an empty isolated profile | Passed; actual AOT SQLite loaded, schema 1, integrity `ok`, zero accounts, private DB permissions |
| Clean Snapcraft build and unconfined packaged-resource validation | Exit 0; exact source/recipe provenance and all resource checks passed |
| `git diff --check` | Exit 0 |

The full suite used these resources:

```sh
BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 \
BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" \
flutter test --no-pub --concurrency=1 --reporter expanded
```

An isolated Xvfb server provided display `:97`. The final full-run source hash
snapshot remained unchanged throughout the run. Logs are retained at
`/tmp/busymark-nextcloud-full-tests-serial.log`,
`/tmp/busymark-nextcloud-focused-final.log` and
`/tmp/busymark-nextcloud-audits-final.log`. Final localization regeneration
preserved generated-file hashes; the workflow's clean-checkout
`git diff --exit-code` cannot be used literally while implementation changes
are still uncommitted.

The local environment lacked `xvfb-run`, Weston and `python3-gi-cairo`. The
corresponding distro binaries/libraries were extracted under `/tmp` and used
for the checks without installing host packages. CI's privileged network
namespace step could not run directly; a Docker container with no network
provided the actual offline spelling check.

Before the final source snapshot, two full runs exposed existing local UI
wall-clock waits: the first had 3,304 passed, one skipped and three failures
(two obsolete source-audit assertions and a spelling-fixture timeout); the
audits were updated for the intended integration. The next had 3,331 passed,
one skipped and two local UI timing failures. Both local UI failures passed in
an isolated rerun, and the spelling-fixture timeout also passed in isolation.
A later run started before the last fixes and was stopped because it retained
older compiled shared source. These runs are not represented as clean passes.
The final fixed-source serial run passed all 3,342 tests without weakening the
existing local-workflow assertions or timeouts.

## Initial Linux, browser and keyring checks

The native credential policy probe passed, retaining the AI key whitelist and
restricting Nextcloud keys to the dedicated UUID namespace. An isolated
libsecret keyring exercised actual credential creation, read and deletion.
Authentication mocks additionally cover missing/locked keyring behavior and
absence of plaintext fallback.

X11 and headless Wayland release visualization/HTML/PDF smoke reports returned
`ok: true`. Real WebKit visualization checks passed under both display systems.
The GTK accent lookup and channel-host/lifecycle probes passed. Existing engine
teardown diagnostics appeared on stderr without failing the lifecycle probe.

Spelling installation and profile restart passed. A separate Docker container
with `--network none` verified an actual offline Wayland restart retained the
installed dictionary and personal word. The container required the test-only
WebKit sandbox-disable environment flag because its user namespaces were
unavailable; production sandbox configuration was unchanged.

The ordinary final release executable was also launched without smoke-test
arguments, using an empty isolated XDG profile and Xvfb. Welcome → Nextcloud
Notes rendered the connection setup and initialized SQLite through the actual
Dart AOT/native asset path. The server field remained empty and no account was
connected. A read-only inspection found schema version **1**, zero accounts,
`integrity_check: ok`, all four expected tables, directory mode **0700**, and
database/WAL/SHM modes **0600**. No Dart exception or native-loader/store error
was logged. A first private-bus attempt encountered a host desktop-portal/FUSE
delay; a minimal isolated bus without host service autostart passed. This checks
the release initialization and entry point, not interactive account acceptance.
The sanitized report, log and inspected screenshots are retained under
`/tmp/busymark-final-aot-notes-ufxzfivk/`. The app, private bus, Xvfb, test server,
Snap builder and Weston processes created for this work were stopped.

## Initial Snap packaging

The final artifact was built from a disposable source snapshot with the official
`ghcr.io/canonical/snapcraft:8_core24` image, Snapcraft **8.11.1**, and the
repository's Flutter **3.47.5** / Dart **3.13.4** pins. At that build,
application/native sources, localization catalogs, lockfile and the embedded
recipe matched the repository.
The container required restoration of its missing extension source and console
entry point from the exact same official Snapcraft version; this affected only
the disposable build environment.

```sh
SNAPCRAFT_BUILD_INFO=1 snapcraft clean --destructive-mode --verbosity=brief
SNAPCRAFT_BUILD_INFO=1 snapcraft pack --destructive-mode --verbosity=brief
```

The artifact is
`/tmp/busymark-nextcloud-snap-source/final-source/busymark_0.5.1_amd64.snap`,
**309,583,872 bytes**, SHA256
`339a2eb9c1c9911f071f5c3a37d6aa535d0daed205c5ec2a14bd9f25a7203a55`.
It contains the build manifest and exact recipe, SHA256
`af358e17aadbd4f816069eccd6d4656818d489443b17345cbe0ad78e481dc590`.

Package validation confirmed strict/core24/amd64 metadata, unchanged network,
browser and keyring plugs, GNOME/Mesa library selection, no missing shared
dependencies, loading SQLite **3.53.4**, application plugins, Git/SSH/setsid,
WebKit helpers, visualization engines, SVG loaders, codecs, fonts/licenses,
Yaru resources and desktop integration. The package-resource probe ran
**unconfined** and returned exit 0; this does not establish installed strict
runtime behavior.

An initial probe exposed Snapcraft's forced RPATH overriding the GNOME runtime
library selection. The recipe now uses its existing `patchelf` dependency to
preserve bundled paths as RUNPATH, allowing the extension runtime to select its
libraries. Intermediate incremental builds also retained stale priming state;
the final artifact came from a complete lifecycle clean and passed provenance
and resource checks. No interfaces or dependencies were added for this fix.
The sanitized result is `/tmp/busymark-nextcloud-snap-validation.json`; the
complete build log is
`/tmp/busymark-nextcloud-snap-source/.task-snap-final-all-clean.log`.

## Limits on acceptance

Strict installation/refresh and confined browser, keyring and network behavior
of the newly built Snap require host administrative permissions unavailable in
this session. The installed older BusyMark Snap was left untouched. These
installed-Snap checks are not claimed as passed.

The real account authorization and repository protocol checks do not constitute
a complete interactive GUI Notes acceptance run. Widget/controller tests cover
source/WYSIWYG boundaries, save/autosave/shutdown, session/history, media/export,
remote UI and local workflow regressions. The uncertain-create/twin-adoption
race is covered deterministically, not reproduced on the live server.

## Changed-file manifest

129 source, test, localization, build and documentation files changed from the initially clean checkout.

```text
.github/workflows/flutter-linux.yml
docs/development/nextcloud-notes-validation.md
docs/development/nextcloud-notes.md
lib/l10n/app_ar.arb
lib/l10n/app_de.arb
lib/l10n/app_en.arb
lib/l10n/app_es.arb
lib/l10n/app_et.arb
lib/l10n/app_fa.arb
lib/l10n/app_fr.arb
lib/l10n/app_hi.arb
lib/l10n/app_id.arb
lib/l10n/app_it.arb
lib/l10n/app_ja.arb
lib/l10n/app_ko.arb
lib/l10n/app_nb.arb
lib/l10n/app_nl.arb
lib/l10n/app_pl.arb
lib/l10n/app_pt.arb
lib/l10n/app_pt_BR.arb
lib/l10n/app_ru.arb
lib/l10n/app_tr.arb
lib/l10n/app_uk.arb
lib/l10n/app_vi.arb
lib/l10n/app_zh.arb
lib/l10n/app_zh_CN.arb
lib/l10n/generated/app_localizations.dart
lib/l10n/generated/app_localizations_ar.dart
lib/l10n/generated/app_localizations_de.dart
lib/l10n/generated/app_localizations_en.dart
lib/l10n/generated/app_localizations_es.dart
lib/l10n/generated/app_localizations_et.dart
lib/l10n/generated/app_localizations_fa.dart
lib/l10n/generated/app_localizations_fr.dart
lib/l10n/generated/app_localizations_hi.dart
lib/l10n/generated/app_localizations_id.dart
lib/l10n/generated/app_localizations_it.dart
lib/l10n/generated/app_localizations_ja.dart
lib/l10n/generated/app_localizations_ko.dart
lib/l10n/generated/app_localizations_nb.dart
lib/l10n/generated/app_localizations_nl.dart
lib/l10n/generated/app_localizations_pl.dart
lib/l10n/generated/app_localizations_pt.dart
lib/l10n/generated/app_localizations_ru.dart
lib/l10n/generated/app_localizations_tr.dart
lib/l10n/generated/app_localizations_uk.dart
lib/l10n/generated/app_localizations_vi.dart
lib/l10n/generated/app_localizations_zh.dart
lib/src/ai/ai_edit_ui.dart
lib/src/app/busymark_app.dart
lib/src/assets/document_media_context.dart
lib/src/assets/provider_asset_ingestion_service.dart
lib/src/editor/markdown_image_view.dart
lib/src/editor/source/source_editor.dart
lib/src/editor/writerside_video_view.dart
lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart
lib/src/editor/wysiwyg/wysiwyg_editor.dart
lib/src/export/html_export_assets.dart
lib/src/export/html_export_links.dart
lib/src/export/html_export_models.dart
lib/src/export/html_export_service.dart
lib/src/export/html_export_ui.dart
lib/src/export/html_rich_content.dart
lib/src/export/markdown_copy_export_service.dart
lib/src/export/markdown_export_assets.dart
lib/src/export/markdown_pdf_export_service.dart
lib/src/export/markdown_pdf_export_ui.dart
lib/src/export/markdown_pdf_models.dart
lib/src/export/markdown_visualization_export.dart
lib/src/git/application/git_controller.dart
lib/src/local_history/local_history_comparison_view.dart
lib/src/local_history/local_history_controller.dart
lib/src/local_history/local_history_models.dart
lib/src/local_history/local_history_store.dart
lib/src/nextcloud_notes/application/attachment_markdown.dart
lib/src/nextcloud_notes/application/nextcloud_connection.dart
lib/src/nextcloud_notes/application/notes_media.dart
lib/src/nextcloud_notes/application/notes_repository.dart
lib/src/nextcloud_notes/data/login_flow.dart
lib/src/nextcloud_notes/data/notes_api_client.dart
lib/src/nextcloud_notes/data/notes_attachment_references.dart
lib/src/nextcloud_notes/data/notes_capabilities.dart
lib/src/nextcloud_notes/data/notes_secret_store.dart
lib/src/nextcloud_notes/data/notes_store.dart
lib/src/nextcloud_notes/data/server_uri.dart
lib/src/nextcloud_notes/domain/notes_models.dart
lib/src/nextcloud_notes/presentation/nextcloud_settings.dart
lib/src/nextcloud_notes/presentation/notes_sidebar.dart
lib/src/search/search_replace_service.dart
lib/src/visualization/openapi_dependency_resolver.dart
lib/src/visualization/visualization_card.dart
lib/src/visualization/visualization_models.dart
lib/src/workspace/document_buffer.dart
lib/src/workspace/document_origin.dart
lib/src/workspace/presentation/settings_screen.dart
lib/src/workspace/presentation/welcome_screen.dart
lib/src/workspace/presentation/workspace_screen.dart
lib/src/workspace/session_persistence.dart
lib/src/workspace/workspace_controller.dart
lib/src/workspace/workspace_glyphs.dart
lib/src/workspace/workspace_model.dart
lib/src/workspace/workspace_service.dart
linux/runner/credential_key_policy.h
linux/runner/secure_credential_host.cc
pubspec.lock
pubspec.yaml
snap/snapcraft.yaml
test/src/ai_edit_ui_test.dart
test/src/localization_audit_test.dart
test/src/nextcloud_capabilities_test.dart
test/src/nextcloud_connection_test.dart
test/src/nextcloud_document_model_test.dart
test/src/nextcloud_editor_boundary_test.dart
test/src/nextcloud_login_flow_test.dart
test/src/nextcloud_media_export_test.dart
test/src/nextcloud_notes/notes_api_test.dart
test/src/nextcloud_notes/notes_attachment_references_test.dart
test/src/nextcloud_notes/notes_repository_test.dart
test/src/nextcloud_notes_ui_test.dart
test/src/nextcloud_secret_store_test.dart
test/src/nextcloud_workspace_test.dart
test/src/openapi_dependency_resolver_test.dart
test/src/source_audit_test.dart
tools/nextcloud_libsecret_probe.cc
tools/nextcloud_login_live_acceptance.py
tools/nextcloud_notes_live_acceptance.dart
tools/secure_credential_policy_probe.cc
tools/test_nextcloud_libsecret.sh
tools/test_secure_credential_policy.sh
```

## Explicit-adoption validation, 7 October 2026

This section supersedes earlier automatic-adoption expectations. Evidence is
retained in `delivery/nextcloud-explicit-adoption/evidence/` and the delivered
manifest records source and artifact hashes. Initial HEAD was `f9b734c`; the
workspace was clean before this work. No unrelated edits were discarded.

A pre-fix regression failed because discovery assigned server ID 1 without
confirmation. The replacement regression verifies repeated discovery first,
then explicitly confirms adoption before permitting an If-Match PUT.

Upstream `nextcloud/notes` tags v6.0.1 and v6.1.0 were inspected specifically at
`docs/api/v1.md` and `lib/Controller/NotesApiController.php`: POST accepts writable
attributes and returns the server note, without a client idempotency key; PUT
uses the server identity and ETag check. Payload equality is not identity proof.

Actual disposable HTTPS Notes **6.0.1** and **6.1.0** runs each passed **14 checks**,
including dropped successful POST response, staged attachment and newer edit
across restart, repeated nonmutating discovery, deliberate adoption, byte
verification, a second restart, and an independently created identical note
whose BusyMark POST was never delivered. CRUD, canonical metadata, ETag conflict,
chunking, deletion and version-specific attachment checks remain included.
The harness's separate `offline` transport-injection scenario is a repository
test and does not establish denied application network access.

Browser Login Flow passed anonymous start, pending 404, external-browser
launch, browser grant and one-time 200 credentials with disposable browser
profiles. Native libsecret store/read/delete and credential-policy checks passed
in an isolated keyring. Writerside conformance passed 181 checks. The Welcome
routing test passed without weakening its assertions (5 tests in the router
file). The native spelling package passed 13 tests.

Final regression validation used Flutter **3.47.5**, Dart **3.13.4**, the frozen
Linux release bundle and the CI spelling resources. The complete Nextcloud set
passed **216 tests**; the entire Flutter suite passed **3,638 tests, zero failures
and zero skips** in 18:21. The unchanged Welcome restoration assertion passed in
the full suite. Localization audit passed 21 tests, actual dictionary integration
passed 3, the native spell package passed 13 and Writerside conformance passed 181.
Formatting reported 544 files with zero changes; analysis reported no issues.
Dependency-lock enforcement succeeded without changing the lockfile.

The final confirmation UI regression clicks a real dropdown option and the
**Use this server note** action. A short timing poll initially failed under
load; the final test drives dialog-dismissal frames and real SQLite work while
retaining its binding, content, pending-revision and duplicate assertions. A
separate failing regression exposed unsaved draft edits arriving during the
confirmation GET; the commit-time controller guard fixes that race. Both
pre-fix failures and the superseded full-suite timing failure remain historical
evidence, alongside the successful final logs.

The native application and the actual installed **strict Snap** completed
browser Login Flow through the desktop portal and an external Chromium browser
with disposable profiles. Account credentials used the guest's libsecret Secret
Service and survived application restart. Both applications exercised staged
attachment creation, discarded successful POST response, restart, newer local
edit, repeated refresh without binding or publication, actual candidate-dialog
confirmation, canonical metadata, exact attachment bytes, one original POST and
another restart with the exact acknowledged revision. The native binding is
server note 184; the Snap binding is 223. Both preserve their original local IDs.
Snapshots, durable-state reports and server comparisons are retained.

Application network denial was real: native acceptance used a root-created
network namespace, and installed-Snap acceptance disconnected `busymark:network`.
The Snap kernel audit records denied Internet socket creation by the actual
`busymark` process; the UI preserved its offline draft and bytes across restart.
Reconnect created that previously unsubmitted draft once. No harness `offline`
flag is counted as application network acceptance.

The native final binary passed fresh dictionary installation and denied-network
restarts on X11 and Wayland in the disposable VM. Linux release visualization
and real WebKit smoke runs passed on both backends. Installed-Snap online and
denied-network X11 spelling passed. Its visualization run failed in WebKit
(`Unsupported result type`, with another run failing MathJax recovery). An
experimental Promise-retention change did not fix acceptance and was reverted.
Installed-Snap Wayland spelling subsequently passed all 20 checks with network
access denied. Wayland visualization failed during Mermaid/Typst export after
13 checks. At that stage, passing installed visualization acceptance remained outstanding.
Automatic approval review rejected uploading the source to public GitHub for
the Ubuntu CI run; explicit export approval was requested. These failed VM
checks are not counted as passing acceptance. The final KVM acceptance below
supersedes that incomplete release status while retaining these failed results.

The VM is Ubuntu **24.04.5**, kernel **6.8.0-142**, snapd **2.77.1**, software QEMU
TCG (2 CPUs, 4 GiB), Xvfb/Openbox and Weston headless. Its desktop portal has the
correct display/DBus environment. A disposable test CA was trusted only in the
VM/browser fixture; production HTTPS checks were preserved. The VM permits
unprivileged user namespaces for WebKit Bubblewrap; Snap AppArmor profiles remain
enforced, as independently proved by the network denials. `LP_NUM_THREADS=2`
caps software-renderer workers. The final native runs retain the existing smoke
assertions and timeouts. Earlier display/portal setup failures are fixture
history, not passed checks.

The Snap was built with **Snapcraft 8.11.1**, the official core24 builder and the
unchanged actual `snap/snapcraft.yaml`, from a fresh source directory after
`snapcraft clean --destructive-mode`. `snapcraft pack --destructive-mode` produced
the strict package. The development repack script was not used. The installed
payload checks verify SVG loading, GTK/WebKit/GNOME/Mesa libraries, fonts, media,
Git/SSH/session tools and Yaru assets. Required desktop, X11/Wayland, network,
content and manually connected password-manager interfaces were inspected.
The installed package SHA-256 matches the delivered recipe-built artifact.

The disposable accounts were deleted after application acceptance; both
HTTPS APIs returned 401 for their revoked credentials. All grants belonging
to those accounts, including application Login Flow grants, were invalidated.
Private fixture credentials, keys and Login Flow URLs are excluded.

Exact commands and final reports are under
`delivery/nextcloud-explicit-adoption/evidence/`. Key invocations were:

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter test test/src/localization_audit_test.dart
dart format --set-exit-if-changed .
flutter analyze
(cd packages/busymark_spellcheck_native && dart pub get && dart test)
tools/fetch_spelling_dictionaries.sh build/spelling-test
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" flutter test test/src/spelling_bundle_integration_test.dart
tools/validate_writerside_conformance.sh
flutter build linux --release
flutter test --no-pub --concurrency=1 --reporter expanded test/src/nextcloud_notes test/src/nextcloud_*_test.dart
BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY=:97 BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" flutter test --no-pub --concurrency=1 --reporter expanded
dart run tools/nextcloud_notes_live_acceptance.dart PRIVATE_CREDENTIALS SANITIZED_REPORT TEST_CA_PEM
```

The live commands ran separately against Notes 6.0.1 and 6.1.0 on disposable
Nextcloud 35.0.1 HTTPS installations. A persistent server lock through the
supported Files Lock OCS endpoint produced a real **423** while an unrelated note
synchronized successfully. The first Text browser lock probe did not produce
423 and remains a failed historical fixture attempt.

The final source identity is the commit recorded by the delivery manifest.
`linux-source-identity.json` and `snap-source-identity.json` record 568 compilation
input hashes matching that tree, the recipe hash, artifact hashes and frozen
binary hashes. Tests and documentation changed after the build only where they
do not enter compilation; the manifest and extracted-archive verification tie
their final bytes to the committed source and final test logs. The delivered
source archive is generated from that commit, with a fresh extraction checked
byte-for-byte and the complete Nextcloud regression set rerun there.

## Final installed acceptance and delivery, 7 October 2026

The original recipe-built Snap, SHA-256
`2b7c2a7b91a9aa7cbb7f23d35186e59a46173446b95ca9a14ddb5f667ca592ce`,
passed installed visualization on **X11 and Wayland: 23 checks each**, with a
second successful run on each backend. The repeat X11 command took 10 seconds;
the combined Wayland spelling/visualization command took 18 seconds. Installed
spelling passed **20 checks per run**, including fresh dictionary installation,
Snap revision refresh, and X11/Wayland restart with `busymark:network`
disconnected. Wayland visualization also ran with that interface disconnected.
The original assertions and timeouts were retained.

This fresh disposable VM uses **KVM, 4 CPUs, 4 GiB RAM**, Ubuntu **24.04.5**,
kernel **6.8.0-142**, snapd **2.77.1**, core24 revision **2124**, GNOME revision
**168** and Mesa revision **1839**. The content runtimes match the earlier TCG
fixture. The installed root-owned Snap hash, embedded recipe hash, AOT hash,
interfaces and enforced AppArmor profile were rechecked. The package and all
568 recorded compilation inputs are unchanged; no renderer workaround was
shipped and no executable was replaced during tests.

The fresh headless VM initially lacked a usable desktop activation environment.
A temporary D-Bus session could not create Snap's cgroup; its normal systemd
user session fixed that. GTK portal activation then waited on a missing display
and the first visualization attempt timed out. A persistent Xvfb display,
`dbus-update-activation-environment --systemd DISPLAY=:97 XDG_CURRENT_DESKTOP=GNOME`,
and explicit GTK portal selection provided a working Settings portal. Both
backends then passed repeatedly without the experimental `NO_AT_BRIDGE`
override. These observations explain the new fixture failures; they do not
establish the cause of every historical TCG `Unsupported result type` error.
All failures remain labelled in the evidence.

The installed commands were extracted from `.github/workflows/flutter-linux.yml`:
GTK SVG loading; shared-runtime/tool/media/resource inspection; dictionary
install/refresh/offline use; X11 visualization/PDF; and Wayland
spelling/visualization. Their only substitutions are the private report directory
and the exact package path. Scripts, logs, reports, exported HTML/PDF, desktop
configuration and kernel audit evidence are retained in
`delivery/nextcloud-explicit-adoption/evidence/installed-kvm/`.

Public source publication was explicitly approved after the initial automatic
review rejection. GitHub then returned **403, Resource not accessible by
integration**, and the existing SSH identity could not authenticate. No branch
or draft PR was created and no CI result is claimed. The authorized disposable
VM completed the installed-package checks instead.

Release acceptance is complete for the recorded source and artifacts: full
Flutter **3,638 passed / 0 failed / 0 skipped**, complete Nextcloud **216 passed**,
the earlier native/Writerside checks, real HTTPS Notes **6.0.1 and 6.1.0**,
real 423 isolation, actual browser/libsecret/application/offline adoption, and
the installed strict-Snap checks above. The application and test source remains
code commit `d55b41ddf47ef716d5113c89da8a3a2f3b80e819`; the final delivery commit
adds evidence and documentation. The final manifest names that commit and the
archives generated directly from it. Fresh extraction verifies every committed
file and build input, then reruns all 216 Nextcloud tests, including the top-level
files. Test accounts were revoked; the acceptance VM and private keys are removed
after evidence collection.
