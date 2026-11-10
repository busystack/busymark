import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(
  WidgetsApp(
    color: const Color(0xffffffff),
    builder: (context, child) => const Probe(),
  ),
);

class NextIntent extends Intent {
  const NextIntent();
}

class Probe extends StatefulWidget {
  const Probe({super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.tab, control: true): NextIntent(),
    },
    child: Actions(
      actions: {
        NextIntent: CallbackAction<NextIntent>(
          onInvoke: (_) {
            print('PURE CTRL TAB ACTIVATED ${count + 1}');
            setState(() => count++);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          print(
            'PURE KEY $event ctrl=${HardwareKeyboard.instance.isControlPressed}',
          );
          return KeyEventResult.ignored;
        },
        child: Center(
          child: Text(
            'Ctrl+Tab activations: $count',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Color(0xff000000), fontSize: 26),
          ),
        ),
      ),
    ),
  );
}
