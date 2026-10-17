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
  final location =
      resource.isDocument &&
          recentResourceTitle(context, resource) == p.basename(resource.path)
      ? p.dirname(resource.path)
      : resource.path;
  final owner = resource.ownerRoot;
  if (owner != null && p.isWithin(owner, location)) {
    return '${_trailingLocation(owner, 2)} · ${_trailingLocation(p.relative(location, from: owner), 2)}';
  }
  return _trailingLocation(location, 3);
}

String _trailingLocation(String location, int count) {
  final parts = p.split(location).where((part) => part != p.separator).toList();
  if (parts.isEmpty) return location;
  return parts.length <= count
      ? parts.join(p.separator)
      : '…${p.separator}${parts.skip(parts.length - count).join(p.separator)}';
}
