import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_document.dart';
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
}
