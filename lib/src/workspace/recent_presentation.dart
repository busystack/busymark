import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/localization.dart';
import '../platform/user_directories.dart';

String recentResourceTitle(BuildContext context, RecentResource resource) =>
    resource.title ??
    (resource.accountId == null
        ? p.basename(resource.path)
        : context.l10n.nextcloudNotes);

String recentResourceLocation(
  BuildContext context,
  RecentResource resource, {
  String? accountLabel,
  String? homeDirectory,
  String? workspaceRoot,
  Iterable<RecentResource> recentResources = const [],
}) {
  if (resource.accountId != null) {
    final label = accountLabel?.trim().isNotEmpty == true
        ? accountLabel
        : resource.accountLabel;
    return label == null || label.trim().isEmpty
        ? context.l10n.searchAccountUnavailable
        : label;
  }
  final parent = p.dirname(p.normalize(resource.path));
  final home = homeDirectory ?? userHomeDirectory;
  if (home == null || !(p.equals(home, parent) || p.isWithin(home, parent))) {
    return parent;
  }
  String homeRelative(String path) =>
      p.equals(home, path) ? '~' : p.join('~', p.relative(path, from: home));
  if (!resource.isDocument || p.equals(p.dirname(parent), home)) {
    return homeRelative(parent);
  }
  final roots = <String>{
    if (resource.ownerRoot != null) p.normalize(resource.ownerRoot!),
    if (workspaceRoot != null) p.normalize(workspaceRoot),
    for (final other in recentResources) ...[
      if (other.ownerRoot != null) p.normalize(other.ownerRoot!),
      if (!other.isDocument &&
          other.accountId == null &&
          (other.kind == 'markdownFolder' || other.kind == 'writersideModule'))
        p.normalize(other.path),
    ],
  };
  final owners =
      roots
          .where(
            (root) =>
                (p.equals(home, root) || p.isWithin(home, root)) &&
                (p.equals(root, parent) || p.isWithin(root, parent)),
          )
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  if (owners.isEmpty || p.equals(owners.first, home)) {
    return homeRelative(parent);
  }
  final owner = owners.first;
  final ambiguous = roots.any(
    (root) => p.basename(root) == p.basename(owner) && !p.equals(root, owner),
  );
  final label = ambiguous ? homeRelative(owner) : p.basename(owner);
  return p.equals(owner, parent)
      ? label
      : p.join(label, p.relative(parent, from: owner));
}
