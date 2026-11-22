import 'package:flutter/material.dart';

void main() {
  runApp(const SystemMetaliApp());
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
      ),
      home: const MainScreen(),
    );
  }
}

// Na etapie v0.2 korzystamy z cen demonstracyjnych, w PLN za uncję.
const double demoGoldPricePlnOz = 12150;
const double demoSilverPricePlnOz = 154;

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

class Investment {
  final int id;
  final DateTime date;
  final String metal;
  final double ounces;
  final double purchasePricePlnOz;
  final double currentPricePlnOz;

  const Investment({
    required this.id,
    required this.date,
    required this.metal,
    required this.ounces,
    required this.purchasePricePlnOz,
    required this.currentPricePlnOz,
  });

  double get purchaseValue => ounces * purchasePricePlnOz;
  double get currentValue => ounces * currentPricePlnOz;
  double get profit => currentValue - purchaseValue;
  double get roi =>
      purchaseValue == 0 ? 0 : (profit / purchaseValue) * 100;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  // Transakcje przykładowe; użytkownik może je usunąć.
  // Zapis danych między uruchomieniami dodamy w kolejnym etapie.
  final List<Investment> investments = [
    Investment(
      id: 1,
      date: DateTime(2026, 11, 1),
      metal: 'Złoto',
      ounces: 0.75,
      purchasePricePlnOz: 11600,
      currentPricePlnOz: demoGoldPricePlnOz,
    ),
    Investment(
      id: 2,
      date: DateTime(2026, 11, 2),
      metal: 'Srebro',
      ounces: 12,
      purchasePricePlnOz: 145,
      currentPricePlnOz: demoSilverPricePlnOz,
    ),
  ];

  double get totalPurchase => investments.fold<double>(
        0,
        (sum, investment) => sum + investment.purchaseValue,
      );

  double get totalCurrent => investments.fold<double>(
        0,
        (sum, investment) => sum + investment.currentValue,
      );

  double get totalProfit => totalCurrent - totalPurchase;
  double get totalRoi =>
      totalPurchase == 0 ? 0 : (totalProfit / totalPurchase) * 100;

  String pln(double value) {
    final parts = value.abs().toStringAsFixed(2).split('.');
    var integer = parts[0];
    final groups = <String>[];
    while (integer.length > 3) {
      groups.insert(0, integer.substring(integer.length - 3));
      integer = integer.substring(0, integer.length - 3);
    }
    groups.insert(0, integer);
    return '${value < 0 ? '-' : ''}${groups.join(' ')},${parts[1]} zł';
  }

  Future<void> _addTransaction() async {
    final transaction = await showModalBottomSheet<Investment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const TransactionForm(),
    );
    if (!mounted || transaction == null) return;
    setState(() => investments.add(transaction));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transakcja została dodana')),
    );
  }

  Future<void> _deleteTransaction(Investment investment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć transakcję?'),
        content: Text(
          '${investment.metal} — ${investment.ounces.toString().replaceAll('.', ',')} oz',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;
    setState(() => investments.removeWhere((tx) => tx.id == investment.id));
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

  Widget _portfolioScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                label: Text('Dane demonstracyjne — nie są to aktualne kursy'),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard(
                      itemWidth,
                      'Wartość zakupu',
                      pln(totalPurchase),
                      Icons.shopping_bag_outlined,
                    ),
                    _summaryCard(
                      itemWidth,
                      'Wartość aktualna',
                      pln(totalCurrent),
                      Icons.account_balance_wallet_outlined,
                    ),
                    _summaryCard(
                      itemWidth,
                      'Zysk / strata',
                      pln(totalProfit),
                      Icons.trending_up,
                    ),
                    _summaryCard(
                      itemWidth,
                      'ROI',
                      '${totalRoi.toStringAsFixed(2).replaceAll('.', ',')} %',
                      Icons.percent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            const Text(
              'Moje inwestycje',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (investments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('Brak transakcji. Dodaj pierwszy zakup w zakładce Transakcje.'),
              ),
            for (final investment in investments) _investmentCard(investment),
            const SizedBox(height: 14),
            const Text(
              'Aby dodać lub usunąć zakup, przejdź do zakładki Transakcje.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    double width,
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
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
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _investmentCard(Investment investment) {
    final isGold = investment.metal == 'Złoto';
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor:
                  isGold ? const Color(0xFFFFF0C2) : const Color(0xFFE2E8F0),
              child: Icon(
                Icons.toll,
                color: isGold
                    ? const Color(0xFFB7791F)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.metal,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${investment.ounces.toString().replaceAll('.', ',')} oz',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pln(investment.currentValue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${investment.profit >= 0 ? '+' : ''}${pln(investment.profit)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: investment.profit >= 0
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

  Widget _transactionsScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            const Text(
              'Historia transakcji',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${investments.length} ${investments.length == 1 ? 'transakcja' : 'transakcje'}',
              key: const ValueKey('transaction_count'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (investments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Center(child: Text('Nie masz jeszcze żadnych transakcji.')),
              ),
            for (final tx in investments.reversed)
              Card(
                color: Colors.white,
                child: ListTile(
                  title: Text('${tx.metal} • ${tx.ounces.toString().replaceAll('.', ',')} oz'),
                  subtitle: Text(
                    '${formatDate(tx.date)}  ·  Cena zakupu: ${pln(tx.purchasePricePlnOz)}/oz\n'
                    'Wartość zakupu: ${pln(tx.purchaseValue)}',
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
          ],
        ),
      ),
    );
  }

  Widget _comingSoonScreen(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined,
                size: 54, color: Color(0xFF64748B)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ten ekran przygotujemy w kolejnym etapie migracji.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
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
  DateTime date = DateTime.now();

  @override
  void dispose() {
    amountController.dispose();
    priceController.dispose();
    super.dispose();
  }

  double? _parsePositiveNumber(String? input) {
    final normalized = (input ?? '').trim().replaceAll(' ', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
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
    final ounces = _parsePositiveNumber(amountController.text)!;
    final purchasePrice = _parsePositiveNumber(priceController.text)!;
    Navigator.pop(
      context,
      Investment(
        id: DateTime.now().microsecondsSinceEpoch,
        date: date,
        metal: metal,
        ounces: ounces,
        purchasePricePlnOz: purchasePrice,
        currentPricePlnOz:
            metal == 'Złoto' ? demoGoldPricePlnOz : demoSilverPricePlnOz,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dodaj transakcję',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ceny bieżące są demonstracyjne. Ilość i cenę zakupu podajesz samodzielnie.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: metal,
              decoration: const InputDecoration(
                labelText: 'Metal',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Złoto', child: Text('Złoto')),
                DropdownMenuItem(value: 'Srebro', child: Text('Srebro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => metal = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('amount_field'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ilość (oz)',
                hintText: 'np. 0,5',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _parsePositiveNumber(value) == null
                  ? 'Podaj ilość większą od zera'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('price_field'),
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cena zakupu (PLN/oz)',
                hintText: 'np. 12000',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _parsePositiveNumber(value) == null
                  ? 'Podaj cenę większą od zera'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Data zakupu: ${formatDate(date)}'),
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
