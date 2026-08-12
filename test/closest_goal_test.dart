import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/goals/closest_goal.dart';
import 'package:ponvia/domain/models/goal.dart';

void main() {
  final base = DateTime(2026, 1, 1);
  Goal goal(double target,
          {DateTime? createdAt,
          DateTime? achievedAt,
          bool highlightOverride = false}) =>
      Goal(
        targetWeightKg: target,
        createdAt: createdAt ?? base,
        achievedAt: achievedAt,
        highlightOverride: highlightOverride,
      );

  test('suppressed when there is no current weight', () {
    expect(ClosestGoal.select([goal(70)], null), isNull);
  });

  test('suppressed when no active goals remain', () {
    expect(ClosestGoal.select([goal(70, achievedAt: base)], 80), isNull);
  });

  test('selects the goal closest to the current weight', () {
    final goals = [goal(70), goal(78), goal(90)];
    expect(ClosestGoal.select(goals, 80)!.targetWeightKg, 78);
  });

  test('ties break toward the most recently created goal', () {
    final older = goal(75, createdAt: DateTime(2026, 1, 1)); // 5 kg away
    final newer = goal(85, createdAt: DateTime(2026, 2, 1)); // 5 kg away
    expect(ClosestGoal.select([older, newer], 80)!.targetWeightKg, 85);
  });

  test('ignores achieved goals when a closer active one exists', () {
    final goals = [goal(79, achievedAt: base), goal(78)];
    expect(ClosestGoal.select(goals, 80)!.targetWeightKg, 78);
  });

  test('a pinned goal overrides the distance-based choice', () {
    final goals = [goal(78), goal(90, highlightOverride: true)];
    expect(ClosestGoal.select(goals, 80)!.targetWeightKg, 90);
  });

  test('a pinned goal is highlighted even without a current weight', () {
    expect(
      ClosestGoal.select([goal(90, highlightOverride: true)], null)
          ?.targetWeightKg,
      90,
    );
  });

  test('an achieved pinned goal does not win', () {
    final goals = [
      goal(78),
      goal(90, achievedAt: base, highlightOverride: true),
    ];
    expect(ClosestGoal.select(goals, 80)!.targetWeightKg, 78);
  });

  test('among multiple pins the most recently created wins', () {
    final older =
        goal(70, createdAt: DateTime(2026, 1, 1), highlightOverride: true);
    final newer =
        goal(95, createdAt: DateTime(2026, 2, 1), highlightOverride: true);
    expect(ClosestGoal.select([older, newer], 80)!.targetWeightKg, 95);
  });
}
