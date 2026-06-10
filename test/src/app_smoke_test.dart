import 'dart:async';

import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late _FallbackHeaderBarService headerBarService;

  setUp(() {
    headerBarService = _FallbackHeaderBarService();
  });

  testWidgets('app boots to BusyMark welcome screen without login UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BusyMark'), findsWidgets);
    expect(find.text('Open Markdown File'), findsOneWidget);
    expect(find.text('File or folder path'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('settings screen opens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('BusyMark Settings'), findsOneWidget);
    expect(find.text('Validate on edit'), findsOneWidget);
  });
}

class _FallbackHeaderBarService extends LinuxHeaderBarService {
  _FallbackHeaderBarService()
    : super(channel: const MethodChannel('test.busymark/headerbar'));

  @override
  bool get isAvailable => false;

  @override
  bool get usesNativeHeaderBar => false;

  @override
  Stream<HeaderBarAction> get actions => const Stream.empty();
}
