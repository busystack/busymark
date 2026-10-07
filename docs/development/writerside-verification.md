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

The script uses temporary source copies and validates both the builder report
and normalized semantic snapshot. Set `WRITERSIDE_CONFORMANCE_OUTPUT` only when
generated artifacts must be retained for diagnosis.

Regenerate the authoring schema from an intentionally selected official XSD:

```bash
python3 tools/generate_writerside_schema.py /path/to/topic.v2.xsd
dart format lib/src/writerside/writerside_schema_data.dart
```

The generated source records its XSD URL and SHA-256. Review both values when
updating the supported Writerside baseline.
