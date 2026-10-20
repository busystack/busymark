import 'dart:io';

import 'package:path/path.dart' as p;

/// The desktop's actual home, including the original home in a Snap sandbox.
String? get userHomeDirectory {
  for (final key in ['SNAP_REAL_HOME', 'HOME', 'USERPROFILE']) {
    final value = Platform.environment[key];
    if (value != null && value.isNotEmpty && p.isAbsolute(value)) {
      return p.normalize(value);
    }
  }
  return null;
}
