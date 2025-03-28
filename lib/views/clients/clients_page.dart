import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bakan/database/db_helper.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<Map<String, dynamic>> allClients = [];
  List<Map<String, dynamic>> filteredClients = [];
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final searchController = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    loadClients();
    searchController.addListener(() {
      filterClients(searchController.text);
    });
  }

  Future<void> loadClients() async {
    allClients = await DBHelper.getClients();
    filterClients(searchController.text); // filtre initial
  }

  void filterClients(String query) {
    setState(() {
      filteredClients = allClients
          .where((client) =>
              client['name'].toLowerCase().contains(query.toLowerCase()) ||
              client['phone'].contains(query))
          .toList();
    });
  }

  Future<void> addOrUpdateClient() async {
    final data = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
    };
    if (editingId == null) {
      await DBHelper.insertClient(data);
    } else {
      await DBHelper.updateClient(editingId!, data);
    }

    nameController.clear();
    phoneController.clear();
    addressController.clear();
    editingId = null;
    Navigator.pop(context);
    await loadClients();
  }

  void showClientDialog({Map<String, dynamic>? client}) {
    if (client != null) {
      nameController.text = client['name'];
      phoneController.text = client['phone'];
      addressController.text = client['address'];
      editingId = client['id'];
    } else {
      nameController.clear();
      phoneController.clear();
      addressController.clear();
      editingId = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(editingId == null ? 'Nouveau Client' : 'Modifier le Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom')),
              TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone')),
              TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Adresse')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: addOrUpdateClient, child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  void deleteClient(int id) async {
    await DBHelper.deleteClient(id);
    await loadClients();
  }

  void viewClientPurchases(Map<String, dynamic> client) async {
    final sales = await DBHelper.getSalesByClientId(client['id']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Achats de ${client['name']}"),
        content: sales.isEmpty
            ? const Text("Aucune vente enregistrée pour ce client.")
            : SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: sales.map((sale) {
                    final date = DateFormat('dd/MM/yyyy – HH:mm')
                        .format(DateTime.parse(sale['date']));
                    return ListTile(
                      leading:
                          const Icon(Icons.receipt_long, color: Colors.teal),
                      title: Text("Total: ${sale['total']} FCFA"),
                      subtitle: Text("Date: $date"),
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Clients"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showClientDialog(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredClients.isEmpty
                ? const Center(child: Text("Aucun client trouvé."))
                : ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final c = filteredClients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            c['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "📞 ${c['phone']}\n📍 ${c['address']}",
                            style: const TextStyle(height: 1.4),
                          ),
                          onTap: () => viewClientPurchases(c),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => showClientDialog(client: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => deleteClient(c['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
