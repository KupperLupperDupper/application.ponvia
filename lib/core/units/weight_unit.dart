/// Weight units Ponvia can display. Canonical storage is always **kilograms**;
/// these are display/entry units only. See [WeightConverter].
enum WeightUnit {
  kg('kg'),
  lb('lb'),
  st('st');

  const WeightUnit(this.code);

  /// Stable code persisted in settings/backups (never localize this).
  final String code;

  static WeightUnit fromCode(String? code) => WeightUnit.values.firstWhere(
        (u) => u.code == code,
        orElse: () => WeightUnit.kg,
      );
}

/// Whole-stone + remaining-pounds representation, used for the UK `st + lb`
/// composite display and entry.
class StoneParts {
  const StoneParts(this.stone, this.pounds);

  final int stone;
  final double pounds;
}

/// Pure conversions between the canonical kilogram and each [WeightUnit].
///
/// Factors: 1 kg = 2.2046226218 lb; 1 st = 6.35029318 kg (= 14 lb).
class WeightConverter {
  const WeightConverter._();

  static const double lbPerKg = 2.2046226218;
  static const double kgPerStone = 6.35029318;
  static const double lbPerStone = 14;

  /// Converts a canonical [kg] value to the numeric value in [unit].
  ///
  /// For [WeightUnit.st] this returns **decimal stone**; use
  /// [kgToStoneParts] when you need the `st + lb` composite.
  static double fromKg(double kg, WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return kg;
      case WeightUnit.lb:
        return kg * lbPerKg;
      case WeightUnit.st:
        return kg / kgPerStone;
    }
  }

  /// Converts a numeric [value] expressed in [unit] back to canonical kg.
  ///
  /// For [WeightUnit.st], [value] is interpreted as **decimal stone**.
  static double toKg(double value, WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return value;
      case WeightUnit.lb:
        return value / lbPerKg;
      case WeightUnit.st:
        return value * kgPerStone;
    }
  }

  /// Splits canonical [kg] into whole stone and remaining pounds.
  static StoneParts kgToStoneParts(double kg) {
    final totalLb = kg * lbPerKg;
    final stone = totalLb ~/ lbPerStone;
    final pounds = totalLb - stone * lbPerStone;
    return StoneParts(stone, pounds);
  }

  /// Rebuilds canonical kg from a `st + lb` composite.
  static double stonePartsToKg(int stone, double pounds) =>
      (stone * lbPerStone + pounds) / lbPerKg;
}
