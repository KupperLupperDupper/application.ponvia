import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/app/providers.dart';
import 'package:ponvia/app/theme/app_theme.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';
import 'package:ponvia/features/history/history_screen.dart';
import 'package:ponvia/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

MaterialApp _app(Widget home) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// Two recent entries so the month range shows the chart (>= 2 points).
List<WeightEntry> _entries() {
  final now = DateTime.now();
  return [
    WeightEntry(id: 2, timestamp: now.subtract(const Duration(hours: 1)), weightKg: 80),
    WeightEntry(id: 1, timestamp: now.subtract(const Duration(days: 2)), weightKg: 82),
  ];
}

LineChartData _chartData(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart)).data;

void main() {
  testWidgets('trend chart draws a goal marker line at the target', (tester) async {
    final prefs = await _prefs();
    final entries = _entries();
    // Target 78 kg sits just below the 80–82 data, exercising range expansion.
    final goal = Goal(id: 1, targetWeightKg: 78, createdAt: DateTime(2026, 1, 1));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entriesProvider.overrideWith((ref) => Stream.value(entries)),
        goalsProvider.overrideWith((ref) => Stream.value([goal])),
        latestWeightProvider.overrideWith((ref) => Stream.value(entries.first)),
      ],
      child: _app(const HistoryScreen()),
    ));
    await tester.pumpAndSettle();

    final data = _chartData(tester);
    final lines = data.extraLinesData.horizontalLines;
    expect(lines, hasLength(1));
    expect(lines.single.y, closeTo(78.0, 1e-9)); // kg display == canonical

    // Range expanded to keep the off-data line visible, with headroom.
    expect(data.minY, lessThan(78.0));

    // Label wiring: resolver yields the localized "Target 78.0 kg".
    final label = lines.single.label.labelResolver(lines.single);
    expect(label, contains('78.0'));
  });

  testWidgets('no marker line when there is no unachieved goal', (tester) async {
    final prefs = await _prefs();
    final entries = _entries();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entriesProvider.overrideWith((ref) => Stream.value(entries)),
        goalsProvider.overrideWith((ref) => Stream.value(const <Goal>[])),
        latestWeightProvider.overrideWith((ref) => Stream.value(entries.first)),
      ],
      child: _app(const HistoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(_chartData(tester).extraLinesData.horizontalLines, isEmpty);
  });

  testWidgets('achieved goal is ignored — no marker line', (tester) async {
    final prefs = await _prefs();
    final entries = _entries();
    final achieved = Goal(
      id: 1,
      targetWeightKg: 78,
      createdAt: DateTime(2026, 1, 1),
      achievedAt: DateTime(2026, 2, 1),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entriesProvider.overrideWith((ref) => Stream.value(entries)),
        goalsProvider.overrideWith((ref) => Stream.value([achieved])),
        latestWeightProvider.overrideWith((ref) => Stream.value(entries.first)),
      ],
      child: _app(const HistoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(_chartData(tester).extraLinesData.horizontalLines, isEmpty);
  });
}
