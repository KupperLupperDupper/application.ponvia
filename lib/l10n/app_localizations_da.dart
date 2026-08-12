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
  String homeDeltaDown(String amount) {
    return 'Ned $amount';
  }

  @override
  String homeDeltaUp(String amount) {
    return 'Op $amount';
  }

  @override
  String get homeDeltaFlat => 'Ingen ændring';

  @override
  String homeTrendFooter(int days) {
    return 'Sidste $days dage';
  }

  @override
  String homeGoalRow(String target) {
    return 'Mål · $target';
  }

  @override
  String homeToGo(String amount) {
    return '$amount tilbage';
  }

  @override
  String homeProgressFrom(int percent, String start) {
    return '$percent % af vejen fra $start';
  }

  @override
  String homeGoalEta(String date) {
    return 'I dit nuværende tempo · ~$date';
  }

  @override
  String get homeCaloriesSlot => 'Kalorier — kommer snart';

  @override
  String get historyTitle => 'Historik';

  @override
  String get historyEmpty => 'Ingen målinger endnu.';

  @override
  String get historyEmptyRange => 'Ingen målinger i denne periode.';

  @override
  String get historySummaryEyebrow => 'DENNE PERIODE';

  @override
  String get statMin => 'Min';

  @override
  String get statAvg => 'Gns.';

  @override
  String get statMax => 'Maks';

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
  String get chartLegendWeight => 'Vægt';

  @override
  String get chartLegendTrend => 'Tendens';

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
  String goalStarted(String weight, String date) {
    return 'Startede $weight · $date';
  }

  @override
  String goalReached(String date) {
    return 'Nået $date';
  }

  @override
  String get goalClosest => 'Nærmeste mål';

  @override
  String get goalReachedTitle => 'Du nåede det';

  @override
  String goalReachedBody(String weight) {
    return 'Du har nået dit mål på $weight.';
  }

  @override
  String get goalReachedKeepOpen => 'Behold det åbne';

  @override
  String get goalReachedMarked => 'Målet er markeret som nået';

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
  String get logDateLabel => 'Dato';

  @override
  String get logTimeLabel => 'Tid';

  @override
  String get logAddNote => 'Tilføj en note (valgfri)';

  @override
  String get logRangeError => 'Indtast en vægt mellem 20 og 400 kg';

  @override
  String get logDeleted => 'Måling slettet';

  @override
  String get actionUndo => 'Fortryd';

  @override
  String get snackbarEntryDeleted => 'Registrering slettet';

  @override
  String get snackbarGoalDeleted => 'Mål slettet';

  @override
  String snackbarAllDataCleared(int entries, int goals) {
    return 'Alle data er slettet — $entries registreringer og $goals mål';
  }

  @override
  String get snackbarDataReplaced => 'Data erstattet af import';

  @override
  String get settingsAppearance => 'Udseende';

  @override
  String get settingsPreferences => 'Præferencer';

  @override
  String get settingsExportData => 'Eksportér data';

  @override
  String get settingsImportData => 'Importér data';

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
  String get privacyLead =>
      'Ponvia kører udelukkende på denne telefon. Der er ingen konto, ingen server, og intet du skal fravælge.';

  @override
  String get privacyNoAccountTitle => 'Ingen konto — nogensinde';

  @override
  String get privacyNoAccountBody =>
      'Der er intet at oprette, og intet at logge ind på.';

  @override
  String get privacyOnDeviceTitle => 'Dine data forlader aldrig enheden';

  @override
  String get privacyOnDeviceBody =>
      'Vægt, mål og noter ligger kun i appens lokale lager på telefonen.';

  @override
  String get privacyNoNetworkTitle => 'Ingen netværkstilladelse';

  @override
  String get privacyNoNetworkBody =>
      'Appen kan ikke nå internettet — tilladelsen er ikke erklæret i manifestet.';

  @override
  String get privacyNoTrackingTitle => 'Ingen sporing, ingen analyse';

  @override
  String get privacyNoTrackingBody =>
      'Ingen brugshændelser, ingen fejlrapportering, ingen identifikatorer.';

  @override
  String get privacyNoAdsTitle => 'Ingen reklamer, ingen tredjeparter';

  @override
  String get privacyNoAdsBody =>
      'Intet indhold i Ponvia leveres af andre end appen selv.';

  @override
  String get privacyFooter =>
      'Den eneste måde, dine data forlader telefonen på, er en eksport, du selv starter, under Indstillinger › Data › Eksportér.';

  @override
  String get importDialogTitle => 'Importér data';

  @override
  String get importDialogBody =>
      'Flet tilføjer nye poster til dine eksisterende data. Erstat sletter alle nuværende data først — du kan fortryde det umiddelbart efter.';

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
      'Dette sletter permanent alle vægtmålinger og mål — du kan fortryde det umiddelbart efter. Eksportér først, hvis du vil have en varig kopi.';

  @override
  String get onboardWelcomeTitle => 'Velkommen til Ponvia';

  @override
  String get onboardWelcomeBody =>
      'Registrér din vægt på sekunder og se tendensen tage form. Ingen konto, ingen sky — alt bliver på denne telefon.';

  @override
  String onboardStep(int current, int total) {
    return 'Trin $current af $total';
  }

  @override
  String get onboardStartTracking => 'Begynd at registrere';

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

  @override
  String get settingsNotifications => 'Notifikationer';

  @override
  String get notifOff => 'Fra';

  @override
  String notifSummary(String freq, String time) {
    return '$freq · $time';
  }

  @override
  String get notifTitle => 'Påmindelser';

  @override
  String get notifWeighInReminder => 'Vejningspåmindelse';

  @override
  String get notifFrequency => 'Hyppighed';

  @override
  String get freqDaily => 'Dagligt';

  @override
  String get freqWeekly => 'Ugentligt';

  @override
  String get freqMonthly => 'Månedligt';

  @override
  String get notifDayOfWeek => 'Ugedag';

  @override
  String get notifDayOfMonth => 'Dag i måneden';

  @override
  String get notifTimeOfDay => 'Tidspunkt';

  @override
  String get notifPermTitle => 'Notifikationer er slået fra';

  @override
  String get notifPermBody =>
      'Slå notifikationer til for at få lokale vejningspåmindelser.';

  @override
  String get notifAllow => 'Tillad notifikationer';

  @override
  String get notifPushTitle => 'Tid til at veje dig';

  @override
  String get notifPushBody => 'Registrér dagens vægt i Ponvia.';

  @override
  String notifNext(String when) {
    return 'Næste: $when';
  }

  @override
  String notifDaySelected(String day) {
    return '$day valgt';
  }

  @override
  String get goalTargetLabel => 'Målvægt';

  @override
  String get goalLabelHint => 'f.eks. Sommermål';

  @override
  String get goalDirectionLabel => 'Retning';

  @override
  String get goalDirectionLose => 'Tab';

  @override
  String get goalDirectionGain => 'Tag på';

  @override
  String get goalDirectionUnknown => 'Ikke nok data endnu';

  @override
  String get goalHighlightOnHome => 'Fremhæv på forsiden';

  @override
  String get goalHighlightOnHomeSub => 'Vis dette måls fremgang på forsiden';

  @override
  String get goalSave => 'Gem mål';
}
