import 'package:flutter/material.dart';

import '../api.dart';
import '../push.dart';
import 'alerts_tab.dart';
import 'portfolio_tab.dart';
import 'setup_screen.dart';
import 'setup_wizard.dart';
import 'transactions_tab.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  final HubConfig config;
  final ValueChanged<HubConfig> onConfigChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HubApi _api = HubApi(widget.config);
  final _refresh = ValueNotifier<int>(0);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    initPush(onMessage: _bump).then((enabled) {
      if (enabled) registerWithHub(_api);
    });
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  void _bump() => _refresh.value++;

  void _onConfigSaved(HubConfig config) {
    setState(() => _api = HubApi(config));
    widget.onConfigChanged(config);
    registerWithHub(_api);
    _bump();
    Navigator.of(context).pop();
  }

  void _openWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetupWizard(
          api: _api,
          onDone: () {
            Navigator.of(context).pop();
            _bump();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('NEPSE PORTFOLIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: _bump,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) {
              if (v == 'setup') _openWizard();
              if (v == 'hub') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SetupScreen(
                      initial: HubConfig(
                        url: _api.config.url,
                        token: _api.config.token,
                      ),
                      onSaved: _onConfigSaved,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'setup',
                child: Text('Redo portfolio setup'),
              ),
              PopupMenuItem(value: 'hub', child: Text('Hub connection')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          PortfolioTab(
            api: _api,
            refresh: _refresh,
            onChanged: _bump,
            onSetup: _openWizard,
          ),
          TransactionsTab(api: _api, refresh: _refresh),
          AlertsTab(api: _api, refresh: _refresh),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: T.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Portfolio',
            ),
            NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Trades'),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
