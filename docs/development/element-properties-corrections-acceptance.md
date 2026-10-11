# Element Properties targeted corrections

Date: 2026-10-11. Implementation commit: `38b8d157f334fd43d8abe58faddbf589a8c13148`. This record supplements
[element-properties-acceptance.md](element-properties-acceptance.md). It verifies
the four review corrections while retaining the workspace-owned inspector,
target/session logic, source-buffer transactions, schema baseline and supported
editing views. No dependencies or generated schema rules were upgraded.

## Contract and mappings

Official sources consulted: [paragraphs](https://www.jetbrains.com/help/writerside/paragraphs.html),
[links](https://www.jetbrains.com/help/writerside/links-and-references.html),
[images](https://www.jetbrains.com/help/writerside/images.html),
[lists](https://www.jetbrains.com/help/writerside/lists.html),
[admonitions](https://www.jetbrains.com/help/writerside/admonitions.html),
[topic navigation](https://www.jetbrains.com/help/writerside/structural-elements.html),
and [module defaults](https://www.jetbrains.com/help/writerside/writerside-cfg.html).
The supported builder remains **2026.08.0328**.

| Correction | Authored mapping and regression |
| --- | --- |
| Paragraph ownership | The existing Markdown inline grammar marks actual attribute syntax with source ranges. Paragraph ownership consumes a trailing parsed attribute token after inline references have consumed their own tokens. Inline code, escaped braces and formatted content are never flattened to locate attributes. Ordinary content edit → disk write → reparse tests preserve code, literals and reference properties. |
| List ownership | A standalone Markdown attribute line after the list describes the complete list. It uses the existing list container model and scanner ranges and remains native Markdown when editing list properties. An item-specific override materializes that list through the existing XML model/serializer, with properties on the selected `li`. Other items, formatted body content, checked task state and surrounding ranges remain intact. Checkbox items map deliberately to `li@checked`; editor `task` metadata never leaks into source. Markdown chapter ancestry is navigation, not physical parentage. |
| Admonition persistence | Native quoted content retains its supported representation. Common semantic properties serialize on the admonition's attribute line, separated by a blank line. Parser and lossless scanner attach that line to the admonition, not to a child paragraph. Style-only authoring retains its established representation. |
| Navigation selector | Classification uses `WritersideEditingAdapter.sourceAttributes`, excluding `element` and other projection metadata. Absent declaration = default; empty declaration = All; `for="none"` = None; other authored attributes = Custom. Widget and native tests select, save, close, reopen and inspect the selected value. |
| Definition layout | The curated layout control uses the shared effective-property resolver and schema enum, including reset labels and origin tooltip. The module-default fixture sets `deflist.type=medium`. Local Wide and Full overrides remain distinct; resetting removes the override. Medium's label now correctly describes its 1:2 ratio through the ARB/generated-localization workflow. |

The workspace compares authored model state before accepting unchanged
serialization. A genuine no-op remains successful; a semantic change that never
reaches source is rejected with localized feedback and a retained draft. The
comparison excludes transient editor placeholders and includes fence language,
admonition style and topic navigation. Item reconciliation uses semantic
ordinals so XML whitespace nodes cannot move the inspector to another item.
Existing exact buffer/revision/source and stale-target guards remain in place.

## Pinned-builder observations

The expanded `property_conformance` and `property_defaults_conformance` fixtures
retain all previous collapse and reference cases and add literal code/braces,
inline reference ownership, whole-list and individual-item IDs, admonition IDs
and layout defaults/overrides. `tools/verify_writerside_property_fixture.py`
asserts generated HTML, not only the process exit.

* An adjacent admonition property line with an ID reproduced **MRK003**: the
  builder assigned the same ID to the outer admonition and its paragraph. A
  blank line before the attribute line produces one `aside.prompt` with that
  ID and a separately identified paragraph. This positive form passes the
  official duplicate-ID inspection and is used for semantic property edits.
* The native list suffix produces `ul#native-list`; the explicit item override
  produces `li#converted-list-item` under its list. The builder retains the
  authored `instance` and `filter` source without inspection errors.
* Native task lists and `<list type="checkbox">` both publish checkbox lists. `li@checked="true"` retains the checked state; absence and explicit `false` both retain unchecked state (the builder omits the published `checked` marker for false). This builder-verified boolean overlay uses the existing `writerside_schema.dart` mechanism because the published generated XSD omits it. The generated data and baseline are unchanged. Save/reopen, later checkbox toggling and invalid boolean rejection are regression-tested.
* With no local type, a definition list renders `data-style="title-top"` under
  built-in defaults. A module `type=medium` changes it to
  `data-style="title-left" data-title-width="medium"`. Explicit Wide renders
  `data-title-width="wide"`; explicit Full remains `title-top` in both modules.
* Literal `{id="literal-code"}` stays code text and never becomes an element ID.
  Inline link/image IDs belong beneath their separately identified paragraphs.

## Executed gates and evidence

Five focused regressions reproduced the four reported defects before correction: paragraph inline ownership, individual list properties, admonition properties, navigation selected value and module layout. Their original failing output is retained as `reproduction.log`.

The fresh evidence directory is
[evidence/element-properties-corrections/](evidence/element-properties-corrections/).
Prior milestone screenshots are not evidence for these corrections.

Commands use `/home/albert/flutter/bin` (Flutter 3.47.5 / Dart 3.13.4), `--no-pub`
and the existing lockfiles:

```sh
flutter gen-l10n
flutter test --no-pub test/src/writerside_properties_round_trip_test.dart \
  test/src/writerside_authoring_ui_test.dart test/src/writerside_inspector_session_test.dart
flutter test --no-pub test/src/writerside_admonition_test.dart
flutter test --no-pub test/src/localization_audit_test.dart
(cd packages/busymark_spellcheck_native && dart test)
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed .
bash tools/test_secure_credential_policy.sh
flutter build linux --release --no-pub
BUSYMARK_D2_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/d2" \
BUSYMARK_TYPST_PATH="$PWD/build/linux/x64/release/bundle/libexec/busymark/typst" \
BUSYMARK_TEST_SPELLING_ROOT="$PWD/build/spelling-test" \
flutter test --no-pub --concurrency=1
WRITERSIDE_CONFORMANCE_OUTPUT=/tmp/busymark-inspector-corrections-builder-verified \
bash tools/validate_writerside_conformance.sh
flutter build linux --debug --no-pub \
  --target=test/support/writerside_authoring_native_smoke.dart
docker exec busymark-properties-native bash -lc '
  cd /workspace
  WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1 NO_AT_BRIDGE=0 \
  GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 BUSYMARK_NATIVE_PROBE=1 \
  xvfb-run -a -s "-screen 0 1440x1000x24" dbus-run-session -- \
    build/linux/x64/debug/bundle/busymark \
    test/fixtures/writerside/conformance_project \
    /evidence/busymark-inspector-corrections-native-verified-20261011'
```

The display-dependent GTK gate uses the existing
`test/support/native_writerside_dialog_host_test.cc`, compiled with
`-std=c++14 -Wall -Werror`, the production Flutter GTK library and method-call
response wrapper, then executed with `xvfb-run` in the same disposable runtime.
All four directional native dialog cases pass. The full Flutter suite skips its
display-dependent wrapper when no isolated `DISPLAY` is configured; the direct
native execution supplies that coverage.

The existing native smoke harness boots the production `BusyMarkApp` workspace
and uses X11/GTK controls, native keyboard shortcuts and actual file save/close/
reopen. The added workflows cover all four corrections, item conversion target
and ancestry, one undo/redo, module layout override/reset and reopened selector
values. Existing Source, Split, Reading, narrow overlay, RTL/scaling and focus
checks still execute. The disposable runtime uses its existing WebKit sandbox
workaround; host security settings are unchanged.

During validation, the integrated native case found the chapter-versus-physical
parent distinction missing from the initial item conversion. A dedicated
regression now covers it. The complete suite also caught a style-only admonition
spacing change; the implementation preserves that established source contract. It also caught a space-prefixed attribute block missed by the first syntax rule, which lost a diagram source reference. The rule accepts that established spelling, verified by the original diagram and export tests. Escaped/entity braces and dotted attribute names have additional preservation cases.
The harness restores its previous code target after the new layout workflow
before executing its original keyboard-traversal assertions. A final continuation probe found that toggling a reopened task item after an ID edit could leave its old property patch in control. The checkbox change now merges into that patch; the ordinary authoring action and subsequent save/reopen are regression-tested. The final complete suite was restarted after this correction. Assertions were
retained and no tests were disabled.

The final-binary full native run completed **161 checks** with no failure. A
supplementary inspector-only run moves only its own X11 window to `(0, 0)`
before capture, so the enlarged window fits completely within the 1440×1000
isolated display. It uses the same production binary and save/reopen assertions.
The supplementary run completed **93 checks**, also with no failure; its three saved inspector topics match the full run byte for byte. The full run's saved project also passed **181 official-builder checks** and the
native HTML assertions. The saved module-default project passed another **181 builder checks** and `native-defaults` HTML assertions confirming Medium after reset. The final complete Flutter suite passed **4,374 tests** in 19m57s. Its single skipped isolated-display wrapper is covered by the four passing native GTK dialog cases.


The saved native projects were copied out of the disposable runtime and checked
with the same conformance entry point, followed by:

```sh
python3 tools/verify_writerside_property_fixture.py \
  /tmp/busymark-inspector-corrections-native-published-verified/webHelpCONFORMANCE2-all.zip native
python3 tools/verify_writerside_property_fixture.py \
  /tmp/busymark-inspector-corrections-native-defaults-published/webHelpCONFORMANCE2-all.zip native-defaults
```


## Final results

| Gate | Final result |
| --- | --- |
| Focused property/session/widget regressions | 98 passed |
| Existing diagram and visualization export regressions | 10 passed |
| Complete Flutter suite | 4,374 passed; one display-dependent wrapper skipped and covered by direct native GTK execution |
| Localization audit | 21 passed; all ARB/generated catalogs updated |
| Native spelling package | 13 passed |
| Native GTK dialogs | 4 passed under isolated X11 |
| Analysis | No issues |
| Formatting | 596 files; zero changes |
| Security policy | Exit 0 |
| Linux production release and native acceptance builds | Both passed, locked dependencies |
| Production workspace native run | 161 checks; no failure |
| Supplementary framed inspector run | 93 checks; no failure |
| Pinned builder | Six fixture/saved-project validations, 181 checks each; zero errors/warnings; property/reference/native HTML assertions passed |

No required gate remains unexecuted. No tests were disabled or assertions
weakened. The one Flutter skip is the existing isolated-display wrapper; its
native cases ran directly. The implementation retains the workspace inspector
architecture, schema builder pin and lockfiles. Evidence includes original
screenshots, saved source, generated HTML, official reports and execution logs.
Artifact hashes are in
[evidence/element-properties-corrections/SHA256SUMS](evidence/element-properties-corrections/SHA256SUMS).
