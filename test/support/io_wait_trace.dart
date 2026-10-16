import 'dart:convert';
import 'dart:io';

/// Opt-in correlation with an external syscall trace. These timestamps describe
/// test operations, not display presentation or performance acceptance.
void traceTestIo(String operation, String phase, [String? detail]) {
  if (Platform.environment['BUSYMARK_TEST_IO_TRACE'] != '1') return;
  stderr.writeln(
    'BUSYMARK_TEST_IO ${jsonEncode({'pid': pid, 'wallUs': DateTime.now().microsecondsSinceEpoch, 'operation': operation, 'phase': phase, if (detail != null) 'detail': detail})}',
  );
}

class TestIoWaitTrace {
  TestIoWaitTrace(this.operation)
    : startUs = DateTime.now().microsecondsSinceEpoch {
    traceTestIo(operation, 'begin', 'startUs=$startUs');
  }

  final String operation;
  final int startUs;
  final Stopwatch _elapsed = Stopwatch()..start();

  String get description =>
      'pid=$pid, waitStartUs=$startUs, '
      'waitEndUs=${DateTime.now().microsecondsSinceEpoch}, '
      'elapsedUs=${_elapsed.elapsedMicroseconds}';

  void finish(bool completed) => traceTestIo(
    operation,
    completed ? 'complete' : 'incomplete',
    description,
  );
}
