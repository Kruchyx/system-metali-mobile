import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_metali_mobile/main.dart';

void main() {
  testWidgets('Portfel wyświetla początkowe dane demonstracyjne', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    expect(find.text('Mój portfel'), findsOneWidget);
    expect(find.text('10 440,00 zł'), findsOneWidget);
    expect(find.text('10 960,50 zł'), findsOneWidget);
    expect(find.text('520,50 zł'), findsOneWidget);
    expect(find.text('4,99 %'), findsOneWidget);
  });

  testWidgets('Transakcje pokazują dwa przykładowe zakupy', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());
    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();
    expect(find.text('Historia transakcji'), findsOneWidget);
    expect(find.text('2 transakcje'), findsOneWidget);
  });

  testWidgets('Dodanie transakcji zwiększa ich liczbę i zmienia portfel',
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
    expect(find.text('20 440,00 zł'), findsOneWidget);
  });

  testWidgets('Usunięcie transakcji zmniejsza ich liczbę', (tester) async {
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
