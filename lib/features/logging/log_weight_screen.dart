import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/weight_entry.dart';

/// Opens the log/edit form as a modal bottom sheet (the design's logging model).
/// Pass [existing] to edit an entry; omit it to add a new one.
Future<void> showLogWeightSheet(BuildContext context, {WeightEntry? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => LogWeightForm(existing: existing),
  );
}

/// Full-screen host for the log form (used by the `/log` route, e.g. reminder
/// deep-links in M4).
class LogWeightScreen extends StatelessWidget {
  const LogWeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log weight')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(Insets.screenH),
        child: LogWeightForm(),
      ),
    );
  }
}

/// The weight add/edit form. Value is entered in the user's unit and stored as
/// kg; timestamp and note are editable.
class LogWeightForm extends ConsumerStatefulWidget {
  const LogWeightForm({super.key, this.existing});

  final WeightEntry? existing;

  @override
  ConsumerState<LogWeightForm> createState() => _LogWeightFormState();
}

class _LogWeightFormState extends ConsumerState<LogWeightForm> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _timestamp;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _timestamp = e?.timestamp ?? DateTime.now();
    if (e != null) {
      final unit = ref.read(settingsControllerProvider).unit;
      _valueController.text =
          WeightConverter.fromKg(e.weightKg, unit).toStringAsFixed(1);
      _noteController.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (!mounted) return;
    setState(() {
      _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _timestamp.hour,
        time?.minute ?? _timestamp.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final unit = ref.read(settingsControllerProvider).unit;
    final value = double.parse(_valueController.text.trim().replaceAll(',', '.'));
    final kg = WeightConverter.toKg(value, unit);
    final note = _noteController.text.trim();
    final entry = WeightEntry(
      id: widget.existing?.id,
      timestamp: _timestamp,
      weightKg: kg,
      note: note.isEmpty ? null : note,
    );
    final repo = ref.read(weightRepositoryProvider);
    if (_isEditing) {
      await repo.update(entry);
    } else {
      await repo.add(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsControllerProvider).unit;
    final settings = ref.watch(settingsControllerProvider);
    final dateFmt = PonviaDateFormatter(locale: settings.localeCode);

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        top: Insets.sm,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit entry' : 'Log weight',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Insets.lg),
            TextFormField(
              controller: _valueController,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.displaySmall,
              decoration: InputDecoration(
                labelText: 'Weight (${unit.code})',
                suffixText: unit.code,
              ),
              validator: (raw) {
                final v = double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
                if (v == null) return 'Enter a number';
                if (v <= 0 || v > 1000) return 'Enter a realistic weight';
                return null;
              },
            ),
            const SizedBox(height: Insets.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(dateFmt.dateTime(_timestamp)),
              trailing: TextButton(
                onPressed: _pickDateTime,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: Insets.sm),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: Insets.xxl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
