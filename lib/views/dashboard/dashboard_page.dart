import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalSales = 0.0;
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  int productsInStock = 0;
  int clientsCount = 0;
  int tasksTotal = 0;
  int tasksDone = 0;

  Future<void> loadStats() async {
    final sales = await DBHelper.getSales();
    final wallet = await DBHelper.getTransactions();
    final products = await DBHelper.getProducts();
    final clients = await DBHelper.getClients();
    final tasks = await DBHelper.getTasks();

    totalSales = sales.fold(0.0, (sum, s) => sum + (s['total'] as num));
    totalIncome = wallet
        .where((t) => t['type'] == 'Entrée')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num));
    totalExpenses = wallet
        .where((t) => t['type'] == 'Sortie')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num));
    productsInStock =
        products.fold(0, (sum, p) => sum + (p['quantity'] as int));
    clientsCount = clients.length;
    tasksTotal = tasks.length;
    tasksDone = tasks.where((t) => t['isDone'] == 1).length;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          DashboardCard(
              title: 'Ventes totales',
              value: '${totalSales.toStringAsFixed(0)} FCFA',
              icon: Icons.sell,
              color: Colors.blue),
          DashboardCard(
              title: 'Revenus',
              value: '${totalIncome.toStringAsFixed(0)} FCFA',
              icon: Icons.trending_up,
              color: Colors.green),
          DashboardCard(
              title: 'Dépenses',
              value: '${totalExpenses.toStringAsFixed(0)} FCFA',
              icon: Icons.trending_down,
              color: Colors.red),
          DashboardCard(
              title: 'Produits en stock',
              value: '$productsInStock',
              icon: Icons.inventory,
              color: Colors.orange),
          DashboardCard(
              title: 'Clients enregistrés',
              value: '$clientsCount',
              icon: Icons.people,
              color: Colors.purple),
          DashboardCard(
              title: 'Tâches terminées',
              value: '$tasksDone / $tasksTotal',
              icon: Icons.check_circle,
              color: Colors.teal),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
