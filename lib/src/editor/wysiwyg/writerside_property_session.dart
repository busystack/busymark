import 'package:flutter/foundation.dart';

enum WritersidePropertyRejection { invalid, readOnly, stale, unresolved }

/// Pending text belongs to a captured target, independently of field widgets.
/// Transitions explicitly flush this session; disposal never publishes edits.
class WritersidePropertySession extends ChangeNotifier {
  final Map<String, WritersidePropertyDraft> _drafts = {};
  WritersidePropertyRejection rejection = WritersidePropertyRejection.invalid;
  String? detail;
  WritersidePropertyRejection? feedback;
  bool _processing = false;

  bool get hasPending => _drafts.values.any((d) => d.pending);
  Iterable<WritersidePropertyDraft> get drafts => _drafts.values;

  WritersidePropertyDraft bind(
    String key,
    String value,
    bool Function(String) apply,
  ) {
    final draft = _drafts.putIfAbsent(
      key,
      () => WritersidePropertyDraft(value, apply),
    );
    if (!draft.pending) {
      draft.committed = value;
      draft.text = value;
      draft.apply = apply;
      draft.error = null;
      draft.detail = null;
    }
    return draft;
  }

  void edit(WritersidePropertyDraft draft, String text) {
    draft.text = text;
    draft.error = null;
    draft.detail = null;
  }

  void revert(WritersidePropertyDraft draft) {
    draft.text = draft.committed;
    draft.error = null;
    draft.detail = null;
    feedback = null;
    notifyListeners();
  }

  void revertAll() {
    for (final draft in _drafts.values) {
      draft.text = draft.committed;
      draft.error = null;
      draft.detail = null;
    }
    notifyListeners();
  }

  bool reject(WritersidePropertyRejection reason, [String? explanation]) {
    rejection = reason;
    detail = explanation;
    feedback = reason;
    notifyListeners();
    return false;
  }

  bool commit(WritersidePropertyDraft draft) {
    if (!draft.pending) return true;
    rejection = WritersidePropertyRejection.invalid;
    detail = null;
    if (!draft.apply(draft.text)) {
      draft.error = rejection;
      draft.detail = detail;
      notifyListeners();
      return false;
    }
    draft.committed = draft.text;
    draft.error = null;
    draft.detail = null;
    feedback = null;
    notifyListeners();
    return true;
  }

  bool flush() {
    if (_processing) return true;
    _processing = true;
    try {
      for (final draft in _drafts.values.toList()) {
        if (!commit(draft)) return false;
      }
      return true;
    } finally {
      _processing = false;
    }
  }

  /// Only a successfully processed transition can retire old field bindings.
  bool transition() {
    if (!flush()) return false;
    _drafts.clear();
    feedback = null;
    return true;
  }
}

class WritersidePropertyDraft {
  WritersidePropertyDraft(this.committed, this.apply) : text = committed;
  String committed;
  String text;
  bool Function(String) apply;
  WritersidePropertyRejection? error;
  String? detail;
  bool get pending => text != committed;
}
