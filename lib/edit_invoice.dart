import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditInvoicePage extends StatefulWidget {
  final String invoiceId;
  final Map<String, dynamic> data;

  const EditInvoicePage({super.key, required this.invoiceId, required this.data});

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _paymentMethod;
  late List<Map<String, dynamic>> _medicines;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['customerName']);
    _phoneController = TextEditingController(text: widget.data['customerPhone']);
    _addressController = TextEditingController(text: widget.data['customerAddress']);
    _paymentMethod = widget.data['paymentMethod'] ?? 'Cash';
    _medicines = List<Map<String, dynamic>>.from(widget.data['medicines']);
  }

  double get subtotal =>
      _medicines.fold(0, (sum, m) => sum + (m['qty'] * m['price']));
  double get tax => subtotal * 0.05;
  double get total => subtotal + tax;

  void _addMedicine() {
    setState(() {
      _medicines.add({'name': '', 'qty': 1, 'price': 0.0});
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(widget.invoiceId)
          .update({
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'customerAddress': _addressController.text.trim(),
        'paymentMethod': _paymentMethod,
        'medicines': _medicines,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Invoice updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update invoice: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Invoice"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer Information",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            const Text("Medicines",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),

            ..._medicines.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: "Medicine Name"),
                        controller: TextEditingController(text: item['name']),
                        onChanged: (val) => item['name'] = val,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "Quantity"),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: item['qty'].toString()),
                              onChanged: (val) =>
                              item['qty'] = int.tryParse(val) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "Price"),
                              keyboardType: TextInputType.number,
                              controller:
                              TextEditingController(text: item['price'].toString()),
                              onChanged: (val) =>
                              item['price'] = double.tryParse(val) ?? 0.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeMedicine(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addMedicine,
                icon: const Icon(Icons.add),
                label: const Text("Add Medicine"),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(thickness: 1.2),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Subtotal: Rs ${subtotal.toStringAsFixed(2)}"),
                  Text("Tax (5%): Rs ${tax.toStringAsFixed(2)}"),
                  Text("Total: Rs ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
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
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
