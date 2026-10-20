import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// One measured elision of a location, retaining its trailing path components.
/// Full navigation identities and accessible descriptions belong to the row.
class BusyMarkPathLabel extends StatelessWidget {
  const BusyMarkPathLabel({required this.path, this.style, super.key});
  final String path;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
      final scaler = MediaQuery.textScalerOf(context);
      bool fits(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final result = painter.width <= constraints.maxWidth;
        painter.dispose();
        return result;
      }

      var label = path;
      if (!fits(label)) {
        final prefix = p.isAbsolute(path)
            ? '${p.rootPrefix(path)}…${p.separator}'
            : path.startsWith('~${p.separator}')
            ? '~${p.separator}…${p.separator}'
            : '…${p.separator}';
        final parts = p
            .split(path)
            .where((part) => part != p.rootPrefix(path) && part != '~')
            .toList();
        for (var i = 1; i < parts.length; i++) {
          label = '$prefix${p.joinAll(parts.skip(i))}';
          if (fits(label)) break;
        }
        if (!fits(label)) {
          final end = (parts.lastOrNull ?? path).characters.toList();
          var low = 0, high = end.length;
          while (low < high) {
            final mid = (low + high) ~/ 2;
            if (fits('$prefix${end.skip(mid).join()}')) {
              high = mid;
            } else {
              low = mid + 1;
            }
          }
          label = '$prefix${end.skip(low).join()}';
        }
      }
      return Text(
        label,
        style: style,
        maxLines: 1,
        softWrap: false,
        textDirection: TextDirection.ltr,
        overflow: TextOverflow.clip,
      );
    },
  );
}
