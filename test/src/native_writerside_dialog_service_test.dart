import 'package:busymark/src/platform/native_writerside_dialog_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Duplicate Topic is serialized to the native dialog host', () async {
    const channel = MethodChannel('busymark/test/native-writerside-duplicate');
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (value) async {
          call = value;
          return 'install-copy';
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final result = await const NativeWritersideDialogService(channel: channel)
        .showDuplicateTopic(
          title: 'Duplicate Topic',
          fileNameLabel: 'Topic Filename:',
          initialValue: 'install',
          cancelLabel: 'Cancel',
          okLabel: 'OK',
          requiredError: 'required',
          invalidCharactersError: 'invalid',
          duplicateError: 'duplicate',
          existingTopicIds: const {'install', 'start'},
          textDirection: TextDirection.ltr,
        );

    expect(result.available, isTrue);
    expect(result.value, 'install-copy');
    expect(call?.method, 'showDuplicateTopic');
    expect(call?.arguments, {
      'title': 'Duplicate Topic',
      'fileNameLabel': 'Topic Filename:',
      'initialValue': 'install',
      'cancelLabel': 'Cancel',
      'okLabel': 'OK',
      'requiredError': 'required',
      'invalidCharactersError': 'invalid',
      'duplicateError': 'duplicate',
      'existingTopicIds': ['install', 'start'],
      'textDirection': 'ltr',
    });
  });

  test('Edit Title returns all native field values', () async {
    const channel = MethodChannel('busymark/test/native-writerside-title');
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (value) async {
          call = value;
          return <String, Object>{
            'title': 'Published title',
            'instanceTitle': 'Instance title',
            'tocTitle': 'TOC title',
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final result = await const NativeWritersideDialogService(channel: channel)
        .showEditTitle(
          dialogTitle: 'Edit Title',
          topicTitleLabel: 'Topic title:',
          advancedLabel: 'Advanced Settings',
          instanceTitleLabel: "Title for 'docs':",
          tocTitleLabel: 'TOC-only title:',
          instanceExplanation: 'Instance explanation',
          tocExplanation: 'TOC explanation',
          documentationLabel: 'here',
          documentationUrl: 'https://example.test/titles',
          initialTitle: 'Original',
          initialInstanceTitle: '',
          initialTocTitle: '',
          cancelLabel: 'Cancel',
          okLabel: 'OK',
          textDirection: TextDirection.rtl,
        );

    expect(result.available, isTrue);
    expect(result.value?.title, 'Published title');
    expect(result.value?.instanceTitle, 'Instance title');
    expect(result.value?.tocTitle, 'TOC title');
    expect(call?.method, 'showEditTitle');
    expect((call?.arguments as Map<Object?, Object?>)['textDirection'], 'rtl');
    expect(
      (call?.arguments as Map<Object?, Object?>)['initialTitle'],
      'Original',
    );
  });

  test(
    'native cancellation remains distinct from an unavailable host',
    () async {
      const cancelChannel = MethodChannel('busymark/test/native-dialog-cancel');
      const missingChannel = MethodChannel(
        'busymark/test/native-dialog-missing',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(cancelChannel, (_) async => null);
      messenger.setMockMethodCallHandler(
        missingChannel,
        (_) async => throw MissingPluginException(),
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(cancelChannel, null);
        messenger.setMockMethodCallHandler(missingChannel, null);
      });

      Future<NativeWritersideDialogResult<String>> invoke(
        MethodChannel channel,
      ) {
        return NativeWritersideDialogService(
          channel: channel,
        ).showDuplicateTopic(
          title: 'Duplicate Topic',
          fileNameLabel: 'Topic Filename:',
          initialValue: 'topic',
          cancelLabel: 'Cancel',
          okLabel: 'OK',
          requiredError: 'required',
          invalidCharactersError: 'invalid',
          duplicateError: 'duplicate',
          existingTopicIds: const [],
        );
      }

      final cancelled = await invoke(cancelChannel);
      final unavailable = await invoke(missingChannel);
      expect(cancelled.available, isTrue);
      expect(cancelled.value, isNull);
      expect(unavailable.available, isFalse);
      expect(unavailable.value, isNull);
    },
  );
}
