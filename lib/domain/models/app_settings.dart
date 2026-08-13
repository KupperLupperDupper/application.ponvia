import 'package:meta/meta.dart';

import '../../core/units/weight_unit.dart';
import 'reminder_config.dart';

/// Theme preference, kept Flutter-free in the domain. Mapped to Flutter's
/// `ThemeMode` in the presentation layer.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.code);
  final String code;

  static AppThemeMode fromCode(String? code) => AppThemeMode.values.firstWhere(
        (m) => m.code == code,
        orElse: () => AppThemeMode.system,
      );
}

/// All scalar user settings. Persisted via the SettingsStore (shared_preferences)
/// and included in JSON backups.
@immutable
class AppSettings {
  const AppSettings({
    this.localeCode,
    this.themeMode = AppThemeMode.system,
    this.unit = WeightUnit.kg,
    this.hasOnboarded = false,
    this.reminder = ReminderConfig.disabled,
    this.heightCm,
  });

  /// `null` follows the system locale; otherwise `'en'` or `'da'`.
  final String? localeCode;
  final AppThemeMode themeMode;
  final WeightUnit unit;
  final bool hasOnboarded;
  final ReminderConfig reminder;

  /// Optional body height in centimetres (canonical), used only to derive BMI.
  /// `null` when unset — the BMI tile is hidden and nothing else depends on it.
  final int? heightCm;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    AppThemeMode? themeMode,
    WeightUnit? unit,
    bool? hasOnboarded,
    ReminderConfig? reminder,
    int? heightCm,
    bool clearHeight = false,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      themeMode: themeMode ?? this.themeMode,
      unit: unit ?? this.unit,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      reminder: reminder ?? this.reminder,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
    );
  }

  Map<String, dynamic> toJson() => {
        if (localeCode != null) 'localeCode': localeCode,
        'themeMode': themeMode.code,
        'unit': unit.code,
        'hasOnboarded': hasOnboarded,
        'reminder': reminder.toJson(),
        if (heightCm != null) 'heightCm': heightCm,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        localeCode: json['localeCode'] as String?,
        themeMode: AppThemeMode.fromCode(json['themeMode'] as String?),
        unit: WeightUnit.fromCode(json['unit'] as String?),
        hasOnboarded: json['hasOnboarded'] as bool? ?? false,
        reminder: json['reminder'] == null
            ? ReminderConfig.disabled
            : ReminderConfig.fromJson(
                (json['reminder'] as Map).cast<String, dynamic>()),
        heightCm: (json['heightCm'] as num?)?.toInt(),
      );
}
