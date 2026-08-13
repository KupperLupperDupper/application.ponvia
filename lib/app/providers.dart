import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/units/weight_unit.dart';
import '../data/backup/backup_service.dart';
import '../data/db/database.dart';
import '../data/prefs/settings_store.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../features/notifications/notification_service.dart';
import '../domain/goals/closest_goal.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/goal.dart';
import '../domain/models/reminder_config.dart';
import '../domain/models/weight_entry.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Overridden in `main()` with the initialized service.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationServiceProvider must be overridden'),
);

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(sharedPreferencesProvider)),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => WeightRepository(ref.watch(databaseProvider)),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    weights: ref.watch(weightRepositoryProvider),
    goals: ref.watch(goalRepositoryProvider),
    settingsStore: ref.watch(settingsStoreProvider),
  ),
);

/// Holds and persists [AppSettings]. Reads/writes flow through [SettingsStore].
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).read();

  Future<void> _persist() => ref.read(settingsStoreProvider).write(state);

  Future<void> setLocale(String? code) {
    state = state.copyWith(localeCode: code, clearLocale: code == null);
    return _persist();
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    return _persist();
  }

  Future<void> setUnit(WeightUnit unit) {
    state = state.copyWith(unit: unit);
    return _persist();
  }

  Future<void> setReminder(ReminderConfig reminder) {
    state = state.copyWith(reminder: reminder);
    return _persist();
  }

  /// Sets (or clears, with null) the optional body height in cm.
  Future<void> setHeight(int? cm) {
    state = state.copyWith(heightCm: cm, clearHeight: cm == null);
    return _persist();
  }

  Future<void> completeOnboarding() {
    state = state.copyWith(hasOnboarded: true);
    return _persist();
  }

  Future<void> clearAll() async {
    await ref.read(settingsStoreProvider).clear();
    state = AppSettings.defaults;
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final entriesProvider = StreamProvider<List<WeightEntry>>(
  (ref) => ref.watch(weightRepositoryProvider).watchAll(),
);

final latestWeightProvider = StreamProvider<WeightEntry?>(
  (ref) => ref.watch(weightRepositoryProvider).watchLatest(),
);

final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).watchAll(),
);

/// The highlighted goal (closest active target to the latest weight), or null.
final closestGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider).asData?.value ?? const [];
  final latest = ref.watch(latestWeightProvider).asData?.value;
  return ClosestGoal.select(goals, latest?.weightKg);
});
