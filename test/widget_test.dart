import 'package:flutter_test/flutter_test.dart';
import 'package:system_metali_mobile/main.dart';

void main() {
  testWidgets('Portfel wyświetla podsumowanie inwestycji', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());

    expect(find.text('Mój portfel'), findsOneWidget);
    expect(find.text('10 440,00 zł'), findsOneWidget);
    expect(find.text('10 960,50 zł'), findsOneWidget);
    expect(find.text('520,50 zł'), findsOneWidget);
    expect(find.text('4,99 %'), findsOneWidget);
  });

  testWidgets('Można przejść do zakładki Transakcje', (tester) async {
    await tester.pumpWidget(const SystemMetaliApp());

    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();

    expect(find.text('Ten ekran przygotujemy w kolejnym etapie migracji.'),
        findsOneWidget);
  });
}
