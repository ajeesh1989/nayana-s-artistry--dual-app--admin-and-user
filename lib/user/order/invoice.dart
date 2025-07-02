import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicePreviewPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const InvoicePreviewPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Preview')),
      body: PdfPreview(
        build: (format) async {
          try {
            final pdf = await _generatePdf(order);
            return pdf;
          } catch (e, st) {
            debugPrint("PDF error: $e\n$st");
            return Uint8List(0);
          }
        },
      ),
    );
  }

  Future<Uint8List> _generatePdf(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;

    // Load logo image from assets
    final ByteData logoBytes = await rootBundle.load(
      'assets/images/logo_black.png',
    );
    final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoUint8List);

    final List items = order['items'] ?? [];

    final orderId = order['id'] ?? '-';
    final paymentMethod = order['paymentMethod'] ?? 'N/A';
    final status = order['status'] ?? 'Placed';
    final customerName = order['customerName'] ?? user?.displayName ?? '-';
    final customerEmail = order['customerEmail'] ?? user?.email ?? '-';
    final customerPhone = order['customerPhone'] ?? '-';
    final address = order['deliveryAddress'] ?? '-';

    final orderDate =
        order['orderDate'] is Timestamp
            ? DateFormat.yMMMd().add_jm().format(
              (order['orderDate'] as Timestamp).toDate(),
            )
            : '-';

    final deliveredDateRaw = order['deliveredDate'];
    final deliveredDate =
        deliveredDateRaw is Timestamp
            ? DateFormat.yMMMd().add_jm().format(deliveredDateRaw.toDate())
            : null;

    final assignedRiderId = order['assignedRiderId'];
    String riderName = 'CourierX';

    if (assignedRiderId != null) {
      final riderDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(assignedRiderId)
              .get();
      if (riderDoc.exists) {
        final riderData = riderDoc.data()!;
        riderName = riderData['name'] ?? 'CourierX';
      }
    }

    double itemsTotal = 0.0;
    for (var item in items) {
      final price = item['price'] ?? 0.0;
      final qty = item['quantity'] ?? 1;
      itemsTotal += price * qty;
    }

    const deliveryCharge = 100.0;
    final grandTotal = itemsTotal + deliveryCharge;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 🖼️ Logo at the top
                pw.SizedBox(height: 12),

                // INVOICE TITLE
                pw.Center(
                  child: pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 60),

                // Order Details
                pw.Text(
                  "Order ID: $orderId",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text("Status: $status", style: pw.TextStyle(fontSize: 14)),
                pw.Text(
                  "Order Date: $orderDate",
                  style: pw.TextStyle(fontSize: 14),
                ),
                if (deliveredDate != null)
                  pw.Text(
                    "Delivered Date: $deliveredDate",
                    style: pw.TextStyle(fontSize: 14),
                  ),
                pw.Text(
                  "Payment Method: $paymentMethod",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Delivered By: $riderName",
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 20),

                // Customer Info
                pw.Text(
                  "Customer Details",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  "Name: $customerName",
                  style: pw.TextStyle(fontSize: 13),
                ),
                pw.Text(
                  "Email: $customerEmail",
                  style: pw.TextStyle(fontSize: 13),
                ),
                pw.Text(
                  "Phone: $customerPhone",
                  style: pw.TextStyle(fontSize: 13),
                ),
                pw.Text(
                  "Address:",
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(address, style: pw.TextStyle(fontSize: 13)),

                pw.SizedBox(height: 20),
                pw.Divider(),

                // Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          "Item",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "Qty",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "Price",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          "Total",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),

                // Table Rows
                ...items.map<pw.Widget>((item) {
                  final name = item['name'] ?? 'Item';
                  final qty = item['quantity'] ?? 1;
                  final price = item['price'] ?? 0.0;
                  final total = qty * price;

                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(flex: 4, child: pw.Text(name)),
                        pw.Expanded(
                          child: pw.Text("$qty", textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            "${price.toStringAsFixed(2)}",
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            "${total.toStringAsFixed(2)}",
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                pw.SizedBox(height: 16),
                pw.Divider(),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Subtotal", style: pw.TextStyle(fontSize: 14)),
                    pw.Text(
                      itemsTotal.toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Delivery Charge",
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      deliveryCharge.toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Grand Total",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      grandTotal.toStringAsFixed(2),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 60),
                pw.Center(child: pw.Image(logoImage, width: 80)),
                pw.Center(
                  child: pw.Text(
                    "Thank you for shopping with us!",
                    style: pw.TextStyle(fontSize: 13, color: PdfColors.grey),
                  ),
                ),
              ],
            ),
      ),
    );

    return pdf.save();
  }
}
