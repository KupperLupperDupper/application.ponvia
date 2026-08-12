import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/goal_projection.dart';
import 'package:ponvia/domain/models/weight_entry.dart';

void main() {
  // Fixed reference clock so tests are deterministic.
  final base = DateTime(2026, 1, 1, 8);
  DateTime at(int day) => base.add(Duration(days: day));

  /// Builds daily entries for days [0, count) using [kgForDay]. Newest last —
  /// projectGoalEta sorts internally, so order here doesn't matter.
  List<WeightEntry> series(int count, double Function(int day) kgForDay) => [
        for (var d = 0; d < count; d++)
          WeightEntry(timestamp: at(d), weightKg: kgForDay(d)),
      ];

  group('projectGoalEta — happy paths', () {
    test('steady loss toward target projects a plausible date', () {
      // 90 kg losing 0.1 kg/day; target 85 kg. now = last entry (day 29).
      final entries = series(30, (d) => 90.0 - 0.1 * d);
      final p = projectGoalEta(entries, 85.0, now: at(29));

      expect(p.outcome, ProjectionOutcome.projected);
      expect(p.slopeKgPerDay, closeTo(-0.1, 1e-9));
      // fittedNow = 87.1, remaining = -2.1, days = 21 → ~day 50.
      expect(p.etaDate!.difference(at(50)).inDays.abs(), lessThanOrEqualTo(1));
    });

    test('gain goal while gaining projects a date', () {
      final entries = series(30, (d) => 70.0 + 0.08 * d);
      final p = projectGoalEta(entries, 73.0, now: at(29));

      expect(p.outcome, ProjectionOutcome.projected);
      expect(p.slopeKgPerDay, greaterThan(0));
      expect(p.etaDate!.isAfter(at(29)), isTrue);
    });
  });

  group('projectGoalEta — guards suppress the date', () {
    test('empty entries → notEnoughData', () {
      expect(projectGoalEta(const [], 80.0).outcome,
          ProjectionOutcome.notEnoughData);
    });

    test('too few entries → notEnoughData', () {
      final entries = series(3, (d) => 90.0 - 0.1 * d);
      expect(projectGoalEta(entries, 85.0, now: at(2)).outcome,
          ProjectionOutcome.notEnoughData);
    });

    test('span shorter than the minimum → notEnoughData', () {
      // 5 entries (enough count) but only spanning 8 days (< 14-day minimum).
      final short = [
        for (var d = 0; d < 5; d++)
          WeightEntry(timestamp: at(d * 2), weightKg: 90.0 - 0.2 * d),
      ];
      expect(projectGoalEta(short, 85.0, now: at(8)).outcome,
          ProjectionOutcome.notEnoughData);
    });

    test('flat trend → trendFlat', () {
      final entries = series(30, (_) => 84.0);
      expect(projectGoalEta(entries, 80.0, now: at(29)).outcome,
          ProjectionOutcome.trendFlat);
    });

    test('trend moving away from target → movingAway', () {
      // Target below current, but weight is climbing.
      final entries = series(30, (d) => 84.0 + 0.1 * d);
      expect(projectGoalEta(entries, 80.0, now: at(29)).outcome,
          ProjectionOutcome.movingAway);
    });

    test('noisy scatter toward target → tooNoisy', () {
      // Slight downward drift buried under ±2 kg alternating noise.
      final entries = series(
          20, (d) => 90.0 - 0.05 * d + (d.isEven ? 2.0 : -2.0));
      final p = projectGoalEta(entries, 85.0, now: at(19));
      expect(p.outcome, ProjectionOutcome.tooNoisy);
    });

    test('already at the target → targetReached', () {
      // Declines to exactly 85 at the last entry; target 85.
      final entries = series(30, (d) => 85.0 + 0.1 * (29 - d));
      expect(projectGoalEta(entries, 85.0, now: at(29)).outcome,
          ProjectionOutcome.targetReached);
    });

    test('valid but absurdly slow pace → tooFar', () {
      // Losing 0.01 kg/day; ~10 kg to go ⇒ ~1000 days > 2-year horizon.
      final entries = series(30, (d) => 90.0 - 0.01 * d);
      final p = projectGoalEta(entries, 80.0, now: at(29));
      expect(p.outcome, ProjectionOutcome.tooFar);
    });
  });

  test('entries outside the window are ignored', () {
    // A stale cluster 200 days ago plus a fresh 30-day steady loss.
    final stale = [
      for (var d = 0; d < 5; d++)
        WeightEntry(timestamp: at(-200 + d), weightKg: 120.0),
    ];
    final fresh = series(30, (d) => 90.0 - 0.1 * d);
    final p = projectGoalEta([...stale, ...fresh], 85.0, now: at(29));
    expect(p.outcome, ProjectionOutcome.projected);
    expect(p.slopeKgPerDay, closeTo(-0.1, 1e-9));
  });
}
