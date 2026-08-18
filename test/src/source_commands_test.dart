import 'package:busymark/src/editor/source/source_commands.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tab inserts spaces', () {
    final value = SourceCommands.insertTab(
      const TextEditingValue(
        text: 'a',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );

    expect(value.text, 'a  ');
  });

  test('indent and outdent selected lines', () {
    const value = TextEditingValue(
      text: 'one\ntwo\n',
      selection: TextSelection(baseOffset: 0, extentOffset: 7),
    );

    final indented = SourceCommands.indentSelection(value);
    expect(indented.text, '  one\n  two\n');

    final outdented = SourceCommands.outdentSelection(indented);
    expect(outdented.text, 'one\ntwo\n');
  });

  test('smart Enter continues unordered ordered task and blockquote lines', () {
    expect(
      SourceCommands.smartEnter(
        const TextEditingValue(
          text: '- item',
          selection: TextSelection.collapsed(offset: 6),
        ),
      ).text,
      '- item\n- ',
    );
    expect(
      SourceCommands.smartEnter(
        const TextEditingValue(
          text: '3. item',
          selection: TextSelection.collapsed(offset: 7),
        ),
      ).text,
      '3. item\n4. ',
    );
    expect(
      SourceCommands.smartEnter(
        const TextEditingValue(
          text: '- [ ] task',
          selection: TextSelection.collapsed(offset: 10),
        ),
      ).text,
      '- [ ] task\n- [ ] ',
    );
    expect(
      SourceCommands.smartEnter(
        const TextEditingValue(
          text: '> quote',
          selection: TextSelection.collapsed(offset: 7),
        ),
      ).text,
      '> quote\n> ',
    );
  });

  test('smart Enter exits empty list item', () {
    final value = SourceCommands.smartEnter(
      const TextEditingValue(
        text: '- ',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );

    expect(value.text, '\n');
    expect(value.selection.start, 1);
  });

  test('ordered list numbering restarts for nested source lines', () {
    const source = 'One\nTwo\nThree\n  Child\n';

    final ordered = SourceCommands.applyBlockCommand(
      const TextEditingValue(
        text: source,
        selection: TextSelection(baseOffset: 0, extentOffset: source.length),
      ),
      SourceBlockCommand.orderedList,
    );

    expect(ordered.text, '1. One\n2. Two\n3. Three\n   1. Child\n');
  });

  test('ordered list numbering restarts beneath each source parent', () {
    const source = 'Parent A\n  Child A\nParent B\n  Child B\n';

    final ordered = SourceCommands.applyBlockCommand(
      const TextEditingValue(
        text: source,
        selection: TextSelection(baseOffset: 0, extentOffset: source.length),
      ),
      SourceBlockCommand.orderedList,
    );

    expect(
      ordered.text,
      '1. Parent A\n   1. Child A\n2. Parent B\n   1. Child B\n',
    );
  });

  test('inline commands toggle bold italic code and links', () {
    final bold = SourceCommands.applyInlineCommand(
      const TextEditingValue(
        text: 'word',
        selection: TextSelection(baseOffset: 0, extentOffset: 4),
      ),
      SourceInlineCommand.bold,
      placeholder: 'text',
    );
    expect(bold.text, '**word**');
    expect(
      SourceCommands.applyInlineCommand(
        bold,
        SourceInlineCommand.bold,
        placeholder: 'text',
      ).text,
      'word',
    );

    expect(
      SourceCommands.applyInlineCommand(
        const TextEditingValue(
          text: 'word',
          selection: TextSelection(baseOffset: 0, extentOffset: 4),
        ),
        SourceInlineCommand.italic,
        placeholder: 'text',
      ).text,
      '*word*',
    );
    expect(
      SourceCommands.applyInlineCommand(
        const TextEditingValue(
          text: 'word',
          selection: TextSelection(baseOffset: 0, extentOffset: 4),
        ),
        SourceInlineCommand.code,
        placeholder: 'code',
      ).text,
      '`word`',
    );
    expect(
      SourceCommands.insertLink(
        const TextEditingValue(
          text: 'label',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        labelPlaceholder: 'text',
      ).text,
      '[label](url)',
    );
  });

  test('code fence and image insertion keep source-specific placeholders', () {
    expect(
      SourceCommands.insertCodeFence(
        const TextEditingValue(
          text: 'print(1);',
          selection: TextSelection(baseOffset: 0, extentOffset: 9),
        ),
        language: 'dart',
        contentPlaceholder: 'code',
      ).text,
      '```dart\nprint(1);\n```',
    );
    expect(
      SourceCommands.insertImage(
        const TextEditingValue(
          text: 'Logo',
          selection: TextSelection(baseOffset: 0, extentOffset: 4),
        ),
        block: false,
        altPlaceholder: 'alt text',
      ).text,
      '![Logo](url)',
    );
  });

  test('block insertion accepts localized default content', () {
    const value = TextEditingValue(
      selection: TextSelection.collapsed(offset: 0),
    );

    expect(
      SourceCommands.insertTable(
        value,
        headerTextForColumn: (column) => 'Spalte $column',
        cellText: 'Zelle',
      ).text,
      '\n| Spalte 1 | Spalte 2 |\n| --- | --- |\n| Zelle | Zelle |\n',
    );
    expect(
      SourceCommands.insertHtmlBlock(value, defaultContent: 'HTML-Inhalt').text,
      '\n<div>\n  <p>HTML-Inhalt</p>\n</div>\n',
    );
  });
}
