import 'package:drift/drift.dart';

import '../../domain/models/weight_entry.dart';
import '../db/database.dart';

/// App-facing API over the `weight_entries` table. Returns domain [WeightEntry]s,
/// never Drift rows.
class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  WeightEntry _toDomain(WeightEntryRow r) => WeightEntry(
        id: r.id,
        timestamp: r.timestamp,
        weightKg: r.weightKg,
        note: r.note,
      );

  Stream<List<WeightEntry>> watchAll() {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Stream<WeightEntry?> watchLatest() {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    return q.watchSingleOrNull().map((r) => r == null ? null : _toDomain(r));
  }

  /// The single most recent entry by timestamp, or null when there are none.
  /// A point-in-time read (not a stream) for the goal-achievement check.
  Future<WeightEntry?> latest() async {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<WeightEntry>> getAll() async {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return (await q.get()).map(_toDomain).toList();
  }

  Future<int> add(WeightEntry e) {
    return _db.into(_db.weightEntries).insert(
          WeightEntriesCompanion.insert(
            timestamp: e.timestamp,
            weightKg: e.weightKg,
            note: Value(e.note),
          ),
        );
  }

  Future<void> update(WeightEntry e) {
    assert(e.id != null, 'update requires a persisted entry');
    return (_db.update(_db.weightEntries)..where((t) => t.id.equals(e.id!)))
        .write(
      WeightEntriesCompanion(
        timestamp: Value(e.timestamp),
        weightKg: Value(e.weightKg),
        note: Value(e.note),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();

  /// Imports entries. When [replace] is false, existing timestamps are skipped
  /// (deterministic de-dup). Returns how many rows were inserted.
  Future<int> importEntries(
    List<WeightEntry> entries, {
    required bool replace,
  }) async {
    var inserted = 0;
    await _db.transaction(() async {
      if (replace) await _db.delete(_db.weightEntries).go();
      final seen = replace
          ? <DateTime>{}
          : (await _db.select(_db.weightEntries).get())
              .map((r) => r.timestamp)
              .toSet();
      for (final e in entries) {
        if (seen.contains(e.timestamp)) continue;
        await _db.into(_db.weightEntries).insert(
              WeightEntriesCompanion.insert(
                timestamp: e.timestamp,
                weightKg: e.weightKg,
                note: Value(e.note),
              ),
            );
        seen.add(e.timestamp);
        inserted++;
      }
    });
    return inserted;
  }
}
