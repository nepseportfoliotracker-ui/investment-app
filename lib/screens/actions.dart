import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../theme.dart';
import '../ui.dart';

/// Record a buy or sell you made outside the bot.
Future<void> showTradeSheet(
  BuildContext context,
  HubApi api, {
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TradeSheet(api: api, onSaved: onSaved),
  );
}

/// Deposit or withdraw bank cash, or move cash to collateral.
Future<void> showCashSheet(
  BuildContext context,
  HubApi api, {
  required VoidCallback onSaved,
  String kind = 'deposit',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CashSheet(api: api, onSaved: onSaved, kind: kind),
  );
}

/// Correct cash and collateral to what the bank and TMS really show.
Future<void> showBalancesSheet(
  BuildContext context,
  HubApi api, {
  required double cash,
  required double collateral,
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BalancesSheet(
      api: api,
      cash: cash,
      collateral: collateral,
      onSaved: onSaved,
    ),
  );
}

class _BalancesSheet extends StatefulWidget {
  const _BalancesSheet({
    required this.api,
    required this.cash,
    required this.collateral,
    required this.onSaved,
  });

  final HubApi api;
  final double cash;
  final double collateral;
  final VoidCallback onSaved;

  @override
  State<_BalancesSheet> createState() => _BalancesSheetState();
}

class _BalancesSheetState extends State<_BalancesSheet> {
  final _form = GlobalKey<FormState>();
  late final _cash = TextEditingController(
    text: widget.cash.toStringAsFixed(2),
  );
  late final _collateral = TextEditingController(
    text: widget.collateral.toStringAsFixed(2),
  );
  bool _saving = false;

  @override
  void dispose() {
    _cash.dispose();
    _collateral.dispose();
    super.dispose();
  }

  static double? _parse(String v) =>
      double.tryParse(v.replaceAll(',', '').trim());

  static String? _validate(String? v) =>
      _parse(v ?? '') == null ? 'Enter an amount' : null;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.setBalances(
        cash: _parse(_cash.text),
        collateral: _parse(_collateral.text),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Correct balances',
      form: _form,
      saving: _saving,
      onSave: _save,
      children: [
        Text(
          'Enter what your bank and TMS show now. The difference is recorded '
          'as an adjustment; trades keep updating from these figures.',
          style: T.sans(size: 12, color: T.muted, height: 16 / 12),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cash,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(labelText: 'Cash in bank (Rs)'),
          validator: _validate,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _collateral,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Collateral in TMS (Rs)',
          ),
          validator: _validate,
        ),
      ],
    );
  }
}

class _TradeSheet extends StatefulWidget {
  const _TradeSheet({required this.api, required this.onSaved});

  final HubApi api;
  final VoidCallback onSaved;

  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<_TradeSheet> {
  final _form = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  String _side = 'buy';
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_symbol, _qty, _price, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final date = _date == null ? null : isoDate(_date!);
      final note = await widget.api.addTrade(
        side: _side,
        symbol: _symbol.text.trim().toUpperCase(),
        qty: int.parse(_qty.text.trim()),
        price: double.parse(_price.text.trim()),
        date: date,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      if (note != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(note)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Record a trade',
      form: _form,
      saving: _saving,
      onSave: _save,
      children: [
        Seg<String>(
          value: _side,
          options: const [('buy', 'Buy'), ('sell', 'Sell')],
          onChanged: (v) => setState(() => _side = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _symbol,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Symbol'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        TextFormField(
          controller: _qty,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Units'),
          validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) > 0
              ? null
              : 'Enter units above 0',
        ),
        TextFormField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price per unit (Rs)'),
          validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) > 0
              ? null
              : 'Enter a price above 0',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text('Date', style: T.sans(size: 12, color: T.muted)),
              const SizedBox(width: 16),
              Text(
                _date == null ? 'Today' : isoDate(_date!),
                style: T.mono(color: T.textStrong),
              ),
              const Spacer(),
              LinkButton('Change', onPressed: _pickDate),
            ],
          ),
        ),
        TextFormField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}

class _CashSheet extends StatefulWidget {
  const _CashSheet({
    required this.api,
    required this.onSaved,
    required this.kind,
  });

  final HubApi api;
  final VoidCallback onSaved;
  final String kind;

  @override
  State<_CashSheet> createState() => _CashSheetState();
}

class _CashSheetState extends State<_CashSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _kind = widget.kind;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.addCash(
        kind: _kind,
        amount: double.parse(_amount.text.replaceAll(',', '').trim()),
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Cash',
      form: _form,
      saving: _saving,
      onSave: _save,
      children: [
        Seg<String>(
          value: _kind,
          options: const [
            ('deposit', 'Deposit'),
            ('withdraw', 'Withdraw'),
            ('transfer', 'To collateral'),
          ],
          onChanged: (v) => setState(() => _kind = v),
        ),
        const SizedBox(height: 8),
        Text(switch (_kind) {
          'deposit' => 'Money added to your bank cash.',
          'withdraw' => 'Money taken out of your bank cash.',
          _ => 'Moves money from cash to collateral so the bot can buy.',
        }, style: T.sans(size: 12, color: T.faint)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (Rs)'),
          validator: (v) =>
              (double.tryParse((v ?? '').replaceAll(',', '').trim()) ?? 0) > 0
              ? null
              : 'Enter an amount above 0',
        ),
        TextFormField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.form,
    required this.saving,
    required this.onSave,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> form;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: T.sans(
                  size: T.fsLg,
                  weight: FontWeight.w600,
                  color: T.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
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
