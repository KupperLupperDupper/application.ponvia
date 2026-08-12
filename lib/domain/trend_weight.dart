/// Trend weight — an exponential moving average (EMA) that smooths day-to-day
/// noise so a single heavy or light reading doesn't read as failure. It is the
/// calm-tracker signature: the raw line shows what the scale said, the trend
/// line shows where the body is actually going.
///
/// The default smoothing factor [defaultSmoothing] = `0.1` follows the
/// "Hacker's Diet" / TrendWeight convention: each reading pulls the trend 10%
/// of the way toward itself, i.e. a ~10-reading half-life
/// (`ln(0.5) / ln(1 - 0.1) ≈ 6.6` readings to close half the gap). Smoothing is
/// applied per-entry in chronological order — the app's charts already connect
/// irregularly spaced points index-by-index, so the trend aligns 1:1 with the
/// raw series and shares its x-coordinates.
///
/// Pure Dart — no Flutter or database imports (unit-tested in isolation). The
/// canonical unit is kilograms, but the maths is unit-agnostic: because the
/// kg→lb→st conversions are purely multiplicative, smoothing in kg then
/// converting equals converting then smoothing. Callers therefore smooth the
/// canonical kg values and convert the result for display like any other point.
class TrendWeight {
  const TrendWeight._();

  /// Default EMA smoothing factor (`alpha`). Lower = calmer/laggier.
  static const double defaultSmoothing = 0.1;

  /// Rendering hint: below this many readings the smoothed line sits almost on
  /// top of the raw line, adding clutter without insight, so the charts omit
  /// the trend overlay entirely. Not used by [ema] itself.
  static const int minRenderPoints = 4;

  /// EMA of [values], which must be in chronological (oldest → newest) order.
  ///
  /// Returns a new list of the same length. The first element seeds the trend
  /// at the first value; each subsequent element is
  /// `trend[i] = trend[i-1] + alpha * (values[i] - trend[i-1])`.
  ///
  /// [alpha] is clamped to `(0, 1]`. An empty input returns an empty list; a
  /// single value returns `[value]`. Because every output is a convex blend of
  /// inputs, the trend never leaves the `[min, max]` range of [values].
  static List<double> ema(
    List<double> values, {
    double alpha = defaultSmoothing,
  }) {
    if (values.isEmpty) return const <double>[];
    final a = alpha.clamp(1e-6, 1.0);
    final out = List<double>.filled(values.length, 0);
    var trend = values.first;
    out[0] = trend;
    for (var i = 1; i < values.length; i++) {
      trend += a * (values[i] - trend);
      out[i] = trend;
    }
    return out;
  }
}
