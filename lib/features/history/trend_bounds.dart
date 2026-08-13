import 'dart:math' as math;

/// Pure y-axis math for the History trend chart. Kept out of the widget so the
/// range logic — including folding a goal target into view — is unit-testable.
class TrendBounds {
  const TrendBounds({
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.decimals,
  });

  final double minY;
  final double maxY;
  final double interval;
  final int decimals;

  /// Bounds for [values] (non-empty, display-unit weights). When [target] is
  /// non-null it is folded into the range first, so a goal marker line at that
  /// value is always visible; then a 15% pad (min 0.5) is applied on both ends.
  ///
  /// The interval is snapped to a "nice" step (1/2/2.5/5 × 10ⁿ) and [minY] /
  /// [maxY] are rounded outward to whole multiples of it. This makes the axis
  /// labels round numbers AND aligns the chart's min/max with tick positions,
  /// so fl_chart no longer draws a stray edge label next to the nearest tick
  /// (which is what made the old, unrounded bounds overlap).
  factory TrendBounds.of(List<double> values, {double? target}) {
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (target != null) {
      if (target < minV) minV = target;
      if (target > maxV) maxV = target;
    }
    final pad = ((maxV - minV) * 0.15).clamp(0.5, double.infinity);
    final lo = minV - pad;
    final hi = maxV + pad;
    final rawRange = hi - lo;
    final interval = _niceInterval(rawRange <= 0 ? 1.0 : rawRange / 4);
    final minY = (lo / interval).floorToDouble() * interval;
    final maxY = (hi / interval).ceilToDouble() * interval;
    // A fractional step (0.5, 2.5, …) needs one decimal to render its labels;
    // a whole step yields whole-number labels.
    final decimals = interval == interval.roundToDouble() ? 0 : 1;
    return TrendBounds(
      minY: minY,
      maxY: maxY,
      interval: interval,
      decimals: decimals,
    );
  }

  /// Rounds [raw] up to the nearest 1, 2, 2.5 or 5 times a power of ten.
  static double _niceInterval(double raw) {
    if (raw <= 0) return 1.0;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final normalized = raw / magnitude; // [1, 10)
    final double niceNorm;
    if (normalized <= 1) {
      niceNorm = 1;
    } else if (normalized <= 2) {
      niceNorm = 2;
    } else if (normalized <= 2.5) {
      niceNorm = 2.5;
    } else if (normalized <= 5) {
      niceNorm = 5;
    } else {
      niceNorm = 10;
    }
    return niceNorm * magnitude;
  }
}
