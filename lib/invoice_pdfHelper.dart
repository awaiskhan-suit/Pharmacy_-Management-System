import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePdfHelper {
  static Future<void> generateInvoice({
    required String invoiceNo,
    required String customerName,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    final subtotal = items.fold(0.0, (sum, i) => sum + (i['qty'] * i['price']));
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
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
            pw.Text("Invoice No: $invoiceNo"),
            pw.Text("Customer: $customerName"),
            pw.Text("Phone: $phone"),
            pw.Text("Address: $address"),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ["Medicine", "Qty", "Price", "Total"],
              data: items.map((i) {
                final t = i['qty'] * i['price'];
                return [i['name'], i['qty'].toString(), i['price'].toString(), t.toStringAsFixed(2)];
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
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Payment Method: $paymentMethod"),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text("Thank you for visiting!",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // ✅ Save in app's documents directory (works without USB)
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // ✅ Share via WhatsApp or other apps
    await Share.shareXFiles([XFile(file.path)],
        text: "Here’s your invoice from Health-Plus Pharmacy!");

    print("✅ Invoice saved at: $filePath");
  }
}
