import '../models/goal.dart';

/// Selects the goal whose target is closest to the current weight — the one the
/// Home screen highlights.
class ClosestGoal {
  const ClosestGoal._();

  /// Returns the highlighted goal.
  ///
  /// A goal manually pinned via "Highlight on Home" ([Goal.highlightOverride])
  /// always wins — even before a first weight is logged — with ties broken
  /// toward the more recently created pin. Otherwise this returns the
  /// non-achieved goal minimizing `|target - current|`, ties breaking toward the
  /// more recently created goal. Returns `null` when there are no active goals,
  /// or (absent a pin) when there is no current weight yet.
  static Goal? select(List<Goal> goals, double? currentKg) {
    final active = goals.where((g) => !g.isAchieved).toList();
    if (active.isEmpty) return null;

    final pinned = active.where((g) => g.highlightOverride).toList();
    if (pinned.isNotEmpty) {
      pinned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pinned.first;
    }

    if (currentKg == null) return null;

    active.sort((a, b) {
      final da = (a.targetWeightKg - currentKg).abs();
      final db = (b.targetWeightKg - currentKg).abs();
      final byDistance = da.compareTo(db);
      if (byDistance != 0) return byDistance;
      return b.createdAt.compareTo(a.createdAt); // most recent first
    });
    return active.first;
  }
}
