import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';

class GitBranchesView extends StatefulWidget {
  const GitBranchesView({
    super.key,
    required this.state,
    required this.onCreateBranch,
    required this.onSwitchBranch,
  });

  final GitState state;
  final Future<void> Function(String branchName) onCreateBranch;
  final Future<void> Function(String branchName) onSwitchBranch;

  @override
  State<GitBranchesView> createState() => _GitBranchesViewState();
}

class _GitBranchesViewState extends State<GitBranchesView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.state.branches;
    final canCreate = _controller.text.trim().isNotEmpty;
    return ListView(
      padding: BusyMarkInsets.sidebarList,
      children: [
        Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: canCreate ? (_) => _create() : null,
            decoration: InputDecoration(
              labelText: context.l10n.gitBranchName,
              suffixIcon: IconButton(
                tooltip: context.l10n.gitCreateBranch,
                icon: const Icon(BusyMarkGlyphs.newDocument),
                onPressed: canCreate ? _create : null,
              ),
            ),
          ),
        ),
        Padding(
          padding: BusyMarkInsets.sectionLabel,
          child: Text(
            context.l10n.gitBranches,
            style: busyMarkSectionHeaderStyle(context),
          ),
        ),
        if (branches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Text(context.l10n.gitNoBranches),
          )
        else
          for (final branch in branches)
            _BranchRow(
              branch: branch,
              onSwitch: () => widget.onSwitchBranch(branch.name),
            ),
      ],
    );
  }

  Future<void> _create() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    await widget.onCreateBranch(value);
    if (mounted) {
      _controller.clear();
    }
  }

  void _handleChanged() {
    setState(() {});
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch, required this.onSwitch});

  final GitBranch branch;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: branch.current
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: busyMarkRowHoverColor(context),
          onTap: branch.current ? null : onSwitch,
          child: Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: Row(
              children: [
                Icon(
                  branch.current ? BusyMarkGlyphs.check : BusyMarkGlyphs.tree,
                  size: BusyMarkSizes.iconSm,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (branch.upstream != null)
                        Text(
                          branch.upstream!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                    ],
                  ),
                ),
                if (!branch.current)
                  Text(
                    context.l10n.gitSwitchBranch,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
