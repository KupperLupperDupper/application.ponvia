import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// Ponvia's local SQLite database. Domain data only (weights, goals); scalar
/// settings live in shared_preferences. Room is intentionally left for future
/// calorie tables without reworking these.
@DriftDatabase(tables: [WeightEntries, Goals])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Test constructor for an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: manual "Highlight on Home" pin, plus goal auto-detection's
          // direction anchor (startWeightKg) and one-shot prompt flag.
          if (from < 2) {
            await m.addColumn(goals, goals.highlightOverride);
            await m.addColumn(goals, goals.startWeightKg);
            await m.addColumn(goals, goals.reachedPromptShownAt);
          }
        },
      );

  /// Removes all domain data (used by "clear all data" and import-replace).
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(weightEntries).go();
      await delete(goals).go();
    });
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'ponvia.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
