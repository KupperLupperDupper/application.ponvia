import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/reminder_config.dart';

/// Synchronous read / async write wrapper over shared_preferences for scalar
/// app settings.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLocale = 'settings.locale';
  static const _kTheme = 'settings.themeMode';
  static const _kUnit = 'settings.unit';
  static const _kOnboarded = 'settings.hasOnboarded';
  static const _kReminder = 'settings.reminder';

  AppSettings read() {
    final reminderRaw = _prefs.getString(_kReminder);
    return AppSettings(
      localeCode: _prefs.getString(_kLocale),
      themeMode: AppThemeMode.fromCode(_prefs.getString(_kTheme)),
      unit: WeightUnit.fromCode(_prefs.getString(_kUnit)),
      hasOnboarded: _prefs.getBool(_kOnboarded) ?? false,
      reminder: reminderRaw == null
          ? ReminderConfig.disabled
          : ReminderConfig.fromJson(
              (jsonDecode(reminderRaw) as Map).cast<String, dynamic>()),
    );
  }

  Future<void> write(AppSettings s) async {
    if (s.localeCode == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, s.localeCode!);
    }
    await _prefs.setString(_kTheme, s.themeMode.code);
    await _prefs.setString(_kUnit, s.unit.code);
    await _prefs.setBool(_kOnboarded, s.hasOnboarded);
    await _prefs.setString(_kReminder, jsonEncode(s.reminder.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_kLocale);
    await _prefs.remove(_kTheme);
    await _prefs.remove(_kUnit);
    await _prefs.remove(_kOnboarded);
    await _prefs.remove(_kReminder);
  }
}
