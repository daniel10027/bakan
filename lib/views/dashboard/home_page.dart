import 'package:flutter/material.dart';
import 'package:bakan/views/clients/clients_page.dart';
import 'package:bakan/views/dashboard/dashboard_page.dart';
import 'package:bakan/views/products/products_page.dart';
import 'package:bakan/views/sales/sales_page.dart';
import 'package:bakan/views/tasks/tasks_page.dart';
import 'package:bakan/views/wallet/wallet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const DashboardPage(),
    const ProductsPage(),
    const SalesPage(),
    const ClientsPage(),
    const WalletPage(),
    const TasksPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bakan"),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Invité'),
              accountEmail: Text('Non connecté'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
              decoration: BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text("Sauvegarder dans Drive"),
              onTap: () => _showComingSoonDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text("Restaurer depuis Drive"),
              onTap: () => _showComingSoonDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Déconnexion Google"),
              onTap: () => _showComingSoonDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Se déconnecter de Bakan"),
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ],
        ),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1C1C1E),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Produits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: 'Ventes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wallet), label: 'Portefeuille'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tâches'),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Fonctionnalité à venir"),
        content: const Text("Cette fonctionnalité sera bientôt disponible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
