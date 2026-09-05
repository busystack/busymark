import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../markdown/preview_model.dart';

class WritersideSelectionController extends ChangeNotifier {
  final Map<String, String> _keys = {};
  String? selected(String group) => _keys[group];
  void select(String group, String key) {
    if (_keys[group] == key) return;
    _keys[group] = key;
    notifyListeners();
  }
}

class WritersidePreviewScope extends StatefulWidget {
  const WritersidePreviewScope({super.key, required this.child});
  final Widget child;
  static WritersideSelectionController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectionScope>()?.notifier;
  @override
  State<WritersidePreviewScope> createState() => _WritersidePreviewScopeState();
}

class _WritersidePreviewScopeState extends State<WritersidePreviewScope> {
  final controller = WritersideSelectionController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SelectionScope(notifier: controller, child: widget.child);
}

class _SelectionScope extends InheritedNotifier<WritersideSelectionController> {
  const _SelectionScope({required super.notifier, required super.child});
}

class WritersideTabsView extends StatefulWidget {
  const WritersideTabsView({
    super.key,
    required this.block,
    required this.panelBuilder,
  });
  final PreviewBlock block;
  final Widget Function(List<PreviewBlock>) panelBuilder;
  @override
  State<WritersideTabsView> createState() => _WritersideTabsViewState();
}

class _WritersideTabsViewState extends State<WritersideTabsView> {
  int selected = 0;
  final List<FocusNode> focuses = [];
  @override
  void dispose() {
    for (final focus in focuses) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panels = widget.block.children;
    if (panels.isEmpty) return const SizedBox.shrink();
    while (focuses.length < panels.length) {
      focuses.add(FocusNode());
    }
    final controller = WritersidePreviewScope.of(context);
    final group = widget.block.attributes['group'];
    String key(int index) =>
        panels[index].attributes['group-key'] ?? panels[index].text;
    final shared = group == null ? null : controller?.selected(group);
    final sharedIndex = panels.indexWhere(
      (panel) => (panel.attributes['group-key'] ?? panel.text) == shared,
    );
    final active = sharedIndex < 0
        ? selected.clamp(0, panels.length - 1)
        : sharedIndex;
    for (var index = 0; index < panels.length; index++) {
      focuses[index].skipTraversal = index != active;
    }
    void select(int index, {bool focus = false}) {
      setState(() => selected = index);
      if (group != null) controller?.select(group, key(index));
      if (focus) focuses[index].requestFocus();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.block.attributes['topic-switcher'] == 'true')
          Text(widget.block.attributes['title'] ?? 'Section'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < panels.length; index++)
                Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    final next = switch (event.logicalKey) {
                      LogicalKeyboardKey.arrowRight =>
                        (index + 1) % panels.length,
                      LogicalKeyboardKey.arrowLeft =>
                        (index + panels.length - 1) % panels.length,
                      LogicalKeyboardKey.home => 0,
                      LogicalKeyboardKey.end => panels.length - 1,
                      _ => null,
                    };
                    if (next == null) return KeyEventResult.ignored;
                    select(next, focus: true);
                    return KeyEventResult.handled;
                  },
                  child: Semantics(
                    selected: index == active,
                    button: true,
                    child: TextButton(
                      focusNode: focuses[index],
                      onPressed: () => select(index),
                      style: index == active
                          ? TextButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            )
                          : null,
                      child: Text(panels[index].text),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.block.attributes['topic-switcher'] != 'true')
          FocusTraversalGroup(
            child: Focus(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: widget.panelBuilder(panels[active].children),
              ),
            ),
          ),
      ],
    );
  }
}
