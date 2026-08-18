import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/document_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('probe editable and preview wrapping', (tester) async {
    final fontBytes = await File(
      '/usr/share/fonts/truetype/ubuntu/Ubuntu[wdth,wght].ttf',
    ).readAsBytes();
    await (FontLoader('Ubuntu')
          ..addFont(Future.value(ByteData.sublistView(fontBytes))))
        .load();
    const text =
        'P1 — Git push can target the wrong workspace. '
        'lib/src/git/application/ git_controller.dart:578 captures repository A, '
        'awaits its remotes, then lib/src/git/application/git_controller.dart:781 '
        'reads the current repository again. Switching to repository B during that '
        'await can push B using A’s branch and remote. Pin the repository/workspace '
        'epoch for the entire operation and discard stale completions. History, '
        'commit- detail, branch, and diff loaders need the same protection.';
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);

    Widget app(Widget child) => MaterialApp(
      theme: buildBusyMarkTheme(
        brightness: Brightness.light,
        accentColor: BusyMarkLinuxPalette.ubuntuOrangeAccent,
      ),
      home: Scaffold(body: Center(child: SizedBox(width: 734, child: child))),
    );

    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextField(
            key: const ValueKey('editor'),
            controller: controller,
            maxLines: null,
            minLines: 1,
            style: busyMarkDocumentBodyTextStyle(context),
            cursorWidth: 2,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
    final editor = tester.renderObject(
      find.byElementPredicate((element) => element.renderObject is RenderEditable),
    );
    _printLines('EDITOR', editor, text);

    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Text.rich(
            key: const ValueKey('preview'),
            TextSpan(
              text: text,
              style: busyMarkDocumentBodyTextStyle(context),
            ),
          ),
        ),
      ),
    );
    final preview = tester.renderObject(
      find.descendant(
        of: find.byKey(const ValueKey('preview')),
        matching: find.byType(RichText),
      ),
    );
    _printLines('PREVIEW', preview, text);
  });
}

void _printLines(String label, RenderObject renderObject, String text) {
  final endsByTop = <String, int>{};
  for (var index = 0; index < text.length; index += 1) {
    final boxes = (renderObject as dynamic).getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + 1),
    );
    if (boxes.isEmpty) {
      continue;
    }
    final top = (boxes.first.top as double).toStringAsFixed(2);
    endsByTop[top] = index + 1;
  }
  var start = 0;
  var line = 1;
  for (final end in endsByTop.values) {
    // ignore: avoid_print
    print('$label line $line: "${text.substring(start, end).trimRight()}"');
    start = end;
    line += 1;
  }
}
