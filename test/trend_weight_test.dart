import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/trend_weight.dart';

void main() {
  test('empty input yields an empty series', () {
    expect(TrendWeight.ema(const []), isEmpty);
  });

  test('single value passes through unchanged (seeds the trend)', () {
    expect(TrendWeight.ema(const [82.4]), [82.4]);
  });

  test('output length always matches input length', () {
    expect(TrendWeight.ema(const [80, 81, 79, 82, 80]).length, 5);
  });

  test('first element seeds at the first value regardless of alpha', () {
    expect(TrendWeight.ema(const [70, 90], alpha: 0.5).first, 70);
    expect(TrendWeight.ema(const [70, 90], alpha: 0.1).first, 70);
  });

  test('a constant series stays constant', () {
    expect(TrendWeight.ema(const [75, 75, 75, 75]), [75, 75, 75, 75]);
  });

  test('applies the EMA recurrence with the given alpha', () {
    // trend[i] = trend[i-1] + a*(x[i]-trend[i-1]); seed = 80.
    final out = TrendWeight.ema(const [80, 90, 70], alpha: 0.5);
    expect(out[0], closeTo(80, 1e-9));
    expect(out[1], closeTo(85, 1e-9)); // 80 + .5*(90-80)
    expect(out[2], closeTo(77.5, 1e-9)); // 85 + .5*(70-85)
  });

  test('default smoothing lags a step change (calm, not instant)', () {
    // Step from 80 to 90; with alpha 0.1 the trend barely moves on the first
    // reading — daily noise should not swing the line.
    final out = TrendWeight.ema(const [80, 90], alpha: TrendWeight.defaultSmoothing);
    expect(out[1], closeTo(81.0, 1e-9)); // 80 + .1*10
    expect(out[1], lessThan(90));
  });

  test('a lower alpha lags more than a higher one', () {
    const xs = [80.0, 90.0, 90.0, 90.0];
    final calm = TrendWeight.ema(xs, alpha: 0.1);
    final quick = TrendWeight.ema(xs, alpha: 0.3);
    for (var i = 1; i < xs.length; i++) {
      expect(calm[i], lessThan(quick[i]));
    }
  });

  test('the trend never leaves the [min, max] range of the inputs', () {
    const xs = [80.0, 95.0, 60.0, 88.0, 72.0];
    final out = TrendWeight.ema(xs);
    final lo = xs.reduce((a, b) => a < b ? a : b);
    final hi = xs.reduce((a, b) => a > b ? a : b);
    for (final v in out) {
      expect(v, inInclusiveRange(lo, hi));
    }
  });

  test('converges toward a sustained new level', () {
    // 30 readings at 70 after starting at 80 → trend approaches 70.
    final xs = [80.0, for (var i = 0; i < 30; i++) 70.0];
    final out = TrendWeight.ema(xs);
    expect(out.last, closeTo(70, 0.5));
  });

  test('alpha is clamped to (0, 1] (alpha >= 1 tracks the raw values)', () {
    expect(TrendWeight.ema(const [80, 90, 70], alpha: 1.0), [80, 90, 70]);
    // Out-of-range alpha clamps rather than throwing.
    expect(TrendWeight.ema(const [80, 90], alpha: 5.0), [80, 90]);
    expect(TrendWeight.ema(const [80, 90], alpha: 0.0).first, 80);
  });

  test('smoothing commutes with a multiplicative unit conversion', () {
    // EMA(kg)*factor == EMA(kg*factor) — the property that lets callers smooth
    // in canonical kg and convert the result for display.
    const kg = [80.0, 82.0, 79.5, 81.0];
    const factor = 2.2046226218; // kg → lb
    final trendKg = TrendWeight.ema(kg);
    final trendLb = TrendWeight.ema([for (final v in kg) v * factor]);
    for (var i = 0; i < kg.length; i++) {
      expect(trendLb[i], closeTo(trendKg[i] * factor, 1e-6));
    }
  });
}
