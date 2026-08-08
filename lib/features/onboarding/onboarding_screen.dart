import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/app_settings.dart';

/// Minimal first-run flow for M1: pick unit + theme, then continue. The full
/// designed onboarding (welcome, language, reminders) lands in M3.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Ponvia', style: text.displaySmall),
              const SizedBox(height: Insets.md),
              Text(
                'Track your weight. All data stays on your device.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: Insets.xxxl),
              Text('Preferred unit', style: text.labelLarge),
              const SizedBox(height: Insets.sm),
              SegmentedButton<WeightUnit>(
                segments: const [
                  ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                  ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                  ButtonSegment(value: WeightUnit.st, label: Text('st')),
                ],
                selected: {settings.unit},
                onSelectionChanged: (s) => controller.setUnit(s.first),
              ),
              const SizedBox(height: Insets.xl),
              Text('Theme', style: text.labelLarge),
              const SizedBox(height: Insets.sm),
              SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: AppThemeMode.system, label: Text('System')),
                  ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => controller.setThemeMode(s.first),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () async {
                  await controller.completeOnboarding();
                  if (context.mounted) context.go('/');
                },
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
