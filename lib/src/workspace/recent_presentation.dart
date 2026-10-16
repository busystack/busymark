import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/localization.dart';

String recentResourceTitle(BuildContext context, RecentResource resource) =>
    resource.title ??
    (resource.accountId == null
        ? p.basename(resource.path)
        : context.l10n.nextcloudNotes);

String recentResourceLocation(
  BuildContext context,
  RecentResource resource, {
  String? accountLabel,
}) {
  if (resource.accountId != null) {
    final label = accountLabel?.trim().isNotEmpty == true
        ? accountLabel
        : resource.accountLabel;
    return label == null || label.trim().isEmpty
        ? context.l10n.searchAccountUnavailable
        : label;
  }
  // A single full location retains project ownership without repeating its root.
  return resource.path;
}
