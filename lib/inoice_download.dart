import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePdfHelper {
  static Future<void> generateInvoice({
    required String invoiceNo,
    required String customerName,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
    required double totalAmount, required String paymentMethod,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Health-Plus Pharmacy',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Address: Street 12, City Name'),
                  pw.Text('Contact: +92 300 1234567'),
                  pw.Text('Website: www.healthpluspharmacy.com'),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                ],
              ),
            ),

            pw.Center(
              child: pw.Text(
                'Pharmacy Invoice',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Divider(),

            // Customer Info
            pw.Text('Date: ${DateTime.now().toString().split(" ")[0]}'),
            pw.Text('Invoice No: $invoiceNo'),
            pw.Text('Customer: $customerName'),
            pw.Text('Phone: $phone'),
            pw.Text('Address: $address'),
            pw.SizedBox(height: 10),
            pw.Divider(),

            // Table Header
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Medicine', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            pw.Divider(),

            // Medicine List
            ...items.map((item) {
              final total = item['qty'] * item['price'];
              return pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(item['name'])),
                  pw.Expanded(flex: 1, child: pw.Text(item['qty'].toString())),
                  pw.Expanded(flex: 2, child: pw.Text('${item['price']}')),
                  pw.Expanded(flex: 2, child: pw.Text('$total')),
                ],
              );
            }),

            pw.Divider(),
            pw.SizedBox(height: 10),

            // Total
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Grand Total: Rs. $totalAmount',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
            ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );

    // Share PDF or let user choose where to save it
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_$invoiceNo.pdf',
    );
  }
}
