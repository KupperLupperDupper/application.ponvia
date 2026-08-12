import '../models/goal.dart';

/// Detects when the latest weight has reached a goal's target, so the app can
/// offer the calm "you reached it" moment. Pure — no Flutter or DB imports.
///
/// A goal qualifies when it is still active (`achievedAt == null`), has not been
/// prompted yet (`reachedPromptShownAt == null`), and the new latest weight sits
/// at or beyond the target in the goal's direction:
/// - **lose** (`target < start`): reached when `latest <= target`
/// - **gain** (`target > start`): reached when `latest >= target`
///
/// Direction is anchored to the goal's [Goal.startWeightKg]. For goals created
/// before that was captured it falls back to [previousLatestKg] (the weight just
/// before this update). This is a state check, not a crossing check: an already
/// past-target goal that was never prompted still qualifies once.
class GoalAchievement {
  const GoalAchievement._();

  /// Every qualifying goal for this save (the nearest one is prompted; the rest
  /// are marked silently reachable by the caller).
  static List<Goal> allReached({
    required double newLatestKg,
    double? previousLatestKg,
    required List<Goal> goals,
  }) =>
      goals
          .where((g) => _qualifies(g, newLatestKg, previousLatestKg))
          .toList();

  /// The single goal to prompt: among the qualifying goals, the one whose
  /// target is nearest the new weight (ties break toward the most recent goal).
  /// Null when none qualify.
  static Goal? nearestReached({
    required double newLatestKg,
    double? previousLatestKg,
    required List<Goal> goals,
  }) {
    final reached = allReached(
      newLatestKg: newLatestKg,
      previousLatestKg: previousLatestKg,
      goals: goals,
    );
    if (reached.isEmpty) return null;
    reached.sort((a, b) {
      final byNear = (a.targetWeightKg - newLatestKg)
          .abs()
          .compareTo((b.targetWeightKg - newLatestKg).abs());
      if (byNear != 0) return byNear;
      return b.createdAt.compareTo(a.createdAt);
    });
    return reached.first;
  }

  static bool _qualifies(Goal g, double newLatest, double? previous) {
    if (g.isAchieved || g.reachedPromptShownAt != null) return false;
    final direction = _direction(g, previous);
    if (direction == 0) return false;
    return direction < 0
        ? newLatest <= g.targetWeightKg // lose goal
        : newLatest >= g.targetWeightKg; // gain goal
  }

  /// -1 lose (approached from above), +1 gain (from below), 0 unknown.
  static int _direction(Goal g, double? previous) {
    final start = g.startWeightKg ?? previous;
    if (start == null) return 0;
    if (g.targetWeightKg < start) return -1;
    if (g.targetWeightKg > start) return 1;
    return 0;
  }
}
