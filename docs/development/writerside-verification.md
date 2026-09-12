# Writerside verification

The user-facing [Writerside support](../writerside-support.md) page describes the
supported semantic surface and known limitations. This note contains the
maintainer checks behind those claims.

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
