import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
