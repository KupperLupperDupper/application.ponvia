import 'package:meta/meta.dart';

enum ReminderFrequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const ReminderFrequency(this.code);
  final String code;

  static ReminderFrequency fromCode(String? code) =>
      ReminderFrequency.values.firstWhere(
        (f) => f.code == code,
        orElse: () => ReminderFrequency.weekly,
      );
}

/// Weigh-in reminder schedule. Pure config; the scheduling engine (M4) turns
/// this into platform notifications.
@immutable
class ReminderConfig {
  const ReminderConfig({
    this.enabled = false,
    this.frequency = ReminderFrequency.weekly,
    this.weekday = DateTime.monday,
    this.dayOfMonth = 1,
    this.hour = 8,
    this.minute = 0,
  });

  final bool enabled;
  final ReminderFrequency frequency;

  /// 1 = Monday … 7 = Sunday (matches [DateTime.weekday]). Used when [frequency]
  /// is [ReminderFrequency.weekly].
  final int weekday;

  /// 1–31; clamped to a month's last day at schedule time. Used when [frequency]
  /// is [ReminderFrequency.monthly].
  final int dayOfMonth;

  final int hour;
  final int minute;

  static const ReminderConfig disabled = ReminderConfig();

  ReminderConfig copyWith({
    bool? enabled,
    ReminderFrequency? frequency,
    int? weekday,
    int? dayOfMonth,
    int? hour,
    int? minute,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'frequency': frequency.code,
        'weekday': weekday,
        'dayOfMonth': dayOfMonth,
        'hour': hour,
        'minute': minute,
      };

  factory ReminderConfig.fromJson(Map<String, dynamic> json) => ReminderConfig(
        enabled: json['enabled'] as bool? ?? false,
        frequency: ReminderFrequency.fromCode(json['frequency'] as String?),
        weekday: json['weekday'] as int? ?? DateTime.monday,
        dayOfMonth: json['dayOfMonth'] as int? ?? 1,
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      );
}
