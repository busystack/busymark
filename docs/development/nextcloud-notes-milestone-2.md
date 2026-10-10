# Nextcloud Notes Milestone 2

Baseline: `7b44bc2a54542c7741763e21e8a75f0a96d02cc1`, clean working tree,
`feature/nextcloud-notes-workspace`. No applicable `AGENTS.md`. Milestone 1
invariants and verification environment read; no reset or repeat audit.

Contracts: [Notes v6.1.0 API](https://raw.githubusercontent.com/nextcloud/notes/v6.1.0/docs/api/v1.md)
and [SQLite FTS5](https://sqlite.org/fts5.html) read before changes. Categories
remain slash-separated attribute values; read-only notes allow favorite-only
changes. Attachment filenames retain the established decode-once boundary.

This record lists implementation decisions and actual acceptance results.
Private fixtures, credentials, CA, profiles, screenshots and raw logs remain in
`/tmp/busymark-m2`. Initial ordinary Flutter invocation could not write the SDK
cache; required Flutter commands use the managed escalation boundary.

## Implementation decisions and locations

Module paths below are under `lib/src/nextcloud_notes/` unless qualified.

- Schema **5**, transactional migration from the reviewed schema 4, in
  `data/notes_store.dart`: FTS5 trigram index plus an ordinary indexed identity/
  revision mapping, account-scoped offline requirements/cancellation and import
  associations. Existing note JSON, conflicts, exact creation evidence, outbox,
  attachments and settings are retained. Index writes accompany every durable
  note write; bounded 32-note rebuilding yields the worker between requests.
  Missing derived indexes rebuild; newer schemas are rejected. Migration tests
  remove the new tables to exercise real old-schema creation and rollback.
- `application/notes_navigation.dart` and existing `presentation/notes_sidebar.dart`:
  descendant counts, destinations, deterministic activity/title ordering, stable
  local-ID selection/focus/open states, reviewed context targets and batch actions.
  Category and note rows are rendered through bounded scrolling viewports.
  `notes_repository.dart` applies field-aware patches inside its existing mutation
  boundary; `workspace_controller.dart` saves dirty target buffers first. Partial
  outcomes preserve successes. Read-only writes retain favorite-only payloads.
- `domain/notes_search.dart`, `application/notes_search_controller.dart`,
  `presentation/notes_workspace_ui.dart`: literal AND terms, phrases, title/
  category restrictions, Unicode whole-word verification and partial/short terms.
  NFC/lowercase trigrams narrow candidates; exact literal verification supplies
  original UTF-16 offsets, snippets and content digests. Dirty-buffer overlays run
  outside SQLite in an isolate. Bounded transfers, request generations, indexing,
  errors and Show more are explicit. Metadata-only matches highlight their own
  text without fabricating content offsets. Navigation checks revisions/digests,
  relocates changed occurrences and offers an explicit source action. Both Notes
  search entry points use this workflow; local search/replacement is preserved.
- `app/quick_open.dart`, existing command/shortcut/menu registries: Ctrl+P,
  deterministic exact/prefix/title/path ranking, keyboard selection/dismissal and
  focus restoration. Local paths and remote local IDs remain distinct. Unicode
  normalization is cached per candidate before sorting, following the real UI
  performance finding. Ctrl+Shift+P remains the command palette.
- `application/notes_offline_controller.dart`: separate note/category requirements,
  reconciliation after membership/reference changes, current-revision inspection,
  progress/missing/external/failure details and persistent cancellation. It invokes
  the existing repository resolver, preserving credentials, throttling, size and
  ownership checks, freshness invalidation and account-removal fences. Failed
  downloads wait for deliberate retry. Retained SQLite bytes survive cache-file
  cleanup/restart; removing requirements removes no document or sole upload copy.
- Recovery uses existing deleted records and Local History, account-scoped previews,
  actual supported-media availability and existing recover-as-new paths. Deletion
  conflicts remain in the ordinary list. No server trash/history is claimed.
- `application/notes_transfer_service.dart`, existing Markdown copy exporter and
  AtomicFileWriter: immutable saved local snapshots with attachment-generation/account fences, category directories,
  version-1 metadata manifest, collision/Unicode/path-safe names, cached recognized
  media, explicit omissions, staged publication/cancellation and bounded media
  copying. Reviewed imports validate source paths/symlinks/versions/digests, allow
  selection/category correction and create distinct identities. Note/outbox/media/
  source-item association commit together; restart/resume cannot duplicate a
  successfully imported item. Existing uncertain publication rules still apply.
  The pure media resolver was separated from its Flutter scope so the existing
  Dart live harness can reuse the same exporter/service.
- 29 new messages are translated in all 23 ARB catalogs; generated localization
  output is regenerated. Existing Writerside editing-button code and dependency
  pins are unchanged. User instructions and manifest format are documented in
  `nextcloud-notes.md`, the README and `docs/search-and-replace.md`.

## Acceptance evidence collected

Private reports/screenshots/logs are under `/tmp/busymark-m2`; no credential,
certificate, profile, raw report or test database is committed.

| Check | Actual result |
| --- | --- |
| Initial locked dependency resolution; localization generation | PASS |
| Localization audit | PASS, 21 tests; later combined localized UI run 53 passed |
| Focused Notes/controller/widget/command regression run | PASS, 270 tests, including metadata race, review corrections and synchronization coordinator suites |
| New deterministic M2 storage/repository/controller cases | PASS, 30 cases including original-offset metadata highlights, batch conflict blocking after held PUT/restart, export media fencing and account-removal publication cancellation |
| Local History store exhaustive group | PASS, 50 tests, complete file separately |
| Previously failing spelling/Local History workspace files | PASS, 285 tests, unchanged assertions |
| Secure credential policy and libsecret scripts | PASS, both scripts exited 0 |
| HTTPS browser Login Flow | PASS on Notes 6.0.2 and 6.1.0, disposable Nextcloud 35.0.1 fixtures, API 1.4, dedicated CA/hostname verification and browser certificate pin |
| Extended Dart live acceptance | PASS, final snapshot-fence rerun: 28 scenarios + 2 version entries on each baseline; includes batch/index/offline snapshot/recovery/resumable import and real subsequent HTTP synchronization |
| Native complete everyday journey | PASS on each baseline in two actual processes: 3 checks before offline shutdown + 13 after offline restart, proving pending identity/text/media and zero publication before continuing Quick Open/search → batch → reconnect/sync → category retention → disconnect/media → delete/recover → export/import |
| Separate actual offline process restart | PASS, final actual-process run after fixture removal: 14 checks, persisted account/category bytes, all four views, indexed search, Local History, actual OS Ctrl+P/Enter/Escape and Ctrl+Shift+P, local Markdown/Writerside Quick Open and native Ctrl+F search |
| Screenshots inspected | Populated sidebar, Quick Open, contextual search/highlights, batch targets, offline completeness, Recovery preview, export result, import collision/media review; corrected hidden snippet matches, compact row hit targets and misleading text/sync labels |

Tests cover nested/uncategorized/recovery inclusion, sorting and stable selection, including real Ctrl-toggle/Shift-range/Ctrl+A widget events and reviewed context targets surviving a concurrent reorder,
mixed permissions, concurrent unrelated/same-field metadata changes, offline
batch/restart; unopened/pending/dirty search, phrases/filters/whole words, short
Unicode/combining/technical terms and literal FTS operators, cancellation/paging,
stale relocation/index rebuild/deletion/account removal; independent retention,
new references, failures/manual retry/persistent cancellation/late account removal
and pending sole copies; deleted drafts/retained media/new-identity recovery;
nested duplicate-title/favorite/Unicode/percent Markdown+HTML media round trips,
unsafe versions/paths/symlinks/changed files, omissions, cancelled and failed
filesystem publication, partial import resume and transactional rollback; changed attachment generations or account removal prevent export publication without blocking unrelated local text edits.

## Reproducible 10,000-note performance

`tools/nextcloud_notes_performance.dart` is compiled with `dart build cli` and run
as a native product/AOT executable using the project's SQLite native build hook.
Corpus: 10,000 real durable notes, 1,279 category values including Uncategorized,
250 duplicate title values, **21,785,692 UTF-8 content bytes**, 2,000 cached
attachments / 4,096,000 bytes. Content includes Latin accents/decomposed combining
marks, Chinese, Japanese, Russian, Arabic, Korean, Greek and technical identifiers.
Reproduce with `dart build cli -t tools/nextcloud_notes_performance.dart -o /tmp/busymark-perf-build`, then `/tmp/busymark-perf-build/bundle/bin/nextcloud_notes_performance /tmp/busymark-perf-corpus` (use an empty corpus directory).
It performs a fresh rebuild, ten warm queries each, saves during rebuild/query,
and twenty durable imports during search. The database is 117,727,232 bytes.

Machine: Linux x64 7.0.0-34, Intel i9-9900K at 3.60 GHz (8 cores / 16 logical CPUs), 50,303,365,120 RAM bytes; Dart 3.13.4,
Flutter 3.47.5, actual SQLite **3.53.4** with FTS5 trigram support. All dependency
pins remain locked. Measured native report `performance-third/report.json`:

| Measurement | Actual |
| --- | --- |
| Corpus creation with maintained index | 39.862 s |
| Fresh initial index rebuild | 21.825 s |
| `token42` median / p95 | 48.747 / 52.049 ms |
| `"alpha beta" category:"Area 7"` median / p95 | 49.311 / 64.661 ms |
| `中文` median / p95 | 53.954 / 62.059 ms |
| `C++` median / p95 | 48.100 / 66.695 ms |
| `é` median / p95 | 44.573 / 55.456 ms |
| Durable saves during rebuild median / p95 / maximum | 41.745 / 170.007 / 592.668 ms |
| Durable save during query | 42.985 ms |
| Durable import during query median / p95 | 19.798 / 75.712 ms |
| RSS before / after repository loaded | 14,213,120 / 181,030,912 bytes |
| Reported maximum RSS | 180,297,728 bytes (OS sample counter) |

The packaged Linux UI also opened this real corpus plus the 20 imported notes,
rendered sidebar/search/Quick Open and saved while searching. Its first run
measured Quick Open 5,644 ms and a concurrent durable save 132 ms, RSS 617 MB /
maximum 630 MB, exposing repeated normalization in the ranking comparator.
That finding caused the candidate-normalization correction; final UI measurements
are: Quick Open **228 ms**, concurrent durable save **111 ms**, RSS 608555008 bytes / maximum 629751808 bytes, from `ui-corpus/ui-performance.json`. This is the actual Linux release application with the same real SQLite library, using Impeller OpenGLES with `LIBGL_ALWAYS_SOFTWARE=1` on isolated Xvfb `:97`; timing polls are 100 ms. It is not a mocked widget list or a hardware-GPU measurement. The service benchmark's bounded worker execution remained
responsive, but its worst rebuild save exceeded half a second under concurrent
build/test load; the measured maximum is retained here rather than concealed.

## Failed attempts and corrections

- Initial M2 tests exposed an outbox SQL typo and an isolate closure capturing the
  store; corrected and all new cases rerun. Dart live harness first failed to
  compile through a Flutter media-scope import; pure resolver extraction fixed it.
- Legacy widget selectors referred to the old filtering controls/properties
  button. Updated them to actual new destinations/search/menu and drained real
  SQLite work outside fake time, retaining assertions. A compact category row
  later missed pointer hit testing; explicit dimensions and a settled scroll fixed
  it. The exact category pointer scenario passed afterward.
- First native run used a stale fixture ETag for a simulated external update;
  fixture now gets its current ETag. Other attempts exposed uncertain creation
  during simulated transport loss, unavailable inline media when adjacent raw
  HTML shared its paragraph, and the fixture expecting `local.md` while Quick
  Open displays the extension-free title `local`. Corrected the journey to create
  online before offline edits, separate image blocks, and match the actual title.
  One capabilities request timed out during concurrent fixture/load work; the
  verified endpoint subsequently responded. Interrupted early native runs are
  retained in private logs; they are not represented as successful journeys.
- A concurrent focused run timed out the 30-second mixed-batch test during broad
  compilation/test load; all 26 cases subsequently passed alone in 4 seconds.
- First exhaustive remaining-file attempt was interrupted after spelling install
  and Local History workspace timing failures, plus cancellation/finalization
  errors. It is not a clean exhaustive run. A second four-worker attempt again hit the unchanged spelling-install timing failure and was interrupted; the final remaining-file group uses one worker. Both unchanged affected files passed
  together afterward (285 tests). A one-worker exhaustive attempt reached the source audits and exposed two implementation violations: Material icons outside BusyMark's glyph catalog and the old blanket Ctrl+P prohibition. Both controls now use the catalog, and the audit verifies the newly authorized Quick Open binding while retaining all no-print checks. That attempt completed with **4,168 passed, 2 failed, 0 skipped**. The corrected audit passed all 49 cases. Final exhaustive groups and exact totals follow.

- A final 6.0.2 live attempt stopped after 27 checks at an organization-sync assertion; the unchanged workflow rerun passed all 30. The assertion now reports state/error/deadline on failure; the transient cause was not established.
- The added pointer/keyboard production-widget test initially named a nonexistent batch widget; corrected to the existing BusyMark dialog shell. Its targeted run passed, then it entered the exhaustive current-file run.
- Export review identified a same-path media refresh race. Captured snapshots now carry attachment generations and account fences; refreshed bytes or account removal abort staged publication. Two new deterministic cases passed; analysis and all source audits pass.
- The separate restart harness initially required absent `xdotool`; a test-only standard-library X11/XTest helper now sends actual Ctrl+F events without adding an application dependency. The restart run passed all 11 checks. Actual OS Ctrl+P/Enter/Escape and Ctrl+Shift+P checks were then added; their first attempt exposed the harness's assumption that Quick Open had an explicit text controller. It now enters text through the rendered EditableText controller. The next attempt passed Ctrl+P/Enter/Escape but expected the wrong capitalization for the existing "Command Palette" title; corrected to the catalog label. The final native restart passed all **14** checks after the fixtures were removed.

- Directly invoking the non-executable credential scripts returned shell status 126; the documented Bash invocations both passed (exit 0), without permission/file changes.

- Before handoff, the prior native journey was tightened: its fresh-store reopen occurred before search, while its actual process restart occurred after synchronization. The final harness now supports `--stop-offline-m2` / `--resume-offline-m2`, retains only test-owned fixture IDs between processes, and stays offline through first-process shutdown. Both baselines passed the exact requested sequence (3 + 13 checks each), with pending text, stable identity and bytes asserted before publication. A draft assertion incorrectly treated the availability record as an object; corrected to its existing required/available/external fields. No production code changed.

## Final verification and completion

Implementation commits: `0ce81ca`, `860f18f`; production-widget selection regression: `383a403`.

The final exhaustive verification uses the documented bundled D2/Typst/spelling setup and native display `:97`, with `--no-pub --concurrency=1`. The complete Local History store file passed **50 tests**, exit 0 (`full-history-verified.log`). The other group uses all **200** paths from `remaining-test-files.txt` exactly once; the manifest SHA-256 is `623f4e141e1a877c18aee1a4a906c61d8a01c4e40521a66d893756eda36c622a`. A fresh filesystem comparison accounts for all **201** current files with no omissions/duplicates. That group passed **4,173 tests**, exit 0 (`full-remaining-verified.log`). Combined: **4,223 passed, 0 failed, 0 skipped**, in the established **two-group** approach. The new export-fence and production multiselection cases appear in the final log. This is exhaustive split verification; the single-invocation runner limitation remains documented in Milestone 1.

Both credential probes passed through Bash (exit 0). Final analysis found no issues; formatting checked **568 files, 0 changes**. The normal production release passed, exit 0 (`production-release-segmented-final.log`), restoring the production entry point after native acceptance. Locked dependency resolution and localization regeneration passed after implementation, with unchanged pins/generated output; the fresh localization audit passed **21** tests. Handoff repeats both SDK commands after the evidence commit and checks Git status.

Only test-owned fixtures were removed: both `busymark-m2-6-0` / `busymark-m2-6-1` containers and anonymous volumes, and the two proxies after verifying their PID/command/port. Cleanup exited 0. Private CA, credential/profile/report/corpus artifacts remain outside Git. The final shortcut restart test ran after the first fixture removal. Fresh isolated fixtures were then recreated for the exact two-process journey; browser Login Flow passed on both again, and the same owned cleanup was repeated afterward.

All five Milestone 2 areas are implemented, connected to the production UI, and verified together. No unresolved implementation or feature-acceptance blocker; no Milestone 3 work. Implementation and evidence are committed locally without merge, push, or publication.
