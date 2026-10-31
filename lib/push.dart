import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Background and terminated-app messages are shown by the system from the
/// notification payload, so there is nothing to do here.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

/// Starts Firebase Messaging.  If Firebase is not configured yet the app still
/// runs; alerts are then only visible in the Alerts tab.
Future<bool> initPush({required VoidCallback onMessage}) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Push disabled, Firebase not configured: $e');
    return false;
  }
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((message) {
    final n = message.notification;
    if (n != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('${n.title ?? ''}\n${n.body ?? ''}')),
      );
    }
    onMessage();
  });
  return true;
}

StreamSubscription<String>? _registration;

/// Sends this phone's FCM token to the hub so it can receive alerts.  Called
/// again whenever the hub settings change, so the newest hub always gets it.
Future<void> registerWithHub(HubApi api) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await _registration?.cancel();
    // ignore: deprecated_member_use
    _registration = messaging.onTokenRefresh.listen((token) async {
      try {
        await api.registerDevice(token);
      } catch (e) {
        debugPrint('Could not send push token to hub: $e');
      }
    });
    // ignore: deprecated_member_use
    final token = await messaging.getToken();
    if (token != null) {
      await api.registerDevice(token);
    }
  } catch (e) {
    debugPrint('Could not register push token: $e');
  }
}
