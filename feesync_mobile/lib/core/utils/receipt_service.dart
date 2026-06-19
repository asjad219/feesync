import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/student.dart';

class ReceiptService {
  static Future<File> generatePdfReceipt({
    required Student student,
    required double amount,
    required String paymentMode,
    required DateTime date,
    required String invoiceNo,
    String? institutionName,
    bool isAdvance = false,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            institutionName?.toUpperCase() ?? 'INSTITUTION NAME',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF1E3A8A), // dark blue
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'PAYMENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),
                
                // Invoice Details Table
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice To:', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(student.fullName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text('Class: ${student.studentClass}', style: const pw.TextStyle(fontSize: 12)),
                        if (student.rollNumber != null) pw.Text('Roll No: ${student.rollNumber}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice No:', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text(invoiceNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 8),
                        pw.Text('Date:', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                
                // Payment Details
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Column(
                    children: [
                      // Header
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, fontSize: 12)),
                            pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Row
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(isAdvance ? 'Advance Fee Payment' : 'Fee Payment', style: const pw.TextStyle(fontSize: 14)),
                            pw.Text('INR ${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      // Total
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFEFF6FF), // blue-50
                          borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(8)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Paid:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E3A8A))),
                            pw.Text('INR ${amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: const PdfColor.fromInt(0xFF1E3A8A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                
                pw.Row(
                  children: [
                    _buildPdfRowColumn('Payment Mode', paymentMode.toUpperCase()),
                    pw.SizedBox(width: 48),
                    _buildPdfRowColumn('Status', 'SUCCESSFUL', color: PdfColors.green700),
                  ],
                ),
                
                pw.Spacer(),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('This is a computer-generated receipt.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text('Powered by FeeSync', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_$invoiceNo.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildPdfRowColumn(String label, String value, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }

  static String generateTextReceipt({
    required Student student,
    required double amount,
    required String paymentMode,
    required DateTime date,
    required String invoiceNo,
    String? institutionName,
    bool isAdvance = false,
  }) {
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final header = institutionName != null ? '🏦 *${institutionName.toUpperCase()}*\n' : '';
    return """
$header📝 *${isAdvance ? 'ADVANCE ' : ''}PAYMENT RECEIPT*
--------------------------
*Invoice No:* $invoiceNo
*Date:* $dateStr
--------------------------
*Student:* ${student.fullName}
*Class:* ${student.studentClass}
*Amount Paid:* ₹${amount.toStringAsFixed(0)}
*Payment Mode:* ${paymentMode.toUpperCase()}
--------------------------
*Status:* ✅ SUCCESSFUL

Thank you for the payment!
_Generated by FeeSync_
""";
  }

  static Future<void> shareToWhatsApp({
    required String phone,
    required String text,
    File? pdfFile,
  }) async {
    String finalMessage = text;

    if (pdfFile != null) {
      try {
        final fileName = pdfFile.path.split('/').last;
        final supabase = Supabase.instance.client;
        
        await supabase.storage.from('receipts').upload(
          fileName,
          pdfFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        
        final publicUrl = supabase.storage.from('receipts').getPublicUrl(fileName);
        finalMessage += '\n\nDownload PDF Receipt: $publicUrl';
      } catch (e) {
        debugPrint('Error uploading PDF receipt: $e');
      }
    }

    if (phone.isNotEmpty) {
      // For text-only receipts or links, we target the number directly.
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(finalMessage)}';
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // If canLaunchUrl fails, attempt launchUrl anyway
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        await SharePlus.instance.share(ShareParams(text: finalMessage));
      }
    } else {
      await SharePlus.instance.share(ShareParams(text: finalMessage));
    }
  }
}
