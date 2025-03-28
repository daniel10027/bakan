import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';

class WalletStatsPage extends StatefulWidget {
  const WalletStatsPage({super.key});

  @override
  State<WalletStatsPage> createState() => _WalletStatsPageState();
}

class _WalletStatsPageState extends State<WalletStatsPage> {
  List<Map<String, dynamic>> totalsByCategory = [];
  final GlobalKey _screenshotKey = GlobalKey();

  Future<void> loadStats() async {
    totalsByCategory = await DBHelper.getTotalsByCategory();
    setState(() {});
  }

  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> saveAndShareImage() async {
    await requestStoragePermission();
    if (await Permission.storage.isGranted) {
      try {
        RenderRepaintBoundary boundary = _screenshotKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File("${tempDir.path}/wallet_stats.png").create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)],
            text: "Statistiques du portefeuille Bakan");

        await ImageGallerySaver.saveImage(pngBytes,
            quality: 100,
            name: "wallet_stats_${DateTime.now().millisecondsSinceEpoch}");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Image enregistrée et prête à être partagée.")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Permission de stockage refusée. Impossible de sauvegarder l'image.")),
      );
    }
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();
    final imageBytes = await rootBundle.load('assets/images/sf/2.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());
    final now = DateTime.now();
    final formattedDate =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(image, width: 80),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Rapport du Portefeuille",
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10))
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ["Catégorie", "Montant"],
              data: totalsByCategory
                  .map((e) =>
                      [e['category'], "${e['total'].toStringAsFixed(2)} FCFA"])
                  .toList(),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/wallet_stats.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'Rapport PDF du portefeuille Bakan');
  }

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final total = totalsByCategory.fold<double>(
        0, (sum, item) => sum + (item['total'] as num).abs());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Portefeuille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: saveAndShareImage,
          // )
        ],
      ),
      body: totalsByCategory.isEmpty
          ? const Center(child: Text('Aucune donnée'))
          : SingleChildScrollView(
              child: RepaintBoundary(
                key: _screenshotKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= totalsByCategory.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    totalsByCategory[index]['category'] ?? '',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              totalsByCategory.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isPositive = item['total'] >= 0;
                            return BarChartGroupData(x: index, barRods: [
                              BarChartRodData(
                                toY: (item['total'] as num).toDouble(),
                                color: isPositive ? Colors.green : Colors.red,
                                width: 16,
                              )
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: totalsByCategory.map((item) {
                            final isPositive = item['total'] >= 0;
                            final percentage =
                                ((item['total'] as num).abs() / total * 100)
                                    .toStringAsFixed(1);
                            return PieChartSectionData(
                              color: isPositive ? Colors.green : Colors.red,
                              value: (item['total'] as num).abs().toDouble(),
                              title: "$percentage%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalsByCategory.length,
                      itemBuilder: (context, index) {
                        final item = totalsByCategory[index];
                        final color =
                            item['total'] >= 0 ? Colors.green : Colors.red;
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(item['category'] ?? 'Sans catégorie'),
                          trailing: Text(
                              "${item['total'].toStringAsFixed(2)} FCFA",
                              style: TextStyle(color: color)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
