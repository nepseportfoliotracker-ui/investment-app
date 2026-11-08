import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';
import 'actions.dart';

/// Place real TMS orders (run by the bot 12:10-14:55) and follow them.
class OrdersTab extends StatefulWidget {
  const OrdersTab({
    super.key,
    required this.api,
    required this.refresh,
    required this.onChanged,
  });

  final HubApi api;
  final ValueListenable<int> refresh;
  final VoidCallback onChanged;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

typedef _Data = ({List<AppOrder> orders, Map<String, int> held});

class _OrdersTabState extends State<OrdersTab> {
  late Future<_Data> _future = _load();

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_reload);
    super.dispose();
  }

  Future<_Data> _load() async {
    final orders = widget.api.orders();
    // Holdings only feed the "you hold" hint; never block the page on them.
    final held = widget.api
        .portfolio()
        .then((p) => {for (final h in p.holdings) h.symbol: h.qty})
        .catchError((_) => <String, int>{});
    return (orders: await orders, held: await held);
  }

  void _reload() => setState(() => _future = _load());

  void _placed() {
    widget.onChanged();
    _reload();
  }

  Future<void> _cancel(AppOrder o) async {
    try {
      await widget.api.cancelOrder(o.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      color: T.accent,
      backgroundColor: T.surface,
      child: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          final loading = snap.connectionState != ConnectionState.done;
          final open =
              data?.orders
                  .where((o) => o.status == 'queued' || o.status == 'claimed')
                  .toList() ??
              [];
          final done =
              data?.orders
                  .where((o) => o.status != 'queued' && o.status != 'claimed')
                  .toList() ??
              [];
          return ListView(
            padding: pagePad,
            children: [
              PageHead('Orders', lede: orderWindowStatus()),
              _OrderForm(
                api: widget.api,
                held: data?.held ?? const {},
                onPlaced: _placed,
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    '${snap.error}',
                    style: T.sans(color: T.down, height: 24 / 13),
                  ),
                )
              else ...[
                SectionLabel(
                  'Open',
                  trailing: Text(
                    '${open.length}',
                    style: T.mono(size: 11, color: T.faint),
                  ),
                ),
                if (open.isEmpty)
                  Text('No open orders.', style: T.sans(color: T.muted)),
                for (final o in open)
                  OrderRow(o, onCancel: o.canCancel ? () => _cancel(o) : null),
                SectionLabel(
                  'Finished',
                  trailing: Text(
                    '${done.length}',
                    style: T.mono(size: 11, color: T.faint),
                  ),
                ),
                if (done.isEmpty)
                  Text('Nothing yet.', style: T.sans(color: T.muted)),
                for (final o in done) OrderRow(o),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OrderForm extends StatefulWidget {
  const _OrderForm({
    required this.api,
    required this.held,
    required this.onPlaced,
  });

  final HubApi api;
  final Map<String, int> held;
  final VoidCallback onPlaced;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final _form = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  final _qty = TextEditingController();
  String _side = 'buy';
  bool _saving = false;

  @override
  void dispose() {
    _symbol.dispose();
    _qty.dispose();
    super.dispose();
  }

  String get _sym => _symbol.text.trim().toUpperCase();

  Future<void> _place() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final qty = int.parse(_qty.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place a real order?'),
        content: Text(
          '${_side.toUpperCase()} $qty $_sym in TMS at market price. '
          'The bot prices it like its own trades and cancels anything '
          'unfilled at 14:55. ${orderTiming()}',
          style: T.sans(height: 20 / 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Place $_side'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.api.placeOrder(side: _side, symbol: _sym, qty: qty);
      if (!mounted) return;
      _symbol.clear();
      _qty.clear();
      widget.onPlaced();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order queued. ${orderTiming()}')));
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
    final held = widget.held[_sym];
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Seg<String>(
            value: _side,
            options: const [('buy', 'Buy'), ('sell', 'Sell')],
            onChanged: (v) => setState(() => _side = v),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _symbol,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  style: T.mono(size: T.fsSm, color: T.textStrong),
                  decoration: const InputDecoration(labelText: 'Units'),
                  validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) > 0
                      ? null
                      : 'Above 0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _sym.isEmpty
                ? 'Market price, auto re-priced until filled; leftovers '
                      'cancelled at 14:55.'
                : 'You hold ${held ?? 0} $_sym.',
            style: T.sans(size: 12, color: T.faint, height: 16 / 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _place,
            style: FilledButton.styleFrom(
              backgroundColor: _side == 'buy' ? T.accent : T.down,
            ),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_side == 'buy' ? 'Place buy order' : 'Place sell order'),
          ),
        ],
      ),
    );
  }
}

/// One app order: side, symbol, units, state tag, fill, reason, time.
class OrderRow extends StatelessWidget {
  const OrderRow(this.o, {super.key, this.onCancel});

  final AppOrder o;
  final VoidCallback? onCancel;

  static const _tags = {
    'queued': ('QUEUED', T.muted),
    'claimed': ('RUNNING', T.accent),
    'filled': ('FILLED', T.up),
    'partial': ('PARTLY FILLED', T.warn),
    'failed': ('FAILED', T.down),
    'cancelled': ('CANCELLED', T.faint),
    'expired': ('EXPIRED', T.faint),
    'unknown': ('CHECK TMS', T.warn),
  };

  @override
  Widget build(BuildContext context) {
    final (tag, color) = _tags[o.status] ?? (o.status.toUpperCase(), T.muted);
    final fill = o.filledQty > 0 && o.price != null
        ? '${o.filledQty} @ ${plain(o.price!)}'
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              o.isBuy ? 'BUY' : 'SELL',
              style: T.sans(
                size: T.fsXs,
                weight: FontWeight.w600,
                letterSpacing: .04 * 11,
                color: o.isBuy ? T.up : T.down,
                height: 20 / 11,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: o.symbol,
                        style: T.sans(
                          weight: FontWeight.w600,
                          color: T.textStrong,
                        ),
                      ),
                      TextSpan(
                        text: '   ${o.qty} units',
                        style: T.mono(color: T.muted),
                      ),
                    ],
                  ),
                ),
                if (o.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    o.reason!,
                    style: T.sans(size: 12, color: T.muted, height: 16 / 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  shortTime(o.finishedAt ?? o.createdAt),
                  style: T.mono(size: 11, color: T.faint),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tag,
                style: T.sans(
                  size: T.fsXs,
                  weight: FontWeight.w600,
                  letterSpacing: .04 * 11,
                  color: color,
                ),
              ),
              if (fill != null) ...[
                const SizedBox(height: 4),
                Text(fill, style: T.mono(color: T.text)),
              ],
              if (onCancel != null) LinkButton('Cancel', onPressed: onCancel),
            ],
          ),
        ],
      ),
    );
  }
}
