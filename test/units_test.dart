import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/core/units/weight_unit.dart';

void main() {
  group('WeightConverter', () {
    test('kg is the identity', () {
      expect(WeightConverter.fromKg(80, WeightUnit.kg), 80);
      expect(WeightConverter.toKg(80, WeightUnit.kg), 80);
    });

    test('kg <-> lb round-trips', () {
      final lb = WeightConverter.fromKg(80, WeightUnit.lb);
      expect(lb, closeTo(176.37, 0.01));
      expect(WeightConverter.toKg(lb, WeightUnit.lb), closeTo(80, 1e-9));
    });

    test('kg <-> decimal stone round-trips', () {
      final st = WeightConverter.fromKg(80, WeightUnit.st);
      expect(WeightConverter.toKg(st, WeightUnit.st), closeTo(80, 1e-9));
    });

    test('stone parts split and rebuild', () {
      final parts = WeightConverter.kgToStoneParts(80);
      expect(parts.stone, 12); // 80 kg = 176.37 lb = 12 st 8.37 lb
      expect(parts.pounds, closeTo(8.37, 0.05));
      final kg = WeightConverter.stonePartsToKg(parts.stone, parts.pounds);
      expect(kg, closeTo(80, 1e-6));
    });
  });

  test('WeightUnit.fromCode falls back to kg', () {
    expect(WeightUnit.fromCode('lb'), WeightUnit.lb);
    expect(WeightUnit.fromCode('nonsense'), WeightUnit.kg);
    expect(WeightUnit.fromCode(null), WeightUnit.kg);
  });
}
