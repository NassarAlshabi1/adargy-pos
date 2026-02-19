import 'dart:async';

/// A simple guard to prevent rapid or re-entrant taps on sensitive actions.
///
/// - Use [runExclusive] to ignore subsequent presses while the first is running.
/// - Optionally provide a [cooldown] to ignore presses for a short time after completion.
class ClickGuard {
  ClickGuard._();

  static final Map<String, _GuardState> _states = <String, _GuardState>{};

  /// Runs [action] exclusively for the given [key].
  /// If another call with the same key is in progress or within cooldown, it is ignored.
  static Future<void> runExclusive(
    String key,
    FutureOr<void> Function() action, {
    Duration cooldown = const Duration(milliseconds: 400),
  }) async {
    final now = DateTime.now();
    final state = _states[key] ?? _GuardState();

    // If already running or still cooling down, ignore
    if (state.isRunning) return;
    if (state.lastFinishedAt != null &&
        now.difference(state.lastFinishedAt!) < cooldown) {
      return;
    }

    state.isRunning = true;
    _states[key] = state;
    try {
      await action();
    } finally {
      state.isRunning = false;
      state.lastFinishedAt = DateTime.now();
      _states[key] = state;
    }
  }
}

class _GuardState {
  bool isRunning = false;
  DateTime? lastFinishedAt;
}
