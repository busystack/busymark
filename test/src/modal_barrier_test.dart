import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (brightness, expectedAlpha) in [
    (Brightness.light, 0.07),
    (Brightness.dark, 0.25),
  ]) {
    testWidgets('$brightness modal barriers use the semantic shade role', (
      tester,
    ) async {
      final theme = buildBusyMarkTheme(
        brightness: brightness,
        accentColor: const Color(0xFF3584E4),
      );
      late Color flutterBarrier;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              flutterBarrier = busyMarkModalBarrierColor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final shade = theme.extension<BusyMarkSurfaceColors>()!.shade;
      expect(flutterBarrier, shade);
      expect(flutterBarrier.a, closeTo(expectedAlpha, 0.0001));
    });
  }
}
