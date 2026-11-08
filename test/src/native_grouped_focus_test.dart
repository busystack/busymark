import 'dart:io';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

Iterable<Color> borders(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((w) => w.foregroundDecoration)
    .whereType<BoxDecoration>()
    .map((d) => d.border)
    .whereType<Border>()
    .map((b) => b.top.color);

void main() {
  test('each design boundary owns exactly one upstream focus-border primitive', () {
    const owners = {
      'lib/src/app/busymark_focus.dart': 'BusyMarkFocusIndicator',
      '../busystack_git_flutter/lib/src/native_primitives.dart':
          'NativeFocusIndicator',
    };
    final construction = RegExp(r'\bYaruFocusBorder(?:\.\w+)?\s*\(');
    for (final entry in owners.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(construction.allMatches(source), hasLength(1), reason: entry.key);
      expect(source, contains('class ${entry.value}'));
    }
    expect(
      File('lib/src/app/busymark_focus.dart').readAsStringSync(),
      isNot(contains("import 'package:busystack_git_flutter/")),
    );
    for (final root in ['lib', '../busystack_git_flutter/lib']) {
      for (final file
          in Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (owners.containsKey(file.path)) continue;
        if (!file.path.endsWith('/busymark_design.dart') &&
            !file.path.endsWith('/linux_native.dart')) {
          expect(
            RegExp(
              r'\bYaru(?:ListTile|MasterTile|CheckboxListTile|SwitchListTile|IconButton|Checkbox|CheckButton|Switch|Radio|RadioButton)(?:\.\w+)?\s*\(',
            ).hasMatch(file.readAsStringSync()),
            isFalse,
            reason:
                '${file.path}: focus-capable controls must use their design boundary',
          );
        }
        expect(
          construction.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    }
  });
  for (final brightness in Brightness.values) {
    for (final kind in [
      'action',
      'master',
      'switch',
      'checkbox',
      'git icon',
      'git checkbox',
    ]) {
      testWidgets('central focus decoration $kind $brightness', (tester) async {
        var activated = 0;
        final theme = buildBusyMarkTheme(
          brightness: brightness,
          accentColor: const Color(0xffb34cb4),
        );
        final Widget control = switch (kind) {
          'action' => BusyMarkActionRow(
            title: 'Action',
            onTap: () => activated++,
          ),
          'master' => BusyMarkMasterTile(
            title: const Text('Navigation'),
            onTap: () => activated++,
          ),
          'switch' => BusyMarkSwitchRow(
            title: 'Switch',
            value: false,
            onChanged: (_) => activated++,
          ),
          'checkbox' => BusyMarkCheckboxListTile(
            title: const Text('Checkbox'),
            value: false,
            onChanged: (_) => activated++,
          ),
          'git icon' => git.NativeGitIconAction(
            tooltip: 'Git action',
            icon: YaruIcons.plus,
            onPressed: () => activated++,
          ),
          _ => git.NativeGitCheckbox(
            label: 'Amend',
            value: false,
            tristate: false,
            onChanged: (_) => activated++,
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: YaruTheme(
              data: const YaruThemeData(focusBorders: true),
              child: Theme(
                data: theme,
                child: Scaffold(body: Column(children: [control])),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(borders(tester).where((c) => c.a > 0), isNotEmpty);
        expect(
          borders(tester)
              .where((c) => c.a > 0)
              .every(
                (c) => c == theme.colorScheme.onSurface.withValues(alpha: .65),
              ),
          isTrue,
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        final focus = FocusManager.instance.primaryFocus;
        final box = focus!.context!.findRenderObject() as RenderBox;
        await mouse.down(box.localToGlobal(box.size.center(Offset.zero)));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(activated, 1);
        expect(borders(tester).every((c) => c.a == 0), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(borders(tester).any((c) => c.a > 0), isTrue);
        expect(tester.takeException(), isNull);
      }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
    }
    testWidgets(
      'grouped editing focus remains visible after pointer focus $brightness',
      (tester) async {
        final theme = buildBusyMarkTheme(
          brightness: brightness,
          accentColor: const Color(0xffb34cb4),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: YaruTheme(
              data: const YaruThemeData(focusBorders: true),
              child: Scaffold(body: BusyMarkGroupedTextEntry(label: 'Name')),
            ),
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.down(tester.getCenter(find.byType(TextFormField)));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(borders(tester).any((c) => c.a > 0), isTrue);
        expect(
          borders(
            tester,
          ).where((c) => c.a > 0).every((c) => c != theme.colorScheme.primary),
          isTrue,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
