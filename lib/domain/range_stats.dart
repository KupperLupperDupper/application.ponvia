import 'package:meta/meta.dart';

import 'models/weight_entry.dart';

/// Summary statistics over a set of weight entries — the numbers behind the
/// History screen's "this period" card. All weights are canonical kilograms.
@immutable
class RangeStats {
  const RangeStats({
    required this.minKg,
    required this.maxKg,
    required this.avgKg,
    required this.netKg,
    required this.count,
  });

  /// Lowest weight in the set.
  final double minKg;

  /// Highest weight in the set.
  final double maxKg;

  /// Arithmetic mean of the weights.
  final double avgKg;

  /// Net change across the period: the chronologically latest weight minus the
  /// earliest. Negative = the period ended lighter. Zero for a single entry.
  final double netKg;

  /// Number of entries the stats were computed over.
  final int count;
}

/// Computes [RangeStats] over [entries], or returns `null` when the list is
/// empty (the caller hides the card in that case).
///
/// Order-independent: min/max/avg scan the whole set, and net change is derived
/// from the entries with the earliest and latest [WeightEntry.timestamp] — it
/// does not assume the list is sorted.
RangeStats? computeRangeStats(List<WeightEntry> entries) {
  if (entries.isEmpty) return null;

  var min = entries.first.weightKg;
  var max = entries.first.weightKg;
  var sum = 0.0;
  var earliest = entries.first;
  var latest = entries.first;

  for (final e in entries) {
    if (e.weightKg < min) min = e.weightKg;
    if (e.weightKg > max) max = e.weightKg;
    sum += e.weightKg;
    if (e.timestamp.isBefore(earliest.timestamp)) earliest = e;
    if (e.timestamp.isAfter(latest.timestamp)) latest = e;
  }

  return RangeStats(
    minKg: min,
    maxKg: max,
    avgKg: sum / entries.length,
    netKg: latest.weightKg - earliest.weightKg,
    count: entries.length,
  );
}
