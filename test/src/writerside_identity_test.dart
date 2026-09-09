import 'dart:io';

import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  late WritersideProject project;
  late Map<String, String> sources;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('writerside-identities-');
    sources = {
      'writerside.cfg':
          '<ihp><module name="docs"/><topics dir="topics"/><vars src="v.list"/><instance src="one.tree"/><instance src="two.tree"/></ihp>',
      'one.tree':
          '<instance-profile id="one" name="One" start-page="a.topic"><toc-element topic="a.topic"/></instance-profile>',
      'two.tree':
          '<instance-profile id="two" name="Two" start-page="b.topic"><toc-element topic="b.topic"/></instance-profile>',
      'v.list':
          '<vars><var name="product" value="One" instance="one"/><var name="product" value="Two" instance="two"/></vars>',
      'topics/a.topic':
          '<topic id="a" title="A"><chapter id="same" title="First"><p>A</p></chapter><a anchor="same"/><p>%product%</p><include from="b.topic" element-id="snippet"><var name="label" value="Caller"/></include></topic>',
      'topics/b.topic':
          '<topic id="b" title="B"><chapter id="same" title="Second"><p>B</p></chapter><a href="a.topic" anchor="same"/><a href="b.topic#same"/><p>%product%</p><snippet id="snippet"><var name="label" value="Default"/><p>%label%</p></snippet></topic>',
      'topics/extra.md':
          '# Extra\n\n## Section {id="same"}\n\n[First](a.topic#same)\n\n[Second](b.topic#same)\n',
    };
    for (final entry in sources.entries) {
      final file = File(p.join(directory.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value.replaceAll(r'\n', '\n'));
    }
    project = await const WritersideProjectService().load(directory.path);
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'anchor identity includes topic and all instances participate in usages',
    () {
      final index = project.index;
      final a = index.definitions('a.topic#same', moduleId: 'docs').single;
      final b = index.definitions('b.topic#same', moduleId: 'docs').single;
      expect(a.filePath, isNot(b.filePath));
      expect(index.findUsages(a), hasLength(3));
      expect(index.findUsages(b), hasLength(2));
      final edits = index.safeRenameEdits(a, 'first');
      expect(edits, hasLength(4));
      final contents = <String, String>{};
      for (final path in edits.map((edit) => edit.filePath).toSet()) {
        var text = File(path).readAsStringSync();
        final changes = edits.where((edit) => edit.filePath == path).toList()
          ..sort((a, b) => b.span.startOffset.compareTo(a.span.startOffset));
        for (final edit in changes) {
          expect(
            text.substring(edit.span.startOffset, edit.span.endOffset),
            edit.expectedText,
          );
          text = text.replaceRange(
            edit.span.startOffset,
            edit.span.endOffset,
            edit.replacement,
          );
        }
        contents[p.basename(path)] = text;
      }
      expect(contents['b.topic'], contains('<chapter id="same"'));
      expect(
        contents['b.topic'],
        contains('<a href="a.topic" anchor="first"/>'),
      );
      expect(contents['extra.md'], contains('[First](a.topic#first)'));
      expect(contents['extra.md'], contains('[Second](b.topic#same)'));
    },
  );

  test('conditional globals and snippet variables have distinct scopes', () {
    final index = project.index;
    expect(
      index.diagnostics.where(
        (d) => d.code == 'writerside.index.duplicate-symbol',
      ),
      isEmpty,
    );
    final global = index.symbols.firstWhere((s) => s.name == 'product');
    final edits = index.safeRenameEdits(global, 'app');
    expect(edits, hasLength(4));
    expect(
      edits.map((e) => e.expectedText),
      containsAll(['product', '%product%']),
    );
    final local = index.symbols.firstWhere((s) => s.name == 'label');
    expect(index.findUsages(local), hasLength(2));
    expect(index.safeRenameEdits(local, 'caption'), hasLength(3));
  });

  test('completion filters context and target identity before limiting', () {
    List<String> suggest(String text, {int limit = 40}) =>
        const SourceAutocompleteProvider()
            .suggestions(
              document: SourceDocument(fullText: text),
              fullOffset: text.length,
              limit: limit,
              context: SourceAutocompleteContext(
                projectIndex: project.index,
                moduleId: 'docs',
                filePath: p.join(directory.path, 'topics/a.topic'),
              ),
            )
            .map((item) => item.insertText)
            .toList();
    expect(suggest('<topic><web-s', limit: 1), ['web-summary']);
    expect(suggest('<topic><include from="b.topic" element-id="sn'), [
      'snippet',
    ]);
    expect(suggest('<topic><a href="a.topic#sa'), ['same']);
    expect(suggest('<topic><table style="header-c'), ['header-column']);
    expect(suggest('<topic><p instance="tw'), ['two']);
  });

  test(
    'validation uses relationships, typed values and current configuration syntax',
    () {
      const parser = WritersideTopicParser();
      final module = project.activeModule!;
      final topic = parser.parseXml(
        filePath: p.join(directory.path, 'topics/invalid.topic'),
        source:
            '<topic id="invalid" title="Invalid"><td colspan="zero"/><table style="bogus"/><a anchor="valid"/></topic>',
        topicsRoot: p.join(directory.path, 'topics'),
      );
      final index = WritersideProjectIndex.build([
        module.copyWith(topics: [topic]),
      ]);
      expect(
        index.diagnostics.map((d) => d.code),
        containsAll([
          'writerside.schema.invalid-parent',
          'writerside.schema.invalid-attribute-value',
        ]),
      );
      expect(
        index.diagnostics.where((d) => d.args['attribute'] == 'href'),
        isEmpty,
      );
      const profiles = WritersideBuildProfilesParser();
      expect(
        profiles
            .parse(
              '/cfg/buildprofiles.xml',
              '<buildprofiles><variables><llms-txt>true</llms-txt></variables></buildprofiles>',
            )
            .diagnostics,
        isEmpty,
      );
      expect(
        profiles
            .parse(
              '/cfg/buildprofiles.xml',
              '<buildprofiles><variables><llms-txt single-file="true"/></variables></buildprofiles>',
            )
            .diagnostics,
        isNotEmpty,
      );
    },
  );
}
