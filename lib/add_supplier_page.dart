import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  List<Map<String, dynamic>> _medicines = [];

  /// Add new medicine field
  void _addMedicine() {
    setState(() {
      _medicines.add({'name': '', 'quantity': ''});
    });
  }

  /// Save supplier data into Firestore + generate PDF
  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // ✅ Save medicine names & qty

      await FirebaseFirestore.instance.collection('suppliers').add({
        'name': _nameController.text,
        'contact_person': _contactPersonController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'medicines_supplied': _medicines,
        'last_supply_date': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supplier added successfully!")),
      );

      await _generatePdf();
      _formKey.currentState!.reset();
      setState(() => _medicines.clear());
    }
  }

  /// Generate PDF & share via WhatsApp
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "Health Plus Pharmacy",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Supplier Name: ${_nameController.text}"),
              pw.Text("Contact Person: ${_contactPersonController.text}"),
              pw.Text("Phone: ${_phoneController.text}"),
              pw.Text("Email: ${_emailController.text}"),
              pw.Text("Address: ${_addressController.text}"),
              pw.SizedBox(height: 20),

              pw.Text("Medicines Supplied:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // ✅ Medicines Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Medicine Name",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Quantity",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ..._medicines.map((m) => pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(m['name'].toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(m['quantity'].toString())),
                  ])),
                ],
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/supplier_${_nameController.text}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: "Supplier Record - ${_nameController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Supplier"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🧩 Supplier Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Supplier Name", border: OutlineInputBorder()),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter supplier name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                    labelText: "Contact Person", border: OutlineInputBorder()),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter contact person" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Phone Number", border: OutlineInputBorder()),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email", border: OutlineInputBorder()),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter email address" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: "Address", border: OutlineInputBorder()),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 20),

              // 💊 Add Medicine Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Medicines", style: TextStyle(fontSize: 16)),
                  IconButton(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                  ),
                ],
              ),

              // Dynamic medicine input fields
              Column(
                children: _medicines.map((medicine) {
                  final index = _medicines.indexOf(medicine);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            decoration: const InputDecoration(
                                labelText: "Medicine Name",
                                border: OutlineInputBorder()),
                            onSaved: (val) =>
                            _medicines[index]['name'] = val ?? '',
                            validator: (v) =>
                            v == null || v.isEmpty ? "Enter name" : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,

                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "Quantity",
                                border: OutlineInputBorder()),
                            onSaved: (val) =>
                            _medicines[index]['quantity'] = val ?? '',
                            validator: (v) =>
                            v == null || v.isEmpty ? "Enter qty" : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ✅ Save Button
              ElevatedButton.icon(
                onPressed: _saveSupplier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Save & Generate PDF"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
