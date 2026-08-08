import 'package:intl/intl.dart';

import '../units/weight_unit.dart';

/// Formats canonical kilogram values into localized, unit-aware display strings.
///
/// Numbers use the active [locale] for decimal separators. Stone renders as the
/// composite `st + lb` (e.g. `12 st 6.2 lb`).
class WeightFormatter {
  WeightFormatter(this.unit, {String? locale})
      : _one = NumberFormat('0.0', locale),
        _lb = NumberFormat('0.0', locale),
        _int = NumberFormat('0', locale);

  final WeightUnit unit;
  final NumberFormat _one;
  final NumberFormat _lb;
  final NumberFormat _int;

  /// The numeric portion only (no unit suffix), e.g. `82.4`.
  /// For stone this is the composite `12 st 6.2 lb`.
  String value(double kg) {
    switch (unit) {
      case WeightUnit.kg:
        return _one.format(WeightConverter.fromKg(kg, WeightUnit.kg));
      case WeightUnit.lb:
        return _one.format(WeightConverter.fromKg(kg, WeightUnit.lb));
      case WeightUnit.st:
        final parts = WeightConverter.kgToStoneParts(kg);
        return '${_int.format(parts.stone)} st ${_lb.format(parts.pounds)} lb';
    }
  }

  /// Value with a trailing unit suffix, e.g. `82.4 kg`. Stone already carries
  /// its own `st`/`lb` labels so no suffix is appended.
  String withUnit(double kg) {
    if (unit == WeightUnit.st) return value(kg);
    return '${value(kg)} ${unit.code}';
  }

  /// The magnitude of a weight in the display unit with no unit label, e.g.
  /// `0.6`. For stone it falls back to the composite string.
  String magnitudeShort(double kg) {
    if (unit == WeightUnit.st) return value(kg);
    return _one.format(WeightConverter.fromKg(kg, unit));
  }

  /// A signed delta between two canonical weights in the display unit, e.g.
  /// `+0.4 kg` / `-1.2 lb`. Returns `0.0`-style for no change.
  String delta(double kgDelta) {
    final display = WeightConverter.fromKg(kgDelta.abs(), unit);
    final magnitude =
        unit == WeightUnit.st ? _one.format(display) : _one.format(display);
    final sign = kgDelta > 0
        ? '+'
        : kgDelta < 0
            ? '-'
            : '';
    final suffix = unit == WeightUnit.st ? 'st' : unit.code;
    return '$sign$magnitude $suffix';
  }
}
