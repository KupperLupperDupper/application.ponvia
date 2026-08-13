import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/domain/bmi.dart';

void main() {
  test('bmiValue = kg / (cm/100)^2', () {
    // 74.8 kg at 178 cm → 23.6 (the design's reference figure).
    expect(bmiValue(74.8, 178)!, closeTo(23.6, 0.05));
    expect(bmiValue(60, 170)!, closeTo(20.76, 0.05));
  });

  test('bmiValue guards a non-positive height', () {
    expect(bmiValue(70, 0), isNull);
    expect(bmiValue(70, -5), isNull);
  });

  test('bmiBand cutoffs: below 18.5, normal 18.5–<25, above >=25', () {
    expect(bmiBand(18.49), BmiBand.below);
    expect(bmiBand(18.5), BmiBand.normal);
    expect(bmiBand(24.99), BmiBand.normal);
    expect(bmiBand(25.0), BmiBand.above);
    expect(bmiBand(31.2), BmiBand.above);
  });
}
