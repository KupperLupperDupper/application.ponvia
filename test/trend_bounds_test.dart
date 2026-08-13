import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/features/history/trend_bounds.dart';

void main() {
  // Data spans 80–90; a 15% pad (of the 10-wide range) = 1.5 on each end, giving
  // a raw 78.5–91.5 window that then rounds outward to nice multiples of the step.
  final values = [80.0, 85.0, 90.0];

  test('no target — bounds pad the range then round outward to nice steps', () {
    final b = TrendBounds.of(values);
    // raw 78.5..91.5 (range 13) → step 5 → 75..95.
    expect(b.interval, closeTo(5.0, 1e-9));
    expect(b.minY, closeTo(75.0, 1e-9));
    expect(b.maxY, closeTo(95.0, 1e-9));
    expect(b.decimals, 0);
  });

  test('target inside the data range leaves the bounds unchanged', () {
    final withTarget = TrendBounds.of(values, target: 85.0);
    final without = TrendBounds.of(values);
    expect(withTarget.minY, closeTo(without.minY, 1e-9));
    expect(withTarget.maxY, closeTo(without.maxY, 1e-9));
  });

  test('target above the data range grows maxY so the line is visible', () {
    final b = TrendBounds.of(values, target: 100.0);
    // range becomes 80..100 (pad 3 → 77..103, step 10) → 70..110.
    expect(b.maxY, closeTo(110.0, 1e-9));
    expect(b.maxY, greaterThan(100.0)); // headroom above the marker
    expect(b.minY, closeTo(70.0, 1e-9));
  });

  test('target below the data range shrinks minY so the line is visible', () {
    final b = TrendBounds.of(values, target: 70.0);
    // range becomes 70..90 (pad 3 → 67..93, step 10) → 60..100.
    expect(b.minY, closeTo(60.0, 1e-9));
    expect(b.minY, lessThan(70.0)); // room below the marker
    expect(b.maxY, closeTo(100.0, 1e-9));
  });

  test('flat data still yields a non-zero interval and 1-decimal labels', () {
    final b = TrendBounds.of([82.0, 82.0]);
    expect(b.maxY - b.minY, greaterThan(0));
    expect(b.interval, greaterThan(0));
    expect(b.decimals, 1);
  });

  test('min/max land on interval multiples so edge labels never crowd a tick', () {
    // The anti-overlap invariant: because fl_chart also emits labels at minY and
    // maxY, those must coincide with tick positions or they collide with the
    // nearest tick. A few varied datasets, including fractional steps.
    for (final sample in [
      [80.0, 85.0, 90.0],
      [70.4, 71.1, 70.8, 71.9],
      [82.0, 82.3],
      [55.0, 120.0],
    ]) {
      final b = TrendBounds.of(sample);
      final minTicks = b.minY / b.interval;
      final maxTicks = b.maxY / b.interval;
      expect(minTicks, closeTo(minTicks.roundToDouble(), 1e-6),
          reason: 'minY $b not a multiple of the step');
      expect(maxTicks, closeTo(maxTicks.roundToDouble(), 1e-6),
          reason: 'maxY $b not a multiple of the step');
    }
  });
}
