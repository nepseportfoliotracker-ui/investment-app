import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';

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

  IconData _icon(AppAlert a) => switch (a.kind) {
    'collateral' => Icons.account_balance_wallet,
    _ =>
      a.title.startsWith('Bought') ? Icons.arrow_downward : Icons.arrow_upward,
  };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: FutureBuilder<List<AppAlert>>(
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
          final alerts = snap.data!;
          if (alerts.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No alerts yet.'),
                ),
              ],
            );
          }
          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              return ListTile(
                leading: Icon(
                  _icon(a),
                  color: a.read
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  a.title,
                  style: TextStyle(
                    fontWeight: a.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text('${a.body}\n${shortTime(a.createdAt)}'),
                isThreeLine: true,
                onTap: () => _open(a),
              );
            },
          );
        },
      ),
    );
  }
}
