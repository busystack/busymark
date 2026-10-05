import 'package:busymark/src/app/busymark_motion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'view changes fade one live editor while ordinary data changes do not',
    (tester) async {
      final counts = <String, int>{};
      var view = 'editor';
      var revision = 0;
      var disabled = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disabled),
                child: Scaffold(
                  body: BusyMarkSemanticFade(
                    transitionKey: view,
                    child: Column(
                      children: [
                        Text('$revision'),
                        _TrackedPage(
                          key: const ValueKey('editor'),
                          name: 'Editor',
                          counts: counts,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Editor')),
        'draft',
      );
      final editor = tester.state(find.byKey(const ValueKey('editor')));
      Finder fade() => find
          .descendant(
            of: find.byType(BusyMarkSemanticFade),
            matching: find.byType(FadeTransition),
          )
          .first;
      update(() => revision++);
      await tester.pump();
      expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);

      update(() => view = 'source');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.widget<FadeTransition>(fade()).opacity.value,
        inExclusiveRange(0, 1),
      );
      expect(tester.state(find.byKey(const ValueKey('editor'))), same(editor));
      expect(find.text('draft'), findsOneWidget);
      expect(counts, {'Editor': 1});

      update(() => disabled = true);
      await tester.pump();
      expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);
      update(() => view = 'preview');
      await tester.pump();
      expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);
    },
  );

  testWidgets('retained destinations settle immediately under reduced motion', (
    tester,
  ) async {
    var destination = 'Files';
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: BusyMarkKeyedCrossfade(
                transitionKey: destination,
                child: Text(destination),
              ),
            );
          },
        ),
      ),
    );
    update(() => destination = 'Search');
    await tester.pump();
    expect(find.text('Files'), findsNothing);
    expect(find.text('Search'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Search'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 1);
  });
  testWidgets('retained crossfade keeps two live pages and hides outgoing UI', (
    tester,
  ) async {
    final counts = <String, int>{};
    Widget build(int index) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 200,
          child: BusyMarkRetainedCrossfade(
            index: index,
            children: [
              _TrackedPage(
                key: const ValueKey('page-a'),
                name: 'A',
                counts: counts,
              ),
              _TrackedPage(
                key: const ValueKey('page-b'),
                name: 'B',
                counts: counts,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(0));
    expect(counts, {'A': 1, 'B': 1});
    await tester.enterText(find.byKey(const ValueKey('field-A')), 'draft');

    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('draft'), findsOneWidget);
    final opacityBeforeReversal = _pageOpacity(tester, 'page-a');
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('field-A')),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );

    await tester.pumpWidget(build(0));
    await tester.pump();
    expect(
      _pageOpacity(tester, 'page-a'),
      closeTo(opacityBeforeReversal, .001),
    );
    await tester.pumpAndSettle();
    expect(find.text('draft'), findsOneWidget);
    expect(counts, {'A': 1, 'B': 1});
  });

  testWidgets('keyed crossfade retains three semantic destinations', (
    tester,
  ) async {
    final counts = <String, int>{};
    var destination = 'Files';
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox(
                width: 300,
                height: 200,
                child: BusyMarkKeyedCrossfade(
                  transitionKey: destination,
                  child: _TrackedPage(
                    key: ValueKey('page-$destination'),
                    name: destination,
                    counts: counts,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-Files')),
      'retained sidebar state',
    );
    final weekState = tester.state(
      find.byKey(const ValueKey('page-Files'), skipOffstage: false),
    );

    update(() => destination = 'Search');
    await tester.pump();
    expect(counts, {'Files': 1, 'Search': 1});
    expect(
      tester.state(
        find.byKey(const ValueKey('page-Files'), skipOffstage: false),
      ),
      same(weekState),
    );
    await tester.pump(const Duration(milliseconds: 30));
    update(() => destination = 'History');
    await tester.pump();
    expect(counts, {'Files': 1, 'Search': 1, 'History': 1});
    expect(
      tester.state(
        find.byKey(const ValueKey('page-Files'), skipOffstage: false),
      ),
      same(weekState),
    );
    await tester.pump(const Duration(milliseconds: 30));
    update(() => destination = 'Files');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('field-Files'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      tester.state(find.byKey(const ValueKey('page-Files'))),
      same(weekState),
    );
    expect(counts, {'Files': 1, 'Search': 1, 'History': 1});
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('field-Files')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'retained sidebar state',
    );
  });
}

double _pageOpacity(WidgetTester tester, String key) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

class _TrackedPage extends StatefulWidget {
  const _TrackedPage({super.key, required this.name, required this.counts});

  final String name;
  final Map<String, int> counts;

  @override
  State<_TrackedPage> createState() => _TrackedPageState();
}

class _TrackedPageState extends State<_TrackedPage> {
  @override
  void initState() {
    super.initState();
    widget.counts.update(widget.name, (value) => value + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: ValueKey('field-${widget.name}'),
    decoration: InputDecoration(labelText: widget.name),
  );
}
