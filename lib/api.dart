import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class HubConfig {
  const HubConfig({required this.url, required this.token});

  final String url;
  final String token;

  static const _urlKey = 'hub_url';
  static const _tokenKey = 'hub_token';

  static Future<HubConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_urlKey);
    final token = prefs.getString(_tokenKey);
    if (url == null || token == null) return null;
    return HubConfig(url: url, token: token);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
    await prefs.setString(_tokenKey, token);
  }
}

class HubException implements Exception {
  HubException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HubApi {
  HubApi(this.config);

  final HubConfig config;
  static const _timeout = Duration(seconds: 20);

  static String _base(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

  Uri _uri(String path) => Uri.parse('${_base(config.url)}$path');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${config.token}',
  };

  Future<dynamic> _get(String path) async {
    final res = await http.get(_uri(path), headers: _headers).timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .post(
          _uri(path),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 401) {
      throw HubException('Wrong access token');
    }
    if (res.statusCode == 422) {
      throw HubException('The hub rejected the values entered');
    }
    if (res.statusCode == 400) {
      final detail = jsonDecode(res.body)['detail'];
      throw HubException('$detail');
    }
    if (res.statusCode != 200) {
      throw HubException('Hub error ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  /// Hub status without a token: whether it is set up and whether push works.
  static Future<Map<String, dynamic>> health(String url) async {
    final res = await http
        .get(Uri.parse('${_base(url)}/api/health'))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw HubException('Hub not reachable (HTTP ${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Portfolio> portfolio() async =>
      Portfolio.fromJson(await _get('/api/portfolio') as Map<String, dynamic>);

  Future<void> saveSetup(
    double cash,
    double collateral,
    List<OpeningHolding> holdings,
  ) async {
    await _post('/api/setup', {
      'cash': cash,
      'collateral': collateral,
      'holdings': holdings.map((h) => h.toJson()).toList(),
    });
  }

  /// Correct cash and collateral to the real figures.
  Future<void> setBalances({double? cash, double? collateral}) async {
    await _post('/api/balances', {'cash': ?cash, 'collateral': ?collateral});
  }

  Future<void> addCash({
    required String kind,
    required double amount,
    String note = '',
  }) async {
    await _post('/api/cash', {'kind': kind, 'amount': amount, 'note': note});
  }

  /// Returns the hub's message when the trade was not applied (dated before setup).
  Future<String?> addTrade({
    required String side,
    required String symbol,
    required int qty,
    required double price,
    String? date,
    String note = '',
  }) async {
    final res =
        await _post('/api/trades', {
              'side': side,
              'symbol': symbol,
              'qty': qty,
              'price': price,
              'ts': ?date,
              'note': note,
            })
            as Map<String, dynamic>;
    return res['note'] as String?;
  }

  Future<List<TradeEvent>> transactions({int limit = 100}) async {
    final rows = await _get('/api/transactions?limit=$limit') as List;
    return rows
        .map((e) => TradeEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppAlert>> alerts({int limit = 100}) async {
    final rows = await _get('/api/alerts?limit=$limit') as List;
    return rows
        .map((e) => AppAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int alertId) async {
    await _post('/api/alerts/$alertId/read');
  }

  Future<void> registerDevice(String fcmToken) async {
    await _post('/api/devices', {'token': fcmToken});
  }
}
