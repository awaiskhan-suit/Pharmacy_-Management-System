import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});

  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Generate PDF Report
  Future<void> _generatePDF(List<QueryDocumentSnapshot> medicines) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "🏥 Health Plus Pharmacy",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              "📊 Medicine Stock Report",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),

          // 📋 Table Header
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.teal),
                children: [
                  _pdfHeader("Medicine"),
                  _pdfHeader("Brand"),
                  _pdfHeader("Stock"),
                  _pdfHeader("Status"),
                ],
              ),

              // 📦 Table Data
              ...medicines.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final name = data['name'] ?? 'N/A';
                final brand = data['brand'] ?? 'N/A';
                final stock = (data['stock'] is String)
                    ? int.tryParse(data['stock']) ?? 0
                    : (data['stock'] ?? 0);

                String status;
                PdfColor color;

                if (stock <= 0) {
                  status = "❌ Out of Stock";
                  color = PdfColors.red;
                } else if (stock <= 5) {
                  status = "⚠️ Low Stock";
                  color = PdfColors.orange;
                } else {
                  status = "✅ In Stock";
                  color = PdfColors.green;
                }

                return pw.TableRow(
                  children: [
                    _pdfCell(name),
                    _pdfCell(brand),
                    _pdfCell(stock.toString()),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(status,
                          style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on: ${DateTime.now().toString().split(' ')[0]}",
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/Stock_Report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Health Plus Pharmacy - Stock Report 📦",
    );
  }

  pw.Widget _pdfHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text,
        style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold)),
  );

  pw.Widget _pdfCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Stock Report"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Generate PDF",
            onPressed: () async {
              final snapshot = await _firestore.collection('medicines').get();
              await _generatePDF(snapshot.docs);
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final medicines = snapshot.data!.docs;

          if (medicines.isEmpty) {
            return const Center(child: Text("No medicines found."));
          }

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final data = medicines[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final brand = data['brand'] ?? '';
              final stock = (data['stock'] is String)
                  ? int.tryParse(data['stock']) ?? 0
                  : (data['stock'] ?? 0);

              String status;
              Color color;

              if (stock <= 0) {
                status = "❌ Out of Stock";
                color = Colors.red;
              } else if (stock <= 5) {
                status = "⚠️ Low Stock";
                color = Colors.orange;
              } else {
                status = "✅ In Stock";
                color = Colors.green;
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Icon(Icons.medication, color: color),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Brand: $brand"),
                      Text("Stock: $stock"),
                    ],
                  ),
                  trailing: Text(
                    status,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
