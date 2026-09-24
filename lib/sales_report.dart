import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  DateTime? _selectedDate;
  double _totalSales = 0;
  double _totalTax = 0;
  int _invoiceCount = 0;
  int _totalMedicinesSold = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalesReport();
  }

  // 🟢 Fetch data from Firestore
  Future<void> _fetchSalesReport() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('invoices').get();

    double totalSales = 0;
    double totalTax = 0;
    int invoiceCount = 0;
    int totalMedicinesSold = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Filter by date (if selected)
      if (_selectedDate != null) {
        final invoiceDate = DateTime.parse(data['date']);
        if (invoiceDate.year != _selectedDate!.year ||
            invoiceDate.month != _selectedDate!.month ||
            invoiceDate.day != _selectedDate!.day) {
          continue;
        }
      }

      totalSales += (data['total'] ?? 0).toDouble();
      totalTax += (data['tax'] ?? 0).toDouble();
      invoiceCount++;

      // Count total medicine quantity sold
      if (data['medicines'] != null) {
        for (var med in data['medicines']) {
          totalMedicinesSold += (med['qty'] ?? 0) as int;
        }
      }
    }

    setState(() {
      _totalSales = totalSales;
      _totalTax = totalTax;
      _invoiceCount = invoiceCount;
      _totalMedicinesSold = totalMedicinesSold;
      _isLoading = false;
    });
  }

  // 🗓️ Pick a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchSalesReport();
    }
  }

  // 🧮 Clear date filter
  void _clearFilter() {
    setState(() => _selectedDate = null);
    _fetchSalesReport();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDate != null
        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
        : "All Time";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Report"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Health-Plus Pharmacy",
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Sales Report Summary",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Date: $formattedDate",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  color: Colors.green,
                  onPressed: () => _selectDate(context),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.red,
                    onPressed: _clearFilter,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 💰 Total Sales Card
            _buildReportCard(
              title: "Total Sales",
              value: "Rs ${_totalSales.toStringAsFixed(2)}",
              icon: Icons.attach_money,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 10),

            // 🧾 Invoice Count
            _buildReportCard(
              title: "Total Invoices",
              value: _invoiceCount.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 10),

            // 💊 Total Medicines Sold
            _buildReportCard(
              title: "Total Medicines Sold",
              value: _totalMedicinesSold.toString(),
              icon: Icons.local_pharmacy,
              color: Colors.purple.shade600,
            ),
            const SizedBox(height: 10),

            // 🧮 Tax Collected
            _buildReportCard(
              title: "Total Tax Collected",
              value: "Rs ${_totalTax.toStringAsFixed(2)}",
              icon: Icons.percent,
              color: Colors.orange.shade700,
            ),

            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _fetchSalesReport,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
