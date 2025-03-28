import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  Future<void> loadProducts() async {
    allProducts = await DBHelper.getProducts();
    filteredProducts = allProducts;
    setState(() {});
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      filteredProducts = allProducts;
    } else {
      filteredProducts = allProducts
          .where((p) =>
              p['name'].toLowerCase().contains(query.toLowerCase().trim()))
          .toList();
    }
    setState(() {});
  }

  void deleteProduct(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteProduct(id);
      await loadProducts();
    }
  }

  void editProduct(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);
    final quantityController =
        TextEditingController(text: product['quantity'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Modifier ${product['name']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantité"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await DBHelper.updateProduct(
                  product['id'],
                  {
                    'name': nameController.text,
                    'quantity': int.tryParse(quantityController.text) ?? 0
                  },
                  // Removed invalid parameters
                );
                Navigator.pop(context);
                await loadProducts();
              },
              child: const Text("Enregistrer"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: searchController,
                onChanged: searchProducts,
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.teal,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text("Aucun produit trouvé"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredProducts.length,
                      itemBuilder: (_, index) {
                        final p = filteredProducts[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: p['imagePath'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(p['imagePath']),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.image, size: 40),
                            title: Text(p['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                "Stock: ${p['quantity']} | Vente: ${p['salePrice']} FCFA"),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  editProduct(p);
                                } else if (value == 'delete') {
                                  deleteProduct(p['id']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text("Modifier")),
                                const PopupMenuItem(
                                    value: 'delete', child: Text("Supprimer")),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_product');
          await loadProducts();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
