import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/models/weight_entry.dart';
import 'package:ponvia/domain/range_stats.dart';

void main() {
  WeightEntry entry(double kg, DateTime at) =>
      WeightEntry(timestamp: at, weightKg: kg);

  test('empty list returns null', () {
    expect(computeRangeStats(const []), isNull);
  });

  test('single entry: min = max = avg = value, net = 0', () {
    final stats = computeRangeStats([entry(82.4, DateTime(2026, 8, 1))])!;
    expect(stats.minKg, 82.4);
    expect(stats.maxKg, 82.4);
    expect(stats.avgKg, 82.4);
    expect(stats.netKg, 0);
    expect(stats.count, 1);
  });

  test('typical set: correct min/max/avg and net = latest - earliest', () {
    // Deliberately unordered input to prove order-independence.
    final entries = [
      entry(81.0, DateTime(2026, 8, 3)),
      entry(83.0, DateTime(2026, 8, 1)), // earliest
      entry(80.0, DateTime(2026, 8, 5)), // latest
      entry(82.0, DateTime(2026, 8, 2)),
    ];
    final stats = computeRangeStats(entries)!;
    expect(stats.minKg, 80.0);
    expect(stats.maxKg, 83.0);
    expect(stats.avgKg, closeTo((81.0 + 83.0 + 80.0 + 82.0) / 4, 1e-9));
    expect(stats.netKg, closeTo(80.0 - 83.0, 1e-9)); // -3.0, ended lighter
    expect(stats.count, 4);
  });

  test('net is positive when the period ended heavier', () {
    final entries = [
      entry(70.0, DateTime(2026, 1, 1)), // earliest
      entry(72.5, DateTime(2026, 1, 10)), // latest
    ];
    expect(computeRangeStats(entries)!.netKg, closeTo(2.5, 1e-9));
  });
}
