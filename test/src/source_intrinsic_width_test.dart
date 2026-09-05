import 'package:busymark/src/editor/source/source_controller.dart';
import 'package:busymark/src/editor/source/source_intrinsic_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('intrinsic width remeasures only edited source lines', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    final controller = BusyMarkSourceController(
      text: 'short\nlongest source line\ntail',
    );
    final cache = SourceIntrinsicWidthCache();
    const style = TextStyle(fontFamily: 'monospace', fontSize: 14);

    final initialWidth = cache.resolve(
      context,
      controller: controller,
      textStyle: style,
      strutStyle: null,
    );
    expect(cache.debugLineMeasureCount, 3);

    controller.value = const TextEditingValue(
      text: 'short\nlongest source line extended\ntail',
      selection: TextSelection.collapsed(offset: 39),
    );
    final editedWidth = cache.resolve(
      context,
      controller: controller,
      textStyle: style,
      strutStyle: null,
    );

    expect(editedWidth, greaterThan(initialWidth));
    expect(cache.debugLineMeasureCount, 4);

    cache.resolve(
      context,
      controller: controller,
      textStyle: style,
      strutStyle: null,
    );
    expect(cache.debugLineMeasureCount, 4);
    controller.dispose();
  });

  testWidgets('large source width uses a bounded estimate', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    final controller = BusyMarkSourceController(
      text: 'x'.padRight(300001, 'x'),
    );
    final cache = SourceIntrinsicWidthCache();

    final width = cache.resolve(
      context,
      controller: controller,
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      strutStyle: null,
    );

    expect(width, greaterThan(1));
    expect(cache.debugUsingLargeFileEstimate, isTrue);
    expect(cache.debugLineMeasureCount, 0);
    controller.dispose();
  });
}
