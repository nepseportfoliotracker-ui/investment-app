import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';

/// First-start setup: bank cash, broker collateral, and the shares you already hold.
/// Trades from the bot and from you are tracked from this moment on.
class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key, required this.api, required this.onDone});

  final HubApi api;
  final VoidCallback onDone;

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  int _step = 0;
  final _cashCtrl = TextEditingController();
  final _collateralCtrl = TextEditingController();
  final _holdings = <OpeningHolding>[];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _collateralCtrl.dispose();
    super.dispose();
  }

  static double? _parse(TextEditingController c) {
    final text = c.text.replaceAll(',', '').trim();
    return text.isEmpty ? 0 : double.tryParse(text);
  }

  double? get _cash => _parse(_cashCtrl);
  double? get _collateral => _parse(_collateralCtrl);

  double get _cost => _holdings.fold(0.0, (s, h) => s + h.qty * h.avgPrice);

  Future<void> _addHolding() async {
    final result = await showDialog<OpeningHolding>(
      context: context,
      builder: (_) => const _HoldingDialog(),
    );
    if (result != null) setState(() => _holdings.add(result));
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.saveSetup(_cash ?? 0, _collateral ?? 0, _holdings);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canContinue => switch (_step) {
    0 =>
      _cash != null && _cash! >= 0 && _collateral != null && _collateral! >= 0,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your portfolio')),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (i) => setState(() => _step = i),
        onStepContinue: () {
          if (_step < 2) {
            setState(() => _step++);
          } else {
            _finish();
          }
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              FilledButton(
                onPressed: (_saving || !_canContinue)
                    ? null
                    : details.onStepContinue,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 2 ? 'Finish' : 'Continue'),
              ),
              const SizedBox(width: 12),
              if (details.onStepCancel != null)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Cash and collateral'),
            subtitle: const Text('Money in your bank and your broker collateral'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cash in bank (Rs)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _collateralCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Collateral at broker (Rs)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sells add to cash. Buys are paid from collateral. '
                  'You can move cash to collateral any time.',
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Shares you already hold'),
            subtitle: Text(
              _holdings.isEmpty
                  ? 'Optional'
                  : '${_holdings.length} holding(s), cost ${money(_cost)}',
            ),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add every stock you hold now, with the quantity and your average buy price. '
                  'Trades from before this setup are already included, so do not add them again.',
                ),
                const SizedBox(height: 8),
                for (final h in _holdings)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      h.symbol,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${h.qty} units @ ${money(h.avgPrice)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _holdings.remove(h)),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _addHolding,
                  icon: const Icon(Icons.add),
                  label: const Text('Add holding'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _step >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash: ${money(_cash ?? 0)}'),
                Text('Collateral: ${money(_collateral ?? 0)}'),
                Text('Holdings: ${_holdings.length} (cost ${money(_cost)})'),
                const SizedBox(height: 12),
                Text(
                  'From now on, the bot\'s buys and sells appear here as they happen, '
                  'and their alerts are sent to your phone.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingDialog extends StatefulWidget {
  const _HoldingDialog();

  @override
  State<_HoldingDialog> createState() => _HoldingDialogState();
}

class _HoldingDialogState extends State<_HoldingDialog> {
  final _form = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _symbol.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add holding'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _symbol,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Symbol, e.g. NABIL',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Units held'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return (n == null || n <= 0)
                    ? 'Enter a whole number above 0'
                    : null;
              },
            ),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Average buy price (Rs)',
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                return (n == null || n < 0) ? 'Enter a price' : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              OpeningHolding(
                symbol: _symbol.text.trim().toUpperCase(),
                qty: int.parse(_qty.text.trim()),
                avgPrice: double.parse(_price.text.trim()),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
