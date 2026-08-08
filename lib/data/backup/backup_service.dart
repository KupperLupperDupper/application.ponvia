import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../prefs/settings_store.dart';
import '../repositories/goal_repository.dart';
import '../repositories/weight_repository.dart';
import 'backup_codec.dart';

/// Coordinates backup/restore across repositories and settings. Returns/accepts
/// strings so the UI layer owns the actual file picking and sharing (M2/M3).
class BackupService {
  BackupService({
    required this.weights,
    required this.goals,
    required this.settingsStore,
  });

  final WeightRepository weights;
  final GoalRepository goals;
  final SettingsStore settingsStore;

  Future<String> exportJson({
    required AppSettings settings,
    required DateTime now,
  }) async {
    return BackupCodec.encodeJson(
      entries: await weights.getAll(),
      goals: await goals.getAll(),
      settings: settings,
      exportedAt: now,
    );
  }

  Future<String> exportCsv(WeightUnit unit) async =>
      BackupCodec.encodeCsv(await weights.getAll(), unit);

  /// Restores a JSON backup. [replace] wipes existing data first; otherwise
  /// entries de-dup by timestamp and goals append. Applies backed-up settings
  /// when present. Returns the parsed data (e.g. for a summary).
  Future<BackupData> importJson(String source, {required bool replace}) async {
    final data = BackupCodec.decodeJson(source);
    await weights.importEntries(data.entries, replace: replace);
    await goals.importGoals(data.goals, replace: replace);
    if (data.settings != null) await settingsStore.write(data.settings!);
    return data;
  }

  /// Imports weight rows from CSV. Returns the number inserted.
  Future<int> importCsv(String source, {required bool replace}) async {
    return weights.importEntries(
      BackupCodec.decodeCsv(source),
      replace: replace,
    );
  }
}
