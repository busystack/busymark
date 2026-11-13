import 'package:flutter/widgets.dart';

/// The last source accepted by the document, independent of parent rebuilds.
/// Editors advance this base synchronously after each accepted publication.
@immutable
class DocumentEditBase {
  const DocumentEditBase(this.source, this.revision, [this.history]);
  final String source;
  final int? revision;
  final Object? history;

  /// Saves may advance a remote revision without invalidating editor content.
  /// History identity distinguishes that acknowledgement from an ABA traversal.
  /// Closing a group changes history metadata without advancing the revision.
  bool sameDocumentVersion(DocumentEditBase other) =>
      source == other.source &&
      ((revision != null && revision == other.revision) ||
          (history != null && other.history != null
              ? identical(history, other.history)
              : revision == other.revision));

  @override
  bool operator ==(Object other) =>
      other is DocumentEditBase &&
      source == other.source &&
      revision == other.revision &&
      identical(history, other.history);
  @override
  int get hashCode => Object.hash(source, revision, identityHashCode(history));
}

typedef DocumentEditBaseReader = DocumentEditBase? Function();
typedef DocumentUndoClock = Duration Function();

enum DocumentSimpleEditKind { typing, backspace, delete }

/// Text-only diffs cannot locate an edit inside repeated characters. Validate
/// the one-unit operation at the old/new carets before deciding its group.
DocumentSimpleEditKind? documentSimpleEditKind({
  required String before,
  required String after,
  required TextSelection previousSelection,
  required TextSelection selection,
}) {
  if (!previousSelection.isValid ||
      !previousSelection.isCollapsed ||
      !selection.isValid ||
      !selection.isCollapsed) {
    return null;
  }
  final caret = previousSelection.extentOffset;
  final next = selection.extentOffset;
  bool matches(int start, int removed, int inserted) {
    if (start < 0 ||
        start + removed > before.length ||
        start + inserted > after.length) {
      return false;
    }
    final unit = inserted == 1
        ? after.codeUnitAt(start)
        : before.codeUnitAt(start);
    if (unit == 10 || unit == 13) return false;
    for (var i = 0; i < start; i++) {
      if (before.codeUnitAt(i) != after.codeUnitAt(i)) return false;
    }
    for (
      var i = start + removed, j = start + inserted;
      i < before.length;
      i++, j++
    ) {
      if (before.codeUnitAt(i) != after.codeUnitAt(j)) return false;
    }
    return true;
  }

  if (after.length == before.length + 1 &&
      next == caret + 1 &&
      matches(caret, 0, 1)) {
    return DocumentSimpleEditKind.typing;
  }
  if (after.length == before.length - 1) {
    if (next == caret - 1 && matches(caret - 1, 1, 0)) {
      return DocumentSimpleEditKind.backspace;
    }
    if (next == caret && matches(caret, 1, 0)) {
      return DocumentSimpleEditKind.delete;
    }
  }
  return null;
}

/// A short word-sized transaction, bounded independently of inactivity.
/// Stopwatch is monotonic: system clock adjustments cannot prolong a group.
class DocumentUndoGrouping {
  DocumentUndoGrouping({DocumentUndoClock? clock}) : _clock = clock ?? _now;

  static const idleLimit = Duration(seconds: 2);
  static const ageLimit = Duration(seconds: 10);
  static const sizeLimit = 64; // Inserted + removed UTF-16 code units.
  static final _stopwatch = Stopwatch()..start();
  static Duration _now() => _stopwatch.elapsed;
  static var _sessionSequence = 0;
  final _session = ++_sessionSequence;
  final DocumentUndoClock _clock;
  var _sequence = 0;
  String? _group;
  Duration? _started;
  Duration? _last;
  int _size = 0;

  String next({
    required String owner,
    required bool continues,
    required int size,
  }) {
    final now = _clock();
    if (!continues ||
        _group == null ||
        now < _last! ||
        now < _started! ||
        now - _last! >= idleLimit ||
        now - _started! >= ageLimit ||
        _size + size > sizeLimit) {
      _group = '$owner-$_session-${++_sequence}';
      _started = now;
      _size = 0;
    }
    _last = now;
    _size += size;
    return _group!;
  }
}

/// Override Flutter's overridable field-history actions only around document
/// inputs. Exhaustion and disabled operations still consume their action.
class DocumentUndoActions extends StatelessWidget {
  const DocumentUndoActions({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.child,
  });
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      if (onUndo != null)
        UndoTextIntent: CallbackAction<UndoTextIntent>(
          onInvoke: (_) {
            onUndo!();
            return null;
          },
        ),
      if (onRedo != null)
        RedoTextIntent: CallbackAction<RedoTextIntent>(
          onInvoke: (_) {
            onRedo!();
            return null;
          },
        ),
    },
    child: child,
  );
}
