import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/ui/spacing.dart';
import '../../core/units/weight_unit.dart';
import '../../domain/models/weight_entry.dart';

/// Fast weight entry. M1: value + optional note, saved as a new entry. Date/time
/// editing and the designed bottom-sheet treatment come in M2.
class LogWeightScreen extends ConsumerStatefulWidget {
  const LogWeightScreen({super.key});

  @override
  ConsumerState<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends ConsumerState<LogWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save(WeightUnit unit) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final value =
        double.parse(_valueController.text.trim().replaceAll(',', '.'));
    final kg = WeightConverter.toKg(value, unit);
    final note = _noteController.text.trim();
    await ref.read(weightRepositoryProvider).add(
          WeightEntry(
            timestamp: DateTime.now(),
            weightKg: kg,
            note: note.isEmpty ? null : note,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsControllerProvider).unit;
    return Scaffold(
      appBar: AppBar(title: const Text('Log weight')),
      body: Padding(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _valueController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.displaySmall,
                decoration: InputDecoration(
                  labelText: 'Weight (${unit.code})',
                  suffixText: unit.code,
                ),
                validator: (raw) {
                  final v = double.tryParse(
                      (raw ?? '').trim().replaceAll(',', '.'));
                  if (v == null) return 'Enter a number';
                  if (v <= 0 || v > 1000) return 'Enter a realistic weight';
                  return null;
                },
              ),
              const SizedBox(height: Insets.lg),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: Insets.xxl),
              FilledButton(
                onPressed: _saving ? null : () => _save(unit),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
