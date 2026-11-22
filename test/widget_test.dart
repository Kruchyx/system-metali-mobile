import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_metali_mobile/main.dart';

void main() {
  test('1 kg to 32,1507465686 uncji trojańskich', () {
    expect(toTroyOunces(1, 'kg'), closeTo(32.1507465686, 0.0000001));
    expect(toTroyOunces(1, 'oz'), 1);
  });

  test('Ceny PLN/kg i PLN/oz dają tę samą wartość zakupu', () {
    final kilogram = Investment(
      id: 10,
      date: DateTime(2026, 11, 20),
      metal: 'Złoto',
      amount: 1,
      amountUnit: 'kg',
      purchasePrice: 460000,
      purchasePriceUnit: 'kg',
    );
    final ounceEquivalent = Investment(
      id: 11,
      date: DateTime(2026, 11, 20),
      metal: 'Złoto',
      amount: troyOuncesPerKilogram,
      amountUnit: 'oz',
      purchasePrice: 460000 / troyOuncesPerKilogram,
      purchasePriceUnit: 'oz',
    );
    expect(kilogram.purchaseValue, closeTo(460000, 0.001));
    expect(ounceEquivalent.purchaseValue, closeTo(kilogram.purchaseValue, 0.001));
  });

  test('Można mieszać jednostki ilości i ceny', () {
    final tx = Investment(
      id: 12,
      date: DateTime(2026, 11, 20),
      metal: 'Srebro',
      amount: 0.5,
      amountUnit: 'kg',
      purchasePrice: 150,
      purchasePriceUnit: 'oz',
    );
    expect(tx.purchaseValue,
        closeTo(0.5 * troyOuncesPerKilogram * 150, 0.001));
  });

  test('Obsługa polskiego przecinka i walidacja wartości', () {
    expect(positiveNumber('14 000,50'), 14000.5);
    expect(positiveNumber('-4'), isNull);
    expect(positiveNumber('0'), isNull);
    expect(positiveNumber('abc'), isNull);
  });

  testWidgets('Portfel pokazuje cenę referencyjną i podsumowanie',
      (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    expect(find.text('Mój portfel'), findsOneWidget);
    expect(find.text('13 680,00 zł'), findsOneWidget);
    expect(find.text(moneyPln(0.75 * referenceGoldPlnOz +
        12 * referenceSilverPlnOz)), findsOneWidget);
  });

  testWidgets('Transakcje zawierają dwa przykładowe zakupy', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    expect(find.text('Historia transakcji'), findsOneWidget);
    expect(find.text('2 transakcje'), findsOneWidget);
  });

  testWidgets('Dodanie zakupu zwiększa liczbę i wartość zakupów',
      (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_transaction_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('amount_field')), '1');
    await tester.enterText(find.byKey(const ValueKey('price_field')), '10000');
    await tester.ensureVisible(find.byKey(const ValueKey('save_transaction_button')));
    await tester.tap(find.byKey(const ValueKey('save_transaction_button')));
    await tester.pumpAndSettle();
    expect(find.text('3 transakcje'), findsOneWidget);
    await tester.tap(find.text('Portfel'));
    await tester.pumpAndSettle();
    expect(find.text('23 680,00 zł'), findsOneWidget);
  });

  testWidgets('Można wybrać kilogramy i cenę PLN/kg w formularzu',
      (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_transaction_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('amount_unit_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kilogramy (kg)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('purchase_price_unit_field')));
    await tester.tap(find.byKey(const ValueKey('purchase_price_unit_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLN za kilogram (PLN/kg)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('amount_field')), '1');
    await tester.enterText(find.byKey(const ValueKey('price_field')), '450000');
    await tester.ensureVisible(find.byKey(const ValueKey('save_transaction_button')));
    await tester.tap(find.byKey(const ValueKey('save_transaction_button')));
    await tester.pumpAndSettle();
    expect(find.text('3 transakcje'), findsOneWidget);
    await tester.tap(find.text('Portfel'));
    await tester.pumpAndSettle();
    expect(find.text('463 680,00 zł'), findsOneWidget);
  });

  testWidgets('Zmiana kursu złota zmienia wycenę portfela', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Kursy'));
    await tester.pumpAndSettle();
    expect(find.text('Kursy metali'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit_market_price_gold')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('market_price_field')), '20000');
    await tester.tap(find.byKey(const ValueKey('save_market_price')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portfel'));
    await tester.pumpAndSettle();
    expect(find.text(moneyPln(0.75 * 20000 + 12 * referenceSilverPlnOz)),
        findsOneWidget);
  });

  testWidgets('Usunięcie zakupu zmniejsza liczbę transakcji', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete_transaction_1')));
    await tester.pumpAndSettle();
    expect(find.text('Usunąć transakcję?'), findsOneWidget);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(find.text('1 transakcja'), findsOneWidget);
  });
}
