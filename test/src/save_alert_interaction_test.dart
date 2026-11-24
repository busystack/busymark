import 'dart:ui';

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_native_controls.dart';
import 'package:busymark/src/app/busymark_toast.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in Brightness.values) {
    testWidgets('alert keyboard traversal and cancellation in ${theme.name}', (
      tester,
    ) async {
      bool? response;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: busyMarkLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: theme,
            accentColor: Colors.green,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.65)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  response = await showBusyMarkModalDialog<bool>(
                    context,
                    builder: (context) => BusyMarkAlert(
                      heading: context.l10n.fileChangedOnDisk,
                      responses: [
                        BusyMarkAlertResponse(
                          label: context.l10n.cancel,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        BusyMarkAlertResponse(
                          label: context.l10n.overwrite,
                          destructive: true,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const BusyMarkAlertResponse(
                          label: 'Disabled',
                          onPressed: null,
                        ),
                      ],
                      children: [Text(context.l10n.fileChangedOnDiskMessage)],
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );

      Future<void> show() async {
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(find.byType(BusyMarkAlert), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await show();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(response, isNull);
      expect(find.byType(BusyMarkAlert), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'BusyMark action');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(response, isFalse);

      await show();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(response, isNull);
      expect(find.byType(BusyMarkAlert), findsNothing);
    });
  }

  testWidgets('toast keyboard action activates once and advances the queue', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusyMarkToastOverlay(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BusyMarkToastOverlay.show(
                    context,
                    message: 'PDF exported',
                    actionLabel: 'Open',
                    onAction: () => actions++,
                    duration: Duration.zero,
                  );
                  BusyMarkToastOverlay.show(
                    context,
                    message: 'Queued notification',
                    duration: Duration.zero,
                  );
                },
                child: const Text('Show notifications'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show notifications'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Open')));
    await tester.pump();
    for (var step = 0; step < 3; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (FocusManager.instance.primaryFocus?.debugLabel == 'BusyMark action') {
        break;
      }
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'BusyMark action');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(actions, 1);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);
    expect(find.text('Queued notification'), findsOneWidget);
    await mouse.removePointer();
  });
}
