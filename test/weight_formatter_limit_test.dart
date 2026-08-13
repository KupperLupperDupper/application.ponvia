import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/core/formatting/weight_formatter.dart';
import 'package:ponvia/core/units/weight_unit.dart';

void main() {
  // The 20–400 kg entry limits, converted to each display unit for the range
  // hint ("Enter a weight between … and …"). Limits never carry a decimal.
  group('WeightFormatter.limit', () {
    test('kg shows the whole kilograms', () {
      final f = WeightFormatter(WeightUnit.kg, locale: 'en');
      expect(f.limit(20), '20 kg');
      expect(f.limit(400), '400 kg');
    });

    test('lb shows whole pounds', () {
      final f = WeightFormatter(WeightUnit.lb, locale: 'en');
      expect(f.limit(20), '44 lb'); // 20 kg ≈ 44.09 lb
      expect(f.limit(400), '882 lb'); // 400 kg ≈ 881.85 lb
    });

    test('stone shows whole st + lb, no decimal', () {
      final f = WeightFormatter(WeightUnit.st, locale: 'en');
      expect(f.limit(20), '3 st 2 lb'); // 20 kg ≈ 3 st 2.1 lb
      expect(f.limit(400), '63 st 0 lb'); // 400 kg ≈ 62 st 13.9 lb
    });
  });
}
