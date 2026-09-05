import 'dart:io';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/export/export_options.dart';
import 'package:busymark/src/export/export_options_editor.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final pdf in [true, false]) {
    for (final writerside in [false, true]) {
      testWidgets(
        '${writerside ? 'Writerside' : 'Markdown'} ${pdf ? 'PDF' : 'HTML'} loads confirmed settings and shares controls',
        (tester) async {
          final module = await tester.runAsync(
            () => const WritersideModuleService().load(
              'test/fixtures/writerside/basic_project',
            ),
          );
          final settings = _Settings(
            AppSettings.defaults()
                .copyWith(
                  pdfExportOptions: const PdfExportOptions(bodyFontSize: 14),
                  htmlExportOptions: const HtmlExportOptions(baseFontSize: 21),
                )
                .toJson(),
          );
          ExportOptionsSelection? selected;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                localSettingsStoreProvider.overrideWithValue(settings),
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
                    builder: (context, ref, _) => TextButton(
                      child: const Text('Configure'),
                      onPressed: () async {
                        selected = await showExportOptions(
                          context,
                          ref,
                          pdf: pdf,
                          instances: writerside
                              ? module!.instances
                                    .where((i) => !i.isLibrary)
                                    .toList()
                              : const [],
                          workspaceRoot: writerside ? module!.rootPath : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Configure'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ExportContentOptionsEditor), findsOneWidget);
          if (pdf) {
            expect(
              tester
                  .widget<PdfExportOptionsEditor>(
                    find.byType(PdfExportOptionsEditor),
                  )
                  .value
                  .bodyFontSize,
              14,
            );
            expect(find.byType(HtmlExportOptionsEditor), findsNothing);
          } else {
            expect(
              tester
                  .widget<HtmlExportOptionsEditor>(
                    find.byType(HtmlExportOptionsEditor),
                  )
                  .value
                  .baseFontSize,
              21,
            );
            expect(find.byType(PdfExportOptionsEditor), findsNothing);
          }
          final toc = tester.widget<BusyMarkComboRow<int>>(
            find.byWidgetPredicate(
              (w) => w is BusyMarkComboRow<int> && w.title == 'TOC depth',
            ),
          );
          expect(toc.enabled, !pdf);
          await tester.tap(find.text('Reset to defaults'));
          await tester.pumpAndSettle();
          if (pdf) {
            expect(
              tester
                  .widget<PdfExportOptionsEditor>(
                    find.byType(PdfExportOptionsEditor),
                  )
                  .value
                  .bodyFontSize,
              10.5,
            );
          } else {
            expect(
              tester
                  .widget<HtmlExportOptionsEditor>(
                    find.byType(HtmlExportOptionsEditor),
                  )
                  .value
                  .baseFontSize,
              17,
            );
          }
          await tester.tap(find.text('Export'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pumpAndSettle();
          expect(selected, isNotNull);
          expect(selected!.instance != null, writerside);
          final stored = AppSettings.fromJson(settings.data);
          expect(
            pdf
                ? stored.pdfExportOptions.bodyFontSize
                : stored.htmlExportOptions.baseFontSize,
            pdf ? 10.5 : 17,
          );
          // The other format's remembered appearance is unaffected.
          expect(
            pdf
                ? stored.htmlExportOptions.baseFontSize
                : stored.pdfExportOptions.bodyFontSize,
            pdf ? 21 : 14,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'custom geometry controls, TOC enablement and invalid input at minimum size',
    (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var value = const PdfExportOptions();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: PdfExportOptionsEditor(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Page width (mm)'), findsNothing);
      final size = tester.widget<BusyMarkComboRow<PdfPageSize>>(
        find.byWidgetPredicate((w) => w is BusyMarkComboRow<PdfPageSize>),
      );
      size.onSelected(PdfPageSize.custom);
      await tester.pumpAndSettle();
      expect(find.text('Page width (mm)'), findsOneWidget);
      final margin = tester.widget<BusyMarkComboRow<PdfMarginPreset>>(
        find.byWidgetPredicate((w) => w is BusyMarkComboRow<PdfMarginPreset>),
      );
      margin.onSelected(PdfMarginPreset.custom);
      await tester.pumpAndSettle();
      expect(find.text('Left margin (mm)'), findsOneWidget);
      final tocSwitch = tester.widget<BusyMarkSwitchRow>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkSwitchRow && w.title == 'Include table of contents',
        ),
      );
      tocSwitch.onChanged(true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BusyMarkComboRow<int>>(
              find.byWidgetPredicate((w) => w is BusyMarkComboRow<int>),
            )
            .enabled,
        true,
      );
      final width = find.descendant(
        of: find.byKey(const ValueKey('customWidthMm')),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(width);
      await tester.enterText(width, '1');
      await tester.pumpAndSettle();
      expect(value.validate(), isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelling settings does not confirm or persist edits', (
    tester,
  ) async {
    final settings = _Settings(AppSettings.defaults().toJson());
    final before = Map<String, Object?>.from(settings.data);
    var confirmed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localSettingsStoreProvider.overrideWithValue(settings)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                child: const Text('Configure'),
                onPressed: () async {
                  confirmed =
                      await showExportOptions(context, ref, pdf: false) != null;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Configure'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(confirmed, false);
    expect(settings.data, before);
  });

  test(
    'JSON settings store retains both format settings across controllers',
    () async {
      final dir = await Directory.systemTemp.createTemp('export-settings-');
      addTearDown(() => dir.delete(recursive: true));
      final store = JsonFileLocalSettingsStore(
        settingsFilePathOverride: '${dir.path}/settings.json',
      );
      final first = ProviderContainer(
        overrides: [localSettingsStoreProvider.overrideWithValue(store)],
      );
      final controller = first.read(appSettingsControllerProvider.notifier);
      await controller.waitUntilLoaded();
      await controller.setPdfExportOptions(
        const PdfExportOptions(pageSize: PdfPageSize.legal),
      );
      await controller.setHtmlExportOptions(
        const HtmlExportOptions(theme: HtmlExportTheme.dark),
      );
      first.dispose();
      final next = ProviderContainer(
        overrides: [localSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(next.dispose);
      await next.read(appSettingsControllerProvider.notifier).waitUntilLoaded();
      expect(
        next.read(appSettingsControllerProvider).pdfExportOptions.pageSize,
        PdfPageSize.legal,
      );
      expect(
        next.read(appSettingsControllerProvider).htmlExportOptions.theme,
        HtmlExportTheme.dark,
      );
    },
  );
}

class _Settings implements LocalSettingsStore {
  _Settings(this.data);
  Map<String, Object?> data;
  @override
  Future<Map<String, Object?>> load() async => data;
  @override
  Future<void> save(Map<String, Object?> json) async {
    data = json;
  }
}
