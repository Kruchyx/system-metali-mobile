import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_metali_mobile/main.dart';
import 'package:system_metali_mobile/portfolio_storage.dart';

class MemoryPortfolioStorage implements PortfolioStorage {
  String? data;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String json) async {
    data = json;
  }
}

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
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
    expect(find.text('Mój portfel'), findsOneWidget);
    expect(find.text('13 680,00 zł'), findsOneWidget);
    expect(find.text(moneyPln(0.75 * referenceGoldPlnOz +
        12 * referenceSilverPlnOz)), findsOneWidget);
  });

  testWidgets('Transakcje zawierają dwa przykładowe zakupy', (tester) async {
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    expect(find.text('Historia transakcji'), findsOneWidget);
    expect(find.text('2 transakcje'), findsOneWidget);
  });

  testWidgets('Dodanie zakupu zwiększa liczbę i wartość zakupów',
      (tester) async {
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(SystemMetaliApp(storage: MemoryPortfolioStorage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete_transaction_1')));
    await tester.pumpAndSettle();
    expect(find.text('Usunąć transakcję?'), findsOneWidget);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(find.text('1 transakcja'), findsOneWidget);
  });

  test('Zapis JSON odtwarza transakcję kg oraz ręczne ceny', () {
    final snapshot = PortfolioSnapshot(
      investments: [
        Investment(
          id: 123,
          date: DateTime(2026, 11, 20),
          metal: 'Srebro',
          amount: 0.5,
          amountUnit: 'kg',
          purchasePrice: 5000,
          purchasePriceUnit: 'kg',
        ),
      ],
      goldPricePlnOz: 19000,
      silverPricePlnOz: 200,
      goldEdited: true,
      silverEdited: true,
    );
    final copy = PortfolioSnapshot.decode(snapshot.encode());
    expect(copy.investments.single.metal, 'Srebro');
    expect(copy.investments.single.amountUnit, 'kg');
    expect(copy.investments.single.purchasePriceUnit, 'kg');
    expect(copy.investments.single.purchaseValue, closeTo(2500, 0.001));
    expect(copy.goldPricePlnOz, 19000);
    expect(copy.silverPricePlnOz, 200);
    expect(copy.goldEdited, isTrue);
    expect(copy.silverEdited, isTrue);
  });

  test('Pusty portfel też jest poprawnie zapisywany', () {
    final snapshot = PortfolioSnapshot(
      investments: const [],
      goldPricePlnOz: referenceGoldPlnOz,
      silverPricePlnOz: referenceSilverPlnOz,
      goldEdited: false,
      silverEdited: false,
    );
    expect(PortfolioSnapshot.decode(snapshot.encode()).investments, isEmpty);
  });

  test('Uszkodzony lub nieznany format nie jest akceptowany', () {
    expect(() => PortfolioSnapshot.decode('nie-jest-json'), throwsFormatException);
    expect(() => PortfolioSnapshot.decode('{"schemaVersion":99}'), throwsFormatException);
  });

  testWidgets('Dodanie transakcji jest pamiętane po restarcie', (tester) async {
    final storage = MemoryPortfolioStorage();
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_transaction_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('amount_field')), '1');
    await tester.enterText(find.byKey(const ValueKey('price_field')), '10000');
    await tester.ensureVisible(find.byKey(const ValueKey('save_transaction_button')));
    await tester.tap(find.byKey(const ValueKey('save_transaction_button')));
    await tester.pumpAndSettle();
    expect(storage.data, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    expect(find.text('3 transakcje'), findsOneWidget);
    await tester.tap(find.text('Portfel'));
    await tester.pumpAndSettle();
    expect(find.text('23 680,00 zł'), findsOneWidget);
  });

  testWidgets('Usunięcie wszystkich transakcji pozostaje po restarcie', (tester) async {
    final storage = MemoryPortfolioStorage();
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    for (final id in [1, 2]) {
      await tester.tap(find.byKey(ValueKey('delete_transaction_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    expect(find.text('Nie masz jeszcze żadnych transakcji.'), findsOneWidget);
    expect(PortfolioSnapshot.decode(storage.data!).investments, isEmpty);
  });

  testWidgets('Ręczna cena przetrwa ponowne uruchomienie', (tester) async {
    final storage = MemoryPortfolioStorage();
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kursy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit_market_price_gold')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('market_price_field')), '20000');
    await tester.tap(find.byKey(const ValueKey('save_market_price')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kursy'));
    await tester.pumpAndSettle();
    expect(find.text('20 000,00 zł / oz'), findsOneWidget);
    expect(PortfolioSnapshot.decode(storage.data!).goldEdited, isTrue);
  });

  testWidgets('Przy błędnym zapisie pojawia się ostrzeżenie', (tester) async {
    final storage = MemoryPortfolioStorage()..data = 'błędny JSON';
    await tester.pumpWidget(SystemMetaliApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nie udało się odczytać'), findsOneWidget);
  });

}
