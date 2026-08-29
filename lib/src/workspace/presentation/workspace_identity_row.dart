import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';

class WorkspaceIdentityRow extends StatelessWidget {
  const WorkspaceIdentityRow({
    super.key,
    required this.icon,
    required this.name,
    required this.path,
    this.height,
    this.horizontalPadding = BusyMarkSpacing.sm,
    this.trailing,
  });

  final IconData icon;
  final String name;
  final String path;
  final double? height;
  final double horizontalPadding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final titleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colors.foreground);
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground);
    final detail = path.trim();
    final row = Row(
      children: [
        SizedBox(width: horizontalPadding),
        Icon(icon, size: BusyMarkSizes.iconSm, color: colors.mutedForeground),
        const SizedBox(width: BusyMarkSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: BusyMarkSpacing.xxs),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: detailStyle,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: BusyMarkSpacing.xs),
          trailing!,
        ],
        SizedBox(width: horizontalPadding),
      ],
    );
    return height == null ? row : SizedBox(height: height, child: row);
  }
}
