import 'package:flutter_test/flutter_test.dart';
import 'package:investment_app/screens/actions.dart';

// orderTiming takes UTC; Nepal time is UTC+5:45.
DateTime npt(int y, int m, int d, int hh, int mm) =>
    DateTime.utc(y, m, d, hh, mm).subtract(const Duration(hours: 5, minutes: 45));

void main() {
  // 2026-11-08 is a Sunday (trading day); 2026-11-13 is a Friday.
  test('inside the window on a trading day runs now', () {
    expect(orderTiming(npt(2026, 11, 8, 12, 10)), 'It runs within about a minute.');
    expect(orderTiming(npt(2026, 11, 8, 14, 54)), 'It runs within about a minute.');
  });
  test('before 12:10 on a trading day runs today', () {
    expect(orderTiming(npt(2026, 11, 8, 9, 0)), 'It runs after 12:10 today.');
  });
  test('after 14:55 or on Friday/Saturday waits for the next trading day', () {
    const next = 'It runs after 12:10 on the next trading day.';
    expect(orderTiming(npt(2026, 11, 8, 14, 55)), next);
    expect(orderTiming(npt(2026, 11, 13, 13, 0)), next);
    expect(orderTiming(npt(2026, 11, 14, 9, 0)), next);
  });
}
