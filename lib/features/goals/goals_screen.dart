import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/ponvia_colors.dart';
import '../../app/theme/typography.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/goal_eta_line.dart';
import '../../core/ui/spacing.dart';
import '../../core/ui/undo_snackbar.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../logging/numeric_keypad.dart';

/// Goals list styled to DESIGN_SPEC §6: a highlighted "closest goal" card plus
/// regular / achieved / gain cards, each with progress and a footer.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final closest = ref.watch(closestGoalProvider);
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final currentKg = entries.isEmpty ? null : entries.first.weightKg;
    final startKg = entries.isEmpty ? null : entries.last.weightKg;
    final fmt = WeightFormatter(settings.unit,
        locale: Localizations.localeOf(context).languageCode);
    final dateFmt =
        PonviaDateFormatter(locale: Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Insets.md),
            child: FilledButton.tonalIcon(
              onPressed: () => _showGoalSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.goalNew),
              style: FilledButton.styleFrom(
                // The theme's minimumSize is Size.fromHeight(56) (infinite
                // width); pin a finite 40dp height so it fits an AppBar action.
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
              ),
            ),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (goals) {
          if (goals.isEmpty) return _EmptyGoals(l10n: l10n);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Insets.screenH, Insets.lg, Insets.screenH, 96),
            children: [
              for (final g in goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.cardGap),
                  child: _SwipeToDelete(
                    dismissKey:
                        ValueKey(g.id ?? g.createdAt.toIso8601String()),
                    radius: g.id == closest?.id ? 28 : 24,
                    onDismissed: () => _delete(context, ref, g),
                    child: _GoalCard(
                      goal: g,
                      fmt: fmt,
                      dateFmt: dateFmt,
                      unit: settings.unit,
                      currentKg: currentKg,
                      startKg: startKg,
                      entries: entries,
                      highlighted: g.id == closest?.id,
                      onTap: () => _showGoalSheet(context, existing: g),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, Goal g) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(goalRepositoryProvider);
    if (g.id != null) repo.delete(g.id!);
    showUndoSnackbar(
      context,
      message: l10n.snackbarGoalDeleted,
      undoLabel: l10n.actionUndo,
      icon: Icons.delete_outline,
      onUndo: () => repo.add(Goal(
        targetWeightKg: g.targetWeightKg,
        label: g.label,
        startWeightKg: g.startWeightKg,
        createdAt: g.createdAt,
        achievedAt: g.achievedAt,
        reachedPromptShownAt: g.reachedPromptShownAt,
      )),
    );
  }

  /// Opens the add/edit-goal modal bottom sheet (DESIGN_SPEC §6), driven by the
  /// app's custom [NumericKeypad] — mirroring the log-weight sheet.
  Future<void> _showGoalSheet(BuildContext context, {Goal? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Present over the root navigator so the sheet covers the bottom nav
      // (like the log-weight sheet) instead of opening behind it.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => _GoalForm(existing: existing),
    );
  }
}

/// The add/edit-goal form: a themed sheet whose target-weight field is driven by
/// the custom [NumericKeypad] (kg-canonical, locale decimal separator, one
/// decimal place, range-validated). See DESIGN_SPEC §6.
class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _labelController = TextEditingController();
  String _input = '';
  bool _highlight = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      final unit = ref.read(settingsControllerProvider).unit;
      _input = WeightConverter.fromKg(g.targetWeightKg, unit)
          .toStringAsFixed(1)
          .replaceAll('.', _sep);
      _labelController.text = g.label ?? '';
      _highlight = g.highlightOverride;
    }
  }

  String get _sep =>
      Localizations.localeOf(context).languageCode == 'da' ? ',' : '.';

  double? get _parsed {
    if (_input.isEmpty) return null;
    return double.tryParse(_input.replaceAll(_sep, '.'));
  }

  double? get _kg {
    final v = _parsed;
    if (v == null) return null;
    return WeightConverter.toKg(v, ref.read(settingsControllerProvider).unit);
  }

  bool get _valid {
    final kg = _kg;
    return kg != null && kg >= 20 && kg <= 400;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _onKey(String k) {
    setState(() {
      if (k == _sep) {
        if (!_input.contains(_sep)) {
          _input = _input.isEmpty ? '0$_sep' : '$_input$_sep';
        }
        return;
      }
      // Enforce at most one decimal place.
      final sepIndex = _input.indexOf(_sep);
      if (sepIndex != -1 && _input.length - sepIndex > 1) return;
      if (_input.replaceAll(_sep, '').length >= 5) return;
      _input += k;
    });
  }

  void _onBackspace() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  Future<void> _toggleAchieved() async {
    final g = widget.existing!;
    final repo = ref.read(goalRepositoryProvider);
    await repo.update(g.isAchieved
        ? g.copyWith(clearAchieved: true)
        : g.copyWith(achievedAt: DateTime.now()));
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _save() async {
    final kg = _kg;
    if (kg == null || !_valid) return;
    setState(() => _saving = true);
    final label = _labelController.text.trim();
    final labelOrNull = label.isEmpty ? null : label;
    final repo = ref.read(goalRepositoryProvider);
    final existing = widget.existing;
    final int id;
    if (existing == null) {
      // Anchor the goal's direction (lose vs gain) to the current weight.
      final startKg = ref.read(latestWeightProvider).asData?.value?.weightKg;
      id = await repo.add(Goal(
        targetWeightKg: kg,
        label: labelOrNull,
        startWeightKg: startKg,
        createdAt: DateTime.now(),
      ));
    } else {
      id = existing.id!;
      await repo.update(Goal(
        id: id,
        targetWeightKg: kg,
        label: labelOrNull,
        startWeightKg: existing.startWeightKg,
        createdAt: existing.createdAt,
        achievedAt: existing.achievedAt,
        highlightOverride: existing.highlightOverride,
        reachedPromptShownAt: existing.reachedPromptShownAt,
      ));
    }
    // Apply the pin last so exclusivity (clearing other goals) always holds.
    await repo.setHighlightOverride(id, _highlight);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsControllerProvider);
    final unit = settings.unit;
    final currentKg =
        ref.watch(latestWeightProvider).asData?.value?.weightKg;
    final showError = _input.isNotEmpty && !_valid;

    // Direction is derived from the latest weight; unknown until we have both a
    // valid target and a current weight to compare against.
    final targetKg = _valid ? _kg : null;
    final String directionText;
    final IconData? directionIcon;
    final Color directionColor;
    if (targetKg == null || currentKg == null || targetKg == currentKg) {
      directionText = l10n.goalDirectionUnknown;
      directionIcon = null;
      directionColor = scheme.onSurfaceVariant;
    } else if (targetKg > currentKg) {
      directionText = l10n.goalDirectionGain;
      directionIcon = Icons.arrow_upward;
      directionColor = scheme.onSurfaceVariant;
    } else {
      directionText = l10n.goalDirectionLose;
      directionIcon = Icons.arrow_downward;
      directionColor = scheme.onSurfaceVariant;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        bottom: Insets.xxl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(_isEditing ? l10n.goalEdit : l10n.goalNew,
                    style: text.titleLarge),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    tooltip: widget.existing!.isAchieved
                        ? l10n.goalReopen
                        : l10n.goalMarkAchieved,
                    icon: Icon(widget.existing!.isAchieved
                        ? Icons.undo
                        : Icons.check_circle_outline),
                    onPressed: _toggleAchieved,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            // TARGET WEIGHT label
            Text(
              l10n.goalTargetLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: Insets.sm),
            // Target-weight field (2dp primary border) — driven by the keypad.
            _TargetField(
              input: _input,
              unit: unit,
              error: showError,
            ),
            SizedBox(
              height: 22,
              child: showError
                  ? Padding(
                      padding: const EdgeInsets.only(top: Insets.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: scheme.error),
                          const SizedBox(width: Insets.xs),
                          Text(l10n.logRangeError,
                              style: text.bodySmall
                                  ?.copyWith(color: scheme.error)),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: Insets.sm),
            // Optional label
            TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.goalLabelHint,
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: Insets.md),
            // Read-only direction row
            Row(
              children: [
                Text(l10n.goalDirectionLabel,
                    style: text.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const Spacer(),
                _DirectionChip(
                  label: directionText,
                  icon: directionIcon,
                  color: directionColor,
                ),
              ],
            ),
            const Divider(height: Insets.xl),
            // Highlight on Home switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _highlight,
              onChanged: (v) => setState(() => _highlight = v),
              title: Text(l10n.goalHighlightOnHome,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text(l10n.goalHighlightOnHomeSub,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: Insets.sm),
            NumericKeypad(
              onKey: _onKey,
              onBackspace: _onBackspace,
              decimalSeparator: _sep,
            ),
            const SizedBox(height: Insets.md),
            // Footer: Cancel (flex 1) + Save goal (flex 1.4)
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  flex: 14,
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: (_valid && !_saving) ? _save : null,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.goalSave),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The 64dp target-weight field with a 2dp primary border, showing the keypad
/// input as a 32sp value + 18sp unit (DESIGN_SPEC §6).
class _TargetField extends StatelessWidget {
  const _TargetField(
      {required this.input, required this.unit, required this.error});

  final String input;
  final WeightUnit unit;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = input.isEmpty;
    final borderColor = error ? scheme.error : scheme.primary;
    final valueColor = empty
        ? scheme.onSurfaceVariant
        : (error ? scheme.error : scheme.onSurface);
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: empty ? '0' : input,
              style: PonviaTypography.heroWeight
                  .copyWith(fontSize: 32, color: valueColor),
            ),
            TextSpan(
              text: ' ${unit.code}',
              style: TextStyle(
                fontFamily: PonviaTypography.family,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The read-only Direction chip (lose / gain / not-enough-data).
class _DirectionChip extends StatelessWidget {
  const _DirectionChip(
      {required this.label, required this.icon, required this.color});

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: Insets.xs),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Swipe-to-delete that keeps the red delete surface as a single full-bleed
/// layer *behind* the card (not a separate rounded shape beside it), so the red
/// is revealed flush with the card edge as you swipe — no gap, no hard cut.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    required this.dismissKey,
    required this.radius,
    required this.onDismissed,
    required this.child,
  });

  final Key dismissKey;
  final double radius;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Full-bleed red under the whole card; the sliding card sits on top,
          // so whatever it uncovers is red — flush by construction.
          Positioned.fill(
            child: Container(
              color: scheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: Insets.xl),
              child: Icon(Icons.delete_outline,
                  color: scheme.onErrorContainer),
            ),
          ),
          Dismissible(
            key: dismissKey,
            direction: DismissDirection.endToStart,
            // The red is the Stack layer above; Dismissible needs none of its own.
            background: const SizedBox.shrink(),
            onDismissed: (_) => onDismissed(),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.fmt,
    required this.dateFmt,
    required this.unit,
    required this.currentKg,
    required this.startKg,
    required this.entries,
    required this.highlighted,
    required this.onTap,
  });

  final Goal goal;
  final WeightFormatter fmt;
  final PonviaDateFormatter dateFmt;
  final WeightUnit unit;
  final double? currentKg;
  final double? startKg;
  final List<WeightEntry> entries;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ponvia = Theme.of(context).extension<PonviaColors>()!;
    final text = Theme.of(context).textTheme;

    final onColor = highlighted ? scheme.onPrimaryContainer : scheme.onSurface;
    final subColor =
        highlighted ? scheme.onPrimaryContainer.withValues(alpha: 0.8) : scheme.onSurfaceVariant;

    final isGain = currentKg != null && goal.targetWeightKg > currentKg!;
    final remaining =
        currentKg == null ? null : (goal.targetWeightKg - currentKg!).abs();

    double? progress;
    if (goal.isAchieved) {
      progress = 1;
    } else if (currentKg != null &&
        startKg != null &&
        startKg != goal.targetWeightKg) {
      progress = ((currentKg! - startKg!) / (goal.targetWeightKg - startKg!))
          .clamp(0.0, 1.0);
    }

    Widget directionRow() {
      if (goal.isAchieved) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 18, color: scheme.primary),
          const SizedBox(width: Insets.xs),
          Text(l10n.goalAchieved,
              style: text.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
        ]);
      }
      if (remaining == null) return const SizedBox.shrink();
      final color = isGain ? ponvia.deltaUp : onColor;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isGain ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18, color: color),
        const SizedBox(width: Insets.xs),
        Text(
          isGain
              ? l10n.goalToGain(fmt.withUnit(remaining))
              : l10n.goalToLose(fmt.withUnit(remaining)),
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
      ]);
    }

    final showBar = progress != null && (!isGain || progress > 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(highlighted ? 28 : 24),
      child: Container(
        padding: const EdgeInsets.all(Insets.xl),
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(highlighted ? 28 : 24),
          border: highlighted ? null : Border.all(color: scheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted) ...[
              _ClosestChip(label: l10n.goalClosest.toUpperCase()),
              const SizedBox(height: Insets.md),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: fmt.value(goal.targetWeightKg),
                        style: text.headlineMedium?.copyWith(
                            fontSize: highlighted ? 40 : 32, color: onColor)),
                    if (unit != WeightUnit.st)
                      TextSpan(
                          text: ' ${unit.code}',
                          style: text.titleMedium?.copyWith(color: subColor)),
                  ]),
                ),
                const Spacer(),
                directionRow(),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: Insets.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: highlighted ? 10 : 8,
                  backgroundColor: highlighted
                      ? scheme.onPrimaryContainer.withValues(alpha: 0.16)
                      : scheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ],
            _footer(context, l10n, subColor, progress),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n, Color subColor,
      double? progress) {
    final text = Theme.of(context).textTheme;
    if (goal.isAchieved && goal.achievedAt != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Text(l10n.goalReached(dateFmt.date(goal.achievedAt!)),
            style: text.bodySmall?.copyWith(color: subColor)),
      );
    }
    if (highlighted && startKg != null && progress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Insets.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.goalStarted(
                      fmt.withUnit(startKg!), dateFmt.date(goal.createdAt)),
                  style: text.bodySmall?.copyWith(color: subColor),
                ),
                Text('${(progress * 100).round()}%',
                    style: text.bodySmall?.copyWith(
                        color: subColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          GoalEtaLine(
              entries: entries, targetKg: goal.targetWeightKg, color: subColor),
        ],
      );
    }
    if (goal.label != null && goal.label!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Text(goal.label!, style: text.bodySmall?.copyWith(color: subColor)),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ClosestChip extends StatelessWidget {
  const _ClosestChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: scheme.onPrimary),
          const SizedBox(width: Insets.xs),
          Text(label,
              style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: scheme.surfaceContainer, shape: BoxShape.circle),
              child: Icon(Icons.flag, size: 40, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xl),
            Text(l10n.goalsEmpty,
                textAlign: TextAlign.center, style: text.bodyLarge),
          ],
        ),
      ),
    );
  }
}
