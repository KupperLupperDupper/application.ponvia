/// Body-mass index — pure, no Flutter/DB imports.
///
/// BMI = weight(kg) / height(m)². Ponvia only ever surfaces the value and a
/// single neutral band word relative to the normal range; it deliberately does
/// NOT expose clinical labels ("overweight"/"obese"), advice, or a scale.
library;

/// Where a BMI value sits relative to the normal range. Wording is deliberately
/// neutral (below / within / above) — never a judgemental clinical label.
enum BmiBand { below, normal, above }

/// Standard adult cutoffs: below 18.5, normal 18.5–<25, above ≥25.
const double _normalLow = 18.5;
const double _normalHigh = 25.0;

/// BMI for a weight in kg and a height in cm. Returns `null` for a non-positive
/// height so callers never divide by zero.
double? bmiValue(double weightKg, int heightCm) {
  if (heightCm <= 0) return null;
  final m = heightCm / 100.0;
  return weightKg / (m * m);
}

/// The band a BMI value falls in (relative to the normal range).
BmiBand bmiBand(double bmi) {
  if (bmi < _normalLow) return BmiBand.below;
  if (bmi < _normalHigh) return BmiBand.normal;
  return BmiBand.above;
}
