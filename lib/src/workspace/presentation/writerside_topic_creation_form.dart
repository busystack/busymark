import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../core/path_utils.dart';
import '../../writerside/writerside_model.dart';
import '../../writerside/writerside_topic_file_name.dart';

/// The filename and validation rules shared by the GTK form and its fallback.
final class WritersideTopicCreationForm {
  const WritersideTopicCreationForm({
    required this.format,
    required this.existingIds,
    required this.l10n,
  });

  final WritersideTopicFormat format;
  final Set<String> existingIds;
  final AppLocalizations l10n;

  String get extension => switch (format) {
    WritersideTopicFormat.markdown => '.md',
    WritersideTopicFormat.xml => '.topic',
  };

  String fileNameForTitle(String title) {
    final slug = slugForHeading(title);
    return '${slug.isEmpty ? 'new-topic' : slug}$extension';
  }

  String? titleError(String title) =>
      title.trim().isEmpty ? l10n.topicTitleRequired : null;

  String effectiveFileName(String fileName) {
    final value = fileName.trim();
    return p.extension(value).isEmpty ? '$value$extension' : value;
  }

  String? fileNameError(String fileName) {
    final value = fileName.trim();
    if (value.isEmpty) return l10n.fileNameRequired;
    final suppliedExtension = p.extension(value).toLowerCase();
    if (suppliedExtension.isNotEmpty && suppliedExtension != extension) {
      return l10n.useExpectedExtension(extension);
    }
    final effective = effectiveFileName(value);
    try {
      validateWritersideTopicFileName(effective, requiredExtension: extension);
    } on Object {
      if (value == '.' ||
          value == '..' ||
          p.isAbsolute(value) ||
          value.contains('/') ||
          value.contains(r'\') ||
          value.contains('\u0000')) {
        return l10n.useSingleSafeFileName;
      }
      return l10n.useIdentifierCharacters;
    }
    if (existingIds.contains(p.basenameWithoutExtension(effective))) {
      return l10n.topicIdAlreadyExists;
    }
    return null;
  }
}
