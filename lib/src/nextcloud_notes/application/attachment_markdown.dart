/// Adds a normal Markdown download link without publishing private cache paths.
String appendNextcloudAttachmentLink({
  required String content,
  required String filename,
  required String reference,
}) {
  final label = filename
      .replaceAll('\\', '\\\\')
      .replaceAll('[', '\\[')
      .replaceAll(']', '\\]')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ');
  final separator = content.isEmpty || content.endsWith('\n\n')
      ? ''
      : content.endsWith('\n')
      ? '\n'
      : '\n\n';
  return '$content$separator[$label]($reference)\n';
}
