import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class SearchOptionButton extends StatelessWidget {
  const SearchOptionButton({
    super.key,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget optionLabel() => Builder(
      builder: (context) => Text(
        label,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: IconTheme.of(context).color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: YaruIconButton(
        tooltip: tooltip,
        iconSize: 28,
        isSelected: selected,
        onPressed: onPressed,
        icon: optionLabel(),
        selectedIcon: optionLabel(),
      ),
    );
  }
}
