import 'package:flutter_test/flutter_test.dart';
import 'package:investment_app/models.dart';

void main() {
  test('Watchlists.fromJson maps buy_first', () {
    final w = Watchlists.fromJson({
      'priority': ['NABIL'],
      'buy_first': ['X'],
    });
    expect(w.priority, ['NABIL']);
    expect(w.buyFirst, ['X']);
  });

  test('Watchlists.fromJson tolerates missing lists', () {
    final w = Watchlists.fromJson({});
    expect(w.priority, isEmpty);
    expect(w.buyFirst, isEmpty);
  });
}
