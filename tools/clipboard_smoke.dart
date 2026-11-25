// Build with flutter build linux --debug -t tools/clipboard_smoke.dart.
// Run the resulting binary with:
// roundtrip|write|read|plain|html|quota|paste-source|paste-editor|cut-editor OUTPUT_DIRECTORY.
// Use a private display: this probe intentionally owns that display's clipboard.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

const source =
    '# Issues\n\n**When** selecting all\n\n- [ ] First task\n- [x] Second task\n';

void main(List<String> arguments) {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: roundtrip|write|read|plain|html|quota|paste-source|paste-editor|cut-editor OUTPUT_DIRECTORY',
    );
    exit(2);
  }
  final operation = arguments.first;
  if (operation.startsWith('paste-') || operation == 'cut-editor') {
    runApp(
      MaterialApp(
        localizationsDelegates: busyMarkLocalizationsDelegates,
        home: _ClipboardEditorProbe(operation, Directory(arguments.last)),
      ),
    );
    return;
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
    // The GTK runner presents its window from the native first-frame callback,
    // just after Flutter's first post-frame callbacks have run. Clipboard
    // ownership on Wayland (and some X11 managers) requires that presentation
    // to complete.
    await Future<void>.delayed(const Duration(seconds: 5));
    if (Platform.environment['BUSYMARK_CLIPBOARD_WAIT_FOR_FOCUS'] == '1') {
      await File('${output.path}/$operation.window').writeAsString('ready');
      while (!File('${output.path}/start-$operation').existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    final service = RichClipboardService();
    if (operation == 'quota') {
      final quota =
          jsonDecode(
                File('${output.path}/quota-expected.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final data = await service.read();
      final plain = await service.read(plainTextOnly: true);
      final result = {
        'textBytes': data.text == null ? null : utf8.encode(data.text!).length,
        'plainBytes': plain.text == null
            ? null
            : utf8.encode(plain.text!).length,
        'plainHtml': plain.html != null,
        'plainToken': plain.token != null,
        'htmlBytes': data.html == null ? null : utf8.encode(data.html!).length,
        'generation': data.generation != null,
      };
      await File('${output.path}/quota.json').writeAsString(jsonEncode(result));
      if (quota.entries.any((entry) => result[entry.key] != entry.value)) {
        throw StateError('Unexpected clipboard representations: $result');
      }
      exit(0);
    }
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

    if (operation == 'write' ||
        operation == 'html' ||
        operation == 'roundtrip') {
      check(
        await service.write(
          RichClipboardData(
            text: text,
            html: const WysiwygClipboardHtml().encode(fragment),
            sourceText: operation == 'html' ? null : fragment.markdown,
            richFragment: operation == 'html' ? null : fragment.encode(),
          ),
        ),
        'Clipboard write failed',
      );
      if (operation != 'roundtrip') {
        await File('${output.path}/$operation.ready').writeAsString('ready');
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (File('${output.path}/stop').existsSync()) {
            timer.cancel();
            unawaited(SystemNavigator.pop());
          }
        });
        return;
      }
      // Give the X11 selection owner change a main-loop turn before requesting
      // its targets, matching a real copy followed by a separate paste event.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (operation == 'plain') {
      await Clipboard.setData(const ClipboardData(text: text));
    }
    final data = await service.read();
    check(
      data.text == text,
      'Plain text did not survive transport: '
      '${jsonEncode({'text': data.text, 'html': data.html, 'token': data.token, 'generation': data.generation})}',
    );
    if (operation == 'plain') {
      check(
        data.richFragment == null && data.html == null,
        'Plain copy retained stale rich representations',
      );
    } else {
      check(
        data.html?.contains('<strong>When</strong>') == true,
        'HTML formatting missing',
      );
      final decoded = data.richFragment == null
          ? const WysiwygClipboardHtml().decode(
              data.html ?? '',
              mode: document.mode,
            )
          : WysiwygClipboardFragment.decode(data.richFragment!);
      if (operation == 'read') {
        check(data.token != null, 'Opaque ownership token missing');
        check(
          data.richFragment == null && !data.sessionOwned,
          'Another process resolved session-owned structured data',
        );
      } else if (operation == 'roundtrip') {
        check(
          data.richFragment != null && data.sessionOwned,
          'Same-process ownership token did not resolve structured data',
        );
      }
      check(decoded != null, 'No safe structured or HTML representation');
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
      jsonEncode({
        'passed': true,
        'text': data.text != null,
        'html': data.html != null,
        'rich': data.richFragment != null,
      }),
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

class _ClipboardEditorProbe extends StatefulWidget {
  const _ClipboardEditorProbe(this.operation, this.output);

  final String operation;
  final Directory output;

  @override
  State<_ClipboardEditorProbe> createState() => _ClipboardEditorProbeState();
}

class _ClipboardEditorProbeState extends State<_ClipboardEditorProbe> {
  final _source = GlobalKey<BusyMarkSourceEditorState>();
  final _editor = GlobalKey<BusyMarkWysiwygEditorState>();
  static const _start = 'Target\n';
  static const _raw = '<div dir="auto">Keep me</div>\n\nAfter\n';
  late final bool _cut = widget.operation == 'cut-editor';
  late final bool _sourceMode = widget.operation == 'paste-source';
  late String _value = _cut ? _raw : _start;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  @override
  Widget build(BuildContext context) {
    final path = '${widget.output.path}/target.md';
    return Scaffold(
      body: _sourceMode
          ? BusyMarkSourceEditor(
              key: _source,
              text: _start,
              language: SourceSyntaxLanguage.markdown,
              filePath: path,
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              documentFormat: SourceDocumentFormat.markdown,
              markdownMode: MarkdownMode.gfm,
              onCloseSearch: () {},
              onChanged: (text, _) => _value = text,
            )
          : BusyMarkWysiwygEditor(
              key: _editor,
              document: const MarkdownParser()
                  .parse(
                    filePath: path,
                    source: _cut ? _raw : _start,
                    mode: MarkdownMode.gfm,
                  )
                  .busyDocument,
              onSourceChanged: (_, text) => _value = text,
            ),
    );
  }

  Future<void> _run() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_sourceMode) {
        _source.currentState!.restoreSpellingFocus();
      } else {
        _editor.currentState!.restoreEditingFocus();
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _command(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      if (_cut) {
        _command(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
        _command(PhysicalKeyboardKey.keyX, LogicalKeyboardKey.keyX);
      } else {
        _command(
          PhysicalKeyboardKey.keyV,
          LogicalKeyboardKey.keyV,
          shift: File('${widget.output.path}/plain').existsSync(),
        );
      }
      final expected = _cut
          ? ''
          : File('${widget.output.path}/expected.txt').readAsStringSync();
      for (var i = 0; i < 100 && _value.trim() != expected.trim(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_value.trim() != expected.trim()) {
        throw StateError('Unexpected inserted source: $_value');
      }
      if (_cut) {
        final emitted = await RichClipboardService().read();
        if (emitted.text != 'Keep me\n\nAfter' ||
            emitted.html?.contains('<div dir="auto">Keep me</div>') != true ||
            emitted.richFragment != null) {
          throw StateError(
            'Cut did not publish the complete interoperable selection',
          );
        }
      }
      await File(
        '${widget.output.path}/${widget.operation}.json',
      ).writeAsString(jsonEncode({'passed': true, 'source': _value}));
      exit(0);
    } catch (error, stack) {
      await File(
        '${widget.output.path}/${widget.operation}.error',
      ).writeAsString('$error\n$stack');
      exit(1);
    }
  }
}

void _command(
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical, {
  bool shift = false,
}) {
  final keys = [
    (PhysicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlLeft),
    if (shift) (PhysicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft),
    (physical, logical),
  ];
  void send(
    (PhysicalKeyboardKey, LogicalKeyboardKey) key,
    ui.KeyEventType type,
  ) {
    // Match the framework shortcut path while leaving native clipboard I/O live.
    // ignore: deprecated_member_use
    ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        timeStamp: Duration.zero,
        type: type,
        physical: key.$1.usbHidUsage,
        logical: key.$2.keyId,
        character: null,
        synthesized: true,
      ),
    );
  }

  for (final key in keys) {
    send(key, ui.KeyEventType.down);
  }
  for (final key in keys.reversed) {
    send(key, ui.KeyEventType.up);
  }
}
