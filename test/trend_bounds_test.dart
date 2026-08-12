import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/features/history/trend_bounds.dart';

void main() {
  // Data spans 80–90; a 15% pad (of the 10-wide range) = 1.5 on each end.
  final values = [80.0, 85.0, 90.0];

  test('no target — bounds pad the data range and ignore any goal', () {
    final b = TrendBounds.of(values);
    expect(b.minY, closeTo(78.5, 1e-9));
    expect(b.maxY, closeTo(91.5, 1e-9));
  });

  test('target inside the data range leaves the bounds unchanged', () {
    final withTarget = TrendBounds.of(values, target: 85.0);
    final without = TrendBounds.of(values);
    expect(withTarget.minY, closeTo(without.minY, 1e-9));
    expect(withTarget.maxY, closeTo(without.maxY, 1e-9));
  });

  test('target above the data range grows maxY so the line is visible', () {
    final b = TrendBounds.of(values, target: 100.0);
    // range becomes 80..100 (20 wide), pad = 3.
    expect(b.maxY, closeTo(103.0, 1e-9));
    expect(b.maxY, greaterThan(100.0)); // headroom above the marker
    expect(b.minY, closeTo(77.0, 1e-9));
  });

  test('target below the data range shrinks minY so the line is visible', () {
    final b = TrendBounds.of(values, target: 70.0);
    // range becomes 70..90 (20 wide), pad = 3.
    expect(b.minY, closeTo(67.0, 1e-9));
    expect(b.minY, lessThan(70.0)); // room below the marker
    expect(b.maxY, closeTo(93.0, 1e-9));
  });

  test('flat data still yields a non-zero interval and 1-decimal labels', () {
    final b = TrendBounds.of([82.0, 82.0]);
    expect(b.maxY - b.minY, greaterThan(0));
    expect(b.interval, greaterThan(0));
    expect(b.decimals, 1);
  });
}
