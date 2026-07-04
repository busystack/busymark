import '../source_highlighter.dart';

export '../source_highlighter.dart' show BusyMarkSourceEditingController;
export '../source_language.dart';

class BusyMarkSourceController extends BusyMarkSourceEditingController {
  BusyMarkSourceController({
    super.text,
    super.language = SourceSyntaxLanguage.markdown,
    super.onFullTextChanged,
  }) {
    renderText = false;
    visualMarkdown = false;
  }

  void replaceFullTextAndLanguage({
    required String text,
    required SourceSyntaxLanguage language,
  }) {
    this.language = language;
    setFullText(text);
    renderText = false;
    visualMarkdown = false;
  }
}
