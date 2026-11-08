import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key, required this.api, required this.refresh});

  final HubApi api;
  final ValueListenable<int> refresh;

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  late Future<List<AppAlert>> _future = widget.api.alerts();

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

  void _reload() => setState(() => _future = widget.api.alerts());

  Future<void> _open(AppAlert a) async {
    if (!a.read) {
      await widget.api.markRead(a.id);
      _reload();
    }
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
      child: FutureBuilder<List<AppAlert>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return loadingBody();
          }
          if (snap.hasError) {
            return messageBody('Alerts', '${snap.error}', error: true);
          }
          final alerts = snap.data!;
          final unread = alerts.where((a) => !a.read).length;
          return ListView(
            padding: pagePad,
            children: [
              PageHead(
                'Alerts',
                lede: unread == 0
                    ? 'All read. Tap an alert to mark it read.'
                    : '$unread unread. Tap an alert to mark it read.',
              ),
              if (alerts.isEmpty)
                Text('No alerts yet.', style: T.sans(color: T.muted)),
              for (final a in alerts) _AlertRow(a, onTap: () => _open(a)),
            ],
          );
        },
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow(this.a, {required this.onTap});

  final AppAlert a;
  final VoidCallback onTap;

  String get _tag => switch (a.kind) {
    'collateral' => 'COLLATERAL',
    'trade' =>
      a.title.startsWith('Bought')
          ? 'BUY'
          : a.title.startsWith('Sold')
          ? 'SELL'
          : 'TRADE',
    _ => a.kind.toUpperCase(),
  };

  Color get _tagColor => switch (_tag) {
    'BUY' => T.up,
    'SELL' => T.down,
    'COLLATERAL' => T.warn,
    _ => T.muted,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: T.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!a.read)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: T.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    a.title,
                    style: T.sans(
                      size: T.fsMd,
                      height: 24 / 15,
                      weight: FontWeight.w600,
                      color: a.read ? T.text : T.textStrong,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              a.body,
              style: T.sans(color: a.read ? T.muted : T.text, height: 20 / 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _tag,
                  style: T.sans(
                    size: T.fsXs,
                    weight: FontWeight.w600,
                    letterSpacing: .04 * 11,
                    color: _tagColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  shortTime(a.createdAt),
                  style: T.mono(size: 11, color: T.faint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
