// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Ponvia';

  @override
  String get navHome => 'Hjem';

  @override
  String get navHistory => 'Historik';

  @override
  String get navGoals => 'Mål';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get actionSave => 'Gem';

  @override
  String get actionCancel => 'Annullér';

  @override
  String get actionAdd => 'Tilføj';

  @override
  String get actionDelete => 'Slet';

  @override
  String get actionEdit => 'Redigér';

  @override
  String get actionChange => 'Skift';

  @override
  String get actionNext => 'Næste';

  @override
  String get actionBack => 'Tilbage';

  @override
  String get actionSkip => 'Spring over';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String get homeLatestWeight => 'Seneste vægt';

  @override
  String get homeLogWeight => 'Registrér vægt';

  @override
  String get homeEmptyTitle => 'Ingen vægt registreret endnu';

  @override
  String get homeEmptyBody =>
      'Tryk på “Registrér vægt” for at tilføje din første måling.';

  @override
  String get homeClosestGoal => 'Nærmeste mål';

  @override
  String homeTarget(String value) {
    return 'Mål $value';
  }

  @override
  String goalToLose(String amount) {
    return '$amount at tabe';
  }

  @override
  String goalToGain(String amount) {
    return '$amount at tage på';
  }

  @override
  String get historyTitle => 'Historik';

  @override
  String get historyEmpty => 'Ingen målinger endnu.';

  @override
  String get historyEmptyRange => 'Ingen målinger i denne periode.';

  @override
  String get range1W => '1u';

  @override
  String get range1M => '1m';

  @override
  String get range3M => '3m';

  @override
  String get range1Y => '1å';

  @override
  String get rangeAll => 'Alle';

  @override
  String get goalsTitle => 'Mål';

  @override
  String get goalsEmpty => 'Ingen mål endnu. Tryk på + for at tilføje et.';

  @override
  String get goalNew => 'Nyt mål';

  @override
  String get goalEdit => 'Redigér mål';

  @override
  String goalTargetField(String unit) {
    return 'Mål ($unit)';
  }

  @override
  String get goalLabelField => 'Etiket (valgfri)';

  @override
  String get goalAchieved => 'Opnået';

  @override
  String get goalMarkAchieved => 'Markér som opnået';

  @override
  String get goalReopen => 'Genåbn';

  @override
  String get logTitle => 'Registrér vægt';

  @override
  String get logEditTitle => 'Redigér måling';

  @override
  String logWeightField(String unit) {
    return 'Vægt ($unit)';
  }

  @override
  String get logNoteField => 'Note (valgfri)';

  @override
  String get logSaveChanges => 'Gem ændringer';

  @override
  String get logErrorNumber => 'Indtast et tal';

  @override
  String get logErrorRealistic => 'Indtast en realistisk vægt';

  @override
  String get settingsAppearance => 'Udseende';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeDark => 'Mørk';

  @override
  String get settingsUnit => 'Vægtenhed';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'Engelsk';

  @override
  String get languageDanish => 'Dansk';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExportJson => 'Eksportér backup (JSON)';

  @override
  String get settingsExportJsonSub => 'Fuld backup: vægt, mål, indstillinger';

  @override
  String get settingsExportCsv => 'Eksportér vægt (CSV)';

  @override
  String get settingsExportCsvSub => 'Vægthistorik til regneark';

  @override
  String get settingsImport => 'Importér (JSON eller CSV)';

  @override
  String get settingsImportSub => 'Gendan eller flet en backup';

  @override
  String get settingsClear => 'Ryd målinger og mål';

  @override
  String get settingsAbout => 'Om';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPrivacy => 'Privatliv';

  @override
  String get settingsPrivacyBody => 'Alle data bliver på din enhed.';

  @override
  String get importDialogTitle => 'Importér data';

  @override
  String get importDialogBody =>
      'Flet tilføjer nye poster til dine eksisterende data. Erstat sletter alle nuværende data først. Dette kan ikke fortrydes.';

  @override
  String get importMerge => 'Flet';

  @override
  String get importReplace => 'Erstat';

  @override
  String importedSummary(int entries, int goals) {
    return 'Importerede $entries målinger, $goals mål';
  }

  @override
  String importedCsv(int count) {
    return 'Importerede $count målinger';
  }

  @override
  String get importCouldNotRead => 'Kunne ikke læse filen';

  @override
  String importFailed(String error) {
    return 'Import mislykkedes: $error';
  }

  @override
  String exportSaved(String name) {
    return 'Gemte $name';
  }

  @override
  String exportFailed(String error) {
    return 'Eksport mislykkedes: $error';
  }

  @override
  String get clearDialogTitle => 'Ryd målinger og mål?';

  @override
  String get clearDialogBody =>
      'Dette sletter permanent alle vægtmålinger og mål. Dette kan ikke fortrydes.';

  @override
  String get onboardWelcomeBody =>
      'Følg din vægt. Alle data bliver på din enhed.';

  @override
  String get onboardChooseLanguage => 'Vælg dit sprog';

  @override
  String get onboardPreferredUnit => 'Foretrukken enhed';

  @override
  String get onboardChooseTheme => 'Tema';

  @override
  String get onboardFirstWeightTitle => 'Registrér din første vægt';

  @override
  String get onboardFirstWeightBody =>
      'Valgfrit — du kan altid gøre det senere.';

  @override
  String get onboardAllSetTitle => 'Så er du klar';

  @override
  String get onboardAllSetBody => 'Ponvia holder din seneste vægt i fokus.';

  @override
  String get onboardGetStarted => 'Kom i gang';
}
