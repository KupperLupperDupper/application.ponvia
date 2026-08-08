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
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get achievedAt => dateTime().nullable()();
}
