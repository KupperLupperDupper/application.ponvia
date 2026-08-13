import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/typography.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/formatting/weight_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/ui/undo_snackbar.dart';
import '../../core/units/weight_unit.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/weight_repository.dart';
import '../../domain/goals/goal_achievement.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../goals/goal_reached_sheet.dart';
import 'numeric_keypad.dart';
import 'stone_fields.dart';
import 'stone_input.dart';

/// Opens the log/edit form as a modal bottom sheet (the design's logging model).
Future<void> showLogWeightSheet(BuildContext context, {WeightEntry? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Present over the root navigator so the sheet always covers the bottom nav
    // (e.g. when opened to edit an entry from the History tab).
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => LogWeightForm(existing: existing),
  );
}

/// Full-screen host for the log form (used by the `/log` route, e.g. reminder
/// deep-links).
class LogWeightScreen extends StatelessWidget {
  const LogWeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).logTitle)),
      body: const SafeArea(child: LogWeightForm(embedded: true)),
    );
  }
}

/// The weight add/edit form with a custom numeric keypad (no OS keyboard for the
/// value). Value is entered in the display unit and stored as kg. See
/// DESIGN_SPEC §4.
class LogWeightForm extends ConsumerStatefulWidget {
  const LogWeightForm({super.key, this.existing, this.embedded = false});

  final WeightEntry? existing;

  /// When true the form is hosted full-screen (no close button in the header).
  final bool embedded;

  @override
  ConsumerState<LogWeightForm> createState() => _LogWeightFormState();
}

class _LogWeightFormState extends ConsumerState<LogWeightForm> {
  final _noteController = TextEditingController();
  String _input = '';
  late DateTime _timestamp;
  bool _saving = false;
  bool _prefilled = false;

  /// Split st+lb entry state, non-null only when the display unit is stone.
  late final bool _isStone;
  StoneInput? _stone;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _timestamp = e?.timestamp ?? DateTime.now();
    _noteController.text = e?.note ?? '';
    _isStone = ref.read(settingsControllerProvider).unit == WeightUnit.st;
    if (_isStone) {
      _stone =
          e != null ? StoneInput.fromKg(e.weightKg) : StoneInput();
      _prefilled = true; // stone read-back needs no locale separator
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill the value here, not in initState: it uses `_sep`, which reads
    // Localizations.localeOf(context) — illegal before initState completes.
    final e = widget.existing;
    if (e != null && !_prefilled) {
      _prefilled = true;
      final unit = ref.read(settingsControllerProvider).unit;
      _input = WeightConverter.fromKg(e.weightKg, unit)
          .toStringAsFixed(1)
          .replaceAll('.', _sep);
    }
  }

  String get _sep =>
      Localizations.localeOf(context).languageCode == 'da' ? ',' : '.';

  double? get _parsed {
    if (_input.isEmpty) return null;
    return double.tryParse(_input.replaceAll(_sep, '.'));
  }

  double? get _kg {
    if (_isStone) return _stone!.kg;
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
    _noteController.dispose();
    super.dispose();
  }

  void _onKey(String k) {
    if (_isStone) {
      setState(() => _stone!.onDigit(k));
      return;
    }
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
    if (_isStone) {
      setState(() => _stone!.onBackspace());
      return;
    }
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _timestamp = DateTime(date.year, date.month, date.day,
          _timestamp.hour, _timestamp.minute));
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time != null && mounted) {
      setState(() => _timestamp = DateTime(_timestamp.year, _timestamp.month,
          _timestamp.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    final kg = _kg;
    if (kg == null || !_valid) return;
    setState(() => _saving = true);
    final note = _noteController.text.trim();
    final entry = WeightEntry(
      id: widget.existing?.id,
      timestamp: _timestamp,
      weightKg: kg,
      note: note.isEmpty ? null : note,
    );
    // Capture everything from `ref` before the sheet pops (this State is
    // disposed on pop; the achievement moment is presented over the app root).
    final repo = ref.read(weightRepositoryProvider);
    final goalRepo = ref.read(goalRepositoryProvider);
    final unit = ref.read(settingsControllerProvider).unit;

    final previousLatestKg = (await repo.latest())?.weightKg;
    if (_isEditing) {
      await repo.update(entry);
    } else {
      await repo.add(entry);
    }

    // Did the new latest weight reach any active, un-prompted goals?
    final reached = await _detectReachedGoals(repo, goalRepo, previousLatestKg);

    if (mounted) Navigator.of(context).maybePop();
    if (reached.isNotEmpty) {
      await _presentGoalReached(goalRepo, unit, reached);
    }
  }

  /// Every active, un-prompted goal the new latest weight has reached, sorted
  /// nearest-target-first. The nearest is shown in the calm moment; all of them
  /// are marked complete together on confirm (a single weigh-in can pass more
  /// than one goal).
  Future<List<Goal>> _detectReachedGoals(
    WeightRepository repo,
    GoalRepository goalRepo,
    double? previousLatestKg,
  ) async {
    final latest = await repo.latest();
    if (latest == null) return const [];
    final goals = await goalRepo.getAll();
    final reached = GoalAchievement.allReached(
      newLatestKg: latest.weightKg,
      previousLatestKg: previousLatestKg,
      goals: goals,
    );
    reached.sort((a, b) => (a.targetWeightKg - latest.weightKg)
        .abs()
        .compareTo((b.targetWeightKg - latest.weightKg).abs()));
    return reached;
  }

  /// Presents the calm "you reached it" sheet over the app root (the log sheet
  /// has already closed). Confirm sets `achievedAt`; keep-open just records that
  /// the prompt was shown so it never re-opens for this goal.
  Future<void> _presentGoalReached(
    GoalRepository goalRepo,
    WeightUnit unit,
    List<Goal> reached,
  ) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final nearest = reached.first;
    final fmt =
        WeightFormatter(unit, locale: Localizations.localeOf(ctx).languageCode);
    final weightLabel = fmt.withUnit(nearest.targetWeightKg);
    // Let the log sheet's close animation finish before presenting.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!ctx.mounted) return;

    final confirmed = await showGoalReachedSheet(ctx, weightLabel: weightLabel);
    if (!ctx.mounted) return;
    final l10n = AppLocalizations.of(ctx);
    final now = DateTime.now();
    if (confirmed == true) {
      // A single weigh-in can pass several goals — mark them all complete.
      for (final g in reached) {
        await goalRepo.update(
            g.copyWith(achievedAt: now, reachedPromptShownAt: now));
      }
      if (!ctx.mounted) return;
      showUndoSnackbar(
        ctx,
        message: l10n.goalReachedMarked,
        undoLabel: l10n.actionUndo,
        icon: Icons.check_circle_outline,
        onUndo: () {
          for (final g in reached) {
            goalRepo.update(
                g.copyWith(clearAchieved: true, clearReachedPrompt: true));
          }
        },
      );
    } else {
      // Keep them open: record the prompt on all so they won't re-nag.
      for (final g in reached) {
        await goalRepo.update(g.copyWith(reachedPromptShownAt: now));
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(weightRepositoryProvider);
    final e = widget.existing!;
    if (e.id != null) await repo.delete(e.id!);
    if (mounted) Navigator.of(context).maybePop();
    // The sheet is gone; show over the app via the root context.
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showUndoSnackbar(
      ctx,
      message: l10n.snackbarEntryDeleted,
      undoLabel: l10n.actionUndo,
      icon: Icons.delete_outline,
      onUndo: () => repo.add(WeightEntry(
          timestamp: e.timestamp, weightKg: e.weightKg, note: e.note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsControllerProvider);
    final unit = settings.unit;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = PonviaDateFormatter(locale: locale);
    final fmt = WeightFormatter(unit, locale: locale);
    final rangeError = l10n.logRangeError(fmt.limit(20), fmt.limit(400));
    final showError = _input.isNotEmpty && !_valid;

    final relDay = PonviaDateFormatter.daysAgo(_timestamp, DateTime.now());
    final dateValue = relDay == 0
        ? l10n.today
        : relDay == 1
            ? l10n.yesterday
            : dateFmt.date(_timestamp);

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        bottom: Insets.xxl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(_isEditing ? l10n.logEditTitle : l10n.logTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
              if (!widget.embedded)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
          const SizedBox(height: Insets.md),
          // Value + underline (single field), or the split st + lb columns.
          if (_isStone)
            StoneFields(
              stone: _stone!,
              boxed: false,
              onTapSt: () => setState(() => _stone!.focusLb = false),
              onTapLb: () => setState(() => _stone!.focusLb = true),
            )
          else
            _ValueDisplay(
              input: _input.isEmpty ? '0' : _input,
              unit: unit,
              error: showError,
            ),
          const SizedBox(height: Insets.sm),
          SizedBox(
            height: 20,
            child: _isStone
                ? StoneEchoLine(
                    stone: _stone!,
                    locale: locale,
                    helperText: rangeError,
                  )
                : showError
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: scheme.error),
                          const SizedBox(width: Insets.xs),
                          Text(rangeError,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.error)),
                        ],
                      )
                    : null,
          ),
          const SizedBox(height: Insets.md),
          // Date / time
          Row(
            children: [
              Expanded(
                child: _MetaField(
                  icon: Icons.event,
                  label: l10n.logDateLabel,
                  value: dateValue,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: _MetaField(
                  icon: Icons.schedule,
                  label: l10n.logTimeLabel,
                  value: dateFmt.time(_timestamp),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          // Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: l10n.logAddNote,
              prefixIcon: const Icon(Icons.edit_note),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: Insets.sm),
          NumericKeypad(
            onKey: _onKey,
            onBackspace: _onBackspace,
            decimalSeparator: _sep,
            decimalEnabled: !_isStone,
          ),
          const SizedBox(height: Insets.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_valid && !_saving) ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? l10n.logSaveChanges : l10n.actionSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay(
      {required this.input, required this.unit, required this.error});

  final String input;
  final WeightUnit unit;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = error ? scheme.error : scheme.onSurface;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: input,
                style: PonviaTypography.heroWeight
                    .copyWith(fontSize: 64, color: color),
              ),
              TextSpan(
                text: ' ${unit.code}',
                style: TextStyle(
                  fontFamily: PonviaTypography.family,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: error ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: Insets.sm),
        Container(
          width: 220,
          height: 2,
          color: error ? scheme.error : scheme.primary,
        ),
      ],
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: Insets.md),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
