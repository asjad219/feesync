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
    double? baseAmount,
    double? lateFineAmount,
    double? discountAmount,
    double? taxAmount,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Accent Line
              pw.Container(
                height: 8,
                width: double.infinity,
                color: const PdfColor.fromInt(0xFF1E3A8A), // deep blue
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Section
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
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF0F172A), // Slate 900
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'OFFICIAL RECEIPT',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF64748B), // Slate 500
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Success Badge
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFDCFCE7), // Green 100
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF22C55E)), // Green 500
                            ),
                            child: pw.Text(
                              'SUCCESS',
                              style: pw.TextStyle(
                                color: const PdfColor.fromInt(0xFF166534), // Green 800
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 32),
                      
                      // Billed To & Details Row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Billed To
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BILLED TO', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF94A3B8), fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                              pw.SizedBox(height: 8),
                              pw.Text(student.fullName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: const PdfColor.fromInt(0xFF0F172A))),
                              pw.SizedBox(height: 2),
                              pw.Text('Class: ${student.studentClass}', style: pw.TextStyle(fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
                              if (student.rollNumber != null) 
                                pw.Text('Roll No: ${student.rollNumber}', style: pw.TextStyle(fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
                            ],
                          ),
                          // Invoice Details
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('RECEIPT DETAILS', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF94A3B8), fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                              pw.SizedBox(height: 8),
                              pw.Text('Receipt No: $invoiceNo', style: pw.TextStyle(fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
                              pw.SizedBox(height: 2),
                              pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
                              pw.SizedBox(height: 2),
                              pw.Text('Payment Mode: ${paymentMode.toUpperCase()}', style: pw.TextStyle(fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
                            ],
                          ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 40),
                      
                      // Payment Details Table
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(1),
                        },
                        border: pw.TableBorder(
                          top: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1.5),
                          bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1.5),
                          horizontalInside: const pw.BorderSide(color: PdfColor.fromInt(0xFFF1F5F9), width: 1),
                        ),
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('DESCRIPTION', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF64748B), fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: const PdfColor.fromInt(0xFF64748B), fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                              ),
                            ],
                          ),
                          // Base / Advance
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: pw.Text(isAdvance ? 'Advance Fee Payment' : 'Base Fee Payment', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: pw.Text('INR ${(baseAmount ?? amount).toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                              ),
                            ],
                          ),
                          if (lateFineAmount != null && lateFineAmount > 0)
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('Late Fine Penalty', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('+ INR ${lateFineAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: const PdfColor.fromInt(0xFFEF4444), fontSize: 12)),
                                ),
                              ],
                            ),
                          if (discountAmount != null && discountAmount > 0)
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('Early Payment Discount', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('- INR ${discountAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: const PdfColor.fromInt(0xFF22C55E), fontSize: 12)),
                                ),
                              ],
                            ),
                          if (taxAmount != null && taxAmount > 0)
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('Tax / GST', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: pw.Text('+ INR ${taxAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E293B), fontSize: 12)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 16),
                      
                      // Total Row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFEFF6FF), // Blue 50
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Text('TOTAL PAID:', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E3A8A), fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(width: 24),
                                pw.Text('INR ${amount.toStringAsFixed(2)}', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1E3A8A), fontSize: 16, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      pw.Spacer(),
                      
                      // Signature & Footer Area
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Left side text
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('This is a computer-generated receipt.', style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0xFF94A3B8))),
                              pw.Text('No physical signature is required.', style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0xFF94A3B8))),
                            ]
                          ),
                          // Right side signature line
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(width: 120, height: 1, color: const PdfColor.fromInt(0xFFCBD5E1)),
                              pw.SizedBox(height: 6),
                              pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, color: const PdfColor.fromInt(0xFF475569), fontWeight: pw.FontWeight.bold)),
                            ]
                          ),
                        ]
                      ),
                      
                      pw.SizedBox(height: 32),
                      
                      // Powered by FeeSync
                      pw.Center(
                        child: pw.Text('Powered by FeeSync', style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0xFFCBD5E1), fontStyle: pw.FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    String? template,
  }) {
    if (template != null && template.trim().isNotEmpty) {
      String msg = template;
      final String parentName = (student.parentName == null || student.parentName!.trim().isEmpty)
          ? "Parent"
          : student.parentName!.trim();
          
      final String studentName = student.firstName.trim().isEmpty
          ? "Student"
          : student.fullName.trim();
          
      final String amountStr = '₹${NumberFormat('#,###').format(amount)}';
      final String instName = (institutionName == null || institutionName.isEmpty) ? 'FeeSync' : institutionName;
      
      msg = msg.replaceAll('{parent_name}', parentName);
      msg = msg.replaceAll('{student_name}', studentName);
      msg = msg.replaceAll('{amount}', amountStr);
      msg = msg.replaceAll('{receipt_no}', invoiceNo);
      msg = msg.replaceAll('{school_name}', instName);
      
      msg = msg.replaceAll(RegExp(r'\{[^}]*\}'), '');
      
      return msg;
    }

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
        
        final signedUrl = await supabase.storage.from('receipts').createSignedUrl(fileName, 60 * 60 * 24 * 7);
        finalMessage += '\n\nDownload PDF Receipt: $signedUrl\n(Link valid for 7 days)';
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
