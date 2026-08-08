import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ponvia'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @homeLatestWeight.
  ///
  /// In en, this message translates to:
  /// **'Latest weight'**
  String get homeLatestWeight;

  /// No description provided for @homeLogWeight.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get homeLogWeight;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No weight logged yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap “Log weight” to record your first entry.'**
  String get homeEmptyBody;

  /// No description provided for @homeClosestGoal.
  ///
  /// In en, this message translates to:
  /// **'Closest goal'**
  String get homeClosestGoal;

  /// No description provided for @homeTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {value}'**
  String homeTarget(String value);

  /// No description provided for @goalToLose.
  ///
  /// In en, this message translates to:
  /// **'{amount} to lose'**
  String goalToLose(String amount);

  /// No description provided for @goalToGain.
  ///
  /// In en, this message translates to:
  /// **'{amount} to gain'**
  String goalToGain(String amount);

  /// No description provided for @homeDeltaDown.
  ///
  /// In en, this message translates to:
  /// **'Down {amount}'**
  String homeDeltaDown(String amount);

  /// No description provided for @homeDeltaUp.
  ///
  /// In en, this message translates to:
  /// **'Up {amount}'**
  String homeDeltaUp(String amount);

  /// No description provided for @homeDeltaFlat.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get homeDeltaFlat;

  /// No description provided for @homeTrendFooter.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String homeTrendFooter(int days);

  /// No description provided for @homeGoalRow.
  ///
  /// In en, this message translates to:
  /// **'Goal · {target}'**
  String homeGoalRow(String target);

  /// No description provided for @homeToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String homeToGo(String amount);

  /// No description provided for @homeProgressFrom.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the way from {start}'**
  String homeProgressFrom(int percent, String start);

  /// No description provided for @homeCaloriesSlot.
  ///
  /// In en, this message translates to:
  /// **'Calories — coming soon'**
  String get homeCaloriesSlot;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyRange.
  ///
  /// In en, this message translates to:
  /// **'No entries in this range.'**
  String get historyEmptyRange;

  /// No description provided for @range1W.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get range1W;

  /// No description provided for @range1M.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get range1M;

  /// No description provided for @range3M.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get range3M;

  /// No description provided for @range1Y.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get range1Y;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. Tap + to add one.'**
  String get goalsEmpty;

  /// No description provided for @goalNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalNew;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// No description provided for @goalTargetField.
  ///
  /// In en, this message translates to:
  /// **'Target ({unit})'**
  String goalTargetField(String unit);

  /// No description provided for @goalLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get goalLabelField;

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get goalAchieved;

  /// No description provided for @goalMarkAchieved.
  ///
  /// In en, this message translates to:
  /// **'Mark achieved'**
  String get goalMarkAchieved;

  /// No description provided for @goalReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get goalReopen;

  /// No description provided for @goalStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {weight} · {date}'**
  String goalStarted(String weight, String date);

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Reached {date}'**
  String goalReached(String date);

  /// No description provided for @goalClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest goal'**
  String get goalClosest;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get logTitle;

  /// No description provided for @logEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get logEditTitle;

  /// No description provided for @logWeightField.
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String logWeightField(String unit);

  /// No description provided for @logNoteField.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get logNoteField;

  /// No description provided for @logSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get logSaveChanges;

  /// No description provided for @logErrorNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get logErrorNumber;

  /// No description provided for @logErrorRealistic.
  ///
  /// In en, this message translates to:
  /// **'Enter a realistic weight'**
  String get logErrorRealistic;

  /// No description provided for @logDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get logDateLabel;

  /// No description provided for @logTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get logTimeLabel;

  /// No description provided for @logAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get logAddNote;

  /// No description provided for @logRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 20 and 400 kg'**
  String get logRangeError;

  /// No description provided for @logDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get logDeleted;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExportData;

  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get settingsImportData;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight unit'**
  String get settingsUnit;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDanish.
  ///
  /// In en, this message translates to:
  /// **'Dansk'**
  String get languageDanish;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export backup (JSON)'**
  String get settingsExportJson;

  /// No description provided for @settingsExportJsonSub.
  ///
  /// In en, this message translates to:
  /// **'Full backup: weights, goals, settings'**
  String get settingsExportJsonSub;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export weights (CSV)'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportCsvSub.
  ///
  /// In en, this message translates to:
  /// **'Weight history for spreadsheets'**
  String get settingsExportCsvSub;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import (JSON or CSV)'**
  String get settingsImport;

  /// No description provided for @settingsImportSub.
  ///
  /// In en, this message translates to:
  /// **'Restore or merge a backup'**
  String get settingsImportSub;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear entries & goals'**
  String get settingsClear;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device.'**
  String get settingsPrivacyBody;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importDialogTitle;

  /// No description provided for @importDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Merge adds new records to your existing data. Replace deletes all current data first. This cannot be undone.'**
  String get importDialogBody;

  /// No description provided for @importMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get importMerge;

  /// No description provided for @importReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get importReplace;

  /// No description provided for @importedSummary.
  ///
  /// In en, this message translates to:
  /// **'Imported {entries} entries, {goals} goals'**
  String importedSummary(int entries, int goals);

  /// No description provided for @importedCsv.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} entries'**
  String importedCsv(int count);

  /// No description provided for @importCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read file'**
  String get importCouldNotRead;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String exportSaved(String name);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @clearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear entries & goals?'**
  String get clearDialogTitle;

  /// No description provided for @clearDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all weight entries and goals. This cannot be undone.'**
  String get clearDialogBody;

  /// No description provided for @onboardWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track your weight. All data stays on your device.'**
  String get onboardWelcomeBody;

  /// No description provided for @onboardChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardChooseLanguage;

  /// No description provided for @onboardPreferredUnit.
  ///
  /// In en, this message translates to:
  /// **'Preferred unit'**
  String get onboardPreferredUnit;

  /// No description provided for @onboardChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get onboardChooseTheme;

  /// No description provided for @onboardFirstWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight'**
  String get onboardFirstWeightTitle;

  /// No description provided for @onboardFirstWeightBody.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can always do this later.'**
  String get onboardFirstWeightBody;

  /// No description provided for @onboardAllSetTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get onboardAllSetTitle;

  /// No description provided for @onboardAllSetBody.
  ///
  /// In en, this message translates to:
  /// **'Ponvia keeps your latest weight front and center.'**
  String get onboardAllSetBody;

  /// No description provided for @onboardGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardGetStarted;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notifOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifOff;

  /// No description provided for @notifSummary.
  ///
  /// In en, this message translates to:
  /// **'{freq} · {time}'**
  String notifSummary(String freq, String time);

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifTitle;

  /// No description provided for @notifWeighInReminder.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in reminder'**
  String get notifWeighInReminder;

  /// No description provided for @notifFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get notifFrequency;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @notifDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get notifDayOfWeek;

  /// No description provided for @notifDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get notifDayOfMonth;

  /// No description provided for @notifTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get notifTimeOfDay;

  /// No description provided for @notifPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notifPermTitle;

  /// No description provided for @notifPermBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to get local weigh-in reminders.'**
  String get notifPermBody;

  /// No description provided for @notifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifAllow;

  /// No description provided for @notifPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to weigh in'**
  String get notifPushTitle;

  /// No description provided for @notifPushBody.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s weight in Ponvia.'**
  String get notifPushBody;

  /// No description provided for @notifNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String notifNext(String when);

  /// No description provided for @notifDaySelected.
  ///
  /// In en, this message translates to:
  /// **'{day} selected'**
  String notifDaySelected(String day);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
