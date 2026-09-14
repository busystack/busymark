import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../writerside/writerside_model.dart';
import '../../writerside/writerside_title_editor.dart';
import '../workspace_service.dart';

class WritersideTitleDialog extends StatefulWidget {
  const WritersideTitleDialog({super.key, required this.session});
  final WritersideTitleEditSession session;
  @override
  State<WritersideTitleDialog> createState() => _WritersideTitleDialogState();
}

class _WritersideTitleDialogState extends State<WritersideTitleDialog> {
  late final _title = TextEditingController(
    text: widget.session.topic.title ?? '',
  );
  late final _instance = TextEditingController(
    text:
        widget.session.topic.titleOverrides
            .where((override) => override.instance == widget.session.instanceId)
            .firstOrNull
            ?.title ??
        '',
  );
  late final _toc = TextEditingController(
    text: widget.session.identity.tocTitle ?? '',
  );
  late final _original = (_title.text, _instance.text, _toc.text);
  bool _advanced = false;
  @override
  void initState() {
    super.initState();
    // Evaluate all originals before the first user edit, including fields in
    // the initially collapsed advanced area.
    _original;
    for (final controller in [_title, _instance, _toc]) {
      controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _title.dispose();
    _instance.dispose();
    _toc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      WritersideTitleEdit(
        title: _title.text == _original.$1 ? null : _title.text,
        instanceTitle: _instance.text == _original.$2 ? null : _instance.text,
        tocTitle: _toc.text == _original.$3 ? null : _toc.text,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: BusyMarkSpacing.md),
    child: TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onSubmitted: (_) => _submit(),
    ),
  );
  @override
  Widget build(BuildContext context) => BusyMarkDialogShell(
    title: context.l10n.tocEditTitleDialog,
    maxWidth: BusyMarkSizes.dialog,
    actions: [
      BusyMarkDialogButton(
        label: context.l10n.cancel,
        onPressed: () => Navigator.pop(context),
      ),
      BusyMarkDialogButton(
        label: context.l10n.tocOk,
        suggested: true,
        onPressed: _title.text.trim().isEmpty ? null : _submit,
      ),
    ],
    children: [
      _field(context.l10n.tocTopicTitleField, _title, autofocus: true),
      TextButton(
        onPressed: () => setState(() => _advanced = !_advanced),
        child: Row(
          children: [
            Icon(_advanced ? BusyMarkGlyphs.upArrow : BusyMarkGlyphs.downArrow),
            Text(context.l10n.tocAdvancedSettings),
          ],
        ),
      ),
      if (_advanced) ...[
        _field(
          context.l10n.tocInstanceTitleField(widget.session.instanceId),
          _instance,
          hint: _title.text,
        ),
        _field(
          context.l10n.tocOnlyTitleField,
          _toc,
          hint: _instance.text.isEmpty ? _title.text : _instance.text,
        ),
      ],
    ],
  );
}

class WritersideTocTextDialog extends StatefulWidget {
  const WritersideTocTextDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue = '',
    this.enterOnly = false,
    this.validate,
  });
  final String title;
  final String label;
  final String initialValue;
  final bool enterOnly;
  final String? Function(String)? validate;
  @override
  State<WritersideTocTextDialog> createState() =>
      _WritersideTocTextDialogState();
}

class _WritersideTocTextDialogState extends State<WritersideTocTextDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _error => widget.validate?.call(_controller.text);
  void _submit() {
    if (_controller.text.trim().isNotEmpty && _error == null) {
      Navigator.pop(context, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) => BusyMarkDialogShell(
    title: widget.title,
    maxWidth: BusyMarkSizes.dialog,
    actions: widget.enterOnly
        ? const []
        : [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
            BusyMarkDialogButton(
              label: context.l10n.tocOk,
              suggested: true,
              onPressed: _controller.text.trim().isEmpty || _error != null
                  ? null
                  : _submit,
            ),
          ],
    children: [
      TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
    ],
  );
}

class WritersideExistingTopicPicker extends StatefulWidget {
  const WritersideExistingTopicPicker({super.key, required this.topics});
  final List<WritersideTopic> topics;
  @override
  State<WritersideExistingTopicPicker> createState() =>
      _WritersideExistingTopicPickerState();
}

class _WritersideExistingTopicPickerState
    extends State<WritersideExistingTopicPicker> {
  String _query = '';
  int _selected = 0;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.topics
        .where(
          (topic) =>
              topic.fileName.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return BusyMarkDialogShell(
      title: context.l10n.tocSelectExistingTopic,
      maxWidth: BusyMarkSizes.dialog,
      children: [
        Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            final key = event.logicalKey;
            if (key != LogicalKeyboardKey.arrowDown &&
                key != LogicalKeyboardKey.arrowUp) {
              return KeyEventResult.ignored;
            }
            if (topics.isNotEmpty) {
              setState(
                () => _selected =
                    (_selected + (key == LogicalKeyboardKey.arrowDown ? 1 : -1))
                        .clamp(0, topics.length - 1),
              );
              if (_scroll.hasClients) {
                _scroll.jumpTo(
                  (_selected * 48.0 - 240).clamp(
                    0,
                    _scroll.position.maxScrollExtent,
                  ),
                );
              }
            }
            return KeyEventResult.handled;
          },
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: context.l10n.search),
            onChanged: (value) => setState(() {
              _query = value;
              _selected = 0;
            }),
            onSubmitted: (_) {
              if (topics.isNotEmpty) Navigator.pop(context, topics[_selected]);
            },
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView(
            controller: _scroll,
            itemExtent: 48,
            children: [
              for (var index = 0; index < topics.length; index++)
                ListTile(
                  selected: index == _selected,
                  title: Text(topics[index].fileName),
                  onTap: () => Navigator.pop(context, topics[index]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
