import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  testWidgets('search fallback uses the normal Yaru-themed entry geometry', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changedQuery;
    String? submittedQuery;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: Colors.orange,
        ),
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

    expect(find.byType(YaruSearchField), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.border, isNull);
    expect(field.decoration?.enabledBorder, isNull);
    expect(field.decoration?.focusedBorder, isNull);
    expect(field.decoration?.filled, isTrue);
    final resolvedDecoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(resolvedDecoration.enabledBorder, isA<OutlineInputBorder>());
    expect(resolvedDecoration.focusedBorder, isA<OutlineInputBorder>());
    expect(find.byIcon(YaruIcons.search), findsOneWidget);
    expect(find.text('Search documents'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'native');
    await tester.pump();
    expect(changedQuery, 'native');

    expect(find.byType(IconButton), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changedQuery, isEmpty);

    await tester.enterText(find.byType(EditableText), 'native');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submittedQuery, 'native');
  });

  testWidgets('focus request targets the themed text entry', (tester) async {
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

  testWidgets('Escape clears the query and closes the owner', (tester) async {
    final controller = TextEditingController(text: 'query');
    addTearDown(controller.dispose);
    var escapeCount = 0;
    String? changedQuery;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusyMarkSearchField(
            controller: controller,
            autofocus: true,
            onChanged: (value) => changedQuery = value,
            onEscape: () => escapeCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changedQuery, isEmpty);
    expect(escapeCount, 1);
  });
}
