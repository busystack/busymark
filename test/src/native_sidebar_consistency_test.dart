import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/path_label.dart';
import 'package:busymark/src/app/busymark_design.dart';
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
  testWidgets('informational header stays separate from neighboring actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const BusyMarkSidebarHeader(
                  title: 'Git Log',
                  contextLine: Text('Selected subject'),
                ),
                Semantics(
                  button: true,
                  onTap: () {},
                  child: const Text('Commit details'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(BusyMarkSidebarHeader)),
        matchesSemantics(label: 'Git Log\nSelected subject', isButton: false),
      );
    } finally {
      semantics.dispose();
    }
  });
  for (final brightness in Brightness.values) {
    for (final locale in ['en', 'de', 'ja', 'ar']) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'eight headers share icon/title/context geometry $brightness $locale $scale',
          (tester) async {
            tester.view.physicalSize = const Size(800, 1200);
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
              'References',
            ];
            final icons = [
              BusyMarkGlyphs.folder,
              BusyMarkGlyphs.orderedList,
              BusyMarkGlyphs.indentFor(
                locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
              BusyMarkGlyphs.branch,
              BusyMarkGlyphs.history,
              BusyMarkGlyphs.history,
              BusyMarkGlyphs.paste,
              BusyMarkGlyphs.link,
            ];
            final contexts = [
              '/very/long/directory/path/日本語/العربية',
              'Development',
              'Current document with long name.md',
              'feature/long-branch-name',
              'Selected historical subject with a deliberately long name',
              'Current document.md',
              '',
              'introduction.md',
            ];
            for (final width in [240.0, 300.0]) {
              await tester.pumpWidget(
                app(
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            BusyMarkSidebarHeader(
                              key: ValueKey('header-$i'),
                              title: labels[i],
                              leading: Icon(icons[i], key: ValueKey('icon-$i')),
                              contextLine: i == 6
                                  ? null
                                  : Text(
                                      contexts[i],
                                      key: ValueKey('context-$i'),
                                    ),
                              actions: [
                                if ({1, 3, 4}.contains(i))
                                  SizedBox(
                                    key: ValueKey('select-$i'),
                                    width: 34,
                                    height: 34,
                                  ),
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
              for (var i = 0; i < labels.length; i++) {
                final header = find.byKey(ValueKey('header-$i'));
                final title = find.text(labels[i]);
                final icon = find.byKey(ValueKey('icon-$i'));
                final action = find.byKey(ValueKey('action-$i'));
                expect(start(title), start(find.text(labels.first)));
                expect(
                  start(icon),
                  start(find.byKey(const ValueKey('icon-0'))),
                );
                expect(tester.getSize(icon), const Size.square(16));
                expect(tester.getCenter(title).dy, tester.getCenter(action).dy);
                expect(tester.getCenter(icon).dy, tester.getCenter(action).dy);
                expect(
                  tester.getRect(action).top - tester.getRect(header).top,
                  8,
                );
                expect(
                  tester.getRect(action).right,
                  tester.getRect(find.byKey(const ValueKey('action-0'))).right,
                );
                final text = tester.widget<Text>(title);
                expect(text.maxLines, 1);
                expect(text.overflow, TextOverflow.ellipsis);
                if (i != 6) {
                  final context = find.byKey(ValueKey('context-$i'));
                  expect(start(context), start(icon));
                  expect(
                    tester.getRect(context).top - tester.getRect(action).bottom,
                    4,
                  );
                  expect(
                    tester.getRect(header).bottom -
                        tester.getRect(context).bottom,
                    8,
                  );
                  final style = DefaultTextStyle.of(tester.element(context));
                  expect(style.style.fontSize, lessThan(text.style!.fontSize!));
                  expect(
                    style.style.color,
                    Theme.of(
                      tester.element(context),
                    ).colorScheme.onSurfaceVariant,
                  );
                  expect(style.maxLines, 1);
                  expect(style.overflow, TextOverflow.ellipsis);
                  expect(
                    find.descendant(of: context, matching: find.byType(Icon)),
                    findsNothing,
                  );
                }
                if ({1, 3, 4}.contains(i)) {
                  final select = find.byKey(ValueKey('select-$i'));
                  expect(
                    rtl
                        ? tester.getCenter(select).dx >
                              tester.getCenter(action).dx
                        : tester.getCenter(select).dx <
                              tester.getCenter(action).dx,
                    isTrue,
                  );
                }
              }
              expect(find.byKey(const ValueKey('context-6')), findsNothing);
              expect(
                tester.getSize(find.byKey(const ValueKey('header-6'))).height,
                lessThan(
                  tester.getSize(find.byKey(const ValueKey('header-0'))).height,
                ),
              );
              expect(tester.takeException(), isNull);
            }
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
            BusyMarkFocusStyle.color(scheme, highContrast: contrast),
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
