import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/app/providers.dart';
import 'package:ponvia/app/theme/app_theme.dart';
import 'package:ponvia/domain/models/goal.dart';
import 'package:ponvia/domain/models/weight_entry.dart';
import 'package:ponvia/features/goals/goals_screen.dart';
import 'package:ponvia/features/home/home_screen.dart';
import 'package:ponvia/features/logging/log_weight_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('Home shows the latest weight and delta', (tester) async {
    final prefs = await _prefs();
    final entries = [
      WeightEntry(id: 2, timestamp: DateTime(2026, 8, 2), weightKg: 80),
      WeightEntry(id: 1, timestamp: DateTime(2026, 8, 1), weightKg: 82),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entriesProvider.overrideWith((ref) => Stream.value(entries)),
        goalsProvider.overrideWith((ref) => Stream.value(const <Goal>[])),
        latestWeightProvider.overrideWith((ref) => Stream.value(entries.first)),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('80.0'), findsOneWidget); // hero, kg default
    expect(find.textContaining('2.0 kg'), findsWidgets); // delta -2.0 kg
  });

  testWidgets('Goals highlights the closest goal with distance', (tester) async {
    final prefs = await _prefs();
    final entry = WeightEntry(timestamp: DateTime(2026, 8, 2), weightKg: 80);
    final goals = [
      Goal(id: 1, targetWeightKg: 78, createdAt: DateTime(2026, 1, 1)),
      Goal(id: 2, targetWeightKg: 90, createdAt: DateTime(2026, 1, 1)),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        entriesProvider.overrideWith((ref) => Stream.value([entry])),
        goalsProvider.overrideWith((ref) => Stream.value(goals)),
        latestWeightProvider.overrideWith((ref) => Stream.value(entry)),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const GoalsScreen()),
    ));
    await tester.pumpAndSettle();

    // Closest goal (78) is 2.0 kg to lose from 80.
    expect(find.textContaining('to lose'), findsWidgets);
    expect(find.textContaining('2.0 kg'), findsWidgets);
  });

  testWidgets('Log form validates a non-numeric weight', (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: LogWeightForm())),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a number'), findsOneWidget);
  });
}
