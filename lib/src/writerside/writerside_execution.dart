import 'dart:async';

import 'package:flutter/foundation.dart';

/// Coarse jobs carry explicit sendable input and a top-level entry point.
/// Platform services and controller graphs never travel with a job.
class WritersideExecution {
  const WritersideExecution({this.useWorker = true});
  final bool useWorker;

  Future<R> run<Q, R>(ComputeCallback<Q, R> entry, Q input) => useWorker
      ? compute(entry, input, debugLabel: 'Writerside model')
      : Future<R>.sync(() => entry(input));
}
