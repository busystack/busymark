# Element Properties acceptance

This record covers the workspace inspector change against BusyMark's unchanged
Writerside builder/schema baseline **2026.08.0328**. Generated schema data and
locked dependencies were not replaced. The defect reproduction is retained in
`test/src/writerside_properties_round_trip_test.dart`: before the repair, ten
focused persistence cases failed (`/tmp/busymark-properties-before.log`).

## Implementation contract

The workspace owns visibility, preferred width and the inspected target. A target
captures buffer identity, revision, exact source, model, physical element address
and inline occurrence context. Parser-generated IDs locate nodes only inside
that snapshot. Ancestors come from the inspected node; native Markdown chapters
use the existing structural heading interpretation. Source resolves through
existing source spans and inline source mappings, without a hidden Editor.

The target-bound property session stores pending text and captured mutation
callbacks outside individual field widgets. Enter and blur commit; Escape
reverts. Save, panel hiding and document/view transitions flush explicitly.
Invalid and conflicting drafts block a transition instead of being discarded.
All successful workspace mutations use `applyInspectorSource` and the existing
buffer transaction, preserving Source selection and one history entry. Reading
and read-only buffers reject publication at the transaction boundary.

Curated controls use the existing schema/capabilities for applicability and
allowed values. Advanced excludes editor projection metadata. Native Markdown
attribute edits preserve native syntax; embedded XML attribute edits reuse the
existing authored parser and serializer to patch the original opening tag.
XML attribute spans preserve unrelated quotes, namespace declarations/rebinding,
comments and raw children. Source protection remains active for unsupported nodes.

The effective resolver is shared with the semantic pipeline and Editor folding.
Authored absence/expressions remain separate from resolved defaults and origin.
Opening the inspector does not serialize effective values. Definition-item
collapse comes from the list. Local expansion remains a session preference.

## Verified mappings

| UI/property | Authored representation | Verification |
| --- | --- | --- |
| Paragraph ID | Native Markdown trailing attribute block or XML `p@id` | Edit/remove, formatted text, Unicode, reference syntax and CRLF reparse |
| Code language | Fence info string or authored Markdown `lang` override / XML `lang`; editor `language` stays projection metadata | Deliberate mapping, override/reset reparse, builder HTML and source serialization |
| Code ID/switcher/collapse/state/extraction/emphasis | Attribute line after fence / `code-block` attributes | Attribute-only lines parse without source/collapse; explicit false and removal persist |
| Heading text/title override | Native heading text independently of `title`; XML title attribute | Child title content stays raw and separate |
| List/item state | `deflist@default-state`, `def@default-state`, including literal `inherited` | Shared resolver plus generated HTML assertions |
| Tabs | Parent `group`, child `group-key`/title | Existing add/reorder/remove tests and production native workflow; code-based groups protected from mixed child creation |
| Images | Existing image model, inline/block mapping and typed scalar attributes | Link wrappers, separate image occurrences and reference syntax survive scalar changes |
| Includes | `from`/`element-id`/optional `origin` together | Existing project index and resolver; picker publishes one tuple |
| Topic switcher label | XML root attribute / preserved Markdown front matter | Native save/reopen workflow and quoted-label undo/reopen tests |
| Topic navigation | Absent declaration / empty `show-structure` / `for="none"` | Separate reset; scoped or multiple declarations reject simple mutation |

## Official contract and pinned observations

Sources consulted: JetBrains [semantic markup](https://www.jetbrains.com/help/writerside/semantic-markup-reference.html),
[collapse](https://www.jetbrains.com/help/writerside/collapsible-elements.html),
[code](https://www.jetbrains.com/help/writerside/code.html),
[paragraphs](https://www.jetbrains.com/help/writerside/paragraphs.html),
[references](https://www.jetbrains.com/help/writerside/links-and-references.html),
[images](https://www.jetbrains.com/help/writerside/images.html),
[tabs](https://www.jetbrains.com/help/writerside/tabs.html),
[structure](https://www.jetbrains.com/help/writerside/structural-elements.html),
[module settings](https://www.jetbrains.com/help/writerside/writerside-cfg.html) and
[inspections](https://www.jetbrains.com/help/writerside/inspectopedia.html).

The two authored fixtures are `test/fixtures/writerside/property_conformance` and
`property_defaults_conformance`. They use the existing official-builder fixture
mechanism; `tools/verify_writerside_property_fixture.py` inspects generated HTML,
including class/state/data attributes and extracted snippet text. Builder exit
status alone is not used as proof of effective state.

Observed in the pinned generated HTML:

- Chapters, procedures, code and definition lists require effective
  `collapsible=true`. State-only forms do not enable collapse, in either XML or
  native Markdown. Current chapter documentation describes a different behavior;
  BusyMark follows the supported builder and records that discrepancy.
- Explicit false disables collapse even with an expanded state or a module
  collapse default. A source reference alone leaves code uncollapsed; an
  independent module default can enable collapse.
- Enabled collapse defaults to collapsed; authored/module expanded state opens it.
- Definition-item collapse is controlled by the list; local item false does not
  disable a collapsible list item in this builder.
- Without a module item-state default, absent and literal `inherited` item state
  follow the list. With module item state collapsed, absence uses the module,
  while literal `inherited` uses the expanded list state.
- Extraction selects source lines 2–3; emphasized line 1 refers to the displayed
  second source line. Generated snippet text and emphasis metadata are checked.
- Formatted conditional title children survive a separate default-title edit;
  title-child-only chapters are accepted and publish their child title.
- Native reference-image `src`, `alt` and width overrides publish the selected
  image while retaining the reference definition and surrounding link. The
  paragraph fixture explicitly uses `style="inline"`, as required for its size.
- Native link `href` attribute overrides are ignored. Destination editing changes
  only that occurrence to a direct native Markdown link, retaining formatted
  text and leaving the definition and other occurrences intact.
- Explicit empty XML/native image alt remains authored. In the `logo.png`
  fixtures the builder publishes `Logo` as its fallback; this observation is not
  generalized to an unverified filename transformation algorithm.
- Native Markdown `lang` overrides the fence info string. The fixture uses a
  Java fence with `lang="text"` and publishes `data-lang="none"`. Language edits
  update an existing override; resetting it reveals the original fence language.
  Authored unknown attributes named `language`, `element` or `level` are retained
  separately from editing metadata through scalar and content changes.
- Chapter and code collapse/state expressions resolve from `v.list` to true and
  expanded in generated HTML. The code case authors `ignore-vars="false"`.
  Missing variables remain unresolved in BusyMark's resolver tests; their source
  expressions are preserved rather than replaced with hard-coded values.
- Writerside's front-matter rewrite embeds the switcher label in an XML
  attribute. Literal double quotes, or YAML/JSON quoting around them, produce
  `MRK002` in a minimal official-builder fixture. XML entity encoding passes.
  BusyMark now encodes quotes, ampersands, angle brackets and whitespace without
  adding YAML quotation marks, then decodes the label for re-inspection. A CRLF
  regression checks insertion, replacement and removal while retaining the
  original delimiter and unrelated metadata bytes.

Documentation identifies a known external-image sizing limitation. The inspector
disables dimension changes for hosted images while retaining inspection/reset of
authored sizes. It does not claim hosted dimensions as verified builder sizing. No
external-image download was used as evidence.

## Commands and results

The installed Flutter **3.47.5**, Dart **3.13.4**, and locked packages were used.
Commands requiring Flutter cache writes or Docker used the workspace's approval
mechanism. No toolchain/dependency upgrade was performed.

- Focused original defects: ten failures before fixes; expanded round-trip/session
  cases pass after fixes. Focused authoring, Source widget, selection lifecycle,
  workspace/settings and preservation suites were executed.
- `flutter gen-l10n`: generated from all ARB catalogs. Catalog audits are required.
- `bash tools/test_secure_credential_policy.sh`: passed.
- Native Hunspell package `dart test`: **13 passed**.
- Production GTK accent lookup/observer with `xvfb-run`: passed, GTK 3.24.41,
  `GdkX11Display`.
- `bash tools/validate_writerside_conformance.sh`: baseline, reference, properties
  and module-default fixtures each passed **181 builder checks**; existing
  authored-reference and new HTML behavior assertions passed.

Earlier failed runs were investigated; assertions were not weakened or disabled.
The full suite with parallel workers hit dictionary/template and clipboard I/O
deadlines. Isolated retries passed without implementation or timeout changes;
the complete acceptance run uses one worker with every installed dictionary and
the bundled D2/Typst paths. An ambiguous Home Page test finder was narrowed to its
existing popup menu item after Topic became available in the workspace inspector.

The first broad native-authored builder run stalled with `Markdown gist rewrite:
consumed 0 recorded headings, expected 1`. The retained builder log led to a
minimal quote-bearing switcher-label fixture, which exposed `MRK002`. The
corrected complete native-authored project passes the builder and generated HTML
checks. This was not attributed to network failure or worked around by removing
the affected authoring pages. Fixture root IDs were also made explicitly distinct
for XML and Markdown topics with the same visible title, resolving `INT002`.

Final commands, counts and durable evidence are listed below.

## Native environment and evidence

`test/support/writerside_authoring_native_smoke.dart` boots **BusyMarkApp**, its
production workspace, isolated settings/history/recovery and copied project.
`tools/linux_native_menu_probe.py` drives GTK menus through AT-SPI and native
keyboard chords through xdotool. This is an integrated workspace workflow, not a
standalone properties harness. Save assertions wait for disk completion; reopen
assertions re-inspect properties in the new document generation.

Linux verification ran in isolated Docker image
`busymark-adoption-snapcraft-ready:latest`, using Xvfb, GTK, AT-SPI, Mesa software
rendering and a session bus. The container cannot create the user namespaces
needed by WebKit's sandbox, so the native probe used the container-only
`WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1`; host security settings were not
changed. Production release builds do not set that override.

Weston **13.0.0** was installed only in that disposable runtime to exercise
Wayland with its headless Pixman renderer. Spelling restart checks ran with the
container's bridge network disconnected; its connection was restored afterward.
The packaged dictionary catalog and notices were verified, no dictionary pairs
ship in the bundle, and the installed dictionary/personal word survived offline
restarts under both X11 and Wayland.

Native acceptance checks identity/ancestry with caret in A and inspected B;
Source without a hidden Editor; focused native Ctrl+S and exactly one undo;
invalid Save/view/hide cancellation and Escape; XML/Markdown save/close/reopen;
Split/Reading; default/override/reset; source-neutral local folding; wide/narrow;
light/dark; RTL/scaling; and ordinary Markdown isolation. Evidence includes
screenshots, result JSON and reopened source snapshots. Final evidence locations
and actual results follow.

## Acceptance commands

Run from the repository with the installed SDK on PATH. All Flutter commands
used `--no-pub`; the package test used its existing lockfile.

```sh
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze --no-pub
bash tools/test_secure_credential_policy.sh
(cd packages/busymark_spellcheck_native && dart test)
flutter build linux --release --no-pub
BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" \
flutter test --no-pub --concurrency=1
WRITERSIDE_CONFORMANCE_OUTPUT=/tmp/busymark-properties-builder-publishable \
bash tools/validate_writerside_conformance.sh
```

Native workspace entry point and actual controls:

```sh
flutter build linux --debug --no-pub \
  --target=test/support/writerside_authoring_native_smoke.dart
WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1 NO_AT_BRIDGE=0 \
GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 BUSYMARK_NATIVE_PROBE=1 \
xvfb-run -a -s '-screen 0 1440x1000x24' dbus-run-session -- \
build/linux/x64/debug/bundle/busymark \
test/fixtures/writerside/conformance_project \
/evidence/busymark-properties-native-acceptance-20261011
```

The environment in the preceding command belongs to the isolated container.
Production release checks used `--visualization-release-smoke=REPORT` under
X11/Xvfb and Wayland/Weston, plus `tools/visualization_smoke.py` with the packaged
assets, D2 executable and PlantUML corpus. Both native visualization corpora
passed **36 checks**; both release JSON reports have `ok: true`, **9 HTML pages**,
**0 HTML warnings**, and successful Typst/PDF image checks. Release spelling used
`--spelling-release-smoke=REPORT` with an isolated `XDG_DATA_HOME`: online X11
installed exactly one dictionary, offline X11 and Wayland reopened it and the
personal word with `ok: true`. GTK host lifecycle checks passed; the isolated
native Writerside dialog fixture passed all **4** RTL/LTR cases.

The complete native-authored project was copied from the runtime and passed
**181** pinned builder checks. Generated HTML asserts source inclusion without
implicit collapse, extracted lines, displayed emphasis and inherited definition
state. The final run's four saved topic snapshots are byte-identical to that
accepted source tree; their hashes are recorded with the evidence.

## Durable evidence

Evidence lives in [evidence/element-properties](evidence/element-properties/).
It contains the **118-check** native result, actual saved/reopened XML and
Markdown, build/analysis/native/builder logs and reports, and SHA-256 inventory.
Console log line endings are normalized to LF for Git; authored source snapshots
retain their original bytes.
The snapshots `generated.topic` and `generated.md` cover the preserved native
authoring workflows, including the quote-bearing topic switcher label.

Representative actual workspace captures:

| Case | Screenshot |
| --- | --- |
| Caret A, inspected nested container B | [Nested target](evidence/element-properties/inspector-nested-target.png) |
| Accepted code properties | [Code properties](evidence/element-properties/inspector-topic-code-properties.png) |
| XML Source integration | [XML Source](evidence/element-properties/inspector-topic-source-code.png) |
| Markdown Source integration | [Markdown Source](evidence/element-properties/inspector-md-source-code.png) |
| Module defaults and explicit override | [Defaults](evidence/element-properties/inspector-module-defaults.png), [override](evidence/element-properties/inspector-module-override.png) |
| Dismissible narrow overlay | [Narrow window](evidence/element-properties/inspector-md-narrow-overlay.png) |
| Split and read-only Reading | [Split](evidence/element-properties/inspector-md-split.png), [Reading](evidence/element-properties/inspector-md-reading.png) |
| Dark, RTL and scaling | [Dark](evidence/element-properties/authoring-topic-dark-narrow-vertical.png), [RTL/scaled](evidence/element-properties/authoring-topic-rtl-scaled.png) |
| Invalid draft retained | [Validation](evidence/element-properties/inspector-topic-invalid-draft.png) |

Screenshots accompany disk/reopen, selection, history and transaction assertions;
they are not used alone as evidence of successful mutation or persistence.

## Final results — 2026-10-11

| Gate | Result |
| --- | --- |
| Complete applicable suite with real spelling/D2/Typst resources | **4,364 passed**, **1 skipped**, **0 failed**; 18m56s |
| Skipped Dart native-dialog wrapper | Its isolated C++ GTK fixture ran separately: **4 passed** |
| Native workspace across Editor/Source/Split/Reading | **118 passed**, no failure; XML/Markdown saved and reopened |
| Official builder 2026.08.0328 | Baseline, references, properties, defaults and complete native-authored project: **181 checks each**, no errors/warnings |
| Published semantics | Generated HTML checks passed for collapse/state/defaults/inheritance, expressions, extraction/emphasis, native/embedded code, titles and images |
| Localization | ARB generation and full-suite localization audits passed |
| Format/analysis/security | **596 Dart files, 0 formatting changes**; **no analysis issues**; credential policy passed |
| Native Hunspell package | **13 passed** |
| Production Linux release | Build passed with installed/pinned toolchain and locked dependencies |
| GTK dialogs/host lifecycle | Passed, including direction, native channels and destruction order |
| X11/Wayland native visualization | **36 passed each** |
| X11/Wayland release PDF/HTML/visualization | Both `ok: true`, **9 HTML pages**, **0 warnings**, PDF/image checks passed |
| Online/offline release spelling | X11 installation, X11 offline restart and Wayland offline restart passed |

No required acceptance gate remains unexecuted. Temporary runtime limitations
were handled inside the disposable container as described above. The generated
schema, supported builder version and package lockfiles remain unchanged.

The four subsequent parsing/persistence/default corrections are recorded in
[element-properties-corrections-acceptance.md](element-properties-corrections-acceptance.md),
with fresh production-workspace and pinned-builder evidence.
