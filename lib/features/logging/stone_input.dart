import '../../core/units/weight_unit.dart';

/// Mutable, widget-free model for the split **stone + pounds** weight entry
/// (`design/handoff/STONE_ENTRY_WEEKLY_MULTI.md` §A). Holds the two typed
/// fields plus which one has focus, and owns *all* the digit-routing, clamp and
/// auto-advance rules so they can be unit-tested independently of the UI.
///
/// Pounds are whole integers 0–13; stone is 0–63 (the keypad's decimal key is
/// dead in stone mode). Canonical storage stays kilograms — see [kg].
class StoneInput {
  StoneInput({this.st = '', this.lb = '', this.focusLb = false});

  /// Reads an existing canonical [kg] back into both fields, rounding pounds to
  /// the nearest whole and focusing **pounds** (corrections are almost always
  /// sub-stone — mirrors the height sheet's ft/in read-back).
  factory StoneInput.fromKg(double kg) {
    final parts = WeightConverter.kgToStoneParts(kg);
    var stone = parts.stone;
    var pounds = parts.pounds.round();
    // Rounding can carry into a whole stone (e.g. 13.6 lb -> 14 lb).
    if (pounds >= _lbPerStone) {
      stone += pounds ~/ _lbPerStone;
      pounds = pounds % _lbPerStone;
    }
    if (stone > _stMax) stone = _stMax;
    return StoneInput(st: '$stone', lb: '$pounds', focusLb: true);
  }

  /// The whole-stone field, as typed ('' when empty).
  String st;

  /// The whole-pounds field, as typed ('' when empty; blank counts as 0 lb).
  String lb;

  /// Whether pounds currently has focus (false = stone).
  bool focusLb;

  static const int _stMax = 63;
  static const int _lbPerStone = 14;

  /// Routes a keypad key. Non-digit keys (the dead decimal) are ignored.
  ///
  /// Stone: appends up to two digits, clamps at 63, and auto-advances to pounds
  /// as soon as a further digit is impossible — after the 2nd digit, or after
  /// the 1st if it is 7–9 (since 70+ > 63). Pounds: one or two digits, rejects
  /// anything ≥ 14 or a third digit; the field keeps its value on a reject.
  void onDigit(String key) {
    final digit = int.tryParse(key);
    if (digit == null) return; // decimal / non-digit is dead in stone mode
    if (!focusLb) {
      final next = st + key;
      if (next.length > 2) return; // no third digit
      final value = int.parse(next);
      if (value > _stMax) return; // clamp to 63, keep current
      st = next;
      if (next.length == 2 || value >= 7) focusLb = true; // auto-advance
    } else {
      final next = lb + key;
      if (next.length > 2) return; // no third digit
      if (int.parse(next) >= _lbPerStone) return; // reject >= 14
      lb = next;
    }
  }

  /// Deletes in the focused field. At the start of pounds, focus returns to
  /// stone; at the start of stone it is a no-op.
  void onBackspace() {
    if (focusLb) {
      if (lb.isNotEmpty) {
        lb = lb.substring(0, lb.length - 1);
      } else {
        focusLb = false;
      }
    } else if (st.isNotEmpty) {
      st = st.substring(0, st.length - 1);
    }
  }

  /// The whole-stone value (0 when blank).
  int get stValue => int.tryParse(st) ?? 0;

  /// The whole-pounds value (0 when blank — blank counts as 0 lb).
  int get lbValue => int.tryParse(lb) ?? 0;

  /// True while neither field has been typed into.
  bool get isEmpty => st.isEmpty && lb.isEmpty;

  /// Canonical kilograms for the current entry (blank pounds -> 0 lb).
  double get kg => WeightConverter.stonePartsToKg(stValue, lbValue.toDouble());

  /// Whether [kg] is inside the accepted 20–400 kg range.
  bool get valid {
    final k = kg;
    return k >= 20 && k <= 400;
  }
}
