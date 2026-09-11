import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_toast.dart';
import 'package:busymark/src/assets/asset_input_service.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_history_panel.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keyboard navigation keeps the selected history entry visible', (
    tester,
  ) async {
    final container = _container();
    final history = container.read(clipboardHistoryControllerProvider.notifier);
    for (var index = 0; index < 24; index++) {
      history.retain(
        BusyMarkClipboardCapture(
          kind: BusyMarkClipboardContentKind.text,
          text: 'entry $index',
          sourceText: 'entry $index',
        ),
      );
    }
    container
        .read(clipboardInsertionRegistryProvider)
        .register(_PanelInsertionTarget());
    await _pumpPanel(tester, container);

    await tester.tap(find.text('entry 23'));
    await tester.pump();
    for (var index = 0; index < 14; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }

    final selected = find.text('entry 9');
    expect(selected, findsOneWidget);
    final selectedRect = tester.getRect(selected);
    final listRect = tester.getRect(
      find.byKey(const ValueKey('clipboard-history-list')),
    );
    expect(selectedRect.top, greaterThanOrEqualTo(listRect.top));
    expect(selectedRect.bottom, lessThanOrEqualTo(listRect.bottom));
  });

  testWidgets('unsupported payload disables paste for the destination', (
    tester,
  ) async {
    final container = _container();
    container
        .read(clipboardHistoryControllerProvider.notifier)
        .retain(
          BusyMarkClipboardCapture(
            kind: BusyMarkClipboardContentKind.image,
            imageBytes: Uint8List.fromList([1, 2, 3]),
            imageMimeType: 'image/png',
            imageDisplayName: 'image.png',
          ),
        );
    container
        .read(clipboardInsertionRegistryProvider)
        .register(_PanelInsertionTarget(supportImages: false));
    await _pumpPanel(tester, container);

    final pasteButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Paste',
    );
    final button = tester.widget<IconButton>(pasteButton);
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'plain-text paste remains enabled when rich paste is unavailable',
    (tester) async {
      final container = _container();
      container
          .read(clipboardHistoryControllerProvider.notifier)
          .retain(
            const BusyMarkClipboardCapture(
              kind: BusyMarkClipboardContentKind.richText,
              text: 'Readable fallback',
              sourceText: '**Readable fallback**',
            ),
          );
      final target = _PanelInsertionTarget(
        normalPasteAvailable: false,
        plainTextPasteAvailable: true,
      );
      container.read(clipboardInsertionRegistryProvider).register(target);
      await _pumpPanel(tester, container);

      final paste = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Paste',
      );
      final pastePlain = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Paste as Plain Text',
      );
      expect(tester.widget<IconButton>(paste).onPressed, isNull);
      expect(tester.widget<IconButton>(pastePlain).onPressed, isNotNull);

      await tester.tap(pastePlain);
      await tester.pump();
      expect(target.pasteCalls, 1);
      expect(target.lastPlainText, isTrue);
    },
  );

  testWidgets('failed insertion reports visible feedback', (tester) async {
    final container = _container();
    container
        .read(clipboardHistoryControllerProvider.notifier)
        .retain(
          const BusyMarkClipboardCapture(
            kind: BusyMarkClipboardContentKind.text,
            text: 'stale item',
            sourceText: 'stale item',
          ),
        );
    final target = _PanelInsertionTarget(
      result: ClipboardPasteResult.staleTarget,
    );
    container.read(clipboardInsertionRegistryProvider).register(target);
    await _pumpPanel(tester, container);

    final pasteButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Paste',
    );
    final button = tester.widget<IconButton>(pasteButton);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(target.pasteCalls, 1);
    expect(
      find.text(AppLocalizationsEn().clipboardUnavailable),
      findsOneWidget,
    );
  });

  testWidgets(
    'current external HTML is transient until panel insertion and remains reusable',
    (tester) async {
      const html =
          '<h1>External</h1><p><b>Bold</b> and '
          '<a href="https://example.com">linked</a></p><ul><li>Item</li></ul>';
      final clipboard = _PanelClipboard(
        const RichClipboardData(
          text: 'External\nBold and linked\nItem',
          html: html,
          generation: 21,
        ),
      );
      final container = _container(clipboard: clipboard);
      final target = _PanelInsertionTarget();
      container.read(clipboardInsertionRegistryProvider).register(target);
      await _pumpPanel(tester, container);
      expect(
        container.read(clipboardHistoryControllerProvider).entries,
        isEmpty,
      );

      final currentPaste = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Paste',
        ),
      );
      expect(currentPaste.onPressed, isNotNull);
      currentPaste.onPressed!.call();
      await tester.pumpAndSettle();
      expect(target.payloads.single.html, html);
      expect(target.lastPlainText, isFalse);
      expect(
        container.read(clipboardHistoryControllerProvider).entries,
        hasLength(1),
      );

      clipboard.value = const RichClipboardData(
        text: 'Replacement clipboard',
        generation: 22,
      );
      await container
          .read(clipboardHistoryControllerProvider.notifier)
          .refreshCurrentClipboard();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'External');
      await tester.pumpAndSettle();
      final retainedPaste = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Paste',
        ),
      );
      expect(retainedPaste.onPressed, isNotNull);
      retainedPaste.onPressed!.call();
      await tester.pumpAndSettle();
      expect(target.payloads, hasLength(2));
      expect(target.payloads.last.html, html);
    },
  );

  testWidgets(
    'failed current-item paste is not retained and plain paste stays explicit',
    (tester) async {
      final clipboard = _PanelClipboard(
        const RichClipboardData(
          text: 'Readable fallback',
          html: '<p><strong>Rich source</strong></p>',
          generation: 23,
        ),
      );
      final container = _container(clipboard: clipboard);
      final failed = _PanelInsertionTarget(
        result: ClipboardPasteResult.staleTarget,
      );
      container.read(clipboardInsertionRegistryProvider).register(failed);
      await _pumpPanel(tester, container);

      final failedPaste = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Paste',
        ),
      );
      expect(failedPaste.onPressed, isNotNull);
      failedPaste.onPressed!.call();
      await tester.pumpAndSettle();
      expect(
        container.read(clipboardHistoryControllerProvider).entries,
        isEmpty,
      );

      final successful = _PanelInsertionTarget();
      container.read(clipboardInsertionRegistryProvider).register(successful);
      await tester.pump();
      final plainPaste = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Paste as Plain Text',
        ),
      );
      expect(plainPaste.onPressed, isNotNull);
      plainPaste.onPressed!.call();
      await tester.pumpAndSettle();
      expect(successful.lastPlainText, isTrue);
      expect(successful.payloads.single.text, 'Readable fallback');
      expect(
        container.read(clipboardHistoryControllerProvider).entries,
        hasLength(1),
      );
    },
  );
}

ProviderContainer _container({RichClipboardService? clipboard}) {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      richClipboardServiceProvider.overrideWithValue(
        clipboard ?? _EmptyClipboard(),
      ),
      clipboardAssetInputServiceProvider.overrideWithValue(_EmptyAssetInput()),
    ],
  );
  addTearDown(container.dispose);
  container.read(clipboardHistoryControllerProvider.notifier);
  return container;
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(600, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => BusyMarkToastOverlay(child: child!),
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: Colors.blue,
        ),
        home: const Scaffold(body: ClipboardHistoryPanel()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PanelInsertionTarget
    implements
        BusyMarkClipboardInsertionTarget,
        BusyMarkClipboardInsertionCapabilities {
  _PanelInsertionTarget({
    this.supportImages = true,
    this.normalPasteAvailable,
    this.plainTextPasteAvailable,
    this.result = ClipboardPasteResult.inserted,
  });

  final bool supportImages;
  final bool? normalPasteAvailable;
  final bool? plainTextPasteAvailable;
  final ClipboardPasteResult result;
  int pasteCalls = 0;
  bool? lastPlainText;
  final payloads = <BusyMarkClipboardPayload>[];

  @override
  String get documentId => 'panel-target';

  @override
  String get documentName => 'Target.md';

  @override
  String? get documentPath => '/workspace/Target.md';

  @override
  bool get editable => true;

  @override
  bool canPaste(BusyMarkClipboardPayload payload, {required bool plainText}) {
    final configured = plainText
        ? plainTextPasteAvailable
        : normalPasteAvailable;
    return configured ??
        (supportImages || payload.kind != BusyMarkClipboardContentKind.image);
  }

  @override
  Future<ClipboardPasteResult> paste(
    BusyMarkClipboardPayload payload, {
    required bool plainText,
  }) async {
    pasteCalls++;
    lastPlainText = plainText;
    payloads.add(payload);
    return result;
  }

  @override
  void requestEditorFocus() {}
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async => value = json;
}

class _EmptyClipboard extends RichClipboardService {
  _EmptyClipboard()
    : super(channel: const MethodChannel('busymark.test/panel-clipboard'));

  @override
  Future<RichClipboardData> read() async => const RichClipboardData();
}

class _PanelClipboard extends RichClipboardService {
  _PanelClipboard(this.value)
    : super(
        channel: const MethodChannel('busymark.test/current-panel-clipboard'),
      );

  RichClipboardData value;

  @override
  Future<RichClipboardData> read() async => value;
}

class _EmptyAssetInput extends AssetInputService {
  _EmptyAssetInput()
    : super(channel: const MethodChannel('busymark.test/panel-assets'));

  @override
  Future<List<String>> readClipboardImageFiles() async => const [];

  @override
  Future<Uint8List?> readClipboardImagePng() async => null;
}
