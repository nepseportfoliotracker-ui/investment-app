import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key, required this.api, required this.refresh});

  final HubApi api;
  final ValueListenable<int> refresh;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  late Future<List<TradeEvent>> _future = widget.api.transactions();

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
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: FutureBuilder<List<TradeEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              children: const [
                SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          if (snap.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(child: Text('${snap.error}')),
                ),
              ],
            );
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No trades yet. Bot fills appear here as they happen.',
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final t = rows[i];
              final color = t.applied
                  ? (t.isBuy ? Colors.green : Colors.red)
                  : theme.disabledColor;
              final tags = [
                t.isManual ? 'Manual' : 'Bot',
                if (!t.applied) 'before setup, not counted',
              ].join(' · ');
              return ListTile(
                leading: Icon(
                  t.isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                ),
                title: Text(
                  '${t.isBuy ? 'Bought' : 'Sold'} ${t.symbol} x${t.qty}',
                  style: TextStyle(
                    color: t.applied ? null : theme.disabledColor,
                  ),
                ),
                subtitle: Text('${shortTime(t.ts)}  ·  $tags'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(t.qty * t.price)),
                    if (!t.isBuy && t.pnl != null)
                      Text(
                        '${t.pnl! >= 0 ? '+' : ''}${money(t.pnl!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: t.pnl! >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
