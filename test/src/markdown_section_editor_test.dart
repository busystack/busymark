import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/markdown_section_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();

  MarkdownSectionEditor section(String source, String headingText) {
    final parsed = parser.parse(
      filePath: 'outline-actions.md',
      source: source,
      validateLocalReferences: false,
    );
    final index = parsed.headings.indexWhere(
      (heading) => heading.text == headingText,
    );
    expect(index, isNonNegative, reason: headingText);
    return MarkdownSectionEditor.fromHeadings(
      source: source,
      headings: parsed.headings,
      headingIndex: index,
    );
  }

  test('section includes descendants and stops at the next sibling', () {
    const source = '''
# Root

Intro.

## First

First body.

### Child

Child body.

#### Grandchild

Grandchild body.

## Second

Second body.
''';
    final editor = section(source, 'First');

    expect(editor.sectionText, '''## First

First body.

### Child

Child body.

#### Grandchild

Grandchild body.

''');
    expect(editor.withoutSection(), '''# Root

Intro.

## Second

Second body.
''');
  });

  test('move up and down swap complete sibling subtrees', () {
    const source = '''
# Root

## Alpha

Alpha body.

### Alpha child

Alpha child body.

## Beta

Beta body.

### Beta child

Beta child body.

## Gamma

Gamma body.

# Tail
''';
    final beta = section(source, 'Beta');

    expect(beta.canMoveUp, isTrue);
    expect(beta.canMoveDown, isTrue);
    expect(beta.moveUp(), '''# Root

## Beta

Beta body.

### Beta child

Beta child body.

## Alpha

Alpha body.

### Alpha child

Alpha child body.

## Gamma

Gamma body.

# Tail
''');
    expect(beta.moveDown(), '''# Root

## Alpha

Alpha body.

### Alpha child

Alpha child body.

## Gamma

Gamma body.

## Beta

Beta body.

### Beta child

Beta child body.

# Tail
''');

    expect(section(source, 'Alpha').canMoveUp, isFalse);
    expect(section(source, 'Gamma').canMoveDown, isFalse);
  });

  test('promote and demote preserve descendant hierarchy', () {
    const source = '''
# Root

## Parent

### Selected

Text.

#### Child

##### Grandchild

## Sibling
''';
    final editor = section(source, 'Selected');

    expect(editor.canPromote, isTrue);
    expect(editor.canDemote, isTrue);
    expect(editor.promote(), '''# Root

## Parent

## Selected

Text.

### Child

#### Grandchild

## Sibling
''');
    expect(editor.demote(), '''# Root

## Parent

#### Selected

Text.

##### Child

###### Grandchild

## Sibling
''');
  });

  test('demote is unavailable when a descendant is already H6', () {
    const source = '''
### Selected

###### Deep child
''';
    final editor = section(source, 'Selected');

    expect(editor.canDemote, isFalse);
    expect(editor.demote(), isNull);
  });

  test('level changes preserve and convert Setext headings', () {
    const source = '''
Root
====

Child
-----

### Grandchild
''';
    final root = section(source, 'Root');
    final child = section(source, 'Child');

    expect(root.demote(), '''Root
----

### Child

#### Grandchild
''');
    expect(child.promote(), '''Root
====

Child
=====

## Grandchild
''');
  });
}
