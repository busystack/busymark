import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'autocomplete prioritizes Writerside Markdown authoring suggestions',
    () {
      final suggestions = const SourceAutocompleteProvider().suggestions(
        document: SourceDocument(fullText: '# Install Guide\nUse install.\n'),
        fullOffset: 2,
        context: const SourceAutocompleteContext(
          projectFiles: ['topics/install.md', 'images/logo.png'],
          variables: ['productName'],
          categories: ['getting-started'],
          topicIds: ['install-topic'],
        ),
      );

      expect(
        suggestions.map((suggestion) => suggestion.kind),
        containsAll([
          SourceAutocompleteKind.xmlTag,
          SourceAutocompleteKind.codeLanguage,
          SourceAutocompleteKind.heading,
          SourceAutocompleteKind.link,
          SourceAutocompleteKind.image,
          SourceAutocompleteKind.variable,
          SourceAutocompleteKind.category,
        ]),
      );
      expect(
        suggestions.map((suggestion) => suggestion.insertText),
        contains('install-guide'),
      );
    },
  );

  test(
    'completion derives XML caret context and consumes the project index',
    () {
      const index = WritersideProjectIndex(
        symbols: [
          WritersideSymbol(
            name: 'features',
            qualifiedName: 'main:features',
            kind: WritersideSymbolKind.topic,
            moduleId: 'main',
            filePath: '/project/topics/features.topic',
          ),
        ],
        references: [],
        diagnostics: [],
      );
      const source = '<topic><chapter><fea';
      final caret = writersideXmlCaretContext(source, source.length);
      final suggestions = const SourceAutocompleteProvider().suggestions(
        document: SourceDocument(fullText: source),
        fullOffset: source.length,
        context: const SourceAutocompleteContext(
          projectIndex: index,
          moduleId: 'main',
        ),
      );

      expect(caret.parentElement, 'chapter');
      expect(caret.currentElement, 'fea');
      expect(
        suggestions
            .where(
              (suggestion) => suggestion.kind == SourceAutocompleteKind.topic,
            )
            .map((suggestion) => suggestion.insertText),
        contains('features'),
      );
    },
  );

  test('completion suggests attributes legal for the element at the caret', () {
    const source = '<topic><list ty';
    final suggestions = const SourceAutocompleteProvider().suggestions(
      document: SourceDocument(fullText: source),
      fullOffset: source.length,
    );

    expect(
      suggestions
          .where(
            (suggestion) =>
                suggestion.kind == SourceAutocompleteKind.xmlAttribute,
          )
          .map((suggestion) => suggestion.insertText),
      contains('type'),
    );
  });
}
