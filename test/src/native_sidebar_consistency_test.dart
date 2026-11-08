import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/path_label.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(
  Widget child, {
  Brightness brightness = Brightness.light,
  String locale = 'en',
  double scale = 1,
  bool contrast = false,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildBusyMarkTheme(
    brightness: brightness,
    accentColor: const Color(0xffb34cb4),
  ),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        highContrast: contrast,
      ),
      child: child,
    ),
  ),
);

Border paintedBorder(WidgetTester tester, Finder row) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(of: row, matching: find.byType(AnimatedContainer)),
    )
    .map((w) => w.foregroundDecoration)
    .whereType<BoxDecoration>()
    .map((d) => d.border)
    .whereType<Border>()
    .single;

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in ['en', 'de', 'ja', 'ar']) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'seven headers share title/context grid $brightness $locale $scale',
          (tester) async {
            tester.view.physicalSize = const Size(800, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final labels = [
              'Files',
              'Table of Contents',
              'Outline',
              'Commit',
              'Git Log',
              'Local History',
              'Clipboard History',
            ];
            final contexts = [
              '/very/long/directory/path',
              'Development',
              'Current document.md',
              'feature/long-branch-name',
              'Selected historical subject',
              'Current document.md',
            ];
            await tester.pumpWidget(
              app(
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        for (var i = 0; i < 7; i++)
                          BusyMarkSidebarHeader(
                            key: ValueKey('header-$i'),
                            title: labels[i],
                            contextLine: i == 6
                                ? null
                                : Text(
                                    contexts[i],
                                    key: ValueKey('context-$i'),
                                  ),
                            actions: [
                              SizedBox(
                                key: ValueKey('action-$i'),
                                width: 34,
                                height: 34,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                brightness: brightness,
                locale: locale,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            final rtl = locale == 'ar';
            double start(Finder f) =>
                rtl ? tester.getRect(f).right : tester.getRect(f).left;
            for (var i = 0; i < 7; i++) {
              final heading = find.text(labels[i]);
              expect(start(heading), start(find.text(labels.first)));
              expect(
                tester.getRect(find.byKey(ValueKey('action-$i'))).right,
                tester.getRect(find.byKey(const ValueKey('action-0'))).right,
              );
              expect(
                tester.getRect(heading).top -
                    tester.getRect(find.byKey(ValueKey('header-$i'))).top,
                8,
              );
              expect(
                tester.getRect(find.byKey(ValueKey('action-$i'))).top -
                    tester.getRect(find.byKey(ValueKey('header-$i'))).top,
                8,
              );
              final text = tester.widget<Text>(heading);
              expect(text.maxLines, 1);
              expect(text.overflow, TextOverflow.ellipsis);
              if (i < 6) {
                final context = find.byKey(ValueKey('context-$i'));
                expect(start(context), start(heading));
                expect(
                  tester.getRect(context).top - tester.getRect(heading).bottom,
                  closeTo(2, .01),
                );
                final style = DefaultTextStyle.of(tester.element(context));
                expect(style.style.fontSize, lessThan(text.style!.fontSize!));
                expect(style.maxLines, 1);
                expect(style.overflow, TextOverflow.ellipsis);
              }
            }
            expect(find.byKey(const ValueKey('context-6')), findsNothing);
            expect(
              tester.getSize(find.byKey(const ValueKey('header-6'))).height,
              lessThanOrEqualTo(
                tester.getSize(find.byKey(const ValueKey('header-0'))).height,
              ),
            );
            expect(tester.takeException(), isNull);
          },
        );
        testWidgets(
          'comfortable records retain two lines without inflating history $brightness $locale $scale',
          (tester) async {
            await tester.pumpWidget(
              app(
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      BusyMarkSidebarRecordRow<void>(
                        key: const ValueKey('recent'),
                        icon: BusyMarkGlyphs.folder,
                        title: 'Long recent workspace name 日本語 العربية',
                        subtitle: '/long/path/to/workspace',
                        pathSubtitle: true,
                        density: BusyMarkRecordDensity.comfortable,
                        selected: true,
                        onTap: () {},
                      ),
                      BusyMarkSidebarRecordRow<void>(
                        key: const ValueKey('history'),
                        icon: BusyMarkGlyphs.history,
                        title: '12:34',
                        compact: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                brightness: brightness,
                locale: locale,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getSize(find.byKey(const ValueKey('recent'))).height,
              greaterThanOrEqualTo(54),
            );
            expect(
              tester.getSize(find.byKey(const ValueKey('history'))).height,
              lessThan(
                tester.getSize(find.byKey(const ValueKey('recent'))).height,
              ),
            );
            expect(
              tester
                  .widget<BusyMarkPathLabel>(find.byType(BusyMarkPathLabel))
                  .path,
              '/long/path/to/workspace',
            );
            final surface = find.descendant(
              of: find.byKey(const ValueKey('recent')),
              matching: find.byType(BusyMarkSidebarRowSurface),
            );
            final rowRect = tester.getRect(surface);
            final label = tester.getRect(
              find.text('Long recent workspace name 日本語 العربية'),
            );
            expect(
              locale == 'ar'
                  ? rowRect.right - label.right
                  : label.left - rowRect.left,
              closeTo(42, .01),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
    for (final contrast in [false, true]) {
      testWidgets(
        'row focus modality, traversal and return $brightness contrast=$contrast',
        (tester) async {
          final nodes = [FocusNode(), FocusNode()];
          addTearDown(() {
            for (final node in nodes) {
              node.dispose();
            }
          });
          var opened = 0, activated = 0;
          await tester.pumpWidget(
            app(
              Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    BusyMarkSidebarRowSurface(
                      key: ValueKey(i),
                      enabled: true,
                      clickable: true,
                      selected: i == 0,
                      focusNode: nodes[i],
                      onTap: () => activated++,
                      onSecondaryTapUp: (_) => opened++,
                      onKeyEvent: (_, e) {
                        if (e is KeyDownEvent &&
                            e.logicalKey == LogicalKeyboardKey.arrowDown) {
                          nodes[1 - i].requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Text('row $i'),
                    ),
                ],
              ),
              brightness: brightness,
              contrast: contrast,
            ),
          );
          await tester.pumpAndSettle();
          final first = find.byKey(const ValueKey(0));
          final second = find.byKey(const ValueKey(1));
          Future<void> click(
            Finder f, {
            int buttons = kPrimaryMouseButton,
          }) async {
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: buttons,
            );
            await mouse.down(tester.getCenter(f));
            await mouse.up();
            await tester.pumpAndSettle();
          }

          await click(first);
          expect(nodes[0].hasFocus, isTrue);
          expect(paintedBorder(tester, first).top.color.a, 0);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(activated, 2);
          expect(paintedBorder(tester, first).top.color.a, contrast ? 1 : .65);
          expect(paintedBorder(tester, first).top.width, 2);
          expect(
            paintedBorder(tester, first).top.strokeAlign,
            BorderSide.strokeAlignInside,
          );
          final scheme = Theme.of(tester.element(first)).colorScheme;
          expect(
            paintedBorder(tester, first).top.color,
            NativeFocusStyle.color(scheme, highContrast: contrast),
          );
          final theme = Theme.of(tester.element(first));
          final surface = Color.alphaBlend(
            BusyMarkSurfaceColors.of(tester.element(first)).controlActive,
            theme.scaffoldBackgroundColor,
          );
          final outline = Color.alphaBlend(
            paintedBorder(tester, first).top.color,
            surface,
          );
          final a = outline.computeLuminance(), b = surface.computeLuminance();
          final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason: 'Keyboard outline contrasts against selected rows',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(nodes[1].hasFocus, isTrue);
          expect(paintedBorder(tester, first).top.color.a, 0);
          expect(paintedBorder(tester, second).top.color.a, greaterThan(0));
          await click(first, buttons: kSecondaryMouseButton);
          expect(opened, 1);
          expect(nodes[0].hasFocus, isTrue);
          expect(paintedBorder(tester, first).top.color.a, 0);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          expect(nodes[1].hasFocus, isTrue);
          expect(paintedBorder(tester, second).top.color.a, greaterThan(0));
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pumpAndSettle();
          expect(nodes[0].hasFocus, isTrue);
          expect(paintedBorder(tester, first).top.color.a, greaterThan(0));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.linux),
      );
    }
  }
}
