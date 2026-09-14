import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/workspace/presentation/writerside_toc_dialogs.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('existing-topic picker filters names and selects by keyboard', (
    tester,
  ) async {
    final topics = [
      for (final name in ['alpha.md', 'beta.md', 'gamma.md'])
        const WritersideTopicParser().parseMarkdown(
          filePath: '/topics/$name',
          source: '# $name\n',
          topicsRoot: '/topics',
        ),
    ];
    WritersideTopic? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Link'),
              onPressed: () async => chosen = await showDialog<WritersideTopic>(
                context: context,
                builder: (_) => WritersideExistingTopicPicker(topics: topics),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(chosen?.fileName, 'beta.md');
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GAM');
    await tester.pumpAndSettle();
    expect(find.text('alpha.md'), findsNothing);
    expect(find.text('gamma.md'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(chosen?.fileName, 'gamma.md');
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('nested menus use the native host in $direction', (
      tester,
    ) async {
      MethodCall? call;
      int? response;
      String? selected;
      const channel = MethodChannel(nativeMenuChannelName);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        value,
      ) async {
        call = value;
        return response;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => TextButton(
                child: const Text('Native menu'),
                onPressed: () async {
                  selected = await showBusyMarkMenu<String>(
                    context: context,
                    focusFirst: true,
                    items: [
                      BusyMarkSubmenuItem(
                        label: 'New Topic',
                        items: [
                          BusyMarkPopupMenuItem(value: 'md', label: 'Markdown'),
                          const PopupMenuDivider(),
                          BusyMarkSubmenuItem(
                            label: 'Formats',
                            items: [
                              BusyMarkPopupMenuItem(
                                value: 'disabled',
                                label: 'Disabled',
                                enabled: false,
                              ),
                              BusyMarkPopupMenuItem(value: 'xml', label: 'XML'),
                            ],
                          ),
                        ],
                      ),
                      BusyMarkSubmenuItem(
                        label: 'Unavailable',
                        enabled: false,
                        items: [
                          BusyMarkPopupMenuItem(
                            value: 'ancestor-disabled',
                            label: 'Child',
                          ),
                        ],
                      ),
                      BusyMarkPopupMenuItem(value: 'extra', label: 'Extra'),
                      const PopupMenuDivider(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      for (final index in <int?>[1, 5, 8, 0, 2, 3, 4, 6, 7, 9, 10, -1, null]) {
        response = index;
        await tester.tap(find.text('Native menu'));
        await tester.pumpAndSettle();
        expect(selected, {1: 'md', 5: 'xml', 8: 'extra'}[index]);
        expect(find.byType(MenuAnchor), findsNothing);
        expect(find.text('New Topic'), findsNothing);
      }
      final args = call!.arguments as Map;
      expect(args['textDirection'], direction.name);
      expect(args['focusFirst'], isTrue);
      final entries = args['entries'] as List;
      expect(entries.length, 4);
      expect((entries[0] as Map)['children'], hasLength(3));
      expect(
        ((entries[0] as Map)['children'] as List)[2]['children'],
        hasLength(2),
      );
      expect((entries[1] as Map)['enabled'], isFalse);
    });

    testWidgets(
      'unavailable-host fallback supports keyboard and Escape in $direction',
      (tester) async {
        String? selected;
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: ElevatedButton(
                      focusNode: focus,
                      onPressed: () async {
                        selected = await showBusyMarkMenu<String>(
                          context: context,
                          anchorPoint: const Offset(400, 200),
                          focusFirst: selected == null,
                          items: [
                            BusyMarkSubmenuItem(
                              label: 'New Topic',
                              items: [
                                BusyMarkPopupMenuItem(
                                  value: 'md',
                                  label: 'Empty MD Topic',
                                ),
                                BusyMarkPopupMenuItem(
                                  value: 'xml',
                                  label: 'Empty XML Topic',
                                ),
                              ],
                            ),
                            BusyMarkSubmenuItem(
                              label: 'New Child Topic',
                              items: [
                                BusyMarkPopupMenuItem(
                                  value: 'child',
                                  label: 'Child XML',
                                ),
                              ],
                            ),
                            const PopupMenuDivider(),
                            BusyMarkPopupMenuItem(
                              value: 'extra',
                              label: 'Extra',
                            ),
                            for (var i = 0; i < 25; i++)
                              BusyMarkPopupMenuItem(
                                value: 'extra$i',
                                label: 'Extra $i',
                              ),
                          ],
                        );
                      },
                      child: const Text('Open menu'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('New Topic'), findsOneWidget);
        await tester.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pumpAndSettle();
        expect(find.text('Empty MD Topic'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, 'xml');
        expect(find.text('New Topic'), findsNothing);
        expect(focus.hasFocus, isTrue);
        await tester.tap(find.text('Open menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Child Topic'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Child XML'));
        await tester.pumpAndSettle();
        expect(selected, 'child');
        await tester.tap(find.text('Open menu'));
        await tester.pumpAndSettle();
        if (find.text('Empty XML Topic').evaluate().isEmpty) {
          await tester.tap(find.text('New Topic'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Empty XML Topic'));
        await tester.pumpAndSettle();
        expect(selected, 'xml');
        expect(find.text('New Topic'), findsNothing);
        await tester.tap(find.text('Open menu'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(selected, isNull);
        expect(find.text('New Topic'), findsNothing);
        expect(focus.hasFocus, isTrue);
      },
    );
  }
}
