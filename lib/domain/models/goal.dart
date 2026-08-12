import 'package:meta/meta.dart';

/// A target weight the user is working toward. Canonical unit is kilograms.
@immutable
class Goal {
  const Goal({
    this.id,
    required this.targetWeightKg,
    this.label,
    required this.createdAt,
    this.achievedAt,
    this.highlightOverride = false,
  });

  final int? id;
  final double targetWeightKg;
  final String? label;
  final DateTime createdAt;
  final DateTime? achievedAt;

  /// Manual "Highlight on Home" pin — overrides distance-based highlighting.
  final bool highlightOverride;

  bool get isAchieved => achievedAt != null;

  Goal copyWith({
    int? id,
    double? targetWeightKg,
    String? label,
    DateTime? createdAt,
    DateTime? achievedAt,
    bool clearAchieved = false,
    bool? highlightOverride,
  }) {
    return Goal(
      id: id ?? this.id,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: clearAchieved ? null : (achievedAt ?? this.achievedAt),
      highlightOverride: highlightOverride ?? this.highlightOverride,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetWeightKg': targetWeightKg,
        if (label != null) 'label': label,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (achievedAt != null)
          'achievedAt': achievedAt!.toUtc().toIso8601String(),
        if (highlightOverride) 'highlightOverride': true,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        targetWeightKg: (json['targetWeightKg'] as num).toDouble(),
        label: json['label'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        achievedAt: json['achievedAt'] == null
            ? null
            : DateTime.parse(json['achievedAt'] as String).toLocal(),
        highlightOverride: json['highlightOverride'] as bool? ?? false,
      );
}
