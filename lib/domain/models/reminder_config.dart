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
    this.weekdays = const {DateTime.monday},
    this.dayOfMonth = 1,
    this.hour = 8,
    this.minute = 0,
  });

  final bool enabled;
  final ReminderFrequency frequency;

  /// The weekdays a weekly reminder fires on (1 = Monday … 7 = Sunday, matching
  /// [DateTime.weekday]). Used when [frequency] is [ReminderFrequency.weekly].
  /// Always non-empty — the UI blocks clearing the last day and [fromJson]
  /// falls back to Monday.
  final Set<int> weekdays;

  /// 1–31; clamped to a month's last day at schedule time. Used when [frequency]
  /// is [ReminderFrequency.monthly].
  final int dayOfMonth;

  final int hour;
  final int minute;

  static const ReminderConfig disabled = ReminderConfig();

  ReminderConfig copyWith({
    bool? enabled,
    ReminderFrequency? frequency,
    Set<int>? weekdays,
    int? dayOfMonth,
    int? hour,
    int? minute,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'frequency': frequency.code,
        'weekdays': (weekdays.toList()..sort()),
        'dayOfMonth': dayOfMonth,
        'hour': hour,
        'minute': minute,
      };

  factory ReminderConfig.fromJson(Map<String, dynamic> json) => ReminderConfig(
        enabled: json['enabled'] as bool? ?? false,
        frequency: ReminderFrequency.fromCode(json['frequency'] as String?),
        weekdays: _parseWeekdays(json),
        dayOfMonth: json['dayOfMonth'] as int? ?? 1,
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      );

  /// Reads the weekday set, migrating older data: prefer the `weekdays` list;
  /// fall back to a legacy single `weekday` int; then to Monday. Never empty.
  static Set<int> _parseWeekdays(Map<String, dynamic> json) {
    final raw = json['weekdays'];
    if (raw is List) {
      final set = raw
          .whereType<int>()
          .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
          .toSet();
      if (set.isNotEmpty) return set;
    }
    final legacy = json['weekday'];
    if (legacy is int && legacy >= DateTime.monday && legacy <= DateTime.sunday) {
      return {legacy};
    }
    return {DateTime.monday};
  }
}
