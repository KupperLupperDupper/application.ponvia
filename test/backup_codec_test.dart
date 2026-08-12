import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/core/units/weight_unit.dart';
import 'package:ponvia/data/backup/backup_codec.dart';
import 'package:ponvia/domain/models/app_settings.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';

void main() {
  final now = DateTime(2026, 8, 8, 12);
  final entries = [
    WeightEntry(
      timestamp: DateTime(2026, 8, 1, 7, 30),
      weightKg: 82.4,
      note: 'morning, fasted',
    ),
    WeightEntry(timestamp: DateTime(2026, 8, 2, 7, 30), weightKg: 82.0),
  ];
  final goals = [
    Goal(
      targetWeightKg: 78,
      label: 'Summer',
      startWeightKg: 90.5,
      createdAt: DateTime(2026, 7, 1),
      highlightOverride: true,
      reachedPromptShownAt: DateTime(2026, 7, 20, 8),
    ),
  ];
  const settings = AppSettings(unit: WeightUnit.lb, hasOnboarded: true);

  test('JSON backup round-trips weights, goals and settings', () {
    final json = BackupCodec.encodeJson(
      entries: entries,
      goals: goals,
      settings: settings,
      exportedAt: now,
    );
    final data = BackupCodec.decodeJson(json);
    expect(data.entries.length, 2);
    expect(data.entries.first.weightKg, 82.4);
    expect(data.entries.first.note, 'morning, fasted');
    expect(data.goals.single.label, 'Summer');
    expect(data.goals.single.highlightOverride, true);
    expect(data.goals.single.startWeightKg, 90.5);
    expect(data.goals.single.reachedPromptShownAt, DateTime(2026, 7, 20, 8));
    expect(data.settings!.unit, WeightUnit.lb);
    expect(data.settings!.hasOnboarded, true);
  });

  test('a v1 backup (no goal start/prompt fields) still decodes', () {
    const json = '{"schemaVersion":1,"weights":[],'
        '"goals":[{"targetWeightKg":80,"createdAt":"2026-01-01T00:00:00.000Z"}]}';
    final data = BackupCodec.decodeJson(json);
    expect(data.goals.single.targetWeightKg, 80);
    expect(data.goals.single.startWeightKg, isNull);
    expect(data.goals.single.reachedPromptShownAt, isNull);
  });

  test('rejects a backup from a newer schema', () {
    const json = '{"schemaVersion":999,"weights":[],"goals":[]}';
    expect(
      () => BackupCodec.decodeJson(json),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('CSV round-trips and preserves a note containing a comma', () {
    final csv = BackupCodec.encodeCsv(entries, WeightUnit.kg);
    final parsed = BackupCodec.decodeCsv(csv);
    expect(parsed.length, 2);
    expect(parsed.first.weightKg, 82.4);
    expect(
      parsed.firstWhere((e) => e.note != null).note,
      'morning, fasted',
    );
  });

  test('CSV without required columns is rejected', () {
    expect(
      () => BackupCodec.decodeCsv('foo,bar\n1,2'),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
