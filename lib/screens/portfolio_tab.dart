import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import 'actions.dart';

class PortfolioTab extends StatefulWidget {
  const PortfolioTab({
    super.key,
    required this.api,
    required this.refresh,
    required this.onChanged,
    required this.onSetup,
  });

  final HubApi api;
  final ValueListenable<int> refresh;
  final VoidCallback onChanged;
  final VoidCallback onSetup;

  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  late Future<Portfolio> _future = widget.api.portfolio();

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

  void _reload() => setState(() => _future = widget.api.portfolio());

  Future<void> _pull() async {
    _reload();
    await _future;
  }

  void _changed() {
    widget.onChanged();
    _reload();
  }

  void _actions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: const Text('Record a buy or sell'),
              onTap: () {
                Navigator.pop(ctx);
                showTradeSheet(context, widget.api, onSaved: _changed);
              },
            ),
            ListTile(
              leading: const Icon(Icons.east),
              title: const Text('Move cash to collateral'),
              onTap: () {
                Navigator.pop(ctx);
                showCashSheet(
                  context,
                  widget.api,
                  onSaved: _changed,
                  kind: 'transfer',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Deposit or withdraw cash'),
              onTap: () {
                Navigator.pop(ctx);
                showCashSheet(context, widget.api, onSaved: _changed);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _pull,
        child: FutureBuilder<Portfolio>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return _scrollable(
                const Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return _scrollable(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}', textAlign: TextAlign.center),
                  ),
                ),
              );
            }
            return _content(context, snap.data!);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _actions,
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
    );
  }

  Widget _scrollable(Widget child) =>
      ListView(children: [SizedBox(height: 400, child: child)]);

  Widget _content(BuildContext context, Portfolio p) {
    final theme = Theme.of(context);
    final c = p.collateral;
    final deposit = c.depositNeeded;
    final total = p.total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        if (!p.configured)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.rocket_launch),
              title: const Text('Finish setup to start tracking'),
              subtitle: const Text('Enter your cash and the shares you hold.'),
              trailing: FilledButton(
                onPressed: widget.onSetup,
                child: const Text('Start'),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total (cash + collateral + holdings)',
                  style: theme.textTheme.labelLarge,
                ),
                Text(money(total), style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Realized profit/loss: ${money(p.realizedPnl)}',
                  style: TextStyle(
                    color: p.realizedPnl >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _stat('Cash', money(p.cash))),
                    Expanded(
                      child: _stat(
                        'Collateral',
                        money(c.collateral ?? 0),
                        color: (c.collateral ?? 0) < 0 ? Colors.red : null,
                      ),
                    ),
                    Expanded(child: _stat('Holdings', money(p.investedCost))),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (deposit != null && deposit > 0)
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                'Move cash to collateral',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Today's buys need ${money(c.required)}. "
                'Cash available ${money(deposit)}.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              onTap: () => showCashSheet(
                context,
                widget.api,
                onSaved: _changed,
                kind: 'transfer',
              ),
            ),
          ),
        // Holdings strictly follow the bot's ledger, so no mismatch warning.
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(
            'Holdings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (p.holdings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No holdings yet.'),
          ),
        for (final h in p.holdings)
          Card(
            child: ListTile(
              title: Text(
                h.symbol,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${h.qty} units @ ${money(h.avgPrice)}'),
              trailing: Text(money(h.cost)),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Bot state updated ${shortTime(p.stateUpdatedAt)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    ],
  );
}
