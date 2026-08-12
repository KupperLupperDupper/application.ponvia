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
  factory TrendBounds.of(List<double> values, {double? target}) {
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (target != null) {
      if (target < minV) minV = target;
      if (target > maxV) maxV = target;
    }
    final pad = ((maxV - minV) * 0.15).clamp(0.5, double.infinity);
    final minY = minV - pad;
    final maxY = maxV + pad;
    final range = maxY - minY;
    return TrendBounds(
      minY: minY,
      maxY: maxY,
      interval: range <= 0 ? 1.0 : range / 4,
      decimals: range < 4 ? 1 : 0,
    );
  }
}
