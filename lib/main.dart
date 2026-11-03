import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'push.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/setup_wizard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background/terminated messages with a notification payload are shown by
  // the system; nothing extra to do here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Push disabled, Firebase not configured: $e');
  }
  runApp(const InvestmentApp());
}

class InvestmentApp extends StatelessWidget {
  const InvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investments',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const _Root(),
    );
  }
}

/// Decides the first screen: connect to the hub, then set up the portfolio
/// if this is the first start, then the main app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _loading = true;
  HubConfig? _config;
  bool _configured = true;

  @override
  void initState() {
    super.initState();
    HubConfig.load().then((c) {
      if (c == null) {
        setState(() => _loading = false);
      } else {
        _connect(c);
      }
    });
  }

  Future<void> _connect(HubConfig c) async {
    bool configured = true;
    try {
      final health = await HubApi.health(c.url);
      configured = health['configured'] == true;
    } catch (_) {
      // Unreachable hub: go to the app, which shows the error on each tab.
    }
    if (!mounted) return;
    setState(() {
      _config = c;
      _configured = configured;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final config = _config;
    if (config == null) {
      return SetupScreen(onSaved: _connect);
    }
    if (!_configured) {
      return SetupWizard(
        api: HubApi(config),
        onDone: () => setState(() => _configured = true),
      );
    }
    return HomeScreen(
      config: config,
      onConfigChanged: (c) => setState(() => _config = c),
    );
  }
}
