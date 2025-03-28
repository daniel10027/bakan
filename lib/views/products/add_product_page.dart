import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bakan/database/db_helper.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final purchaseController = TextEditingController();
  final saleController = TextEditingController();
  final quantityController = TextEditingController();
  File? image;
  String error = '';

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  void saveProduct() async {
    // Validation
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        purchaseController.text.isEmpty ||
        saleController.text.isEmpty ||
        quantityController.text.isEmpty ||
        image == null) {
      setState(() => error = 'Tous les champs sont obligatoires.');
      return;
    }

    final data = {
      'name': nameController.text.trim(),
      'description': descController.text.trim(),
      'purchasePrice': double.tryParse(purchaseController.text) ?? 0.0,
      'salePrice': double.tryParse(saleController.text) ?? 0.0,
      'quantity': int.tryParse(quantityController.text) ?? 0,
      'imagePath': image?.path,
    };

    await DBHelper.insertProduct(data);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(image!, fit: BoxFit.cover))
                    : const Center(
                        child: Text(
                          "Appuyez pour ajouter une image",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            buildField(nameController, 'Nom'),
            buildField(descController, 'Description'),
            buildField(purchaseController, "Prix d'achat", isNumber: true),
            buildField(saleController, "Prix de vente", isNumber: true),
            buildField(quantityController, 'Quantité', isNumber: true),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: saveProduct,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer le produit"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
