import 'dart:convert';

import '../../core/formatting/weight_formatter.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/weight_entry.dart';

/// Current JSON backup schema version. Bump when the envelope changes.
const int kBackupSchemaVersion = 1;

/// Thrown when a backup/CSV payload can't be parsed or is too new to restore.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatException: $message';
}

/// The decoded contents of a JSON backup.
class BackupData {
  const BackupData({
    required this.schemaVersion,
    this.exportedAt,
    required this.entries,
    required this.goals,
    this.settings,
  });

  final int schemaVersion;
  final DateTime? exportedAt;
  final List<WeightEntry> entries;
  final List<Goal> goals;
  final AppSettings? settings;
}

/// Pure (de)serialization for backups. No file or DB access — testable in
/// isolation. See [BackupData] for the decoded shape.
class BackupCodec {
  const BackupCodec._();

  // ---- JSON (full backup) --------------------------------------------------

  static String encodeJson({
    required List<WeightEntry> entries,
    required List<Goal> goals,
    required AppSettings settings,
    required DateTime exportedAt,
  }) {
    final map = <String, dynamic>{
      'schemaVersion': kBackupSchemaVersion,
      'app': 'ponvia',
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'weights': entries.map((e) => e.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'settings': settings.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static BackupData decodeJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw BackupFormatException('Invalid JSON: ${e.message}');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('Backup root must be a JSON object');
    }
    final map = decoded.cast<String, dynamic>();
    final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version > kBackupSchemaVersion) {
      throw BackupFormatException(
        'Backup schemaVersion $version is newer than supported '
        '($kBackupSchemaVersion). Update the app to restore it.',
      );
    }
    final entries = (map['weights'] as List? ?? const [])
        .map((e) => WeightEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final goals = (map['goals'] as List? ?? const [])
        .map((g) => Goal.fromJson((g as Map).cast<String, dynamic>()))
        .toList();
    final settings = map['settings'] == null
        ? null
        : AppSettings.fromJson((map['settings'] as Map).cast<String, dynamic>());
    return BackupData(
      schemaVersion: version,
      exportedAt: map['exportedAt'] == null
          ? null
          : DateTime.tryParse(map['exportedAt'] as String),
      entries: entries,
      goals: goals,
      settings: settings,
    );
  }

  // ---- CSV (weight history only) ------------------------------------------

  static const csvHeader = 'timestamp,weight_kg,weight_display,unit,note';

  static String encodeCsv(List<WeightEntry> entries, WeightUnit unit) {
    final fmt = WeightFormatter(unit);
    final sb = StringBuffer()..writeln(csvHeader);
    for (final e in entries) {
      sb.writeln([
        e.timestamp.toUtc().toIso8601String(),
        e.weightKg.toString(),
        fmt.value(e.weightKg),
        unit.code,
        e.note ?? '',
      ].map(_csvEscape).join(','));
    }
    return sb.toString();
  }

  /// Parses CSV weight rows. Requires `timestamp` and `weight_kg` columns;
  /// malformed rows are skipped. `note` is optional.
  static List<WeightEntry> decodeCsv(String source) {
    final rows = _parseCsv(source);
    if (rows.isEmpty) return const [];
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final tsIdx = header.indexOf('timestamp');
    final kgIdx = header.indexOf('weight_kg');
    final noteIdx = header.indexOf('note');
    if (tsIdx < 0 || kgIdx < 0) {
      throw const BackupFormatException(
        'CSV must have "timestamp" and "weight_kg" columns',
      );
    }
    final result = <WeightEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.isEmpty || (r.length == 1 && r.first.trim().isEmpty)) continue;
      if (tsIdx >= r.length || kgIdx >= r.length) continue;
      final ts = DateTime.tryParse(r[tsIdx].trim());
      final kg = double.tryParse(r[kgIdx].trim());
      if (ts == null || kg == null) continue;
      final note = (noteIdx >= 0 && noteIdx < r.length && r[noteIdx].isNotEmpty)
          ? r[noteIdx]
          : null;
      result.add(WeightEntry(timestamp: ts.toLocal(), weightKg: kg, note: note));
    }
    return result;
  }

  static String _csvEscape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Minimal RFC-4180-ish parser handling quoted fields, escaped quotes, and
  /// CRLF/LF line endings.
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        switch (ch) {
          case '"':
            inQuotes = true;
          case ',':
            row.add(field.toString());
            field = StringBuffer();
          case '\n':
            row.add(field.toString());
            rows.add(row);
            row = <String>[];
            field = StringBuffer();
          case '\r':
            break; // handled with the following \n
          default:
            field.write(ch);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
