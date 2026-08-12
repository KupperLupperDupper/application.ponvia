import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/data/db/database.dart';
import 'package:ponvia/data/repositories/goal_repository.dart';
import 'package:ponvia/domain/models/goal.dart';

/// The "Highlight on Home" pin is mutually exclusive: pinning one goal clears
/// the flag on every other goal, so the closest-goal logic never sees two pins.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GoalRepository goals;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    goals = GoalRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> seed(double target, {DateTime? createdAt}) => goals.add(
        Goal(targetWeightKg: target, createdAt: createdAt ?? DateTime(2026, 1, 1)),
      );

  test('pinning one goal clears the pin on all others', () async {
    final a = await seed(70);
    final b = await seed(80);

    await goals.setHighlightOverride(a, true);
    await goals.setHighlightOverride(b, true);

    final all = await goals.getAll();
    expect(all.firstWhere((g) => g.id == a).highlightOverride, isFalse);
    expect(all.firstWhere((g) => g.id == b).highlightOverride, isTrue);
  });

  test('unpinning a goal leaves nothing highlighted', () async {
    final a = await seed(70);
    await goals.setHighlightOverride(a, true);
    await goals.setHighlightOverride(a, false);

    final all = await goals.getAll();
    expect(all.every((g) => !g.highlightOverride), isTrue);
  });

  test('update preserves an unrelated goal\'s pin', () async {
    final a = await seed(70);
    final b = await seed(80);
    await goals.setHighlightOverride(a, true);

    // Editing goal b must not disturb a's pin.
    await goals.update(Goal(
      id: b,
      targetWeightKg: 82,
      createdAt: DateTime(2026, 1, 1),
    ));

    final all = await goals.getAll();
    expect(all.firstWhere((g) => g.id == a).highlightOverride, isTrue);
    expect(all.firstWhere((g) => g.id == b).highlightOverride, isFalse);
  });
}
