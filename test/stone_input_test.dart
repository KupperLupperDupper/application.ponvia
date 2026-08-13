import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/core/units/weight_unit.dart';
import 'package:ponvia/features/logging/stone_input.dart';

void main() {
  group('StoneInput digit routing', () {
    test('auto-advances to pounds after the second stone digit', () {
      final s = StoneInput();
      s.onDigit('1');
      expect(s.st, '1');
      expect(s.focusLb, isFalse);
      s.onDigit('2');
      expect(s.st, '12');
      expect(s.focusLb, isTrue); // no third stone digit is possible
    });

    test('auto-advances after a first stone digit of 7, 8 or 9', () {
      for (final d in ['7', '8', '9']) {
        final s = StoneInput();
        s.onDigit(d);
        expect(s.st, d);
        expect(s.focusLb, isTrue, reason: '$d st cannot take a second digit');
      }
    });

    test('a first stone digit below 7 stays on stone', () {
      final s = StoneInput();
      s.onDigit('6');
      expect(s.st, '6');
      expect(s.focusLb, isFalse); // "6 st 5 lb" needs a tap to reach pounds
    });

    test('clamps stone at 63 and keeps the current value on reject', () {
      final s = StoneInput();
      s.onDigit('6');
      s.onDigit('4'); // 64 > 63 -> rejected
      expect(s.st, '6');
      expect(s.focusLb, isFalse);
      s.onDigit('3'); // 63 is allowed and then auto-advances
      expect(s.st, '63');
      expect(s.focusLb, isTrue);
    });

    test('the decimal / non-digit key is dead in stone mode', () {
      final s = StoneInput();
      s.onDigit('.');
      s.onDigit(',');
      expect(s.st, '');
      expect(s.lb, '');
    });

    test('pounds reject a value >= 14 and any third digit', () {
      final s = StoneInput(st: '12', focusLb: true);
      s.onDigit('1');
      s.onDigit('4'); // 14 rejected
      expect(s.lb, '1');
      s.onDigit('3'); // 13 allowed
      expect(s.lb, '13');
      s.onDigit('0'); // third digit rejected
      expect(s.lb, '13');
    });
  });

  group('StoneInput backspace', () {
    test('at the start of pounds, focus returns to stone', () {
      final s = StoneInput(st: '12', focusLb: true);
      s.onBackspace(); // pounds empty -> back to stone
      expect(s.focusLb, isFalse);
      expect(s.st, '12');
      s.onBackspace();
      expect(s.st, '1');
      s.onBackspace();
      expect(s.st, '');
      s.onBackspace(); // no-op at the start of stone
      expect(s.st, '');
      expect(s.focusLb, isFalse);
    });

    test('deletes within pounds before unfocusing', () {
      final s = StoneInput(st: '12', lb: '13', focusLb: true);
      s.onBackspace();
      expect(s.lb, '1');
      expect(s.focusLb, isTrue);
    });
  });

  group('StoneInput.fromKg read-back', () {
    test('prefills both fields (rounded pounds) and focuses pounds', () {
      final kg = WeightConverter.stonePartsToKg(12, 7);
      final s = StoneInput.fromKg(kg);
      expect(s.st, '12');
      expect(s.lb, '7');
      expect(s.focusLb, isTrue);
    });

    test('carries into a whole stone when pounds round to 14', () {
      final kg = WeightConverter.stonePartsToKg(12, 13.6);
      final s = StoneInput.fromKg(kg);
      expect(s.st, '13');
      expect(s.lb, '0');
    });
  });

  group('StoneInput kg / validity', () {
    test('blank pounds count as 0 lb', () {
      final s = StoneInput(st: '12');
      expect(s.lbValue, 0);
      expect(s.kg, closeTo(WeightConverter.stonePartsToKg(12, 0), 1e-9));
      expect(s.valid, isTrue);
    });

    test('valid only inside the 20-400 kg range', () {
      expect(StoneInput(st: '3', lb: '2').valid, isFalse); // ~19.96 kg
      expect(StoneInput(st: '3', lb: '3').valid, isTrue); //  ~20.41 kg
      expect(StoneInput(st: '62', lb: '13').valid, isTrue); // ~399.6 kg
      expect(StoneInput(st: '63').valid, isFalse); // ~400.07 kg
    });

    test('an empty input is empty and invalid', () {
      final s = StoneInput();
      expect(s.isEmpty, isTrue);
      expect(s.valid, isFalse);
      s.onDigit('5');
      expect(s.isEmpty, isFalse);
    });
  });
}
