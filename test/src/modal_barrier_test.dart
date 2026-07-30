import 'dart:io';

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/platform/header_bar_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native dark startup fallback matches the semantic shade', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();
    final match = RegExp(
      r'kDefaultModalBarrierColor\[\] = '
      r'"rgba\(0,0,0,([0-9.]+)\)"',
    ).firstMatch(source);

    expect(match, isNotNull);
    expect(double.parse(match!.group(1)!), 0.25);
    expect(source, contains('modal_barrier_color_for_depth('));
  });

  test('native headerbar becomes inert while a modal route is active', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(
      source,
      contains(
        'if (self->modal_barrier_visible ||\n'
        '      self->header_bar_channel == nullptr || action == nullptr)',
      ),
    );
    expect(
      source,
      contains('close_header_menu_button(self->sidebar_menu_button);'),
    );
    expect(
      source,
      contains('close_header_menu_button(self->adaptive_menu_button);'),
    );
    expect(
      source,
      contains('close_header_menu_button(self->view_mode_button);'),
    );
    expect(source, contains('focus_flutter_view(self);'));
    expect(
      source,
      contains(
        'gtk_event_box_set_visible_window(GTK_EVENT_BOX(self->modal_scrim), '
        'TRUE);',
      ),
    );
    expect(
      source,
      contains(
        'gtk_widget_add_events(self->modal_scrim, GDK_ALL_EVENTS_MASK);',
      ),
    );
    expect(source, contains('busymark-modal-open'));
  });

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
      late Color nativeBarrier;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              flutterBarrier = busyMarkModalBarrierColor(context);
              nativeBarrier = HeaderBarTheme.fromContext(
                context,
              ).modalBarrierColor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final shade = theme.extension<BusyMarkSurfaceColors>()!.shade;
      expect(flutterBarrier, shade);
      expect(nativeBarrier, shade);
      expect(flutterBarrier.a, closeTo(expectedAlpha, 0.0001));
    });
  }
}
