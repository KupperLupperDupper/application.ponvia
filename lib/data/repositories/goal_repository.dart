import 'package:drift/drift.dart';

import '../../domain/models/goal.dart';
import '../db/database.dart';

/// App-facing API over the `goals` table. Returns domain [Goal]s.
class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  Goal _toDomain(GoalRow r) => Goal(
        id: r.id,
        targetWeightKg: r.targetWeightKg,
        label: r.label,
        startWeightKg: r.startWeightKg,
        createdAt: r.createdAt,
        achievedAt: r.achievedAt,
        highlightOverride: r.highlightOverride,
        reachedPromptShownAt: r.reachedPromptShownAt,
      );

  Stream<List<Goal>> watchAll() {
    final q = _db.select(_db.goals)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Goal>> getAll() async {
    final q = _db.select(_db.goals)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return (await q.get()).map(_toDomain).toList();
  }

  Future<int> add(Goal g) {
    return _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            targetWeightKg: g.targetWeightKg,
            label: Value(g.label),
            startWeightKg: Value(g.startWeightKg),
            createdAt: g.createdAt,
            achievedAt: Value(g.achievedAt),
            highlightOverride: Value(g.highlightOverride),
            reachedPromptShownAt: Value(g.reachedPromptShownAt),
          ),
        );
  }

  Future<void> update(Goal g) {
    assert(g.id != null, 'update requires a persisted goal');
    return (_db.update(_db.goals)..where((t) => t.id.equals(g.id!))).write(
      GoalsCompanion(
        targetWeightKg: Value(g.targetWeightKg),
        label: Value(g.label),
        startWeightKg: Value(g.startWeightKg),
        createdAt: Value(g.createdAt),
        achievedAt: Value(g.achievedAt),
        highlightOverride: Value(g.highlightOverride),
        reachedPromptShownAt: Value(g.reachedPromptShownAt),
      ),
    );
  }

  /// Pins (or unpins) a goal's "Highlight on Home" override. Pinning one goal
  /// clears the flag on every other goal, so at most one is ever highlighted
  /// manually.
  Future<void> setHighlightOverride(int id, bool on) async {
    await _db.transaction(() async {
      if (on) {
        await _db.update(_db.goals).write(
              const GoalsCompanion(highlightOverride: Value(false)),
            );
      }
      await (_db.update(_db.goals)..where((t) => t.id.equals(id))).write(
        GoalsCompanion(highlightOverride: Value(on)),
      );
    });
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();

  Future<int> importGoals(List<Goal> goals, {required bool replace}) async {
    var inserted = 0;
    await _db.transaction(() async {
      if (replace) await _db.delete(_db.goals).go();
      for (final g in goals) {
        await _db.into(_db.goals).insert(
              GoalsCompanion.insert(
                targetWeightKg: g.targetWeightKg,
                label: Value(g.label),
                startWeightKg: Value(g.startWeightKg),
                createdAt: g.createdAt,
                achievedAt: Value(g.achievedAt),
                highlightOverride: Value(g.highlightOverride),
                reachedPromptShownAt: Value(g.reachedPromptShownAt),
              ),
            );
        inserted++;
      }
    });
    return inserted;
  }
}
