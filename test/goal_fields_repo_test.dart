import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/data/db/database.dart';
import 'package:ponvia/data/repositories/goal_repository.dart';
import 'package:ponvia/data/repositories/weight_repository.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';

/// Confirms the v2 goal columns (`startWeightKg`, `reachedPromptShownAt`) and
/// the `WeightRepository.latest()` helper the achievement check relies on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GoalRepository goals;
  late WeightRepository weights;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    goals = GoalRepository(db);
    weights = WeightRepository(db);
  });

  tearDown(() async => db.close());

  test('goal start weight and prompt timestamp round-trip through the DB',
      () async {
    await goals.add(Goal(
      targetWeightKg: 75,
      startWeightKg: 88.2,
      createdAt: DateTime(2026, 7, 1),
      reachedPromptShownAt: DateTime(2026, 7, 15, 9),
    ));
    final stored = (await goals.getAll()).single;
    expect(stored.startWeightKg, 88.2);
    expect(stored.reachedPromptShownAt, DateTime(2026, 7, 15, 9));
    expect(stored.isAchieved, isFalse);
  });

  test('latest() returns the most recent entry by timestamp', () async {
    expect(await weights.latest(), isNull);
    await weights.add(WeightEntry(timestamp: DateTime(2026, 8, 1), weightKg: 82));
    await weights.add(WeightEntry(timestamp: DateTime(2026, 8, 3), weightKg: 80));
    await weights.add(WeightEntry(timestamp: DateTime(2026, 8, 2), weightKg: 81));
    expect((await weights.latest())!.weightKg, 80);
  });
}
