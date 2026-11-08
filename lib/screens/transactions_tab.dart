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

class _TransactionsTabState extends State<TransactionsTab> {
  late Future<List<TradeEvent>> _future = widget.api.transactions();
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

  void _reload() => setState(() => _future = widget.api.transactions());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      color: T.accent,
      backgroundColor: T.surface,
      child: FutureBuilder<List<TradeEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return loadingBody();
          }
          if (snap.hasError) {
            return messageBody('Trades', '${snap.error}', error: true);
          }
          final all = snap.data!;
          final rows = switch (_filter) {
            'buy' => all.where((t) => t.isBuy).toList(),
            'sell' => all.where((t) => !t.isBuy).toList(),
            _ => all,
          };
          final buys = all.where((t) => t.isBuy).length;
          return ListView(
            padding: pagePad,
            children: [
              const PageHead(
                'Trades',
                lede: 'Bot fills and the trades you record, newest first.',
              ),
              Seg<String>(
                value: _filter,
                options: [
                  ('all', 'All ${all.length}'),
                  ('buy', 'Buys $buys'),
                  ('sell', 'Sells ${all.length - buys}'),
                ],
                onChanged: (v) => setState(() => _filter = v),
              ),
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
          );
        },
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
      t.isManual ? 'Manual' : 'Bot',
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
