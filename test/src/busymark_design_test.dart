import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/editor/document_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Split Preview stays fluid without copying Source-only chrome', () {
    const layout = BusyMarkDocumentLayoutSpec.splitPreview;

    expect(
      layout.minimumInsets,
      const EdgeInsets.fromLTRB(
        BusyMarkSpacing.xl,
        BusyMarkSourceEditorMetrics.paddingTop,
        BusyMarkSpacing.xl,
        BusyMarkSizes.iconButton,
      ),
    );
    expect(
      layout.minimumInsets.left,
      lessThan(BusyMarkSizes.sourceGutterWidth),
    );
    expect(layout.maxContentWidth, isNull);
  });

  testWidgets(
    'document frame centers wide content and honors physical safe edges',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Future<Rect> contentRect({
        required double width,
        required TextDirection textDirection,
        required BusyMarkDocumentLayoutSpec layout,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: textDirection,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 100,
                  child: BusyMarkDocumentContentFrame(
                    layout: layout,
                    contentKey: const ValueKey('document-content'),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        return tester.getRect(find.byKey(const ValueKey('document-content')));
      }

      for (final textDirection in TextDirection.values) {
        final wideRect = await contentRect(
          width: 1000,
          textDirection: textDirection,
          layout: BusyMarkDocumentLayoutSpec.standalone,
        );
        expect(wideRect.left, 120);
        expect(wideRect.width, BusyMarkSizes.documentContentWidth);
        expect(wideRect.right, 880);

        final leftToolbarLayout = BusyMarkDocumentLayoutSpec.standalone
            .withEditingToolbar(
              placement: EditorToolbarPlacement.topLeft,
              direction: EditorToolbarDirection.vertical,
            );
        final narrowRect = await contentRect(
          width: 840,
          textDirection: textDirection,
          layout: leftToolbarLayout,
        );
        expect(narrowRect.left, BusyMarkSizes.wysiwygToolbarClearance);
        expect(narrowRect.right, 840 - BusyMarkSpacing.xl);

        final splitPreviewRect = await contentRect(
          width: 500,
          textDirection: textDirection,
          layout: BusyMarkDocumentLayoutSpec.splitPreview,
        );
        expect(splitPreviewRect.left, BusyMarkSpacing.xl);
        expect(splitPreviewRect.right, 500 - BusyMarkSpacing.xl);
      }
    },
  );

  test('toolbar clearance is applied only to the toolbar edge', () {
    const base = BusyMarkDocumentLayoutSpec.standalone;

    final top = base.withEditingToolbar(
      placement: EditorToolbarPlacement.topRight,
      direction: EditorToolbarDirection.horizontal,
    );
    expect(top.minimumInsets.top, BusyMarkSizes.wysiwygToolbarClearance);
    expect(top.minimumInsets.bottom, base.minimumInsets.bottom);

    final bottom = base.withEditingToolbar(
      placement: EditorToolbarPlacement.bottomLeft,
      direction: EditorToolbarDirection.horizontal,
    );
    expect(bottom.minimumInsets.top, base.minimumInsets.top);
    expect(bottom.minimumInsets.bottom, BusyMarkSizes.wysiwygToolbarClearance);

    final right = base.withEditingToolbar(
      placement: EditorToolbarPlacement.bottomRight,
      direction: EditorToolbarDirection.vertical,
    );
    expect(right.minimumInsets.left, base.minimumInsets.left);
    expect(right.minimumInsets.right, BusyMarkSizes.wysiwygToolbarClearance);
  });

  test('sidebar header and list compose the shared vertical gap', () {
    final header = BusyMarkInsets.sidebarHeader.resolve(TextDirection.ltr);
    final tocLtr = BusyMarkInsets.tocHeader.resolve(TextDirection.ltr);
    final tocRtl = BusyMarkInsets.tocHeader.resolve(TextDirection.rtl);

    expect(header.bottom + BusyMarkInsets.sidebarList.top, BusyMarkSpacing.sm);
    expect(tocLtr.top, 0);
    expect(tocLtr.left, BusyMarkSpacing.sm);
    expect(tocLtr.right, 0);
    expect(tocRtl.left, 0);
    expect(tocRtl.right, BusyMarkSpacing.sm);
  });

  testWidgets('elevated header controls use the shared surface shadow', (
    tester,
  ) async {
    late BuildContext themedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            themedContext = context;
            return Scaffold(
              body: Row(
                children: [
                  BusyMarkHeaderIconButton(
                    key: const ValueKey('elevated-icon-button'),
                    tooltip: 'Elevated action',
                    icon: BusyMarkGlyphs.edit,
                    elevated: true,
                    borderRadius: BusyMarkRadius.lg,
                    onPressed: () {},
                  ),
                  BusyMarkHeaderIconButton(
                    key: const ValueKey('flat-icon-button'),
                    tooltip: 'Flat action',
                    icon: BusyMarkGlyphs.edit,
                    onPressed: () {},
                  ),
                  BusyMarkHeaderPopupMenuButton<String>(
                    key: const ValueKey('elevated-popup-button'),
                    tooltip: 'Elevated menu',
                    icon: BusyMarkGlyphs.menuVertical,
                    elevated: true,
                    itemBuilder: (_) => const [
                      BusyMarkPopupMenuItem(value: 'action', label: 'Action'),
                    ],
                    onSelected: (_) {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    List<BoxDecoration> shadowDecorations(Finder control) {
      return tester
          .widgetList<DecoratedBox>(
            find.descendant(of: control, matching: find.byType(DecoratedBox)),
          )
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.boxShadow?.isNotEmpty ?? false)
          .toList();
    }

    final expectedShadows = BusyMarkShadow.surfaceShadowsFor(themedContext);
    final iconDecorations = shadowDecorations(
      find.byKey(const ValueKey('elevated-icon-button')),
    );
    final popupDecorations = shadowDecorations(
      find.byKey(const ValueKey('elevated-popup-button')),
    );

    expect(iconDecorations, hasLength(1));
    expect(iconDecorations.single.boxShadow, expectedShadows);
    expect(
      iconDecorations.single.borderRadius,
      BorderRadius.circular(BusyMarkRadius.lg),
    );
    expect(popupDecorations, hasLength(1));
    expect(popupDecorations.single.boxShadow, expectedShadows);
    expect(
      shadowDecorations(find.byKey(const ValueKey('flat-icon-button'))),
      isEmpty,
    );
  });

  testWidgets(
    'popup menu rows show shortcuts without redundant hover tooltips',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BusyMarkHeaderIconButton(
                  tooltip: 'Main menu',
                  icon: BusyMarkGlyphs.menuVertical,
                  onPressed: () {},
                ),
                const BusyMarkPopupMenuItem<String>(
                  value: 'editor',
                  label: 'Editor',
                  shortcut: 'Ctrl+1',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Ctrl+1'), findsOneWidget);
      expect(find.byTooltip('Editor (Ctrl+1)'), findsNothing);
      expect(find.byTooltip('Main menu'), findsOneWidget);
    },
  );
}
