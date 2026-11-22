import 'package:flutter/material.dart';

void main() => runApp(const SystemMetaliApp());

// Notowania referencyjne z 20.11.2026, a nie aktualizowane automatycznie.
// XAU/USD: 3520.57; XAG/USD: 41.113; USD/PLN (NBP): 4.0613.
// Zrodla: metalcharts.org (XAU, XAG), nbp.pl (tabela 226/A/NBP/2026).
const double troyOuncesPerKilogram = 32.1507465686;
const double referenceUsdPln = 4.0613;
const double referenceGoldUsdOz = 3520.57;
const double referenceSilverUsdOz = 41.113;
const double referenceGoldPlnOz = referenceGoldUsdOz * referenceUsdPln;
const double referenceSilverPlnOz = referenceSilverUsdOz * referenceUsdPln;

// Tak samo jak w oryginalnym backend.py: przechowujemy ilosc w uncjach
// trojanskich, a cene w PLN/oz. Inne jednostki normalizujemy przy zapisie.
double toTroyOunces(double amount, String unit) =>
    unit == 'kg' ? amount * troyOuncesPerKilogram : amount;

double priceToPlnOz(double price, String priceUnit) =>
    priceUnit == 'kg' ? price / troyOuncesPerKilogram : price;

double? positiveNumber(String? text) {
  final value = double.tryParse(
    (text ?? '').replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'),
  );
  return value != null && value.isFinite && value > 0 ? value : null;
}

String money(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  var digits = parts[0];
  final groups = <String>[];
  while (digits.length > 3) {
    groups.insert(0, digits.substring(digits.length - 3));
    digits = digits.substring(0, digits.length - 3);
  }
  groups.insert(0, digits);
  return '${value < 0 ? '-' : ''}${groups.join(' ')},${parts[1]} zl';
}

String moneyPln(double value) => money(value).replaceAll(' zl', ' zł');

String amountText(double value, {int decimals = 6}) {
  var result = value.toStringAsFixed(decimals);
  result = result.replaceFirst(RegExp(r'0+$'), '');
  result = result.replaceFirst(RegExp(r'\.$'), '');
  return result.replaceAll('.', ',');
}

String dateText(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

class Investment {
  final int id;
  final DateTime date;
  final String metal;
  final double amount;
  final String amountUnit;
  final double purchasePrice;
  final String purchasePriceUnit;

  const Investment({
    required this.id,
    required this.date,
    required this.metal,
    required this.amount,
    required this.amountUnit,
    required this.purchasePrice,
    required this.purchasePriceUnit,
  });

  double get ounces => toTroyOunces(amount, amountUnit);
  double get kilograms => ounces / troyOuncesPerKilogram;
  double get purchasePricePlnOz => priceToPlnOz(purchasePrice, purchasePriceUnit);
  double get purchaseValue => ounces * purchasePricePlnOz;
  double currentValue(double currentPricePlnOz) => ounces * currentPricePlnOz;
  double profit(double currentPricePlnOz) =>
      currentValue(currentPricePlnOz) - purchaseValue;
  double roi(double currentPricePlnOz) => purchaseValue == 0
      ? 0
      : profit(currentPricePlnOz) / purchaseValue * 100;
}

class SystemMetaliApp extends StatelessWidget {
  const SystemMetaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Metali Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF172033),
          surfaceTintColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  double goldPricePlnOz = referenceGoldPlnOz;
  double silverPricePlnOz = referenceSilverPlnOz;
  bool goldEdited = false;
  bool silverEdited = false;

  // Przykładowe transakcje. Ceny zakupu sa testowe i nie odzwierciedlaja
  // rzeczywistych zakupow. Lokalna baza danych to osobny etap v0.4.
  final List<Investment> investments = [
    Investment(
      id: 1,
      date: DateTime(2026, 11, 1),
      metal: 'Złoto',
      amount: 0.75,
      amountUnit: 'oz',
      purchasePrice: 15200,
      purchasePriceUnit: 'oz',
    ),
    Investment(
      id: 2,
      date: DateTime(2026, 11, 2),
      metal: 'Srebro',
      amount: 12,
      amountUnit: 'oz',
      purchasePrice: 190,
      purchasePriceUnit: 'oz',
    ),
  ];

  double marketPrice(String metal) =>
      metal == 'Złoto' ? goldPricePlnOz : silverPricePlnOz;

  double get totalPurchase => investments.fold<double>(
        0,
        (sum, tx) => sum + tx.purchaseValue,
      );
  double get totalCurrent => investments.fold<double>(
        0,
        (sum, tx) => sum + tx.currentValue(marketPrice(tx.metal)),
      );
  double get totalProfit => totalCurrent - totalPurchase;
  double get totalRoi =>
      totalPurchase == 0 ? 0 : totalProfit / totalPurchase * 100;

  Future<void> _addTransaction() async {
    final transaction = await showModalBottomSheet<Investment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const TransactionForm(),
    );
    if (!mounted || transaction == null) return;
    setState(() => investments.add(transaction));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transakcja została dodana')),
    );
  }

  Future<void> _deleteTransaction(Investment tx) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usunąć transakcję?'),
        content: Text(
          '${tx.metal} — ${amountText(tx.amount)} ${tx.amountUnit}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (!mounted || answer != true) return;
    setState(() => investments.removeWhere((item) => item.id == tx.id));
  }

  Future<void> _editPrice(String metal) async {
    final editedPricePlnOz = await showDialog<double>(
      context: context,
      builder: (_) => PriceEditDialog(
        metal: metal,
        currentPricePlnOz: marketPrice(metal),
      ),
    );
    if (!mounted || editedPricePlnOz == null) return;
    setState(() {
      if (metal == 'Złoto') {
        goldPricePlnOz = editedPricePlnOz;
        goldEdited = true;
      } else {
        silverPricePlnOz = editedPricePlnOz;
        silverEdited = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Portfel', 'Transakcje', 'Kursy', 'Wykresy'];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'System Metali Mobile',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body: switch (selectedIndex) {
        0 => _portfolioScreen(),
        1 => _transactionsScreen(),
        2 => _marketScreen(),
        _ => _comingSoonScreen(titles[selectedIndex]),
      },
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton.extended(
              key: const ValueKey('add_transaction_button'),
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj zakup'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfel',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transakcje',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Kursy',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Wykresy',
          ),
        ],
      ),
    );
  }

  Widget _page(List<Widget> children, {double bottomPadding = 16}) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
            children: children,
          ),
        ),
      );

  Widget _portfolioScreen() => _page([
        const Text(
          'Mój portfel',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Podsumowanie inwestycji w metale szlachetne',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: Icon(Icons.info_outline, size: 17),
            label: Text('Ceny referencyjne z 20.11.2026 / edytowane ręcznie'),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 340 ? 1 : 2;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard(width, 'Wartość zakupu', moneyPln(totalPurchase),
                  Icons.shopping_bag_outlined),
              _summaryCard(width, 'Wartość aktualna', moneyPln(totalCurrent),
                  Icons.account_balance_wallet_outlined),
              _summaryCard(width, 'Zysk / strata', moneyPln(totalProfit),
                  Icons.trending_up),
              _summaryCard(width, 'ROI',
                  '${totalRoi.toStringAsFixed(2).replaceAll('.', ',')} %', Icons.percent),
            ],
          );
        }),
        const SizedBox(height: 26),
        const Text('Moje inwestycje',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (investments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text('Brak transakcji. Dodaj zakup w zakładce Transakcje.'),
          ),
        for (final tx in investments) _investmentCard(tx),
        const SizedBox(height: 14),
        const Text(
          'Ceny wyceny można zmienić w zakładce Kursy. '
          'Dane nie są pobierane na żywo.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ]);

  Widget _summaryCard(double width, String title, String value, IconData icon) =>
      SizedBox(
        width: width,
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF2563EB), size: 23),
                const SizedBox(height: 13),
                Text(title,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033))),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _investmentCard(Investment tx) {
    final isGold = tx.metal == 'Złoto';
    final current = marketPrice(tx.metal);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isGold
                  ? const Color(0xFFFFF0C2)
                  : const Color(0xFFE2E8F0),
              child: Icon(Icons.toll,
                  color: isGold
                      ? const Color(0xFFB7791F)
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.metal,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${amountText(tx.amount)} ${tx.amountUnit}',
                      style: const TextStyle(color: Color(0xFF64748B))),
                  Text(
                      '${amountText(tx.ounces)} oz · ${amountText(tx.kilograms)} kg',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(moneyPln(tx.currentValue(current)),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${tx.profit(current) >= 0 ? '+' : ''}${moneyPln(tx.profit(current))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: tx.profit(current) >= 0
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionsScreen() => _page([
        const Text('Historia transakcji',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${investments.length} '
            '${investments.length == 1 ? 'transakcja' : 'transakcje'}',
            key: const ValueKey('transaction_count'),
            style: const TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        if (investments.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 35),
              child: Center(child: Text('Nie masz jeszcze żadnych transakcji.'))),
        for (final tx in investments.reversed)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                  '${tx.metal} • ${amountText(tx.amount)} ${tx.amountUnit}'),
              subtitle: Text(
                '${dateText(tx.date)}  ·  Cena zakupu: '
                '${moneyPln(tx.purchasePrice)}/${tx.purchasePriceUnit}\n'
                'Wartość zakupu: ${moneyPln(tx.purchaseValue)}\n'
                'Odpowiednik: ${amountText(tx.ounces)} oz',
              ),
              isThreeLine: true,
              trailing: IconButton(
                key: ValueKey('delete_transaction_${tx.id}'),
                onPressed: () => _deleteTransaction(tx),
                tooltip: 'Usuń transakcję',
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
      ], bottomPadding: 100);

  Widget _marketScreen() => _page([
        const Text('Kursy metali',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Orientacyjne ceny spot przeliczone na PLN na podstawie '
          'notowań z 20.11.2026 (ostatnia sesja przed weekendem). '
          'Możesz je zmienić ręcznie. Brak aktualizacji automatycznej.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),
        _metalPriceCard('Złoto', goldPricePlnOz, goldEdited),
        _metalPriceCard('Srebro', silverPricePlnOz, silverEdited),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Źródła: metalcharts.org (XAU/USD, XAG/USD, 20.11.2026); '
              'NBP tabela 226/A/NBP/2026 (USD/PLN = 4,0613). '
              'Ceny spot nie obejmują marży, podatków ani kosztów zakupu.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ]);

  Widget _metalPriceCard(String metal, double perOz, bool edited) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(metal,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(edited ? 'Cena ręczna' : '20.11.2026',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 12),
              Text('${moneyPln(perOz)} / oz',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${moneyPln(perOz * troyOuncesPerKilogram)} / kg',
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: ValueKey('edit_market_price_${metal == 'Złoto' ? 'gold' : 'silver'}'),
                onPressed: () => _editPrice(metal),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Zmień cenę'),
              ),
            ],
          ),
        ),
      );

  Widget _comingSoonScreen(String title) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 54, color: Color(0xFF64748B)),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ten ekran przygotujemy w kolejnym etapie migracji.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
}

class PriceEditDialog extends StatefulWidget {
  const PriceEditDialog({
    super.key,
    required this.metal,
    required this.currentPricePlnOz,
  });

  final String metal;
  final double currentPricePlnOz;

  @override
  State<PriceEditDialog> createState() => _PriceEditDialogState();
}

class _PriceEditDialogState extends State<PriceEditDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController priceController;
  String priceUnit = 'oz';

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.currentPricePlnOz.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  void _setUnit(String unit) {
    if (unit == priceUnit) return;
    final entered = positiveNumber(priceController.text);
    if (entered != null) {
      final converted = unit == 'kg'
          ? entered * troyOuncesPerKilogram
          : entered / troyOuncesPerKilogram;
      priceController.text = converted.toStringAsFixed(2).replaceAll('.', ',');
    }
    setState(() => priceUnit = unit);
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      priceToPlnOz(positiveNumber(priceController.text)!, priceUnit),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Cena: ${widget.metal}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Podaj orientacyjną cenę rynkową w PLN. '
                  'Wpłynie ona na wycenę wszystkich transakcji tego metalu.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('market_price_unit_$priceUnit'),
                  initialValue: priceUnit,
                  decoration: const InputDecoration(labelText: 'Cena za jednostkę'),
                  items: const [
                    DropdownMenuItem(value: 'oz', child: Text('PLN / oz')),
                    DropdownMenuItem(value: 'kg', child: Text('PLN / kg')),
                  ],
                  onChanged: (unit) {
                    if (unit != null) _setUnit(unit);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('market_price_field'),
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Cena w PLN/$priceUnit',
                    hintText: 'np. 14298,09',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (text) => positiveNumber(text) == null
                      ? 'Podaj cenę większą od zera'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            key: const ValueKey('save_market_price'),
            onPressed: _submit,
            child: const Text('Zapisz cenę'),
          ),
        ],
      );
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final priceController = TextEditingController();
  String metal = 'Złoto';
  String amountUnit = 'oz';
  String purchasePriceUnit = 'oz';
  DateTime date = DateTime.now();

  @override
  void dispose() {
    amountController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosen != null && mounted) setState(() => date = chosen);
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Investment(
        id: DateTime.now().microsecondsSinceEpoch,
        date: date,
        metal: metal,
        amount: positiveNumber(amountController.text)!,
        amountUnit: amountUnit,
        purchasePrice: positiveNumber(priceController.text)!,
        purchasePriceUnit: purchasePriceUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dodaj transakcję',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Ilość i cenę zakupu możesz podać w uncjach trojańskich '
              'lub kilogramach. Wszystkie ceny podajemy w PLN.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: metal,
              decoration: const InputDecoration(labelText: 'Metal'),
              items: const [
                DropdownMenuItem(value: 'Złoto', child: Text('Złoto')),
                DropdownMenuItem(value: 'Srebro', child: Text('Srebro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => metal = value);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const ValueKey('amount_unit_field'),
              initialValue: amountUnit,
              decoration: const InputDecoration(labelText: 'Jednostka ilości'),
              items: const [
                DropdownMenuItem(value: 'oz', child: Text('Uncje trojańskie (oz)')),
                DropdownMenuItem(value: 'kg', child: Text('Kilogramy (kg)')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => amountUnit = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('amount_field'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Ilość ($amountUnit)',
                hintText: amountUnit == 'kg' ? 'np. 0,25' : 'np. 0,5',
              ),
              validator: (text) => positiveNumber(text) == null
                  ? 'Podaj ilość większą od zera'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const ValueKey('purchase_price_unit_field'),
              initialValue: purchasePriceUnit,
              decoration: const InputDecoration(labelText: 'Jednostka ceny zakupu'),
              items: const [
                DropdownMenuItem(value: 'oz', child: Text('PLN za uncję (PLN/oz)')),
                DropdownMenuItem(value: 'kg', child: Text('PLN za kilogram (PLN/kg)')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => purchasePriceUnit = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('price_field'),
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cena zakupu (PLN/$purchasePriceUnit)',
                hintText: purchasePriceUnit == 'kg' ? 'np. 450000' : 'np. 14200',
              ),
              validator: (text) => positiveNumber(text) == null
                  ? 'Podaj cenę większą od zera'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Data zakupu: ${dateText(date)}'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save_transaction_button'),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Zapisz transakcję'),
            ),
          ],
        ),
      ),
    );
  }
}
