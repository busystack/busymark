import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class CloseListener with WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  windowManager.addListener(CloseListener());
  runApp(
    const Directionality(textDirection: TextDirection.ltr, child: LiveFrames()),
  );
}

class LiveFrames extends StatefulWidget {
  const LiveFrames({super.key});
  @override
  State<LiveFrames> createState() => _LiveFramesState();
}

class _LiveFramesState extends State<LiveFrames>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, _) => ColoredBox(
      color: Color.lerp(
        const Color(0xff204070),
        const Color(0xff70a0c0),
        animation.value,
      )!,
      child: const Center(child: Text('Live Flutter close reproducer')),
    ),
  );
}
