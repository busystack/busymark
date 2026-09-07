// Build with flutter build linux --debug -t tools/clipboard_smoke.dart.
// Run the resulting binary with: write|read|plain|html OUTPUT_DIRECTORY.
// Use a private display: this probe intentionally owns that display's clipboard.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const source =
    '# Issues\n\n**When** selecting all\n\n- [ ] First task\n- [x] Second task\n';

void main(List<String> arguments) {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 2) {
    stderr.writeln('Usage: write|read|plain|html OUTPUT_DIRECTORY');
    exit(2);
  }
  runApp(
    MaterialApp(home: Scaffold(body: Text('Clipboard ${arguments.first}'))),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(run(arguments.first, Directory(arguments.last)));
  });
}

Future<void> run(String operation, Directory output) async {
  try {
    if (Platform.environment['BUSYMARK_CLIPBOARD_WAIT_FOR_FOCUS'] == '1') {
      await File('${output.path}/$operation.window').writeAsString('ready');
      while (!File('${output.path}/start-$operation').existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    final service = RichClipboardService();
    const parser = MarkdownParser();
    final document = parser
        .parse(filePath: '/clipboard/source.md', source: source)
        .busyDocument;
    final fragment = WysiwygClipboardFragment(
      mode: document.mode,
      sourcePath: document.filePath,
      blocks: [
        for (final block in document.blocks)
          BusyWysiwygStyledBlock(
            kind: block.kind,
            text: block.plainText,
            ranges: busyInlineStyleRanges(block.inlines),
            attributes: block.attributes,
            completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
          ),
      ],
    );
    const text =
        'Issues\n\nWhen selecting all\n\n[ ] First task\n\n[x] Second task';
    void check(bool condition, String reason) {
      if (!condition) throw StateError(reason);
    }

    if (operation == 'write' || operation == 'html') {
      check(
        await service.write(
          RichClipboardData(
            text: text,
            html: const WysiwygClipboardHtml().encode(fragment),
            fragment: operation == 'write' ? fragment.encode() : null,
          ),
        ),
        'Clipboard write failed',
      );
      await File('${output.path}/$operation.ready').writeAsString('ready');
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (File('${output.path}/stop').existsSync()) {
          timer.cancel();
          unawaited(SystemNavigator.pop());
        }
      });
      return;
    }
    if (operation == 'plain') {
      await Clipboard.setData(const ClipboardData(text: text));
    }
    final data = await service.read();
    check(
      data.text == text,
      'Plain text did not survive transport: ${data.toMap().keys}',
    );
    if (operation == 'plain') {
      check(
        data.fragment == null && data.html == null,
        'Plain copy retained stale rich representations',
      );
    } else {
      check(
        data.html?.contains('<strong>When</strong>') == true,
        'HTML formatting missing',
      );
      final decoded = WysiwygClipboardFragment.decode(data.fragment ?? '');
      check(decoded != null, 'Structured data missing');
      final target = parser
          .parse(filePath: '/clipboard/destination.md', source: 'Target\n')
          .busyDocument;
      final controller = BusyMarkWysiwygDocumentController(document: target);
      final inserted = controller.insertStyledBlocksAtSelection(
        blockId: target.blocks.single.id,
        selectionStart: 0,
        selectionEnd: 6,
        blocks: decoded!.blocks,
      );
      final markdown = controller.markdown;
      check(
        inserted != null &&
            markdown.contains('# Issues') &&
            markdown.contains('**When** selecting all') &&
            markdown.contains('- [ ] First task') &&
            markdown.contains('- [x] Second task'),
        'Formatting changed during insertion: $markdown',
      );
      controller.dispose();
    }
    await File('${output.path}/$operation.json').writeAsString(
      jsonEncode({'passed': true, 'formats': data.toMap().keys.toList()}),
    );
    // Let native render hosts finish their first frame before closing the probe.
    await Future<void>.delayed(const Duration(seconds: 1));
    await SystemNavigator.pop();
  } catch (error, stack) {
    await File(
      '${output.path}/$operation.error',
    ).writeAsString('$error\n$stack');
    exit(1);
  }
}
