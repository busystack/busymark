import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
final class NativeWritersideCreateValidation {
  const NativeWritersideCreateValidation({
    required this.fileName,
    this.titleError,
    this.fileNameError,
  });
  final String fileName;
  final String? titleError;
  final String? fileNameError;

  Map<String, Object?> toMap() => {
    'fileName': fileName,
    'titleError': titleError,
    'fileNameError': fileNameError,
  };
}

@immutable
final class NativeWritersideRenameValues {
  const NativeWritersideRenameValues(this.fileName, {required this.preview});
  final String fileName;
  final bool preview;
}

@visibleForTesting
const nativeWritersideDialogChannelName = 'busymark/native_writerside_dialogs';

/// Result of asking the Linux host to present a Writerside dialog.
///
/// [available] distinguishes a user cancellation (`value == null`) from a
/// platform without the native dialog host, where the Flutter fallback should
/// be shown instead.
@immutable
final class NativeWritersideDialogResult<T> {
  const NativeWritersideDialogResult.available(this.value) : available = true;

  const NativeWritersideDialogResult.unavailable()
    : available = false,
      value = null;

  final bool available;
  final T? value;
}

@immutable
final class NativeWritersideTitleValues {
  const NativeWritersideTitleValues({
    required this.title,
    required this.instanceTitle,
    required this.tocTitle,
  });

  final String title;
  final String instanceTitle;
  final String tocTitle;
}

/// Presents the Writerside dialogs that should be owned by the Linux toolkit.
class NativeWritersideDialogService {
  const NativeWritersideDialogService({
    MethodChannel channel = const MethodChannel(
      nativeWritersideDialogChannelName,
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  // New interactive forms share this channel with the existing operations.
  // A session owns only its own callbacks; destroying one cannot replace a
  // newer dialog's handler or leave a submission callback installed.
  static int _nextSession = 0;
  static final _sessions =
      <String, Map<int, Future<Object?> Function(MethodCall)>>{};

  Future<NativeWritersideDialogResult<Object>> _showInteractive(
    String method,
    Map<String, Object?> arguments,
    Future<Object?> Function(MethodCall) onEvent,
  ) async {
    final session = ++_nextSession;
    var receivedEvent = false;
    final sessions = _sessions.putIfAbsent(_channel.name, () => {});
    sessions[session] = (call) {
      receivedEvent = true;
      return onEvent(call);
    };
    if (sessions.length == 1) {
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'writersideDialogEvent' || call.arguments is! Map) {
          throw PlatformException(code: 'invalid-event');
        }
        final handler = sessions[(call.arguments as Map)['session']];
        if (handler == null) throw PlatformException(code: 'expired-dialog');
        return handler(call);
      });
    }
    try {
      final value = await _channel.invokeMethod<Object?>(method, {
        ...arguments,
        'session': session,
      });
      return NativeWritersideDialogResult.available(value);
    } on MissingPluginException {
      if (receivedEvent) {
        throw PlatformException(code: 'dialog-host-disconnected');
      }
      return const NativeWritersideDialogResult.unavailable();
    } on PlatformException catch (error) {
      if (error.code == 'unavailable' && !receivedEvent) {
        return const NativeWritersideDialogResult.unavailable();
      }
      rethrow;
    } finally {
      sessions.remove(session);
      if (sessions.isEmpty) {
        _sessions.remove(_channel.name);
        _channel.setMethodCallHandler(null);
      }
    }
  }

  /// Keeps the GTK form alive until cancellation or a successful [submit].
  ///
  /// The host asks Dart to [validate] each edit and to submit a valid form.
  /// A null submission error closes the form; a localized error leaves its
  /// values intact for retry. The pending guard also protects against repeated
  /// native submission events. Session callbacks are removed on destruction.
  Future<NativeWritersideDialogResult<bool>> showCreateTopic({
    required String title,
    required String titleLabel,
    required String fileNameLabel,
    required String initialTitle,
    required String initialFileName,
    required String cancelLabel,
    required String okLabel,
    required NativeWritersideCreateValidation Function(
      String title,
      String fileName,
      bool fileNameEdited,
    )
    validate,
    required Future<String?> Function(String title, String fileName) submit,
    required TextDirection textDirection,
  }) async {
    var submitting = false;
    var completed = false;
    var active = true;
    try {
      final result = await _showInteractive(
        'showCreateTopic',
        {
          'title': title,
          'titleLabel': titleLabel,
          'fileNameLabel': fileNameLabel,
          'initialTitle': initialTitle,
          'initialFileName': initialFileName,
          'cancelLabel': cancelLabel,
          'okLabel': okLabel,
          'textDirection': textDirection.name,
        },
        (call) async {
          final args = call.arguments;
          if (!active || completed) {
            throw PlatformException(code: 'expired-dialog');
          }
          if (args case {
            'event': final String event,
            'title': final String title,
            'fileName': final String fileName,
            'fileNameEdited': final bool edited,
          }) {
            if (event != 'changed' && event != 'submit') {
              throw PlatformException(code: 'invalid-event');
            }
            if (submitting) return {'pending': true};
            final validation = validate(title, fileName, edited);
            if (event == 'changed' ||
                validation.titleError != null ||
                validation.fileNameError != null) {
              return {...validation.toMap(), 'created': false};
            }
            submitting = true;
            try {
              final error = await submit(title, validation.fileName);
              completed = error == null;
              return {
                ...validation.toMap(),
                'created': completed,
                'error': error,
              };
            } finally {
              submitting = false;
            }
          }
          throw PlatformException(code: 'invalid-event');
        },
      );
      if (!result.available) {
        return const NativeWritersideDialogResult.unavailable();
      }
      if (result.value == null) {
        return const NativeWritersideDialogResult.available(null);
      }
      if (result.value != true || !completed) {
        throw PlatformException(code: 'invalid-result');
      }
      return const NativeWritersideDialogResult.available(true);
    } finally {
      active = false;
    }
  }

  Future<NativeWritersideDialogResult<NativeWritersideRenameValues>>
  showRenameTopic({
    required String title,
    required String fileNameLabel,
    required String initialValue,
    required String cancelLabel,
    required String previewLabel,
    required String refactorLabel,
    required String? Function(String) validate,
    required TextDirection textDirection,
  }) async {
    final result = await _showInteractive(
      'showRenameTopic',
      {
        'title': title,
        'fileNameLabel': fileNameLabel,
        'initialValue': initialValue,
        'cancelLabel': cancelLabel,
        'previewLabel': previewLabel,
        'okLabel': refactorLabel,
        'textDirection': textDirection.name,
      },
      (call) async {
        if (call.arguments case {
          'event': 'changed',
          'value': final String value,
        }) {
          return {'error': validate(value)};
        }
        throw PlatformException(code: 'invalid-event');
      },
    );
    if (!result.available) {
      return const NativeWritersideDialogResult.unavailable();
    }
    if (result.value == null) {
      return const NativeWritersideDialogResult.available(null);
    }
    if (result.value case {
      'value': final String value,
      'preview': final bool preview,
    }) {
      if (validate(value) == null) {
        return NativeWritersideDialogResult.available(
          NativeWritersideRenameValues(value.trim(), preview: preview),
        );
      }
    }
    throw PlatformException(code: 'invalid-result');
  }

  Future<NativeWritersideDialogResult<String>> showTocText({
    required String title,
    required String label,
    required String cancelLabel,
    required String okLabel,
    required String requiredError,
    bool enterOnly = false,
    required TextDirection textDirection,
  }) async {
    final result = await _showInteractive(
      'showTocText',
      {
        'title': title,
        'fileNameLabel': label,
        'initialValue': '',
        'cancelLabel': cancelLabel,
        'okLabel': okLabel,
        'enterOnly': enterOnly,
        'textDirection': textDirection.name,
      },
      (call) async {
        if (call.arguments case {
          'event': 'changed',
          'value': final String value,
        }) {
          return {'error': value.trim().isEmpty ? requiredError : null};
        }
        throw PlatformException(code: 'invalid-event');
      },
    );
    if (!result.available) {
      return const NativeWritersideDialogResult.unavailable();
    }
    if (result.value == null) {
      return const NativeWritersideDialogResult.available(null);
    }
    if (result.value case final String value when value.trim().isNotEmpty) {
      return NativeWritersideDialogResult.available(value);
    }
    throw PlatformException(code: 'invalid-result');
  }

  Future<NativeWritersideDialogResult<int>> showExistingTopicPicker({
    required String title,
    required String searchLabel,
    required List<String> fileNames,
    required TextDirection textDirection,
  }) async {
    final result = await _showInteractive(
      'showExistingTopicPicker',
      {
        'title': title,
        'searchLabel': searchLabel,
        'fileNames': fileNames,
        'textDirection': textDirection.name,
      },
      (call) async {
        if (call.arguments case {
          'event': 'filter',
          'value': final String query,
        }) {
          return [
            for (var i = 0; i < fileNames.length; i++)
              if (fileNames[i].toLowerCase().contains(query.toLowerCase())) i,
          ];
        }
        throw PlatformException(code: 'invalid-event');
      },
    );
    if (!result.available) {
      return const NativeWritersideDialogResult.unavailable();
    }
    if (result.value == null) {
      return const NativeWritersideDialogResult.available(null);
    }
    if (result.value case final int index
        when index >= 0 && index < fileNames.length) {
      return NativeWritersideDialogResult.available(index);
    }
    throw PlatformException(code: 'invalid-result');
  }

  Future<NativeWritersideDialogResult<String>> showDuplicateTopic({
    required String title,
    required String fileNameLabel,
    required String initialValue,
    required String cancelLabel,
    required String okLabel,
    required String requiredError,
    required String invalidCharactersError,
    required String duplicateError,
    required Iterable<String> existingTopicIds,
    TextDirection? textDirection,
  }) async {
    try {
      final value = await _channel.invokeMethod<Object?>('showDuplicateTopic', {
        'title': title,
        'fileNameLabel': fileNameLabel,
        'initialValue': initialValue,
        'cancelLabel': cancelLabel,
        'okLabel': okLabel,
        'requiredError': requiredError,
        'invalidCharactersError': invalidCharactersError,
        'duplicateError': duplicateError,
        'existingTopicIds': existingTopicIds.toList(growable: false),
        if (textDirection != null) 'textDirection': textDirection.name,
      });
      if (value != null && value is! String) {
        throw PlatformException(code: 'invalid-result');
      }
      return NativeWritersideDialogResult<String>.available(value as String?);
    } on MissingPluginException {
      return const NativeWritersideDialogResult<String>.unavailable();
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') {
        return const NativeWritersideDialogResult<String>.unavailable();
      }
      rethrow;
    }
  }

  Future<NativeWritersideDialogResult<NativeWritersideTitleValues>>
  showEditTitle({
    required String dialogTitle,
    required String topicTitleLabel,
    required String advancedLabel,
    required String instanceTitleLabel,
    required String tocTitleLabel,
    required String instanceExplanation,
    required String tocExplanation,
    required String documentationLabel,
    required String documentationUrl,
    required String initialTitle,
    required String initialInstanceTitle,
    required String initialTocTitle,
    required String cancelLabel,
    required String okLabel,
    TextDirection? textDirection,
  }) async {
    try {
      final value = await _channel.invokeMethod<Object?>('showEditTitle', {
        'title': dialogTitle,
        'topicTitleLabel': topicTitleLabel,
        'advancedLabel': advancedLabel,
        'instanceTitleLabel': instanceTitleLabel,
        'tocTitleLabel': tocTitleLabel,
        'instanceExplanation': instanceExplanation,
        'tocExplanation': tocExplanation,
        'documentationLabel': documentationLabel,
        'documentationUrl': documentationUrl,
        'initialTitle': initialTitle,
        'initialInstanceTitle': initialInstanceTitle,
        'initialTocTitle': initialTocTitle,
        'cancelLabel': cancelLabel,
        'okLabel': okLabel,
        if (textDirection != null) 'textDirection': textDirection.name,
      });
      if (value == null) {
        return const NativeWritersideDialogResult<
          NativeWritersideTitleValues
        >.available(null);
      }
      if (value case {
        'title': final String title,
        'instanceTitle': final String instanceTitle,
        'tocTitle': final String tocTitle,
      }) {
        return NativeWritersideDialogResult<
          NativeWritersideTitleValues
        >.available(
          NativeWritersideTitleValues(
            title: title,
            instanceTitle: instanceTitle,
            tocTitle: tocTitle,
          ),
        );
      }
      throw PlatformException(code: 'invalid-result');
    } on MissingPluginException {
      return const NativeWritersideDialogResult<
        NativeWritersideTitleValues
      >.unavailable();
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') {
        return const NativeWritersideDialogResult<
          NativeWritersideTitleValues
        >.unavailable();
      }
      rethrow;
    }
  }
}
