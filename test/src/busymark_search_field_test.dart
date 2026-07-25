import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  testWidgets('search fallback delegates behavior and geometry to Yaru', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changedQuery;
    String? submittedQuery;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusyMarkSearchField(
            controller: controller,
            hintText: 'Search documents',
            onChanged: (value) => changedQuery = value,
            onSubmitted: (value) => submittedQuery = value,
          ),
        ),
      ),
    );

    expect(find.byType(YaruSearchField), findsOneWidget);
    expect(find.text('Search documents'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'native');
    expect(changedQuery, 'native');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submittedQuery, 'native');
  });

  testWidgets('focus request targets the Yaru-owned text entry', (
    tester,
  ) async {
    var focusRequest = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) {
            setState = update;
            return Scaffold(
              body: BusyMarkSearchField(focusRequest: focusRequest),
            );
          },
        ),
      ),
    );

    setState(() => focusRequest += 1);
    await tester.pump();
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('Escape keeps Yaru clear behavior and closes the owner', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'query');
    addTearDown(controller.dispose);
    var escapeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusyMarkSearchField(
            controller: controller,
            autofocus: true,
            onClear: controller.clear,
            onEscape: () => escapeCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(escapeCount, 1);
  });
}
