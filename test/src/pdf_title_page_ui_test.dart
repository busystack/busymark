import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/export/export_options_editor.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_export_ui.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/workspace_export_ui.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_export_ui.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _defaults = PdfTitlePageData(
  title: 'Document default',
  author: 'Metadata author',
  version: 'Draft version',
);

void main() {
  testWidgets(
    'cover edits survive toggling and format changes, validate, reset, and do not leak through preferences',
    (tester) async {
      final settings = _Settings();
      PdfTitlePageData defaults = _defaults;
      ExportOptionsSelection? selection;
      await tester.pumpWidget(
        _harness(settings, (context, ref) async {
          selection = await showExportOptions(
            context,
            ref,
            pdfTitlePageDefaults: defaults,
          );
        }),
      );
      await _open(tester);
      expect(_field('Title'), findsNothing);
      await _toggle(tester, true);
      expect(_text(tester, 'Title'), 'Document default');
      await _edit(tester, 'Title', '');
      expect(find.text('Enter a title for the title page.'), findsWidgets);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('export-options-submit')),
            )
            .onPressed,
        isNull,
      );
      await _edit(tester, 'Title', 'Export-specific title');
      await _edit(tester, 'Author', '');
      await _toggle(tester, false);
      expect(_field('Title'), findsNothing);
      await _toggle(tester, true);
      expect(_text(tester, 'Title'), 'Export-specific title');
      expect(_text(tester, 'Author'), '');
      tester
          .widget<BusyMarkComboRow<ExportFormat>>(
            find.byType(BusyMarkComboRow<ExportFormat>),
          )
          .onSelected(ExportFormat.html);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pdf-include-title-page')),
        findsNothing,
      );
      expect(_field('Title'), findsNothing);
      final html = tester.widget<HtmlExportOptionsEditor>(
        find.byType(HtmlExportOptionsEditor),
      );
      html.onChanged(html.value.copyWith(baseFontSize: 21));
      tester
          .widget<BusyMarkComboRow<ExportFormat>>(
            find.byType(BusyMarkComboRow<ExportFormat>),
          )
          .onSelected(ExportFormat.pdf);
      await tester.pumpAndSettle();
      expect(_text(tester, 'Title'), 'Export-specific title');
      expect(_text(tester, 'Author'), '');
      await tester.ensureVisible(find.text('Reset to defaults'));
      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();
      expect(_field('Title'), findsNothing);
      expect(
        tester
            .widget<PdfExportOptionsEditor>(find.byType(PdfExportOptionsEditor))
            .value
            .includeTitlePage,
        isFalse,
      );
      await _toggle(tester, true);
      expect(_text(tester, 'Title'), 'Document default');
      expect(_text(tester, 'Author'), 'Metadata author');
      await _edit(tester, 'Title', 'Only this export');
      await _edit(tester, 'Author', '');
      await tester.tap(find.byKey(const ValueKey('export-options-submit')));
      await _settle(tester);
      expect(selection!.titlePage!.title, 'Only this export');
      expect(selection!.titlePage!.author, '');
      expect(
        AppSettings.fromJson(settings.data).pdfExportOptions.includeTitlePage,
        isTrue,
      );
      expect(settings.data.toString(), isNot(contains('Only this export')));
      expect(
        AppSettings.fromJson(settings.data).htmlExportOptions.baseFontSize,
        17,
      );

      defaults = const PdfTitlePageData(title: 'Unrelated document');
      await _open(tester);
      expect(_text(tester, 'Title'), 'Unrelated document');
      expect(_text(tester, 'Author'), '');
      final beforeCancel = settings.data.toString();
      await _edit(tester, 'Title', 'Cancelled title');
      await _toggle(tester, false);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(selection, isNull);
      expect(settings.data.toString(), beforeCancel);
      await _open(tester);
      expect(_text(tester, 'Title'), 'Unrelated document');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'instance changes refresh automatic fields without replacing edited or cleared text',
    (tester) async {
      final instances = [
        for (final id in ['a', 'b'])
          WritersideInstance(
            id: id,
            name: 'Instance $id',
            version: 'Version $id',
            sourceTreePath: '$id.tree',
            startPage: null,
            status: '',
            isLibrary: false,
            tocRoots: const [],
            diagnostics: const [],
          ),
      ];
      ExportOptionsSelection? selection;
      await tester.pumpWidget(
        _harness(_Settings(), (context, ref) async {
          selection = await showExportOptions(
            context,
            ref,
            instances: instances,
            pdfTitlePageDefaults: const PdfTitlePageData(
              title: 'Must not use open topic',
            ),
          );
        }),
      );
      await _open(tester);
      await _toggle(tester, true);
      expect(_text(tester, 'Title'), 'Instance a');
      tester
          .widget<BusyMarkComboRow<WritersideInstance>>(
            find.byType(BusyMarkComboRow<WritersideInstance>),
          )
          .onSelected(instances[1]);
      await tester.pumpAndSettle();
      expect(_text(tester, 'Title'), 'Instance b');
      expect(_text(tester, 'Version'), 'Version b');
      await _edit(tester, 'Title', 'Edited instance cover');
      await _edit(tester, 'Version', '');
      tester
          .widget<BusyMarkComboRow<WritersideInstance>>(
            find.byType(BusyMarkComboRow<WritersideInstance>),
          )
          .onSelected(instances[0]);
      await tester.pumpAndSettle();
      expect(_text(tester, 'Title'), 'Edited instance cover');
      expect(_text(tester, 'Version'), '');
      await tester.tap(find.byKey(const ValueKey('export-options-submit')));
      await _settle(tester);
      expect(selection!.instance!.id, 'a');
      expect(selection!.titlePage!.title, 'Edited instance cover');
      expect(selection!.titlePage!.version, '');
    },
  );

  testWidgets(
    'settings without a document show only the reusable cover preference',
    (tester) async {
      await tester.pumpWidget(
        _harness(_Settings(), (context, ref) async {
          await showExportOptions(context, ref);
        }),
      );
      await _open(tester);
      await _toggle(tester, true);
      expect(_field('Title'), findsNothing);
      expect(_field('Author'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  for (final unified in [false, true]) {
    for (final writerside in [false, true]) {
      testWidgets(
        '${unified ? "Unified" : "Direct"} PDF ${writerside ? "Writerside" : "Markdown"} forwards current defaults and export-owned text',
        (tester) async {
          final root = Directory.systemTemp.createTempSync('pdf-title-ui-');
          addTearDown(() => root.deleteSync(recursive: true));
          final markdown = _MarkdownExporter();
          final instance = _WritersideExporter();
          final picker = Completer<String?>();
          const channel = MethodChannel('plugins.flutter.io/file_selector');
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) => picker.future,
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
          late WidgetRef ref;
          await tester.pumpWidget(
            _harness(
              _Settings(),
              (context, value) => unified
                  ? exportWorkspace(context, value)
                  : exportWorkspaceToPdf(context, value),
              ready: (value) => ref = value,
              markdown: markdown,
              writerside: instance,
            ),
          );
          final controller = ref.read(workspaceControllerProvider.notifier);
          if (writerside) {
            await tester.runAsync(
              () => controller.openPath(
                Directory(
                  'test/fixtures/writerside/pdf_front_matter',
                ).absolute.path,
              ),
            );
            await tester.runAsync(
              () => controller.openActiveFile(
                File(
                  'test/fixtures/writerside/pdf_front_matter/topics/body.topic',
                ).absolute.path,
              ),
            );
          } else {
            await tester.runAsync(controller.createMarkdownFile);
            controller.updateActiveText(
              '---\ntitle: Unsaved cover title\nauthor: Unsaved author\n---\n# Unsaved body\n',
            );
          }
          await _open(tester);
          await _toggle(tester, true);
          expect(
            _text(tester, 'Title'),
            writerside ? 'Instance cover default' : 'Unsaved cover title',
          );
          expect(_text(tester, 'Author'), writerside ? '' : 'Unsaved author');
          await _edit(tester, 'Subtitle', 'Only this request');
          await _edit(tester, 'Author', '');
          // Changing the live Markdown editor while the dialog is open must not
          // separate the exported body from its already captured metadata.
          if (!writerside) {
            controller.updateActiveText('# Later editor revision');
          }
          await tester.tap(find.byKey(const ValueKey('export-options-submit')));
          await _settle(tester);
          picker.complete(p.join(root.path, 'export.pdf'));
          for (var i = 0; i < 20; i++) {
            await _settle(tester);
            if (markdown.request != null || instance.request != null) break;
          }
          final titlePage = writerside
              ? instance.request!.titlePage!
              : markdown.request!.titlePage!;
          expect(titlePage.subtitle, 'Only this request');
          expect(titlePage.author, '');
          if (writerside) {
            expect(instance.request!.instanceId, 'guide');
            expect(instance.request!.options.includeTitlePage, isTrue);
          } else {
            expect(markdown.request!.source, contains('# Unsaved body'));
            expect(
              markdown.request!.document!.frontMatter['title'],
              'Unsaved cover title',
            );
            expect(markdown.request!.options.includeTitlePage, isTrue);
            expect(
              ref.read(workspaceControllerProvider).activeText,
              '# Later editor revision',
            );
          }
          await tester.pump(const Duration(seconds: 8));
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (w) => w is BusyMarkGroupedTextEntry && w.label == label,
);
Finder _input(String label) =>
    find.descendant(of: _field(label), matching: find.byType(TextField));
String _text(WidgetTester tester, String label) =>
    tester.widget<TextField>(_input(label)).controller!.text;
Future<void> _edit(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_input(label));
  await tester.enterText(_input(label), value);
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester, bool value) async {
  tester
      .widget<BusyMarkSwitchRow>(
        find.byKey(const ValueKey('pdf-include-title-page')),
      )
      .onChanged(value);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Run export'));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 70)),
  );
  await tester.pumpAndSettle();
}

Widget _harness(
  _Settings settings,
  Future<void> Function(BuildContext, WidgetRef) action, {
  void Function(WidgetRef)? ready,
  MarkdownPdfExportService? markdown,
  WritersidePdfExportService? writerside,
}) => ProviderScope(
  overrides: [
    localSettingsStoreProvider.overrideWithValue(settings),
    linuxHeaderBarServiceProvider.overrideWithValue(
      LinuxHeaderBarService(
        channel: const MethodChannel('pdf-title-test-header'),
      ),
    ),
    if (markdown != null)
      markdownPdfExportServiceProvider.overrideWithValue(markdown),
    if (writerside != null)
      writersidePdfExportServiceProvider.overrideWithValue(writerside),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: Colors.blue,
    ),
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          ready?.call(ref);
          return TextButton(
            onPressed: () => action(context, ref),
            child: const Text('Run export'),
          );
        },
      ),
    ),
  ),
);

class _Settings implements LocalSettingsStore {
  Map<String, Object?> data = AppSettings.defaults()
      .copyWith(autoSave: false)
      .toJson();
  @override
  Future<Map<String, Object?>> load() async => data;
  @override
  Future<void> save(Map<String, Object?> json) async {
    data = json;
  }
}

class _MarkdownExporter extends MarkdownPdfExportService {
  MarkdownPdfExportRequest? request;
  @override
  Future<MarkdownPdfExportResult> export(
    MarkdownPdfExportRequest request, {
    MarkdownPdfCancellationToken? cancellationToken,
  }) async {
    this.request = request;
    return MarkdownPdfExportResult(
      destinationPath: request.destinationPath,
      pageCount: 2,
      warnings: const [],
    );
  }
}

class _WritersideExporter extends WritersidePdfExportService {
  WritersidePdfExportRequest? request;
  @override
  Future<WritersidePdfExportResult> export(
    WritersidePdfExportRequest request, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    this.request = request;
    return WritersidePdfExportResult(
      destinationPath: request.destinationPath,
      pageCount: 2,
      warnings: const [],
    );
  }
}
