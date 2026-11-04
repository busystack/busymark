import 'dart:async';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

Widget harness(
  Widget child, {
  String locale = 'en',
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildBusyMarkTheme(
    brightness: brightness,
    accentColor: busyMarkDefaultAccentColor,
  ),
  home: YaruTheme(
    data: const YaruThemeData(focusBorders: true),
    child: BusyMarkToastOverlay(
      child: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Padding(padding: BusyMarkInsets.sidebarList, child: child),
        ),
      ),
    ),
  ),
);

void main() {
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'Files disclosure geometry and full context target $locale $scale $brightness',
          (tester) async {
            final focus = FocusNode();
            addTearDown(focus.dispose);
            var primary = 0, menus = 0;
            final selected = ValueNotifier(false);
            addTearDown(selected.dispose);
            await tester.pumpWidget(
              harness(
                SizedBox(
                  width: 280,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: selected,
                    builder: (_, value, _) => Column(
                      children: [
                        BusyMarkSidebarTreeRow(
                          title: 'Parent 日本語 überblick',
                          depth: 0,
                          focusNode: focus,
                          selected: value,
                          hasChildren: true,
                          onTap: () => primary++,
                          onToggle: () {},
                          onMenuRequested: (_, _) => menus++,
                        ),
                        BusyMarkSidebarTreeRow(
                          title: 'Child العربية',
                          depth: 1,
                          onTap: () {},
                          onMenuRequested: (_, _) {},
                        ),
                      ],
                    ),
                  ),
                ),
                locale: locale,
                scale: scale,
                brightness: brightness,
              ),
            );
            await tester.pumpAndSettle();
            final parent = find.text('Parent 日本語 überblick');
            final child = find.text('Child العربية');
            final rtl = locale == 'ar';
            expect(
              rtl
                  ? tester.getTopRight(parent).dx - tester.getTopRight(child).dx
                  : tester.getTopLeft(child).dx - tester.getTopLeft(parent).dx,
              closeTo(BusyMarkSizes.sidebarTreeDepthIndent, .01),
            );
            final disclosure = tester.getRect(
              find.byType(AnimatedRotation).first,
            );
            expect(
              rtl
                  ? disclosure.left - tester.getRect(parent).right
                  : tester.getRect(parent).left - disclosure.right,
              closeTo(BusyMarkSpacing.xs, .01),
            );
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: tester.getCenter(parent));
            await mouse.moveTo(tester.getCenter(parent));
            await tester.pump();
            selected.value = true;
            focus.requestFocus();
            await tester.pumpAndSettle();
            expect(find.byType(BusyMarkCompactIconButton), findsNothing);
            expect(find.byType(BusyMarkHeaderIconButton), findsNothing);
            final press = await tester.startGesture(tester.getCenter(parent));
            await tester.pump();
            expect(find.byType(BusyMarkCompactIconButton), findsNothing);
            await press.cancel();
            await tester.tap(parent, buttons: kSecondaryMouseButton);
            await tester.pump();
            expect(primary, 0);
            expect(menus, 1);
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
            await tester.sendKeyEvent(LogicalKeyboardKey.f10);
            expect(
              menus,
              1,
              reason: 'The native grab waits for trigger release',
            );
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
            await tester.pump();
            expect(menus, 2);
            await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
            await tester.pump();
            expect(menus, 3);
            expect(primary, 0);
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            expect(primary, 1);
            await mouse.removePointer();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('record density, native menu snapshot and focus $brightness', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final reply = Completer<int?>();
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('busymark/native_menus'),
        (call) async {
          calls.add(call);
          return call.method == 'show' ? reply.future : null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          null,
        ),
      );
      var primary = 0, action = 0;
      await tester.pumpWidget(
        harness(
          Column(
            children: [
              BusyMarkSidebarRecordRow<String>(
                key: const ValueKey('revision'),
                title: '12:34:56',
                icon: BusyMarkGlyphs.history,
                focusNode: focus,
                onTap: () => primary++,
                menuTooltip: 'Revision actions',
                menuItemsBuilder: (_) => [
                  BusyMarkPopupMenuItem(
                    value: 'restore',
                    label: 'Restore revision',
                  ),
                ],
                menuSelectionForSession: () {
                  final reviewed = 7;
                  return (_) => action = reviewed;
                },
              ),
              BusyMarkSidebarRecordRow<void>(
                key: const ValueKey('event'),
                title: '12:34:57',
                subtitle: 'Saved by the document author',
                icon: BusyMarkGlyphs.history,
                onTap: () {},
              ),
            ],
          ),
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('revision'))).height,
        closeTo(BusyMarkSizes.iconButton, .01),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('event'))).height,
        greaterThan(
          tester.getSize(find.byKey(const ValueKey('revision'))).height,
        ),
      );
      expect(find.byType(YaruListTile), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(BusyMarkCompactIconButton), findsNothing);
      await tester.tap(find.text('12:34:56'), buttons: kSecondaryMouseButton);
      await tester.pump();
      expect(primary, 0);
      final entries = (calls.single.arguments as Map)['entries'] as List;
      expect((entries.single as Map)['label'], 'Restore revision');
      expect(
        find.text('Restore revision'),
        findsNothing,
        reason: 'GTK owns the menu; no first-party fallback route renders it',
      );
      reply.complete(0);
      await tester.pumpAndSettle();
      expect(action, 7);
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'disabled sidebar rows neither activate nor paint hover/pressed feedback',
    (tester) async {
      var invoked = 0;
      await tester.pumpWidget(
        harness(
          BusyMarkSidebarTreeRow(
            title: 'Unavailable',
            depth: 0,
            enabled: false,
            onTap: () => invoked++,
            onMenuRequested: (_, _) => invoked++,
          ),
        ),
      );
      final surface = find.byType(BusyMarkSidebarRowSurface);
      Color? background() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: surface,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              is BoxDecoration
          ? (tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: surface,
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .color
          : null;
      final idle = background();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Unavailable')),
      );
      await mouse.moveTo(tester.getCenter(find.text('Unavailable')));
      await tester.pump();
      expect(background(), idle);
      await tester.tap(find.text('Unavailable'));
      await tester.tap(
        find.text('Unavailable'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      expect(invoked, 0);
      expect(find.byType(BusyMarkCompactIconButton), findsNothing);
      await mouse.removePointer();
    },
  );
}
