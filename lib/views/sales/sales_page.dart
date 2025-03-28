import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'package:bakan/views/sales/sales_history_page.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> clients = [];
  Map<String, dynamic>? selectedClient;

  Future<void> fetchProducts() async {
    products = await DBHelper.getProducts();
    clients = await DBHelper.getClients();
    if (!mounted) return;
    setState(() {});
  }

  double get total => selectedProducts.fold(
      0.0, (sum, p) => sum + p['salePrice'] * (p['quantity'] ?? 1));

  void toggleSelection(Map<String, dynamic> product) {
    setState(() {
      if (selectedProducts.any((p) => p['id'] == product['id'])) {
        selectedProducts.removeWhere((p) => p['id'] == product['id']);
      } else {
        selectedProducts.add({...product, 'quantity': 1});
      }
    });
  }

  void updateQuantity(Map<String, dynamic> product, int delta) {
    setState(() {
      final index =
          selectedProducts.indexWhere((p) => p['id'] == product['id']);
      if (index != -1) {
        selectedProducts[index]['quantity'] += delta;
        if (selectedProducts[index]['quantity'] <= 0) {
          selectedProducts.removeAt(index);
        }
      }
    });
  }

  Future<void> confirmSale() async {
    if (selectedClient == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    final now = DateTime.now();
    final logoBytes = await rootBundle.load('assets/images/sf/2.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final receipt = pw.Document();

    receipt.addPage(
      pw.Page(
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex("#1E88E5")),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("REÇU DE VENTE",
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
                          style: pw.TextStyle(fontSize: 10))
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text("Client : ${selectedClient!['name']}",
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Produit', 'PU', 'Quantité', 'Sous-total'],
                data: selectedProducts
                    .map((p) => [
                          p['name'],
                          "${p['salePrice']} FCFA",
                          p['quantity'].toString(),
                          "${(p['salePrice'] * p['quantity']).toStringAsFixed(2)} FCFA"
                        ])
                    .toList(),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex("#BBDEFB")),
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Total: ${total.toStringAsFixed(2)} FCFA",
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex("#E3F2FD"),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "🙏 Merci pour votre achat !",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text("Vendeur : Bakan", style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Center(
                  child: pw.Text("Bakan - Votre partenaire de confiance",
                      style: pw.TextStyle(
                          fontSize: 10, color: PdfColor.fromHex("#1E88E5"))))
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/recu_bakan.pdf");
    await file.writeAsBytes(await receipt.save());
    await OpenFile.open(file.path);

    List<String> lowStockAlerts = [];

    for (var p in selectedProducts) {
      final productInDb = await DBHelper.getProductById(p['id']);
      if (productInDb != null) {
        int currentQty = productInDb['quantity'];
        int soldQty = p['quantity'] ?? 1;
        int newQty = currentQty - soldQty;
        if (newQty < 0) newQty = 0;

        await DBHelper.updateProductQuantity(p['id'], newQty);

        if (newQty < 5) {
          lowStockAlerts.add("${p['name']} (reste $newQty)");
        }
      }
    }

    await DBHelper.insertSaleWithItems(
      total,
      selectedProducts,
      clientId: selectedClient!['id'],
    );

    selectedProducts.clear();
    selectedClient = null;

    if (!mounted) return;

    if (lowStockAlerts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ Stock faible pour :\n${lowStockAlerts.join(', ')}",
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vente enregistrée avec reçu PDF')),
      );
    }

    fetchProducts();
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Vente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SalesHistoryPage(),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedClient?['id'],
                    items: clients.map((client) {
                      return DropdownMenuItem<int>(
                        value: client['id'],
                        child: Text(client['name']),
                      );
                    }).toList(),
                    onChanged: (selectedId) {
                      setState(() {
                        selectedClient =
                            clients.firstWhere((c) => c['id'] == selectedId);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un client',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text("Aucun produit"))
                : ListView(
                    children: products.map((p) {
                      final selected =
                          selectedProducts.any((s) => s['id'] == p['id']);
                      final currentQty = selectedProducts.firstWhere(
                          (s) => s['id'] == p['id'],
                          orElse: () => {'quantity': 0})['quantity'];
                      return ListTile(
                        leading: p['imagePath'] != null
                            ? Image.file(File(p['imagePath']),
                                width: 40, height: 40)
                            : const Icon(Icons.image),
                        title: Text(p['name']),
                        subtitle: Text(
                            "${p['salePrice']} FCFA | Stock: ${p['quantity']}"),
                        trailing: selected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () => updateQuantity(p, -1)),
                                  Text('$currentQty'),
                                  IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () => updateQuantity(p, 1)),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.teal,
                                ),
                                onPressed: () => toggleSelection(p)),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text("Total: ${total.toStringAsFixed(2)} FCFA")),
            ElevatedButton(
              onPressed: selectedProducts.isNotEmpty ? confirmSale : null,
              child: const Text("Valider la vente"),
            )
          ],
        ),
      ),
    );
  }
}
