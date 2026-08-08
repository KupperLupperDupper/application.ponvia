import 'package:meta/meta.dart';

/// A single weight measurement. Canonical unit is kilograms.
@immutable
class WeightEntry {
  const WeightEntry({
    this.id,
    required this.timestamp,
    required this.weightKg,
    this.note,
  });

  /// Database id; null for entries not yet persisted.
  final int? id;
  final DateTime timestamp;
  final double weightKg;
  final String? note;

  WeightEntry copyWith({
    int? id,
    DateTime? timestamp,
    double? weightKg,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }

  /// Backup representation (id is intentionally omitted — it is device-local).
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'weightKg': weightKg,
        if (note != null) 'note': note,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
        weightKg: (json['weightKg'] as num).toDouble(),
        note: json['note'] as String?,
      );
}
