import 'package:busymark/src/git/domain/git_diff_parser.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GitDiffParser();

  test('parses added file', () {
    final diff = parser.parse('''
diff --git a/new.md b/new.md
new file mode 100644
--- /dev/null
+++ b/new.md
@@ -0,0 +1,2 @@
+# New
+Body
''');

    expect(diff.files.single.status, GitDiffFileStatus.added);
    expect(diff.files.single.additions, 2);
  });

  test('parses deleted file', () {
    final diff = parser.parse('''
diff --git a/old.md b/old.md
deleted file mode 100644
--- a/old.md
+++ /dev/null
@@ -1,2 +0,0 @@
-# Old
-Body
''');

    expect(diff.files.single.status, GitDiffFileStatus.deleted);
    expect(diff.files.single.deletions, 2);
  });

  test('parses modified file with line numbers', () {
    final diff = parser.parse('''
diff --git a/readme.md b/readme.md
--- a/readme.md
+++ b/readme.md
@@ -1,2 +1,2 @@ heading
 # Title
-Old
+New
''');

    final hunk = diff.files.single.hunks.single;
    expect(hunk.heading, 'heading');
    expect(hunk.lines.map((line) => line.kind), [
      GitDiffLineKind.context,
      GitDiffLineKind.removed,
      GitDiffLineKind.added,
    ]);
    expect(hunk.lines.last.newLineNumber, 2);
  });

  test('parses renamed file', () {
    final diff = parser.parse('''
diff --git a/old.md b/new.md
similarity index 90%
rename from old.md
rename to new.md
--- a/old.md
+++ b/new.md
@@ -1 +1 @@
-Old
+New
''');

    final file = diff.files.single;
    expect(file.status, GitDiffFileStatus.renamed);
    expect(file.oldPath, 'old.md');
    expect(file.newPath, 'new.md');
  });

  test('decodes C-quoted UTF-8 paths emitted by Git', () {
    final diff = parser.parse(r'''
diff --git "a/docs/\303\234ber \"guide\".md" "b/docs/\303\234ber \"guide\".md"
--- "a/docs/\303\234ber \"guide\".md"
+++ "b/docs/\303\234ber \"guide\".md"
@@ -1 +1 @@
-Old
+New
''');

    final file = diff.files.single;
    expect(file.oldPath, 'docs/Über "guide".md');
    expect(file.newPath, 'docs/Über "guide".md');
  });

  test('decodes C-quoted rename metadata emitted by Git', () {
    final diff = parser.parse(r'''
diff --git "a/docs/\303\204lter Name.md" "b/docs/\303\204lterer \"Name\".md"
similarity index 100%
rename from "docs/\303\204lter Name.md"
rename to "docs/\303\204lterer \"Name\".md"
''');

    final file = diff.files.single;
    expect(file.status, GitDiffFileStatus.renamed);
    expect(file.oldPath, 'docs/Älter Name.md');
    expect(file.newPath, 'docs/Älterer "Name".md');
  });

  test('parses binary file marker', () {
    final diff = parser.parse('''
diff --git a/image.png b/image.png
Binary files a/image.png and b/image.png differ
''');

    expect(diff.hasBinaryFiles, isTrue);
    expect(diff.files.single.binary, isTrue);
  });

  test('parses multiple hunks', () {
    final diff = parser.parse('''
diff --git a/readme.md b/readme.md
--- a/readme.md
+++ b/readme.md
@@ -1 +1 @@
-A
+B
@@ -10 +10 @@
-C
+D
''');

    expect(diff.files.single.hunks, hasLength(2));
  });

  test('keeps no newline marker as header line', () {
    final diff = parser.parse(r'''
diff --git a/readme.md b/readme.md
--- a/readme.md
+++ b/readme.md
@@ -1 +1 @@
-A
+B
\ No newline at end of file
''');

    expect(
      diff.files.single.hunks.single.lines.last.kind,
      GitDiffLineKind.header,
    );
  });

  test('tolerates unknown diff header lines', () {
    final diff = parser.parse('''
diff --git a/readme.md b/readme.md
unknown header line
--- a/readme.md
+++ b/readme.md
@@ -1 +1 @@
unknown hunk line
''');

    expect(
      diff.files.single.hunks.single.lines.single.kind,
      GitDiffLineKind.header,
    );
  });
}
