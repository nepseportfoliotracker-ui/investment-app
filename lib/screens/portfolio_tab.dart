import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';
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

  void _transfer() =>
      showCashSheet(context, widget.api, onSaved: _changed, kind: 'transfer');

  void _actions() {
    Widget item(String label, String hint, VoidCallback onTap) => InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: T.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: T.sans(weight: FontWeight.w600, color: T.textStrong),
            ),
            const SizedBox(height: 2),
            Text(hint, style: T.sans(size: 12, color: T.muted)),
          ],
        ),
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Record', first: true),
              item(
                'Buy or sell',
                'A trade made outside the bot',
                () => showTradeSheet(context, widget.api, onSaved: _changed),
              ),
              item(
                'Move cash to collateral',
                'Money you loaded into TMS',
                _transfer,
              ),
              item(
                'Deposit or withdraw cash',
                'Money in or out of your bank',
                () => showCashSheet(context, widget.api, onSaved: _changed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _pull,
        color: T.accent,
        backgroundColor: T.surface,
        child: FutureBuilder<Portfolio>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return loadingBody();
            }
            if (snap.hasError) {
              return messageBody('Portfolio', '${snap.error}', error: true);
            }
            return _content(snap.data!);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _actions,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Record'),
      ),
    );
  }

  Widget _content(Portfolio p) {
    final c = p.collateral;
    final coll = c.collateral ?? 0;
    final deposit = c.depositNeeded;
    return ListView(
      padding: pagePad,
      children: [
        PageHead(
          'Portfolio',
          lede: 'Bot state updated ${shortTime(p.stateUpdatedAt)}',
        ),
        if (!p.configured)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Notice(
              title: 'Finish setup to start tracking',
              body: 'Enter your cash, collateral and the shares you hold.',
              color: T.accent,
              action: 'Start',
              onAction: widget.onSetup,
            ),
          ),
        Text('Total', style: T.sans(size: 12, color: T.muted)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            money(p.total),
            style: T.mono(
              size: T.fsXl,
              height: 40 / 32,
              weight: FontWeight.w500,
              color: T.textStrong,
              letterSpacing: -.02 * 32,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cash + collateral + holdings',
          style: T.sans(size: 12, color: T.faint),
        ),
        const SizedBox(height: 32),
        Figures([
          Fig('Cash', money(p.cash)),
          Fig('Collateral', money(coll), color: coll < 0 ? T.down : null),
          Fig('Holdings at cost', money(p.investedCost)),
          Fig(
            'Realized P/L',
            '${p.realizedPnl > 0 ? '+' : ''}${money(p.realizedPnl)}',
            color: p.realizedPnl == 0 ? null : T.direction(p.realizedPnl),
          ),
        ]),
        if (deposit != null && deposit > 0)
          Notice(
            title: 'Move cash to collateral',
            body:
                "Today's buys need ${money(c.required)}. "
                'Collateral ${money(coll)}, cash ${money(deposit)}.',
            action: 'Move',
            onAction: _transfer,
          ),
        SectionLabel(
          'Holdings',
          trailing: Text(
            '${p.holdings.length}',
            style: T.mono(size: 11, color: T.faint),
          ),
        ),
        if (p.holdings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No holdings yet.', style: T.sans(color: T.muted)),
          )
        else
          RuledTable(
            columns: const [
              Col('Symbol', numeric: false, flex: 3),
              Col('Units', flex: 2),
              Col('Avg', flex: 3),
              Col('Cost', flex: 4),
            ],
            rows: [
              for (final h in p.holdings)
                [
                  RuledTable.name(h.symbol),
                  RuledTable.num('${h.qty}'),
                  RuledTable.num(plain(h.avgPrice)),
                  RuledTable.num(plain(h.cost)),
                ],
            ],
          ),
      ],
    );
  }
}
