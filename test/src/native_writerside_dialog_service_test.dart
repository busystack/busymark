import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'dart:async';
import 'package:busymark/l10n/generated/app_localizations_ar.dart';
import 'package:busymark/src/workspace/presentation/writerside_topic_creation_form.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import '../support/native_writerside_dialog_host.dart';
import 'package:busymark/src/platform/native_writerside_dialog_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final format in WritersideTopicFormat.values) {
    test(
      'New Topic $format preserves filename, slug, case and Unicode rules',
      () {
        final form = WritersideTopicCreationForm(
          format: format,
          existingIds: {'taken', 'Case'},
          l10n: AppLocalizationsEn(),
        );
        final extension = format == WritersideTopicFormat.markdown
            ? '.md'
            : '.topic';
        expect(form.titleError('  '), form.l10n.topicTitleRequired);
        expect(form.titleError(' Title '), isNull);
        expect(form.fileNameForTitle('Hello World'), 'hello-world$extension');
        expect(form.fileNameForTitle('!!!'), 'new-topic$extension');
        expect(
          form.fileNameForTitle('Résumé 世界'),
          '${slugForHeading('Résumé 世界')}$extension',
        );
        expect(form.effectiveFileName('  Manual  '), 'Manual$extension');
        expect(
          form.effectiveFileName('Manual${extension.toUpperCase()}'),
          'Manual${extension.toUpperCase()}',
        );
        expect(form.fileNameError('Manual${extension.toUpperCase()}'), isNull);
        expect(form.fileNameError(''), form.l10n.fileNameRequired);
        expect(
          form.fileNameError('taken$extension'),
          form.l10n.topicIdAlreadyExists,
        );
        expect(
          form.fileNameError('Case$extension'),
          form.l10n.topicIdAlreadyExists,
        );
        expect(form.fileNameError('case$extension'), isNull);
        expect(form.fileNameError('Résumé世界$extension'), isNull);
        expect(
          form.fileNameError('name.txt'),
          form.l10n.useExpectedExtension(extension),
        );
        for (final name in [
          '../unsafe$extension',
          '/unsafe$extension',
          'unsafe\\name$extension',
          'nul\u0000$extension',
        ]) {
          expect(form.fileNameError(name), form.l10n.useSingleSafeFileName);
        }
        for (final name in [
          'CON$extension',
          'nul$extension',
          'with spaces$extension',
          'with.dot$extension',
        ]) {
          expect(form.fileNameError(name), form.l10n.useIdentifierCharacters);
        }
      },
    );
  }
  test(
    'native success without a completed submission is a protocol error',
    () async {
      const channel = MethodChannel('busymark/test/early-success');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => true);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await expectLater(
        _create(channel),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'invalid-result',
          ),
        ),
      );
    },
  );
  test('host unavailability after an event cannot open a fallback', () async {
    final host = TestNativeWritersideDialogHost();
    host.install();
    addTearDown(host.dispose);
    final result = _create(host.channel);
    await host.opened.future;
    await host.event({
      'event': 'changed',
      'title': 'Title',
      'fileName': 'title.md',
      'fileNameEdited': true,
    });
    final assertion = expectLater(
      result,
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'unavailable',
        ),
      ),
    );
    host.closed.completeError(PlatformException(code: 'unavailable'));
    await assertion;
  });
  test('retiring a session leaves other native operations intact', () async {
    const channel = MethodChannel('busymark/test/concurrent-forms');
    final hosts = [
      TestNativeWritersideDialogHost(channel: channel),
      TestNativeWritersideDialogHost(channel: channel),
    ];
    var index = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) {
      if (call.method == 'showDuplicateTopic') return Future.value('copy');
      final host = hosts[index++];
      host.arguments = call.arguments as Map<Object?, Object?>;
      host.opened.complete(host.arguments);
      return host.closed.future;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final first = _text(channel);
    await hosts[0].opened.future;
    final second = _rename(channel);
    await hosts[1].opened.future;
    hosts[0].closed.complete(null);
    expect((await first).value, isNull);
    await expectLater(
      hosts[0].event({'event': 'changed', 'value': 'late'}),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'expired-dialog',
        ),
      ),
    );
    expect(await hosts[1].event({'event': 'changed', 'value': 'new.topic'}), {
      'error': null,
    });
    final duplicate = await _operation('duplicate', channel);
    expect(duplicate.value, 'copy');
    hosts[1].closed.complete({'value': 'new.topic', 'preview': false});
    expect((await second).value?.fileName, 'new.topic');
  });
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
  test(
    'New Topic validates, stays pending, retains failure and retries',
    () async {
      final host = TestNativeWritersideDialogHost();
      host.install();
      addTearDown(host.dispose);
      final form = WritersideTopicCreationForm(
        format: WritersideTopicFormat.xml,
        existingIds: {'taken'},
        l10n: AppLocalizationsAr(),
      );
      var submissions = 0;
      var creation = Completer<String?>();
      final resultFuture = NativeWritersideDialogService(channel: host.channel)
          .showCreateTopic(
            title: form.l10n.newTopic,
            titleLabel: form.l10n.tocTopicTitleField,
            fileNameLabel: form.l10n.tocDuplicateFilename,
            initialTitle: form.l10n.defaultNewTopicTitle,
            initialFileName: form.fileNameForTitle(
              form.l10n.defaultNewTopicTitle,
            ),
            cancelLabel: form.l10n.cancel,
            okLabel: form.l10n.tocOk,
            textDirection: TextDirection.rtl,
            validate: (title, name, edited) {
              final fileName = edited ? name : form.fileNameForTitle(title);
              return NativeWritersideCreateValidation(
                fileName: fileName,
                titleError: form.titleError(title),
                fileNameError: form.fileNameError(fileName),
              );
            },
            submit: (title, name) {
              submissions++;
              expect(title, 'New title');
              expect(name, 'manual.topic');
              return creation.future;
            },
          );
      final request = await host.opened.future;
      expect(request['textDirection'], 'rtl');
      expect(request['titleLabel'], form.l10n.tocTopicTitleField);
      expect(request['initialTitle'], form.l10n.defaultNewTopicTitle);
      expect(request['initialFileName'], endsWith('.topic'));
      Future<Object?> event(
        String type,
        String title,
        String name, {
        bool edited = true,
      }) => host.event({
        'event': type,
        'title': title,
        'fileName': name,
        'fileNameEdited': edited,
      });
      final synchronized =
          await event('changed', 'New title', 'old.topic', edited: false)
              as Map;
      expect(synchronized['fileName'], 'new-title.topic');
      final invalid = await event('submit', '', 'taken.topic') as Map;
      expect(invalid['titleError'], form.l10n.topicTitleRequired);
      expect(invalid['fileNameError'], form.l10n.topicIdAlreadyExists);
      expect(submissions, 0);
      final pending = event('submit', 'New title', 'manual.topic');
      await Future<void>.delayed(Duration.zero);
      expect(submissions, 1);
      expect(await event('submit', 'New title', 'manual.topic'), {
        'pending': true,
      });
      expect(await event('changed', 'Other', 'different.topic'), {
        'pending': true,
      });
      var finished = false;
      unawaited(resultFuture.then((_) => finished = true));
      expect(finished, isFalse);
      creation.complete(form.l10n.createWritersideTopicFailed);
      final failure = await pending as Map;
      expect(failure['created'], isFalse);
      expect(failure['error'], form.l10n.createWritersideTopicFailed);
      expect(failure['fileName'], 'manual.topic');
      expect(finished, isFalse);
      creation = Completer<String?>();
      final retry = event('submit', 'New title', 'manual.topic');
      await Future<void>.delayed(Duration.zero);
      expect(submissions, 2);
      creation.complete(null);
      expect((await retry as Map)['created'], isTrue);
      host.closed.complete(true);
      final result = await resultFuture;
      expect(result.available, isTrue);
      expect(result.value, isTrue);
      await expectLater(
        event('changed', 'Late', 'late.topic'),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );

  test(
    'New Topic destruction during creation removes the session safely',
    () async {
      final host = TestNativeWritersideDialogHost();
      host.install();
      addTearDown(host.dispose);
      final creation = Completer<String?>();
      final future = _create(host.channel, submit: (_, _) => creation.future);
      await host.opened.future;
      final pending = host.event({
        'event': 'submit',
        'title': 'Title',
        'fileName': 'title.md',
        'fileNameEdited': true,
      });
      await Future<void>.delayed(Duration.zero);
      host.closed.complete(null);
      expect((await future).value, isNull);
      creation.complete(null);
      expect((await pending as Map)['created'], isTrue);
      await expectLater(
        host.event({'event': 'changed'}),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );

  for (final operation in [
    'create',
    'rename',
    'text',
    'picker',
    'duplicate',
    'title',
  ]) {
    for (final outcome in [
      'cancel',
      'missing',
      'unavailable',
      'malformed',
      'unexpected',
    ]) {
      test('$operation preserves the $outcome result contract', () async {
        final channel = MethodChannel('busymark/test/$operation/$outcome');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(channel, (_) async {
          switch (outcome) {
            case 'cancel':
              return null;
            case 'missing':
              throw MissingPluginException();
            case 'unavailable':
              throw PlatformException(code: 'unavailable');
            case 'unexpected':
              throw PlatformException(code: 'host-failed');
            default:
              return ['malformed'];
          }
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        final future = _operation(operation, channel);
        if (outcome == 'malformed' || outcome == 'unexpected') {
          await expectLater(
            future,
            throwsA(
              isA<PlatformException>().having(
                (error) => error.code,
                'code',
                outcome == 'malformed' ? 'invalid-result' : 'host-failed',
              ),
            ),
          );
        } else {
          final result = await future;
          expect(result.available, outcome == 'cancel');
          expect(result.value, isNull);
        }
      });
    }
  }

  test('rename uses Dart extension validation and distinct actions', () async {
    for (final preview in [true, false]) {
      final host = TestNativeWritersideDialogHost();
      host.install();
      final resultFuture = _rename(host.channel);
      await host.opened.future;
      expect(host.calls.single.method, 'showRenameTopic');
      expect(host.arguments['textDirection'], 'rtl');
      expect(host.arguments['previewLabel'], 'Preview');
      expect(await host.event({'event': 'changed', 'value': 'wrong.md'}), {
        'error': 'extension',
      });
      host.closed.complete({'value': '  renamed.topic  ', 'preview': preview});
      final result = await resultFuture;
      expect(result.value?.fileName, 'renamed.topic');
      expect(result.value?.preview, preview);
      host.dispose();
    }
  });

  test(
    'Group returns untrimmed text and keeps Enter-only interaction',
    () async {
      final host = TestNativeWritersideDialogHost();
      host.install();
      addTearDown(host.dispose);
      final future = _text(host.channel);
      await host.opened.future;
      expect(host.arguments['enterOnly'], isTrue);
      expect(await host.event({'event': 'changed', 'value': '  '}), {
        'error': 'required',
      });
      host.closed.complete('  Group  ');
      expect((await future).value, '  Group  ');
    },
  );

  test('picker filters in Dart and returns the original index', () async {
    final host = TestNativeWritersideDialogHost();
    host.install();
    addTearDown(host.dispose);
    final future = _picker(host.channel);
    await host.opened.future;
    expect(host.arguments['searchLabel'], 'Search');
    expect(await host.event({'event': 'filter', 'value': 'BETA'}), [1, 2]);
    host.closed.complete(2);
    expect((await future).value, 2);
  });
}

Future<NativeWritersideDialogResult<bool>> _create(
  MethodChannel channel, {
  Future<String?> Function(String, String)? submit,
}) => NativeWritersideDialogService(channel: channel).showCreateTopic(
  title: 'New Topic',
  titleLabel: 'Title',
  fileNameLabel: 'Filename',
  initialTitle: 'Title',
  initialFileName: 'title.md',
  cancelLabel: 'Cancel',
  okLabel: 'OK',
  textDirection: TextDirection.ltr,
  validate: (_, name, _) => NativeWritersideCreateValidation(fileName: name),
  submit: submit ?? (_, _) async => null,
);
Future<NativeWritersideDialogResult<NativeWritersideRenameValues>> _rename(
  MethodChannel channel,
) => NativeWritersideDialogService(channel: channel).showRenameTopic(
  title: 'Rename',
  fileNameLabel: 'Filename',
  initialValue: 'old.topic',
  cancelLabel: 'Cancel',
  previewLabel: 'Preview',
  refactorLabel: 'Refactor',
  validate: (value) => value.trim().endsWith('.topic') ? null : 'extension',
  textDirection: TextDirection.rtl,
);
Future<NativeWritersideDialogResult<String>> _text(MethodChannel channel) =>
    NativeWritersideDialogService(channel: channel).showTocText(
      title: 'Group',
      label: 'Title',
      cancelLabel: 'Cancel',
      okLabel: 'OK',
      requiredError: 'required',
      enterOnly: true,
      textDirection: TextDirection.rtl,
    );
Future<NativeWritersideDialogResult<int>> _picker(MethodChannel channel) =>
    NativeWritersideDialogService(channel: channel).showExistingTopicPicker(
      title: 'Select',
      searchLabel: 'Search',
      fileNames: ['alpha.md', 'beta.md', 'BETA.md'],
      textDirection: TextDirection.rtl,
    );
Future<NativeWritersideDialogResult<Object>> _operation(
  String operation,
  MethodChannel channel,
) {
  final service = NativeWritersideDialogService(channel: channel);
  return switch (operation) {
    'create' => _create(channel),
    'rename' => _rename(channel),
    'text' => _text(channel),
    'picker' => _picker(channel),
    'duplicate' => service.showDuplicateTopic(
      title: 'Duplicate',
      fileNameLabel: 'Filename',
      initialValue: 'old',
      cancelLabel: 'Cancel',
      okLabel: 'OK',
      requiredError: 'required',
      invalidCharactersError: 'invalid',
      duplicateError: 'duplicate',
      existingTopicIds: [],
    ),
    _ => service.showEditTitle(
      dialogTitle: 'Edit Title',
      topicTitleLabel: 'Title',
      advancedLabel: 'Advanced',
      instanceTitleLabel: 'Instance',
      tocTitleLabel: 'TOC',
      instanceExplanation: 'Instance help',
      tocExplanation: 'TOC help',
      documentationLabel: 'Docs',
      documentationUrl: 'https://example.test',
      initialTitle: 'Title',
      initialInstanceTitle: '',
      initialTocTitle: '',
      cancelLabel: 'Cancel',
      okLabel: 'OK',
    ),
  };
}
