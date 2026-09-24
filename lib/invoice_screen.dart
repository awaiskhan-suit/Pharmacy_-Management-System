import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // Customer input controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // Medicine input controllers
  final _medicineNameController = TextEditingController();
  final _medicineQtyController = TextEditingController();
  final _medicinePriceController = TextEditingController();

  final List<Map<String, dynamic>> _medicines = [];
  String _paymentMethod = "Cash";

  double get subtotal => _medicines.fold(0, (sum, m) => sum + (m['qty'] * m['price']));
  double get tax => subtotal * 0.05;
  double get total => subtotal + tax;

  void _addMedicine() {
    if (_medicineNameController.text.isEmpty ||
        _medicineQtyController.text.isEmpty ||
        _medicinePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all medicine fields")),
      );
      return;
    }

    setState(() {
      _medicines.add({
        'name': _medicineNameController.text.trim(),
        'qty': int.parse(_medicineQtyController.text),
        'price': double.parse(_medicinePriceController.text),
      });
    });

    _medicineNameController.clear();
    _medicineQtyController.clear();
    _medicinePriceController.clear();
  }

  // ✅ Update stock in Firestore automatically
  Future<void> _updateStockInFirestore() async {
    for (var med in _medicines) {
      final medicineName = med['name'];
      final soldQty = med['qty'];

      final medicineRef = FirebaseFirestore.instance.collection('medicines').doc(medicineName);
      final doc = await medicineRef.get();

      if (doc.exists) {
        final currentQty = (doc.data()?['purchase_qty'] ?? 0) as int;
        final remainingQty = currentQty - soldQty;

        String status = "In Stock";
        if (remainingQty <= 0) {
          status = "❌ Out of Stock";
        } else if (remainingQty <= 5) {
          status = "⚠️ Low Stock";
        }

        await medicineRef.update({
          'purchase_qty': remainingQty < 0 ? 0 : remainingQty,
          'status': status,
        });
      } else {
        // If medicine not found, create it
        await medicineRef.set({
          'purchase_qty': 0,
          'sold': soldQty,
          'remaining': 0,
          'status': "❌ Out of Stock",
        });
      }
    }
  }

  // ✅ Save Invoice to Firestore and update stock
  Future<void> _saveInvoiceToFirestore() async {
    if (_customerNameController.text.isEmpty ||
        _customerPhoneController.text.isEmpty ||
        _customerAddressController.text.isEmpty ||
        _medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields and add medicines")),
      );
      return;
    }

    try {
      final date = DateTime.now();
      await FirebaseFirestore.instance.collection('invoices').add({
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerAddress': _customerAddressController.text.trim(),
        'paymentMethod': _paymentMethod,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'date': date.toIso8601String(),
        'medicines': _medicines,
      });

      // ✅ Update stock after saving invoice
      await _updateStockInFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Invoice saved and stock updated successfully!")),
      );

      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAddressController.clear();
      setState(() => _medicines.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving invoice: $e")),
      );
    }
  }

  // ✅ Generate PDF
  Future<void> _generateAndDownloadPDF() async {
    if (_customerNameController.text.isEmpty ||
        _customerPhoneController.text.isEmpty ||
        _customerAddressController.text.isEmpty ||
        _medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill customer and medicine info")),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final date = DateTime.now();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("Health-Plus Pharmacy",
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Address: HayatAbad, Peshawar"),
                      pw.Text("Contact: +92 300 7654321"),
                      pw.Text("Website: www.healthpluspharmacy.com"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Center(
                  child: pw.Text("Pharmacy Invoice",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Divider(),
                pw.Text("Date: ${date.day}-${date.month}-${date.year}"),
                pw.Text("Invoice No: INV${date.millisecondsSinceEpoch % 10000}"),
                pw.SizedBox(height: 10),
                pw.Text("Customer Information:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                pw.Text("Name: ${_customerNameController.text}"),
                pw.Text("Phone: ${_customerPhoneController.text}"),
                pw.Text("Address: ${_customerAddressController.text}"),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Table.fromTextArray(
                  headers: ["Medicine", "Qty", "Price", "Total"],
                  data: _medicines.map((m) {
                    final total = m['qty'] * m['price'];
                    return [
                      m['name'],
                      m['qty'].toString(),
                      m['price'].toString(),
                      total.toStringAsFixed(2),
                    ];
                  }).toList(),
                ),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Subtotal: Rs ${subtotal.toStringAsFixed(2)}"),
                      pw.Text("Tax (5%): Rs ${tax.toStringAsFixed(2)}"),
                      pw.Text("Total: Rs ${total.toStringAsFixed(2)}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Payment Method: $_paymentMethod"),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text("Thank you for visiting!",
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ),
              ],
            );
          },
        ),
      );

      Directory downloadsDir = await getApplicationDocumentsDirectory();
      final filePath =
          "${downloadsDir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error generating invoice: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Invoice"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Health-Plus Pharmacy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Address: HayatAbad, Peshawar"),
            const Text("Contact: +92 300 7654321"),
            const Text("Website: www.healthpluspharmacy.com"),
            const Divider(thickness: 1.2),
            Text("Date: ${date.day}-${date.month}-${date.year}"),
            const Text("Invoice No: INV001"),
            const Divider(thickness: 1.2),

            const Text("Customer Information",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerAddressController,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            const Text("Add Medicines",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _medicineNameController,
                    decoration: const InputDecoration(
                      labelText: "Medicine Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _medicineQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _medicinePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addMedicine,
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1.2),

            // Medicine List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Medicine", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Qty"),
                Text("Price"),
                Text("Total"),
              ],
            ),
            const Divider(thickness: 1.2),
            ..._medicines.map((m) {
              final total = m['qty'] * m['price'];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(m['name'])),
                  Text("${m['qty']}"),
                  Text("${m['price']}"),
                  Text(total.toStringAsFixed(2)),
                ],
              );
            }),
            const Divider(thickness: 1.2),

            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Subtotal: Rs ${subtotal.toStringAsFixed(2)}"),
                  Text("Tax (5%): Rs ${tax.toStringAsFixed(2)}"),
                  Text("Total: Rs ${total.toStringAsFixed(2)}",
                      style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const Divider(thickness: 1.2),

            Row(
              children: [
                const Text("Payment Method: "),
                DropdownButton<String>(
                  value: _paymentMethod,
                  items: const [
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(value: "Card", child: Text("Card")),
                    DropdownMenuItem(value: "Credit", child: Text("Credit")),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveInvoiceToFirestore,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Invoice"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _generateAndDownloadPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Thank you for visiting!",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
