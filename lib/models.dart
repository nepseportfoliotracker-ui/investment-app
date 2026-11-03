int _int(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

double _num(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

class Holding {
  Holding({
    required this.symbol,
    required this.qty,
    required this.avgPrice,
    required this.cost,
  });

  final String symbol;
  final int qty;
  final double avgPrice;
  final double cost;

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
    symbol: '${j['symbol']}',
    qty: _int(j['qty']),
    avgPrice: _num(j['avg_price']),
    cost: _num(j['cost']),
  );
}

class OpeningHolding {
  const OpeningHolding({
    required this.symbol,
    required this.qty,
    required this.avgPrice,
  });

  final String symbol;
  final int qty;
  final double avgPrice;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'qty': qty,
    'avg_price': avgPrice,
  };
}

class Collateral {
  Collateral({
    required this.checkedAt,
    required this.fresh,
    required this.collateral,
    required this.cash,
    required this.pendingCount,
    required this.required,
    required this.depositNeeded,
    required this.unitsPerBuy,
  });

  final String? checkedAt;
  final bool fresh;
  final double? collateral;
  final double cash;
  final int pendingCount;
  final double required;
  final double? depositNeeded;
  final int unitsPerBuy;

  factory Collateral.fromJson(Map<String, dynamic> j) => Collateral(
    checkedAt: j['checked_at'] as String?,
    fresh: j['fresh'] == true,
    collateral: j['collateral'] == null ? null : _num(j['collateral']),
    cash: _num(j['cash']),
    pendingCount: (j['pending_buys'] as List?)?.length ?? 0,
    required: _num(j['required']),
    depositNeeded: j['deposit_needed'] == null
        ? null
        : _num(j['deposit_needed']),
    unitsPerBuy: _int(j['units_per_buy']),
  );
}

class Mismatch {
  const Mismatch({
    required this.symbol,
    required this.appQty,
    required this.botQty,
  });

  final String symbol;
  final int appQty;
  final int botQty;

  factory Mismatch.fromJson(Map<String, dynamic> j) => Mismatch(
    symbol: '${j['symbol']}',
    appQty: _int(j['app_qty']),
    botQty: _int(j['bot_qty']),
  );
}

class Portfolio {
  Portfolio({
    required this.configured,
    required this.cash,
    required this.total,
    required this.realizedPnl,
    required this.investedCost,
    required this.holdings,
    required this.collateral,
    required this.mismatches,
    required this.stateUpdatedAt,
  });

  final bool configured;
  final double cash;
  final double total;
  final double realizedPnl;
  final double investedCost;
  final List<Holding> holdings;
  final Collateral collateral;
  final List<Mismatch> mismatches;
  final String? stateUpdatedAt;

  factory Portfolio.fromJson(Map<String, dynamic> j) => Portfolio(
    configured: j['configured'] == true,
    cash: _num(j['cash']),
    total: _num(j['total']),
    realizedPnl: _num(j['realized_pnl']),
    investedCost: _num(j['invested_cost']),
    holdings: ((j['holdings'] as List?) ?? [])
        .map((e) => Holding.fromJson(e as Map<String, dynamic>))
        .toList(),
    collateral: Collateral.fromJson(j['collateral'] as Map<String, dynamic>),
    mismatches: ((j['bot_mismatches'] as List?) ?? [])
        .map((e) => Mismatch.fromJson(e as Map<String, dynamic>))
        .toList(),
    stateUpdatedAt: j['state_updated_at'] as String?,
  );
}

class TradeEvent {
  TradeEvent({
    required this.ts,
    required this.symbol,
    required this.side,
    required this.qty,
    required this.price,
    required this.status,
    required this.source,
    required this.applied,
    this.pnl,
  });

  final String ts;
  final String symbol;
  final String side;
  final int qty;
  final double price;
  final String status;
  final String source;
  final bool applied;
  final double? pnl;

  bool get isBuy => side.toLowerCase() == 'buy';
  bool get isManual => source == 'manual';

  factory TradeEvent.fromJson(Map<String, dynamic> j) => TradeEvent(
    ts: '${j['ts'] ?? ''}',
    symbol: '${j['symbol']}',
    side: '${j['side']}',
    qty: _int(j['qty']),
    price: _num(j['price']),
    status: '${j['status']}',
    source: '${j['source'] ?? 'bot'}',
    applied: j['applied'] == true,
    pnl: j['pnl'] == null ? null : _num(j['pnl']),
  );
}

class AppAlert {
  AppAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final String createdAt;
  final bool read;

  factory AppAlert.fromJson(Map<String, dynamic> j) => AppAlert(
    id: _int(j['id']),
    kind: '${j['kind']}',
    title: '${j['title']}',
    body: '${j['body']}',
    createdAt: '${j['created_at']}',
    read: j['read'] == true,
  );
}
