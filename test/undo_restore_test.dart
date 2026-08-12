import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/data/backup/backup_service.dart';
import 'package:ponvia/data/db/database.dart';
import 'package:ponvia/data/prefs/settings_store.dart';
import 'package:ponvia/data/repositories/goal_repository.dart';
import 'package:ponvia/data/repositories/weight_repository.dart';
import 'package:ponvia/domain/models/app_settings.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs the "undo" on the two bulk-destructive surfaces (Settings → Clear all
/// data, and Replace-import): both snapshot everything with `exportJson` before
/// wiping, and restore it with `importJson(replace: true)`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WeightRepository weights;
  late GoalRepository goals;
  late BackupService backup;

  Future<void> seedOriginal() async {
    await weights
        .add(WeightEntry(timestamp: DateTime(2026, 8, 1, 7, 30), weightKg: 82.4));
    await weights
        .add(WeightEntry(timestamp: DateTime(2026, 8, 2, 7, 30), weightKg: 82.0));
    await goals
        .add(Goal(targetWeightKg: 78, label: 'Summer', createdAt: DateTime(2026, 7, 1)));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    weights = WeightRepository(db);
    goals = GoalRepository(db);
    backup = BackupService(
      weights: weights,
      goals: goals,
      settingsStore: SettingsStore(prefs),
    );
  });

  tearDown(() async => db.close());

  test('clear-all → undo restores every weight and goal', () async {
    await seedOriginal();
    const settings = AppSettings(hasOnboarded: true);

    // The snackbar snapshots before wiping.
    final snapshot =
        await backup.exportJson(settings: settings, now: DateTime(2026, 8, 12));
    await db.clearAllData();
    expect((await weights.getAll()), isEmpty);
    expect((await goals.getAll()), isEmpty);

    // Undo.
    await backup.importJson(snapshot, replace: true);
    expect((await weights.getAll()).length, 2);
    final restoredGoals = await goals.getAll();
    expect(restoredGoals.single.label, 'Summer');
    expect(restoredGoals.single.targetWeightKg, 78);
  });

  test('replace-import → undo restores the pre-import data', () async {
    await seedOriginal();
    const settings = AppSettings(hasOnboarded: true);
    final snapshot =
        await backup.exportJson(settings: settings, now: DateTime(2026, 8, 12));

    // A replace-import wipes and installs a different backup.
    final incoming = BackupServiceTestData.otherBackup;
    await backup.importJson(incoming, replace: true);
    expect((await weights.getAll()).single.weightKg, 90.0);
    expect((await goals.getAll()), isEmpty);

    // Undo restores the original snapshot in full.
    await backup.importJson(snapshot, replace: true);
    expect((await weights.getAll()).length, 2);
    expect((await goals.getAll()).single.label, 'Summer');
  });
}

class BackupServiceTestData {
  static const otherBackup = '{'
      '"schemaVersion":1,"app":"ponvia","exportedAt":"2026-08-10T00:00:00.000Z",'
      '"weights":[{"timestamp":"2026-08-10T07:30:00.000","weightKg":90.0,"note":null}],'
      '"goals":[]'
      '}';
}
