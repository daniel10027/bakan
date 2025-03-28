import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bakan/database/db_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  List<Map<String, dynamic>> sales = [];
  List<Map<String, dynamic>> filteredSales = [];
  List<Map<String, dynamic>> clients = [];

  String? selectedClientName;
  DateTimeRange? selectedDateRange;
  double? minAmount;
  double? maxAmount;

  Future<void> loadSales() async {
    final rawSales = await DBHelper.getSales();
    clients = await DBHelper.getClients();

    final salesWithClients = rawSales.map((sale) {
      final client = clients.firstWhere(
        (c) => c['id'] == sale['client_id'],
        orElse: () => {'name': 'Inconnu'},
      );
      return {
        ...sale,
        'clientName': client['name'],
      };
    }).toList();

    sales = salesWithClients;
    applyFilters();
  }

  void applyFilters() {
    filteredSales = sales.where((sale) {
      final date = DateTime.parse(sale['date']);
      final clientName = sale['clientName'] ?? '';
      final amount = (sale['total'] as num).toDouble();

      final matchClient =
          selectedClientName == null || clientName == selectedClientName;
      final matchDate = selectedDateRange == null ||
          (date.isAfter(
                  selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              date.isBefore(
                  selectedDateRange!.end.add(const Duration(days: 1))));
      final matchMin = minAmount == null || amount >= minAmount!;
      final matchMax = maxAmount == null || amount <= maxAmount!;

      return matchClient && matchDate && matchMin && matchMax;
    }).toList();

    setState(() {});
  }

  List<BarChartGroupData> getMonthlySalesChartData() {
    final monthlyTotals = <String, double>{};
    for (var sale in filteredSales) {
      final date = DateTime.parse(sale['date']);
      final key = DateFormat('MM/yyyy').format(date);
      monthlyTotals[key] =
          (monthlyTotals[key] ?? 0) + (sale['total'] as num).toDouble();
    }
    int i = 0;
    return monthlyTotals.entries.map((e) {
      return BarChartGroupData(
        x: i++,
        barRods: [
          BarChartRodData(
            toY: e.value,
            width: 16,
            color: Colors.teal,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    }).toList();
  }

  List<PieChartSectionData> getTopClientsPieData() {
    final totalsByClient = <String, double>{};
    for (var sale in filteredSales) {
      final name = sale['clientName'] ?? 'Inconnu';
      totalsByClient[name] =
          (totalsByClient[name] ?? 0) + (sale['total'] as num).toDouble();
    }
    final total = totalsByClient.values.fold(0.0, (sum, value) => sum + value);
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.pink
    ];
    int i = 0;
    return totalsByClient.entries.map((e) {
      final percent = (e.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: e.value,
        color: colors[i++ % colors.length],
        radius: 50,
        title: "$percent%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
    }).toList();
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("Historique des ventes exporté",
              style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Client', 'Total', 'Date'],
            data: filteredSales
                .map((sale) =>
                    [sale['clientName'], "${sale['total']} FCFA", sale['date']])
                .toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/historique_ventes.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des Ventes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportPDF,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedClientName,
                        decoration: const InputDecoration(
                          labelText: 'Filtrer par client',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous les clients')),
                          ...clients.map((c) => DropdownMenuItem(
                                value: c['name'],
                                child: Text(c['name']),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => selectedClientName = val);
                          applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          selectedDateRange = range;
                          applyFilters();
                        }
                      },
                      child: const Text('Période'),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Montant min',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          minAmount = double.tryParse(val);
                          applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Montant max',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          maxAmount = double.tryParse(val);
                          applyFilters();
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: getMonthlySalesChartData(),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < filteredSales.length) {
                            final date = DateFormat('MM/yyyy').format(
                                DateTime.parse(filteredSales[index]['date']));
                            return Text(date,
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox();
                        }),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: getTopClientsPieData(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: filteredSales.isEmpty
                ? const Center(child: Text("Aucune vente trouvée."))
                : ListView.builder(
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      final date = DateFormat('dd/MM/yyyy – HH:mm')
                          .format(DateTime.parse(sale['date']));
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text("${sale['total']} FCFA"),
                          subtitle: Text(
                              "Client: ${sale['clientName']}\nDate: $date"),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
