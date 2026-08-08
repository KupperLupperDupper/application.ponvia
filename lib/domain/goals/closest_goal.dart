import '../models/goal.dart';

/// Selects the goal whose target is closest to the current weight — the one the
/// Home screen highlights.
class ClosestGoal {
  const ClosestGoal._();

  /// Returns the non-achieved goal minimizing `|target - current|`.
  ///
  /// Ties break toward the more recently created goal. Returns `null` when there
  /// is no current weight yet or no active goals (highlighting is suppressed).
  static Goal? select(List<Goal> goals, double? currentKg) {
    if (currentKg == null) return null;
    final active = goals.where((g) => !g.isAchieved).toList();
    if (active.isEmpty) return null;

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
