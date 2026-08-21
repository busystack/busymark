import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/math/math_widget.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'inline math applies MathJax baseline and surrounding text metrics',
    (tester) async {
      final host = _MathWidgetHost(width: 24, height: 18, depth: 5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [webRenderHostProvider.overrideWithValue(host)],
          child: const _InlineThemeHarness(),
        ),
      );
      await _pumpRenderedMath(tester);

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel(r'x^2'), findsOneWidget);
      expect(tester.widget<Baseline>(find.byType(Baseline)).baseline, 13);
      expect(host.calls, 1);
      expect(host.lastExpression?['em'], 20);
      expect(host.lastExpression?['ex'], 10);

      await tester.tap(find.byKey(const ValueKey('toggle-math-theme')));
      await tester.pump();
      expect(
        host.calls,
        1,
        reason: 'currentColor SVG must be reusable when the UI theme changes',
      );
    },
  );

  testWidgets('wide display math scrolls horizontally without clipping', (
    tester,
  ) async {
    final host = _MathWidgetHost(width: 900, height: 40, depth: 4);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [webRenderHostProvider.overrideWithValue(host)],
        child: _localizedApp(
          const SizedBox(
            width: 200,
            child: BusyMarkDisplayMath(
              expression: r'\sum_{i=1}^{100} a_i',
              expressionId: 'wide',
              editRevision: 1,
            ),
          ),
        ),
      ),
    );
    await _pumpRenderedMath(tester);

    final scroller = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroller.scrollDirection, Axis.horizontal);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 900,
      ),
      findsOneWidget,
    );
    expect(host.lastExpression?['containerWidth'], 208);
  });

  testWidgets('failed formulas retain source and a localized explanation', (
    tester,
  ) async {
    final host = _MathWidgetHost(fail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [webRenderHostProvider.overrideWithValue(host)],
        child: _localizedApp(
          const BusyMarkDisplayMath(
            expression: r'\frac{',
            expressionId: 'invalid',
            editRevision: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(r'\frac{'), findsOneWidget);
    expect(
      find.byTooltip('The mathematical expression could not be rendered.'),
      findsOneWidget,
    );
    expect(find.byType(SvgPicture), findsNothing);
  });
}

Widget _localizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _InlineThemeHarness extends StatefulWidget {
  const _InlineThemeHarness();

  @override
  State<_InlineThemeHarness> createState() => _InlineThemeHarnessState();
}

class _InlineThemeHarnessState extends State<_InlineThemeHarness> {
  var dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            IconButton(
              key: const ValueKey('toggle-math-theme'),
              onPressed: () => setState(() => dark = !dark),
              icon: const Icon(BusyMarkGlyphs.appearance),
            ),
            const BusyMarkInlineMath(
              expression: r'x^2',
              expressionId: 'inline',
              editRevision: 1,
              textStyle: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpRenderedMath(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (find.byType(SvgPicture).evaluate().isNotEmpty) return;
  }
}

class _MathWidgetHost implements WebRenderHost {
  _MathWidgetHost({
    this.width = 20,
    this.height = 14,
    this.depth = 2,
    this.fail = false,
  });

  final double width;
  final double height;
  final double depth;
  final bool fail;
  int calls = 0;
  Map<String, Object?>? lastExpression;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    calls++;
    lastExpression = expressions.single;
    cancellationToken.throwIfCancelled();
    return {
      'results': [
        if (fail)
          {
            'id': expressions.single['id'],
            'error': {'code': 'math.invalidTex', 'message': 'Invalid TeX'},
          }
        else
          {
            'id': expressions.single['id'],
            'svg': '''<svg xmlns="http://www.w3.org/2000/svg"
              viewBox="0 -10 20 14" style="vertical-align:-0.25ex">
              <defs><path id="glyph" d="M0 0L10 10"/></defs>
              <use href="#glyph" fill="currentColor"/>
            </svg>''',
            'width': width,
            'height': height,
            'depth': depth,
          },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
