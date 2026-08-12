import 'package:meta/meta.dart';

/// A target weight the user is working toward. Canonical unit is kilograms.
@immutable
class Goal {
  const Goal({
    this.id,
    required this.targetWeightKg,
    this.label,
    this.startWeightKg,
    required this.createdAt,
    this.achievedAt,
    this.highlightOverride = false,
    this.reachedPromptShownAt,
  });

  final int? id;
  final double targetWeightKg;
  final String? label;

  /// The latest weight when the goal was created; anchors the lose/gain
  /// direction for auto-detection. Null for goals created before it was
  /// captured (direction is then inferred from the prior weight instead).
  final double? startWeightKg;
  final DateTime createdAt;
  final DateTime? achievedAt;

  /// Manual "Highlight on Home" pin — overrides distance-based highlighting.
  final bool highlightOverride;

  /// When the "you reached it" moment was shown (set once, regardless of the
  /// user's answer) so the prompt never re-opens for this goal.
  final DateTime? reachedPromptShownAt;

  bool get isAchieved => achievedAt != null;

  Goal copyWith({
    int? id,
    double? targetWeightKg,
    String? label,
    double? startWeightKg,
    DateTime? createdAt,
    DateTime? achievedAt,
    DateTime? reachedPromptShownAt,
    bool clearAchieved = false,
    bool? highlightOverride,
    bool clearReachedPrompt = false,
  }) {
    return Goal(
      id: id ?? this.id,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      label: label ?? this.label,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: clearAchieved ? null : (achievedAt ?? this.achievedAt),
      highlightOverride: highlightOverride ?? this.highlightOverride,
      reachedPromptShownAt: clearReachedPrompt
          ? null
          : (reachedPromptShownAt ?? this.reachedPromptShownAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'targetWeightKg': targetWeightKg,
        if (label != null) 'label': label,
        if (startWeightKg != null) 'startWeightKg': startWeightKg,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (achievedAt != null)
          'achievedAt': achievedAt!.toUtc().toIso8601String(),
        if (highlightOverride) 'highlightOverride': true,
        if (reachedPromptShownAt != null)
          'reachedPromptShownAt': reachedPromptShownAt!.toUtc().toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        targetWeightKg: (json['targetWeightKg'] as num).toDouble(),
        label: json['label'] as String?,
        startWeightKg: (json['startWeightKg'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        achievedAt: json['achievedAt'] == null
            ? null
            : DateTime.parse(json['achievedAt'] as String).toLocal(),
        highlightOverride: json['highlightOverride'] as bool? ?? false,
        reachedPromptShownAt: json['reachedPromptShownAt'] == null
            ? null
            : DateTime.parse(json['reachedPromptShownAt'] as String).toLocal(),
      );
}
