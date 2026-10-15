# Writerside verification

The user-facing [Writerside support](../writerside-support.md) page describes the
supported semantic surface and known limitations. This note contains the
maintainer checks behind those claims.

## Mutation and resource constraints

TOC changes validate source identities and expected disk content at publication.
Affected inactive buffers participate in dirty-buffer checks. Multi-file title
edits and refactoring use guarded publication and rollback; file-monitor events
are deferred during foreground file operations. Structural serialization
preserves semantics, not original XML whitespace.

`WritersideTopicRemovalService` analyzes the complete project, including
non-active and nested modules. Its snapshot covers module discovery, topic and
tree sources, variables, instance groups and redirect rules. Hidden and ordinary
build/output directories participate in semantic discovery; `.git`, `.hg` and
`.svn` remain excluded. Incomplete discovery, unparsed topics or changed inputs
block publication. Ownership follows parsed paths or the most-specific containing
module with a configured topic root. Safe Delete is mandatory for Writerside
topics, and unresolved semantic references remain manual blockers in Find.
Apply reanalyzes the project,
publishes guarded updates and deletes the topic last; rollback must not
overwrite another process's changes.

Creation and Markdown import require complete topic discovery and reserve IDs
across every configured topic root, including unparsed files. Import stages
selected topics, deduplicated referenced media and tree changes together,
rechecks snapshots and rolls back on failure. Creation uses exclusive file
creation and rechecks semantic ID ownership before publishing the tree. A
concurrent collision must not leave a partial topic/media/tree publication.

`assets/writerside/templates.json` retains each bundled resource's archive path,
source and SHA-256; keep `assets/writerside/TGDP-LICENSE` with it. Template-store
writes use an isolate queue, process file lock, expected snapshot and atomic
publication. Reject corrupt or non-regular stores. Names are unique within
category and extension; generation does not evaluate Velocity. Validate XML and
root IDs before topic publication.

Linux TOC menus use the existing `busymark/native_menus` GTK channel. Only
enabled leaves may dispatch, including under disabled ancestors. GTK submenu
heading sensitivity is applied explicitly; depth and entry limits, RTL,
anchoring, dismissal and focus return remain part of the contract. The main
application menu remains flat.

## Automated coverage

The Writerside tests cover resolution, source preservation, anchored file
access, instance changes, source assistance, widgets, editing, and export. A
native Typst integration test runs when the bundled compiler is present and is
explicitly skipped otherwise. API unit tests inject the platform parser
interface; they do not claim to exercise the native WebKit parser.

Run the focused suite with:

```bash
flutter test --no-pub test/src/writerside*_test.dart \
  test/src/source_autocomplete_test.dart \
  test/src/source_editor_widget_test.dart \
  test/src/workspace_controller_test.dart \
  test/src/markdown_export_mapper_test.dart
```

The TOC action/workspace/editor, topic-creation/removal, template and title/TOC
regression suites cover these publication constraints and the documented
[authoring limitations](../writerside-instances.md#toc-authoring-and-limitations).
Widget menu fallbacks do not establish native GTK behavior.

## Linux TOC acceptance harness

`tools/writerside_toc_visual_smoke.dart` exercises production controllers,
widgets and real GTK menus, including keyboard traversal, RTL, disabled
headings, dismissal, focus return, TOC operations and template workflows. It
copies `test/fixtures/writerside/toc_ui` into a temporary workspace and isolates
settings, session, recovery, history and template storage.

Run from the repository root with Python GTK/AT-SPI introspection, XTest, Xvfb
and D-Bus installed. Keep captures and results outside the repository:

```bash
toc_output="$(mktemp -d)"
flutter build linux --debug --no-pub --target tools/writerside_toc_visual_smoke.dart
BUSYMARK_NATIVE_PROBE=1 GDK_BACKEND=x11 NO_AT_BRIDGE=0 \
  dbus-run-session -- xvfb-run -a -s '-screen 0 1440x1000x24' \
  build/linux/x64/debug/bundle/busymark \
  test/fixtures/writerside/toc_ui "$toc_output"
flutter build linux --debug --no-pub --target lib/main.dart
```

The harness exits nonzero on failure and writes `result.json` with its checks
and temporary fixture path. Remove the output and disposable fixture after
inspection. It verifies BusyMark's native interactions, not visual parity with
the original IDE or comprehensive assistive-technology support.

## Linux Element Properties harness

`test/support/writerside_authoring_native_smoke.dart` opens the production
`BusyMarkApp` workspace with isolated settings, history, recovery and template
storage. It copies `test/fixtures/writerside/conformance_project` and
`test/fixtures/writerside/property_defaults_conformance`, then drives GTK menus
and native keyboard shortcuts through `tools/linux_native_menu_probe.py`.

Use the pinned Flutter SDK and the Linux build dependencies listed in the README,
plus Python GTK/AT-SPI introspection, XTest, xdotool, Xvfb and a D-Bus session.
Run from the repository root with an isolated display and software rendering:

The harness keeps an AT-SPI probe connection alive until its application exits.
This avoids GTK's [key-listener lifetime bug](https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/10391)
when the last short-lived automation client disconnects during key dispatch.
Accessibility remains enabled; every command still queries real native controls,
and premature probe termination fails the workflow.

Finish the debug build and retain its complete bundle before starting a release
build. Flutter shares generated asset outputs between configurations; concurrent
builds can remove the debug harness's `data/flutter_assets/kernel_blob.bin`.
Check that file before launch. Keep retained bundles outside the checkout.

On GLVND hosts where the NVIDIA vendor blocks an isolated software display,
select the installed Mesa vendor for both Xvfb and the application. For a system
with `/usr/share/glvnd/egl_vendor.d/50_mesa.json`, use
`__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json` and
`__GLX_VENDOR_LIBRARY_NAME=mesa` alongside `LIBGL_ALWAYS_SOFTWARE=1`.
For an isolated CPU-rendered WebKitGTK 2.52 fixture that cannot initialize its
GBM EGL display, the verified environment also uses
`WEBKIT_DISABLE_DMABUF_RENDERER=1` and `WEBKIT_SKIA_ENABLE_CPU_RENDERING=1`.
These are fixture rendering settings; retain WebKit's sandbox protections.

```bash
unset BUSYMARK_PROPERTY_CONTRACT_ONLY BUSYMARK_INLINE_REFERENCES_ONLY \
  BUSYMARK_VARIABLE_MEDIA_ONLY BUSYMARK_NAVIGATION_ONLY BUSYMARK_PROPERTIES_ONLY
inspector_output="$(mktemp -d)"
flutter build linux --debug --no-pub \
  --target=test/support/writerside_authoring_native_smoke.dart
BUSYMARK_NATIVE_PROBE=1 GDK_BACKEND=x11 NO_AT_BRIDGE=0 \
  LIBGL_ALWAYS_SOFTWARE=1 \
  dbus-run-session -- xvfb-run -a -s '-screen 0 1440x1000x24' \
  build/linux/x64/debug/bundle/busymark \
  test/fixtures/writerside/conformance_project "$inspector_output"
flutter build linux --debug --no-pub --target lib/main.dart
```

The full invocation clears focused-mode flags so it reaches the retained
switcher, saved-code, draft-safety, list/admonition and numbering workflows.
Confirm those scenario names in `result.json`'s `checks`, rather than treating a
focused run's check count as evidence that the full workflows executed.

Both invocations also exercise contextual margin access before their later
workflows: native pointer movement from a block to its Properties icon,
off-caret inspection, nested list ancestry, native list attributes, immediate
list/capitalization Undo/Redo and save/close/reopen. The copied
`${fixture}-contextual` project uses `Conformance/conformance`; validate its
saved bytes with the pinned builder, then run the existing property verifier
with mode `list-caps-native`. Review the contextual light/dark captures as well
as the original inspector captures. A narrow-window journey closes the pane
through its guarded Close control before hovering exposed content to reopen it.

The shared journeys also open `nested-references.md` in the contextual project
and target repeated parent, child, quoted and embedded-XML references through
Editor and Source, using the explicit Element Properties command after selecting
an occurrence. The shared explicit-inspection journey also checks pinned owners
across Editor/Source/Split, ordinary editing and caret motion, deletion/Undo,
invalid-draft rejection, multiline XML attributes, and semantic-text wrapping and
insertion through the consolidated Writerside menu. Their saved output is checked
by `list-caps-native`. Review
the `form-*` and `*-form-topic-*` top/bottom captures: these retain the complete
forms at normal/minimum pane widths, light/dark themes, text scaling and RTL,
including expanded optional fields. Opening disclosures and changing display
settings must leave the source and inspected owner unchanged.

Use `test/fixtures/writerside/property_contract_conformance` as the fixture argument
and set `BUSYMARK_PROPERTY_CONTRACT_ONLY=1` for the reusable Topic, Chapter and
Paragraph journey. It exercises the production forms, source ownership, Custom
navigation from all presets, invalid-draft protection, compound undo/redo,
conditions, defaults, Source/Editor/Split/Reading, save/close/reopen, keyboard
focus and narrow light/dark layouts. The two `contract-*` documents come from
`test/fixtures/writerside/property_contract_conformance`. Validate their saved
bytes with the pinned builder and the property verifier's `contract-native`
mode. The `contract` mode checks the checked-in fixture. Both assert published
default titles, XML instance titles, chapter overrides and anchors, navigation
targets, conditional visibility, literal variables and switcher labels; they
explicitly check the topic-H1 attribute and Markdown instance-title limitations
instead of mistaking accepted markup for supported output.

Treat a nonzero exit or a non-null `failure` in `result.json` as failure. The checks
cover target identity and ancestry independently of the caret, Source without a
hidden Editor, native Save and one-step undo/redo, invalid-draft transition
blocking and Escape, XML/Markdown save/close/reopen, defaults/override/reset,
source-neutral folding, Split/Reading, narrow layouts, RTL and text scaling.
Ownership cases retain literal code/image labels and selected inline attributes;
ordered-item conversions retain outer and nested list starts. Screenshots alone
do not establish persistence or correct mutation. Keep output and copied projects
outside the repository and remove them after inspection.

`WRITERSIDE_CONFORMANCE_OUTPUT` retains builder artifacts before report assertions,
including failed reports. The strict fixture checks still require zero errors and
warnings. The native semantic-text journey intentionally inserts a literal
shortcut; when a keymap is configured, the pinned builder reports `SCT001` for
that literal. Inspect and report that advisory instead of replacing the literal
with an invented action ID. The HTML verifier checks its literal keystroke output
separately from action-reference output.

The checked-in `list_capitalization_conformance` fixture and its config variants
assert marker styles, checkbox eligibility, columns, sorted publication, native
start/default precedence and contrasting capitalization output. The ordinary
conformance invocation runs these cases without changing the pinned builder.
It explicitly records ignored module `<caps>` declarations and the native
Markdown checked-state limitation instead of equating accepted markup with
published behavior.

To check the saved source with the pinned builder, pass the copied project named
by `result.json`'s `fixture` field to `tools/validate_writerside_conformance.sh`.
Validate its sibling `${fixture}-defaults` project separately. Both use
`Conformance/conformance`. Retain each build outside the checkout via
`WRITERSIDE_CONFORMANCE_OUTPUT`, then run
`tools/verify_writerside_property_fixture.py` on its `webHelpCONFORMANCE2-all.zip`
with mode `native` or `native-defaults`, respectively. This checks the actual
saved bytes and module defaults as well as the checked-in conformance inputs.

The corresponding executable regressions are
`test/src/writerside_properties_round_trip_test.dart`,
`test/src/writerside_inspector_session_test.dart`,
`test/src/writerside_authoring_ui_test.dart` and
`test/src/workspace_controller_test.dart`.

## Official-builder conformance

`test/fixtures/writerside/conformance_semantics.json` is a normalized semantic
snapshot extracted from the official Writerside builder version named in the
user guide. BusyMark compares representative paragraphs, quotes, shortcuts,
tooltips, table structure, and related links with that snapshot. Passing the
fixture is not a claim of complete website-artifact parity.

Run the builder comparison with:

```bash
bash tools/validate_writerside_conformance.sh
```

The script requires Docker and uses the pinned builder **2026.08.0328** with
temporary source copies. It validates the builder report and normalized semantic
snapshot, then checks `reference_conformance`, `property_conformance`,
`property_defaults_conformance` and `property_contract_conformance` under
`test/fixtures/writerside/`.
`tools/verify_writerside_property_fixture.py` checks generated HTML for collapse,
state/default inheritance, extraction/emphasis, reference ownership and nested
ordered-list starts. Builder errors, warnings, semantic mismatches or failed HTML
assertions fail validation; process success alone does not establish the output
semantics. Set `WRITERSIDE_CONFORMANCE_OUTPUT` to a directory outside the
repository only when generated artifacts must be retained for diagnosis.

Regenerate the authoring schema from an intentionally selected official XSD:

```bash
python3 tools/generate_writerside_schema.py /path/to/topic.v2.xsd
dart format lib/src/writerside/writerside_schema_data.dart
```

The generated source records its XSD URL and SHA-256. Review both values when
updating the supported Writerside baseline.
