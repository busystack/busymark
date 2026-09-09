import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/assets/asset_input_service.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BusyMarkClipboardCapture text(String value) => BusyMarkClipboardCapture(
    kind: BusyMarkClipboardContentKind.text,
    text: value,
    sourceText: value,
  );

  ProviderContainer container({
    ClipboardHistoryPolicy policy = const ClipboardHistoryPolicy(),
    RichClipboardData current = const RichClipboardData(),
  }) {
    final result = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        clipboardHistoryPolicyProvider.overrideWithValue(policy),
        richClipboardServiceProvider.overrideWithValue(
          _FakeClipboardService(current),
        ),
        clipboardAssetInputServiceProvider.overrideWithValue(_FakeAssetInput()),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test(
    'retains newest first, deduplicates, removes, clears, and evicts by count',
    () async {
      final scope = container(
        policy: const ClipboardHistoryPolicy(
          maximumEntries: 2,
          maximumBytes: 1024,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final controller = scope.read(
        clipboardHistoryControllerProvider.notifier,
      );

      expect(controller.retain(text('one')), ClipboardRetentionResult.retained);
      expect(controller.retain(text('two')), ClipboardRetentionResult.retained);
      expect(
        controller.retain(text('one')),
        ClipboardRetentionResult.deduplicated,
      );
      expect(
        scope
            .read(clipboardHistoryControllerProvider)
            .entries
            .map((e) => e.text),
        ['one', 'two'],
      );
      controller.retain(text('three'));
      var entries = scope.read(clipboardHistoryControllerProvider).entries;
      expect(entries.map((e) => e.text), ['three', 'one']);
      controller.remove(entries.first.id);
      expect(
        scope.read(clipboardHistoryControllerProvider).entries.single.text,
        'one',
      );
      controller.clear();
      expect(scope.read(clipboardHistoryControllerProvider).entries, isEmpty);
    },
  );

  test(
    'accounts byte budget and rejects an oversized item without truncation',
    () async {
      final scope = container(
        policy: const ClipboardHistoryPolicy(
          maximumEntries: 10,
          maximumBytes: 20,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final controller = scope.read(
        clipboardHistoryControllerProvider.notifier,
      );
      controller.retain(text('a'));

      expect(
        controller.retain(text('this payload is much too large')),
        ClipboardRetentionResult.oversized,
      );
      expect(
        scope.read(clipboardHistoryControllerProvider).entries.single.text,
        'a',
      );
    },
  );

  test(
    'collection off leaves existing entries and blocks new retention',
    () async {
      final scope = container();
      await Future<void>.delayed(Duration.zero);
      final controller = scope.read(
        clipboardHistoryControllerProvider.notifier,
      );
      controller.retain(text('retained'));
      await scope
          .read(appSettingsControllerProvider.notifier)
          .setClipboardHistoryEnabled(false);

      expect(
        controller.retain(text('blocked')),
        ClipboardRetentionResult.disabled,
      );
      expect(
        scope.read(clipboardHistoryControllerProvider).entries.single.text,
        'retained',
      );
    },
  );

  test(
    'current external clipboard remains transient until explicitly retained',
    () async {
      final scope = container(
        current: const RichClipboardData(text: 'outside', generation: 9),
      );
      await Future<void>.delayed(Duration.zero);
      final controller = scope.read(
        clipboardHistoryControllerProvider.notifier,
      );

      await controller.refreshCurrentClipboard();
      var state = scope.read(clipboardHistoryControllerProvider);
      expect(state.currentClipboard!.text, 'outside');
      expect(state.currentClipboard!.external, isTrue);
      expect(state.entries, isEmpty);
      controller.retainCurrentAfterPaste(state.currentClipboard!);
      state = scope.read(clipboardHistoryControllerProvider);
      expect(state.entries.single.text, 'outside');
    },
  );

  test('equal visible text with different structure stays distinct', () async {
    final scope = container();
    await Future<void>.delayed(Duration.zero);
    final controller = scope.read(clipboardHistoryControllerProvider.notifier);
    controller.retain(
      const BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.richText,
        text: 'link',
        sourceText: '[link](first.md)',
        richFragment: '{"href":"first.md"}',
      ),
    );
    controller.retain(
      const BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.richText,
        text: 'link',
        sourceText: '[link](second.md)',
        richFragment: '{"href":"second.md"}',
      ),
    );
    expect(
      scope.read(clipboardHistoryControllerProvider).entries,
      hasLength(2),
    );
  });

  test('equal relative markup from different origins stays distinct', () async {
    final scope = container();
    await Future<void>.delayed(Duration.zero);
    final controller = scope.read(clipboardHistoryControllerProvider.notifier);
    for (final path in ['/first/topic.md', '/second/topic.md']) {
      controller.retain(
        BusyMarkClipboardCapture(
          kind: BusyMarkClipboardContentKind.richText,
          text: 'diagram',
          sourceText: '![diagram](images/diagram.png)',
          richFragment: '{"image":"images/diagram.png"}',
          origin: BusyMarkClipboardOrigin(
            documentId: path,
            documentName: 'topic.md',
            documentPath: path,
          ),
        ),
      );
    }

    expect(
      scope.read(clipboardHistoryControllerProvider).entries,
      hasLength(2),
    );
  });

  test('retains whitespace-only text and owns image bytes immutably', () async {
    final scope = container();
    await Future<void>.delayed(Duration.zero);
    final controller = scope.read(clipboardHistoryControllerProvider.notifier);
    controller.retain(text(' \n\t'));
    final source = Uint8List.fromList([1, 2, 3]);
    final embedded = Uint8List.fromList([4, 5, 6]);
    controller.retain(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.image,
        imageBytes: source,
        imageMimeType: 'image/png',
        imageDisplayName: 'diagram.png',
        mediaBytes: {'images/embedded.png': embedded},
      ),
    );
    source[0] = 99;
    embedded[0] = 99;

    final entries = scope.read(clipboardHistoryControllerProvider).entries;
    expect(entries.last.text, ' \n\t');
    expect(entries.first.imageBytes, [1, 2, 3]);
    expect(entries.first.mediaBytes['images/embedded.png'], [4, 5, 6]);
  });

  test('a new provider session starts with no retained history', () async {
    final first = container();
    await Future<void>.delayed(Duration.zero);
    first.read(clipboardHistoryControllerProvider.notifier).retain(text('old'));
    final second = container();
    await Future<void>.delayed(Duration.zero);
    expect(second.read(clipboardHistoryControllerProvider).entries, isEmpty);
  });

  test(
    'insertion registry follows latest target and never retains disposed targets',
    () async {
      final registry = BusyMarkClipboardInsertionRegistry();
      final first = _InsertionTarget('first');
      final second = _InsertionTarget('second');
      final payload = BusyMarkClipboardPayload(
        id: 'payload-id',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.text,
        text: 'value',
      );
      registry.register(first);
      registry.register(second);
      registry.unregister(first);

      expect(await registry.paste(payload), ClipboardPasteResult.inserted);
      expect(first.pastes, 0);
      expect(second.pastes, 1);
      expect(second.focusRequests, 1);
      registry.unregister(second);
      expect(await registry.paste(payload), ClipboardPasteResult.unavailable);
    },
  );

  test(
    'unknown token cannot recover rich data through equal plain text',
    () async {
      const channel = MethodChannel('busymark.test/rich-token');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var clipboard = <String, dynamic>{};
      var token = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') {
          clipboard = Map<String, dynamic>.from(call.arguments as Map);
          clipboard['generation'] = ++token;
          return true;
        }
        return clipboard;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final service = RichClipboardService(
        channel: channel,
        createToken: () => 'known-token',
      );
      await service.write(
        const RichClipboardData(
          text: 'same',
          sourceText: '**same**',
          richFragment: '{"strong":true}',
        ),
      );
      expect((await service.read()).richFragment, isNotNull);
      clipboard = {
        'text': 'same',
        'token': 'unknown-token',
        'generation': ++token,
      };

      final external = await service.read();
      expect(external.text, 'same');
      expect(external.richFragment, isNull);
      expect(external.sessionOwned, isFalse);
    },
  );
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async => value = json;
}

class _FakeClipboardService extends RichClipboardService {
  _FakeClipboardService(this.value)
    : super(channel: const MethodChannel('busymark.test/fake-history'));

  RichClipboardData value;

  @override
  Future<RichClipboardData> read() async => value;
}

class _FakeAssetInput extends AssetInputService {
  _FakeAssetInput()
    : super(channel: const MethodChannel('busymark.test/fake-asset-input'));

  @override
  Future<Uint8List?> readClipboardImagePng() async => null;

  @override
  Future<List<String>> readClipboardImageFiles() async => const [];
}

class _InsertionTarget implements BusyMarkClipboardInsertionTarget {
  _InsertionTarget(this.documentId);

  int pastes = 0;
  int focusRequests = 0;

  @override
  final String documentId;

  @override
  String get documentName => documentId;

  @override
  String? get documentPath => '/$documentId.md';

  @override
  bool get editable => true;

  @override
  Future<ClipboardPasteResult> paste(
    BusyMarkClipboardPayload payload, {
    required bool plainText,
  }) async {
    pastes++;
    return ClipboardPasteResult.inserted;
  }

  @override
  void requestEditorFocus() => focusRequests++;
}
