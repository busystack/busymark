import 'package:path/path.dart' as p;

import '../core/busymark_exception.dart';

const writersideTopicExtensions = {'.md', '.markdown', '.topic'};

/// Applies the shared Writerside topic filename policy without permitting a
/// filename to become a path or a rename to change topic format.
String validateWritersideTopicFileName(
  String value, {
  String? requiredExtension,
  String unsafeCode = 'writerside.topic-file.file-name-unsafe',
  String invalidCode = 'writerside.topic-file.file-name-invalid',
  String extensionCode = 'writerside.topic-file.file-extension-mismatch',
}) {
  final fileName = value.trim();
  if (fileName.isEmpty ||
      fileName == '.' ||
      fileName == '..' ||
      p.isAbsolute(fileName) ||
      fileName.contains('/') ||
      fileName.contains(r'\') ||
      fileName.contains('\u0000')) {
    throw BusyMarkException(unsafeCode);
  }
  final extension = p.extension(fileName).toLowerCase();
  if (!writersideTopicExtensions.contains(extension) ||
      (requiredExtension != null && extension != requiredExtension)) {
    throw BusyMarkException(
      extensionCode,
      args: {'extension': requiredExtension ?? extension},
    );
  }
  final id = p.basenameWithoutExtension(fileName);
  if (!isValidWritersideTopicId(id)) {
    throw BusyMarkException(invalidCode);
  }
  return fileName;
}

bool isValidWritersideTopicId(String value) =>
    RegExp(r'^[\p{L}\p{N}_-]+$', unicode: true).hasMatch(value) &&
    !_windowsReservedTopicIds.contains(value.toUpperCase());

const _windowsReservedTopicIds = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
};
