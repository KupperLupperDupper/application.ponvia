// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ponvia';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionChange => 'Change';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get homeLatestWeight => 'Latest weight';

  @override
  String get homeLogWeight => 'Log weight';

  @override
  String get homeEmptyTitle => 'No weight logged yet';

  @override
  String get homeEmptyBody => 'Tap “Log weight” to record your first entry.';

  @override
  String get homeClosestGoal => 'Closest goal';

  @override
  String homeTarget(String value) {
    return 'Target $value';
  }

  @override
  String goalToLose(String amount) {
    return '$amount to lose';
  }

  @override
  String goalToGain(String amount) {
    return '$amount to gain';
  }

  @override
  String homeDeltaDown(String amount) {
    return 'Down $amount';
  }

  @override
  String homeDeltaUp(String amount) {
    return 'Up $amount';
  }

  @override
  String get homeDeltaFlat => 'No change';

  @override
  String homeTrendFooter(int days) {
    return 'Last $days days';
  }

  @override
  String homeGoalRow(String target) {
    return 'Goal · $target';
  }

  @override
  String homeToGo(String amount) {
    return '$amount to go';
  }

  @override
  String homeProgressFrom(int percent, String start) {
    return '$percent% of the way from $start';
  }

  @override
  String get homeCaloriesSlot => 'Calories — coming soon';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No entries yet.';

  @override
  String get historyEmptyRange => 'No entries in this range.';

  @override
  String get historySummaryEyebrow => 'THIS PERIOD';

  @override
  String get statMin => 'Min';

  @override
  String get statAvg => 'Avg';

  @override
  String get statMax => 'Max';

  @override
  String get range1W => '1W';

  @override
  String get range1M => '1M';

  @override
  String get range3M => '3M';

  @override
  String get range1Y => '1Y';

  @override
  String get rangeAll => 'All';

  @override
  String get chartLegendWeight => 'Weight';

  @override
  String get chartLegendTrend => 'Trend';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsEmpty => 'No goals yet. Tap + to add one.';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalEdit => 'Edit goal';

  @override
  String goalTargetField(String unit) {
    return 'Target ($unit)';
  }

  @override
  String get goalLabelField => 'Label (optional)';

  @override
  String get goalAchieved => 'Achieved';

  @override
  String get goalMarkAchieved => 'Mark achieved';

  @override
  String get goalReopen => 'Reopen';

  @override
  String goalStarted(String weight, String date) {
    return 'Started $weight · $date';
  }

  @override
  String goalReached(String date) {
    return 'Reached $date';
  }

  @override
  String get goalClosest => 'Closest goal';

  @override
  String get logTitle => 'Log weight';

  @override
  String get logEditTitle => 'Edit entry';

  @override
  String logWeightField(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get logNoteField => 'Note (optional)';

  @override
  String get logSaveChanges => 'Save changes';

  @override
  String get logErrorNumber => 'Enter a number';

  @override
  String get logErrorRealistic => 'Enter a realistic weight';

  @override
  String get logDateLabel => 'Date';

  @override
  String get logTimeLabel => 'Time';

  @override
  String get logAddNote => 'Add a note (optional)';

  @override
  String get logRangeError => 'Enter a weight between 20 and 400 kg';

  @override
  String get logDeleted => 'Entry deleted';

  @override
  String get actionUndo => 'Undo';

  @override
  String get snackbarEntryDeleted => 'Entry deleted';

  @override
  String get snackbarGoalDeleted => 'Goal deleted';

  @override
  String snackbarAllDataCleared(int entries, int goals) {
    return 'All data cleared — $entries entries and $goals goals';
  }

  @override
  String get snackbarDataReplaced => 'Data replaced by import';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsExportData => 'Export data';

  @override
  String get settingsImportData => 'Import data';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsUnit => 'Weight unit';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDanish => 'Dansk';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExportJson => 'Export backup (JSON)';

  @override
  String get settingsExportJsonSub => 'Full backup: weights, goals, settings';

  @override
  String get settingsExportCsv => 'Export weights (CSV)';

  @override
  String get settingsExportCsvSub => 'Weight history for spreadsheets';

  @override
  String get settingsImport => 'Import (JSON or CSV)';

  @override
  String get settingsImportSub => 'Restore or merge a backup';

  @override
  String get settingsClear => 'Clear entries & goals';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody => 'All data stays on your device.';

  @override
  String get privacyLead =>
      'Ponvia runs entirely on this phone. There is no account, no server, and nothing to opt out of.';

  @override
  String get privacyNoAccountTitle => 'No account, ever';

  @override
  String get privacyNoAccountBody =>
      'Nothing to sign up for, nothing to sign in to.';

  @override
  String get privacyOnDeviceTitle => 'Your data never leaves the device';

  @override
  String get privacyOnDeviceBody =>
      'Weights, goals and notes live in this app\'s local storage only.';

  @override
  String get privacyNoNetworkTitle => 'No network permission';

  @override
  String get privacyNoNetworkBody =>
      'The app cannot reach the internet — it isn\'t declared in the manifest.';

  @override
  String get privacyNoTrackingTitle => 'No tracking, no analytics';

  @override
  String get privacyNoTrackingBody =>
      'No usage events, no crash reporting, no identifiers.';

  @override
  String get privacyNoAdsTitle => 'No ads, no third parties';

  @override
  String get privacyNoAdsBody =>
      'Nothing in Ponvia is supplied by anyone else.';

  @override
  String get privacyFooter =>
      'The only way your data leaves this phone is an export you start yourself, in Settings › Data › Export.';

  @override
  String get importDialogTitle => 'Import data';

  @override
  String get importDialogBody =>
      'Merge adds new records to your existing data. Replace deletes all current data first — you can undo it right after.';

  @override
  String get importMerge => 'Merge';

  @override
  String get importReplace => 'Replace';

  @override
  String importedSummary(int entries, int goals) {
    return 'Imported $entries entries, $goals goals';
  }

  @override
  String importedCsv(int count) {
    return 'Imported $count entries';
  }

  @override
  String get importCouldNotRead => 'Could not read file';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String exportSaved(String name) {
    return 'Saved $name';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get clearDialogTitle => 'Clear entries & goals?';

  @override
  String get clearDialogBody =>
      'This permanently deletes all weight entries and goals. This cannot be undone.';

  @override
  String get onboardWelcomeTitle => 'Welcome to Ponvia';

  @override
  String get onboardWelcomeBody =>
      'Log your weight in seconds and watch the trend take shape. No account, no cloud — everything stays on this phone.';

  @override
  String onboardStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardStartTracking => 'Start tracking';

  @override
  String get onboardChooseLanguage => 'Choose your language';

  @override
  String get onboardPreferredUnit => 'Preferred unit';

  @override
  String get onboardChooseTheme => 'Theme';

  @override
  String get onboardFirstWeightTitle => 'Log your first weight';

  @override
  String get onboardFirstWeightBody =>
      'Optional — you can always do this later.';

  @override
  String get onboardAllSetTitle => 'You’re all set';

  @override
  String get onboardAllSetBody =>
      'Ponvia keeps your latest weight front and center.';

  @override
  String get onboardGetStarted => 'Get started';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notifOff => 'Off';

  @override
  String notifSummary(String freq, String time) {
    return '$freq · $time';
  }

  @override
  String get notifTitle => 'Reminders';

  @override
  String get notifWeighInReminder => 'Weigh-in reminder';

  @override
  String get notifFrequency => 'Frequency';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get notifDayOfWeek => 'Day of week';

  @override
  String get notifDayOfMonth => 'Day of month';

  @override
  String get notifTimeOfDay => 'Time of day';

  @override
  String get notifPermTitle => 'Notifications are off';

  @override
  String get notifPermBody =>
      'Turn on notifications to get local weigh-in reminders.';

  @override
  String get notifAllow => 'Allow notifications';

  @override
  String get notifPushTitle => 'Time to weigh in';

  @override
  String get notifPushBody => 'Record today\'s weight in Ponvia.';

  @override
  String notifNext(String when) {
    return 'Next: $when';
  }

  @override
  String notifDaySelected(String day) {
    return '$day selected';
  }
}
