// 🧾 Nouvelle version stylée et moderne de WalletPage avec carte bancaire, filtres puissants et TabController
import 'package:bakan/views/wallet/stat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bakan/database/db_helper.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> transactions = [];
  List<String> categories = [];
  double balance = 0.0;
  String type = 'Entrée';
  String category = 'Nourriture';

  final descController = TextEditingController();
  final amountController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    final all = await DBHelper.getTransactions();
    categories = await DBHelper.getCategories();
    final filtered = all.where((t) {
      final date = DateTime.parse(t['date']);
      final matchStart = startDate == null ||
          date.isAfter(startDate!.subtract(const Duration(days: 1)));
      final matchEnd = endDate == null ||
          date.isBefore(endDate!.add(const Duration(days: 1)));
      return matchStart && matchEnd;
    }).toList();
    transactions = filtered;
    balance = await DBHelper.getWalletBalance();
    setState(() {});
  }

  void showNewOperationPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nouvelle opération",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant'),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: type,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'Entrée', child: Text('Entrée')),
                        DropdownMenuItem(
                            value: 'Sortie', child: Text('Sortie')),
                      ],
                      onChanged: (val) => setState(() => type = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) => setState(() => category = val!),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (descController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    await DBHelper.insertTransaction({
                      'description': descController.text,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'type': type,
                      'category': category,
                      'date': DateTime.now().toIso8601String(),
                    });
                    descController.clear();
                    amountController.clear();
                    Navigator.pop(context);
                    await loadData();
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text("Valider"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCardBalance() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient:
            const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PORTFEUILLE BAKAN",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text("${balance.toStringAsFixed(2)} FCFA",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70))
        ],
      ),
    );
  }

  Widget buildTransactionList(String filterType) {
    final list = transactions.where((t) => t['type'] == filterType).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        final date =
            DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.parse(t['date']));
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              filterType == 'Entrée'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: filterType == 'Entrée' ? Colors.green : Colors.red,
            ),
            title: Text("${t['description']} - ${t['amount']} FCFA"),
            subtitle: Text("${t['category']} • $date"),
          ),
        );
      },
    );
  }

  void selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null) {
      startDate = range.start;
      endDate = range.end;
      await loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showNewOperationPopup,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Portefeuille"),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletStatsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: selectDateRange,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Entrées"),
            Tab(text: "Sorties"),
          ],
        ),
      ),
      body: Column(
        children: [
          buildCardBalance(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildTransactionList('Entrée'),
                buildTransactionList('Sortie'),
              ],
            ),
          )
        ],
      ),
    );
  }
}
