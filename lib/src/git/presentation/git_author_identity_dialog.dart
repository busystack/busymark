import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/localization.dart';

class GitAuthorIdentityInput {
  const GitAuthorIdentityInput({
    required this.name,
    required this.email,
    required this.globally,
  });

  final String name;
  final String email;
  final bool globally;
}

Future<GitAuthorIdentityInput?> showGitAuthorIdentityDialog(
  BuildContext context,
) {
  return showBusyMarkModalEditorDialog<GitAuthorIdentityInput>(
    context,
    maxWidth: BusyMarkSizes.dialogCompact,
    builder: (context) => const _GitAuthorIdentityDialog(),
  );
}

class _GitAuthorIdentityDialog extends StatefulWidget {
  const _GitAuthorIdentityDialog();

  @override
  State<_GitAuthorIdentityDialog> createState() =>
      _GitAuthorIdentityDialogState();
}

class _GitAuthorIdentityDialogState extends State<_GitAuthorIdentityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final FocusNode _emailFocusNode;
  var _globally = true;

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      !_nameController.text.contains(RegExp(r'[\r\n]')) &&
      !_emailController.text.contains(RegExp(r'[\r\n]'));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_handleChanged);
    _emailController = TextEditingController()..addListener(_handleChanged);
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleChanged)
      ..dispose();
    _emailController
      ..removeListener(_handleChanged)
      ..dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: context.l10n.gitAuthorIdentityTitle,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.gitSaveIdentityAndCommit,
      onCancel: () => Navigator.pop(context),
      onSave: _canSubmit ? _submit : null,
      children: [
        Text(context.l10n.gitAuthorIdentityMessage),
        const SizedBox(height: BusyMarkSpacing.lg),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.gitAuthorName,
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _emailFocusNode.requestFocus(),
            ),
            BusyMarkGroupedTextEntry(
              label: context.l10n.gitAuthorEmail,
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            BusyMarkSwitchRow(
              title: context.l10n.gitAuthorIdentityGlobal,
              subtitle: context.l10n.gitAuthorIdentityGlobalDescription,
              value: _globally,
              onChanged: (value) => setState(() => _globally = value),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }
    Navigator.pop(
      context,
      GitAuthorIdentityInput(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        globally: _globally,
      ),
    );
  }

  void _handleChanged() {
    setState(() {});
  }
}
