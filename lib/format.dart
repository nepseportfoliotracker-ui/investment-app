import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00');

String money(num value) => 'Rs ${_money.format(value)}';

/// DateTime -> "2026-10-06"
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "2026-10-06T22:34:20" -> "2026-10-06 22:34"
String shortTime(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final s = iso.replaceAll('T', ' ');
  return s.length >= 16 ? s.substring(0, 16) : s;
}

/// 1234.5 -> "1,234.50" (no currency, for dense tables).
String plain(num value) => _money.format(value);
