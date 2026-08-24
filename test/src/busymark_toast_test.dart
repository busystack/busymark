import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_toast.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toast appears at the bottom center and dismisses itself', (
    tester,
  ) async {
    await tester.pumpWidget(
      _toastApp(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => BusyMarkToastOverlay.show(
                context,
                message: 'Document saved',
                duration: const Duration(seconds: 1),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('Document saved'), findsOneWidget);
    final messageCenter = tester.getCenter(find.text('Document saved'));
    expect(messageCenter.dx, closeTo(400, 120));
    expect(messageCenter.dy, greaterThan(500));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Document saved'), findsNothing);
  });

  testWidgets('toast action runs and dismisses the toast', (tester) async {
    var actionInvoked = false;
    await tester.pumpWidget(
      _toastApp(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => BusyMarkToastOverlay.show(
                context,
                message: 'PDF exported',
                actionLabel: 'Open',
                onAction: () => actionInvoked = true,
                duration: Duration.zero,
              ),
              child: const Text('Export'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(actionInvoked, isTrue);
    expect(find.text('PDF exported'), findsNothing);
  });

  testWidgets('toasts queue instead of covering each other', (tester) async {
    await tester.pumpWidget(
      _toastApp(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                BusyMarkToastOverlay.show(
                  context,
                  message: 'First message',
                  duration: const Duration(milliseconds: 500),
                );
                BusyMarkToastOverlay.show(
                  context,
                  message: 'Second message',
                  duration: Duration.zero,
                );
              },
              child: const Text('Show both'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show both'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Second message'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);
  });
}

Widget _toastApp(Widget child) {
  return MaterialApp(
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: busyMarkDefaultAccentColor,
    ),
    home: BusyMarkToastOverlay(child: Scaffold(body: child)),
  );
}
