import 'package:drift/drift.dart';

/// Weight measurements. Canonical unit kilograms. Generated row class is
/// `WeightEntryRow` to avoid clashing with the domain `WeightEntry`.
@DataClassName('WeightEntryRow')
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
}

/// Target-weight goals. Generated row class is `GoalRow`.
@DataClassName('GoalRow')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get targetWeightKg => real()();
  TextColumn get label => text().nullable()();

  /// The latest weight at the moment the goal was created, used to classify the
  /// goal's direction (lose when `target < start`, gain when `target > start`)
  /// for auto-detection. Null for goals created before this was captured.
  RealColumn get startWeightKg => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get achievedAt => dateTime().nullable()();

  /// Manual "Highlight on Home" pin. When set, this goal overrides the
  /// distance-based closest-goal selection. At most one goal is pinned at a
  /// time (enforced by [GoalRepository.setHighlightOverride]).
  BoolColumn get highlightOverride =>
      boolean().withDefault(const Constant(false))();

  /// When the "you reached it" moment was shown for this goal (whatever the
  /// user answered). Set once so a later re-crossing never re-opens the prompt.
  DateTimeColumn get reachedPromptShownAt => dateTime().nullable()();
}
