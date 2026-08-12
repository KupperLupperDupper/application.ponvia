import 'dart:math' as math;

import 'models/weight_entry.dart';

/// Why an ETA is or isn't shown. Only [projected] carries a date; every other
/// outcome means "suppress the ETA" — we never render a misleading date.
enum ProjectionOutcome {
  /// A trustworthy ETA was computed ([GoalProjection.etaDate] is non-null).
  projected,

  /// Too few points, or too short a span, to trust a slope.
  notEnoughData,

  /// The trend is essentially flat — no meaningful pace toward anything.
  trendFlat,

  /// The recent trend moves away from the target, not toward it.
  movingAway,

  /// The points scatter too much around the line to trust the slope.
  tooNoisy,

  /// Already at (or past) the target — nothing left to project.
  targetReached,

  /// A valid pace, but the ETA lands absurdly far out; not worth showing.
  tooFar,
}

/// Result of [projectGoalEta]: an outcome plus, when [outcome] is
/// [ProjectionOutcome.projected], the estimated date the target is reached.
class GoalProjection {
  const GoalProjection(this.outcome, {this.etaDate, this.slopeKgPerDay = 0});

  final ProjectionOutcome outcome;

  /// Estimated calendar date the target is reached; null unless [outcome] is
  /// [ProjectionOutcome.projected].
  final DateTime? etaDate;

  /// Fitted slope in kg/day (negative = losing). Exposed for tests/debug.
  final double slopeKgPerDay;

  bool get hasEta => outcome == ProjectionOutcome.projected && etaDate != null;
}

/// Estimates when [targetKg] will be reached from recent weighing pace.
///
/// Runs a least-squares linear regression of weight (kg) against time over a
/// trailing [windowDays] window, then extrapolates the fitted line to the
/// target. The regression itself is the smoothing step, so raw entries are fine
/// (no separate trend series required).
///
/// Deliberately conservative: it returns a non-[ProjectionOutcome.projected]
/// outcome — and no date — whenever the data is too sparse, too flat, too
/// noisy, or heading the wrong way. Callers render nothing in those cases.
///
/// [entries] may be in any order (Ponvia's providers are newest-first); only
/// entries within [windowDays] of the most recent one are used.
GoalProjection projectGoalEta(
  List<WeightEntry> entries,
  double targetKg, {
  DateTime? now,
  int windowDays = kProjectionWindowDays,
}) {
  if (entries.isEmpty) {
    return const GoalProjection(ProjectionOutcome.notEnoughData);
  }

  // Sort oldest→newest so time is monotonically increasing.
  final sorted = [...entries]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Window is measured back from the newest entry (not `now`), so a projection
  // still appears if the user opens the app a few days after weighing.
  final newest = sorted.last.timestamp;
  final cutoff = newest.subtract(Duration(days: windowDays));
  final window =
      sorted.where((e) => !e.timestamp.isBefore(cutoff)).toList(growable: false);

  if (window.length < kProjectionMinEntries) {
    return const GoalProjection(ProjectionOutcome.notEnoughData);
  }

  // Time axis in fractional days relative to the first windowed entry.
  final t0 = window.first.timestamp;
  final xs = <double>[];
  final ys = <double>[];
  for (final e in window) {
    xs.add(e.timestamp.difference(t0).inMinutes / _minutesPerDay);
    ys.add(e.weightKg);
  }

  final spanDays = xs.last - xs.first;
  if (spanDays < kProjectionMinSpanDays) {
    return const GoalProjection(ProjectionOutcome.notEnoughData);
  }

  final fit = _linearFit(xs, ys);
  final slope = fit.slope; // kg/day
  final now0 = now ?? newest;

  // Where the trend line sits *now* — denoised reference, not the last raw point.
  final nowX = now0.difference(t0).inMinutes / _minutesPerDay;
  final fittedNow = fit.intercept + slope * nowX;
  final remaining = targetKg - fittedNow; // signed: >0 must gain, <0 must lose

  if (remaining.abs() < kProjectionReachedKg) {
    return GoalProjection(ProjectionOutcome.targetReached,
        slopeKgPerDay: slope);
  }
  if (slope.abs() < kProjectionFlatSlopeKgPerDay) {
    return GoalProjection(ProjectionOutcome.trendFlat, slopeKgPerDay: slope);
  }
  // Slope and remaining must share a sign — trend heading toward the target.
  if (slope.sign != remaining.sign) {
    return GoalProjection(ProjectionOutcome.movingAway, slopeKgPerDay: slope);
  }
  if (fit.rSquared < kProjectionMinRSquared) {
    return GoalProjection(ProjectionOutcome.tooNoisy, slopeKgPerDay: slope);
  }

  final daysToTarget = remaining / slope; // > 0 by the sign check above
  if (daysToTarget > kProjectionMaxHorizonDays) {
    return GoalProjection(ProjectionOutcome.tooFar, slopeKgPerDay: slope);
  }

  final eta = now0.add(Duration(minutes: (daysToTarget * _minutesPerDay).round()));
  return GoalProjection(ProjectionOutcome.projected,
      etaDate: eta, slopeKgPerDay: slope);
}

/// Trailing window used for the pace estimate.
const int kProjectionWindowDays = 30;

/// Minimum weigh-ins within the window to attempt a projection.
const int kProjectionMinEntries = 4;

/// Minimum span (days) the windowed entries must cover.
const double kProjectionMinSpanDays = 14;

/// Below this |slope| the trend counts as flat (~50 g/week).
const double kProjectionFlatSlopeKgPerDay = 0.05 / 7;

/// Within this distance the goal is treated as already reached.
const double kProjectionReachedKg = 0.2;

/// Minimum regression R² to trust the slope; below this the data is too noisy.
const double kProjectionMinRSquared = 0.5;

/// ETAs beyond this horizon are suppressed as not worth showing (~2 years).
const double kProjectionMaxHorizonDays = 730;

const double _minutesPerDay = 1440;

class _Fit {
  const _Fit(this.slope, this.intercept, this.rSquared);
  final double slope;
  final double intercept;
  final double rSquared;
}

/// Ordinary least-squares fit of y = intercept + slope·x, with R² (coefficient
/// of determination). Assumes [xs] and [ys] are non-empty and equal length.
_Fit _linearFit(List<double> xs, List<double> ys) {
  final n = xs.length;
  var sumX = 0.0, sumY = 0.0, sumXX = 0.0, sumXY = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += xs[i];
    sumY += ys[i];
    sumXX += xs[i] * xs[i];
    sumXY += xs[i] * ys[i];
  }
  final meanX = sumX / n;
  final meanY = sumY / n;
  final varX = sumXX - n * meanX * meanX;
  if (varX == 0) return const _Fit(0, 0, 0); // all timestamps identical
  final slope = (sumXY - n * meanX * meanY) / varX;
  final intercept = meanY - slope * meanX;

  // R² = 1 − SS_res / SS_tot. If y is constant (SS_tot = 0) the line fits
  // perfectly by definition.
  var ssRes = 0.0, ssTot = 0.0;
  for (var i = 0; i < n; i++) {
    final predicted = intercept + slope * xs[i];
    ssRes += math.pow(ys[i] - predicted, 2).toDouble();
    ssTot += math.pow(ys[i] - meanY, 2).toDouble();
  }
  final rSquared = ssTot == 0 ? 1.0 : (1 - ssRes / ssTot);
  return _Fit(slope, intercept, rSquared);
}
