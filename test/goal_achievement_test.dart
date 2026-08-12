import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/goals/goal_achievement.dart';
import 'package:ponvia/domain/models/goal.dart';

void main() {
  final base = DateTime(2026, 1, 1);
  Goal goal(
    double target, {
    double? start,
    DateTime? createdAt,
    DateTime? achievedAt,
    DateTime? promptShownAt,
    int? id,
  }) =>
      Goal(
        id: id,
        targetWeightKg: target,
        startWeightKg: start,
        createdAt: createdAt ?? base,
        achievedAt: achievedAt,
        reachedPromptShownAt: promptShownAt,
      );

  Goal? nearest(double latest, List<Goal> goals, {double? previous}) =>
      GoalAchievement.nearestReached(
        newLatestKg: latest,
        previousLatestKg: previous,
        goals: goals,
      );

  group('lose goals (target < start)', () {
    final g = goal(75, start: 90);

    test('reached exactly at the target boundary', () {
      expect(nearest(75, [g])?.targetWeightKg, 75);
    });

    test('reached when the latest drops past the target', () {
      expect(nearest(74, [g])?.targetWeightKg, 75);
    });

    test('not reached while still above the target', () {
      expect(nearest(75.1, [g]), isNull);
    });
  });

  group('gain goals (target > start)', () {
    final g = goal(85, start: 80);

    test('reached exactly at the target boundary', () {
      expect(nearest(85, [g])?.targetWeightKg, 85);
    });

    test('reached when the latest rises past the target', () {
      expect(nearest(86, [g])?.targetWeightKg, 85);
    });

    test('not reached while still below the target', () {
      expect(nearest(84.9, [g]), isNull);
    });
  });

  test('achieved goals never qualify', () {
    final g = goal(75, start: 90, achievedAt: base);
    expect(nearest(70, [g]), isNull);
  });

  test('a goal already prompted never qualifies again', () {
    final g = goal(75, start: 90, promptShownAt: base);
    expect(nearest(70, [g]), isNull);
  });

  test('direction comes from startWeightKg, not the current weight', () {
    // Gain goal reached; passing a high "previous" must not flip direction.
    final g = goal(85, start: 80);
    expect(nearest(85, [g], previous: 200)?.targetWeightKg, 85);
  });

  group('fallback to previous latest when startWeightKg is null', () {
    test('lose direction inferred from a higher previous weight', () {
      final g = goal(75); // no start captured
      expect(nearest(74, [g], previous: 90)?.targetWeightKg, 75);
    });

    test('gain direction inferred from a lower previous weight', () {
      final g = goal(85); // no start captured
      expect(nearest(86, [g], previous: 80)?.targetWeightKg, 85);
    });

    test('unknown direction (no start, no previous) never fires', () {
      final g = goal(75);
      expect(nearest(74, [g]), isNull);
    });
  });

  group('multiple goals crossed on one save', () {
    // Losing from 90 to 74 clears both a 78 and a 75 target.
    final g78 = goal(78, start: 90, id: 1);
    final g75 = goal(75, start: 90, id: 2);

    test('nearest target to the new weight is chosen for the prompt', () {
      expect(nearest(74, [g78, g75])?.targetWeightKg, 75);
    });

    test('allReached returns every qualifying goal', () {
      final all = GoalAchievement.allReached(
        newLatestKg: 74,
        previousLatestKg: null,
        goals: [g78, g75],
      );
      expect(all.map((g) => g.targetWeightKg).toSet(), {78, 75});
    });

    test('equal-distance ties break toward the more recent goal', () {
      // A lose target above and a gain target below straddle latest 75, both
      // reached and both 3 kg away; the newer goal wins the tie.
      final older = goal(78, start: 90, createdAt: DateTime(2026, 1, 1), id: 1);
      final newer = goal(72, start: 60, createdAt: DateTime(2026, 2, 1), id: 2);
      expect(nearest(75, [older, newer])?.targetWeightKg, 72);
    });
  });

  test('degenerate goal where target equals start never fires', () {
    final g = goal(80, start: 80);
    expect(nearest(80, [g]), isNull);
  });
}
