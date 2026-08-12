import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ponvia/data/db/database.dart';
import 'package:ponvia/data/repositories/goal_repository.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// Exercises the v1 -> v2 upgrade path that adds `goals.highlight_override`.
/// The other DB tests open a fresh v2 database via `onCreate`; this one builds a
/// v1-schema file by hand (matching the shipped v0.2.0 schema) and forces
/// drift's `onUpgrade` to run, catching a missing/incorrect migration strategy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ponvia_mig');
    file = File(p.join(dir.path, 'v1.sqlite'));
    final db = raw.sqlite3.open(file.path);
    // The v1 schema (no highlight_override column). DateTimes are stored as
    // Unix seconds, matching drift's default DriftSqlType.dateTime encoding.
    db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        note TEXT
      );
      CREATE TABLE goals (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        target_weight_kg REAL NOT NULL,
        label TEXT,
        created_at INTEGER NOT NULL,
        achieved_at INTEGER
      );
      INSERT INTO goals (target_weight_kg, label, created_at)
        VALUES (78.0, 'Summer', 1700000000);
      PRAGMA user_version = 1;
    ''');
    db.close();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('upgrades a v1 database, adding highlight_override (default false)',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final goals = GoalRepository(db);

    // Reading the goal forces the database to open and run onUpgrade.
    final all = await goals.getAll();
    expect(all.single.targetWeightKg, 78.0);
    expect(all.single.label, 'Summer');
    expect(all.single.highlightOverride, isFalse);

    // The migrated-in column is fully usable afterwards.
    await goals.setHighlightOverride(all.single.id!, true);
    expect((await goals.getAll()).single.highlightOverride, isTrue);

    await db.close();
  });
}
