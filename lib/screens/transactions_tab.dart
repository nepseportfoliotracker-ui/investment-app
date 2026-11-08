import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key, required this.api, required this.refresh});

  final HubApi api;
  final ValueListenable<int> refresh;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

typedef _Data = ({List<TradeEvent> trades, List<AppOrder> orders});

class _TransactionsTabState extends State<TransactionsTab> {
  late Future<_Data> _future = _load();
  String _filter = 'all';

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
    final trades = widget.api.transactions();
    // A hub without app orders yet must not break the trade list.
    final orders = widget.api.orders().catchError((_) => <AppOrder>[]);
    return (trades: await trades, orders: await orders);
  }

  void _reload() => setState(() => _future = _load());

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
          if (snap.connectionState != ConnectionState.done) {
            return loadingBody();
          }
          if (snap.hasError) {
            return messageBody('Trades', '${snap.error}', error: true);
          }
          final all = snap.data!.trades;
          final orders = snap.data!.orders;
          final rows = switch (_filter) {
            'buy' => all.where((t) => t.isBuy).toList(),
            'sell' => all.where((t) => !t.isBuy).toList(),
            _ => all,
          };
          final buys = all.where((t) => t.isBuy).length;
          final open = orders
              .where((o) => o.status == 'queued' || o.status == 'claimed')
              .length;
          return ListView(
            padding: pagePad,
            children: [
              const PageHead(
                'Trades',
                lede: 'Bot fills, app orders and the trades you record.',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Seg<String>(
                  value: _filter,
                  options: [
                    ('all', 'All ${all.length}'),
                    ('buy', 'Buys $buys'),
                    ('sell', 'Sells ${all.length - buys}'),
                    ('orders', open > 0 ? 'Orders $open open' : 'Orders'),
                  ],
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              if (_filter == 'orders') ...[
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No orders yet. Place one from Record on the Portfolio tab.',
                      style: T.sans(color: T.muted),
                    ),
                  ),
                for (final o in orders)
                  _OrderRow(o, onCancel: o.canCancel ? () => _cancel(o) : null),
              ] else ...[
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No trades yet. Bot fills appear here as they happen.',
                      style: T.sans(color: T.muted),
                    ),
                  ),
                for (final t in rows) _TradeRow(t),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow(this.o, {this.onCancel});

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
    final done = o.filledQty > 0 && o.price != null
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
              if (done != null) ...[
                const SizedBox(height: 4),
                Text(done, style: T.mono(color: T.text)),
              ],
              if (onCancel != null) LinkButton('Cancel', onPressed: onCancel),
            ],
          ),
        ],
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow(this.t);

  final TradeEvent t;

  @override
  Widget build(BuildContext context) {
    final dim = !t.applied;
    final meta = [
      shortTime(t.ts),
      switch (t.source) {
        'manual' => 'Manual',
        'app' => 'App order',
        _ => 'Bot',
      },
      if (dim) 'before setup, not counted',
    ].join('  ·  ');
    return Opacity(
      opacity: dim ? .5 : 1,
      child: Container(
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
                t.isBuy ? 'BUY' : 'SELL',
                style: T.sans(
                  size: T.fsXs,
                  weight: FontWeight.w600,
                  letterSpacing: .04 * 11,
                  color: t.isBuy ? T.up : T.down,
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
                          text: t.symbol,
                          style: T.sans(
                            weight: FontWeight.w600,
                            color: T.textStrong,
                          ),
                        ),
                        TextSpan(
                          text: '   ${t.qty} @ ${plain(t.price)}',
                          style: T.mono(color: T.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(meta, style: T.sans(size: 11, color: T.faint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plain(t.qty * t.price), style: T.mono(color: T.text)),
                if (!t.isBuy && t.pnl != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t.pnl! >= 0 ? '+' : ''}${plain(t.pnl!)}',
                    style: T.mono(size: 11, color: T.direction(t.pnl!)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
