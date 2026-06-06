import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';

// ── Import result model ───────────────────────────────────────────────────────
class _ImportResult {
  final int inserted;
  final int skipped;
  final List<String> errors;

  _ImportResult({
    required this.inserted,
    required this.skipped,
    required this.errors,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ImportDataScreen extends ConsumerStatefulWidget {
  const ImportDataScreen({super.key});

  @override
  ConsumerState<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends ConsumerState<ImportDataScreen> {
  // Parse state
  List<List<String>>? _parsedRows;
  List<String>? _headers;
  bool _isParsing = false;
  bool _isImporting = false;
  bool _isDownloadingTemplate = false;
  _ImportResult? _result;
  String? _parseError;
  bool _showPasteMode = false;

  final _csvPasteController = TextEditingController();

  // ── Template ──────────────────────────────────────────────────────────────
  static const _templateCsv =
      'admission_number,first_name,last_name,class,section,gender,'
      'date_of_birth,parent_name,parent_phone,parent_email,address\n'
      'ADM001,Aarav,Kumar,10,A,male,2010-06-15,Rajesh Kumar,'
      '9876543210,rajesh@example.com,"123 MG Road, Delhi"\n'
      'ADM002,Priya,Sharma,9,B,female,2011-03-22,Meena Sharma,'
      '9123456780,meena@example.com,"45 Park Street, Mumbai"\n';

  static const _requiredHeaders = [
    'admission_number',
    'first_name',
    'last_name',
    'class',
  ];

  @override
  void dispose() {
    _csvPasteController.dispose();
    super.dispose();
  }

  // ── Template download ─────────────────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    setState(() => _isDownloadingTemplate = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/student_import_template.csv');
      await file.writeAsString(_templateCsv);
      
      final params = SaveFileDialogParams(
        sourceFilePath: file.path,
        fileName: 'student_import_template.csv',
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);
      
      if (mounted) {
        if (filePath != null) {
          _showSnack('Template downloaded successfully to device!');
        } else {
          _showSnack('Download cancelled', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to save template: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloadingTemplate = false);
    }
  }

  // ── CSV parsing ───────────────────────────────────────────────────────────
  List<List<String>> _parseCsv(String content) {
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return lines.map(_parseCsvLine).toList();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  void _parseContent(String content) {
    setState(() {
      _isParsing = true;
      _parseError = null;
      _parsedRows = null;
      _headers = null;
      _result = null;
    });

    try {
      final rows = _parseCsv(content);
      if (rows.isEmpty) {
        setState(() {
          _parseError = 'The file appears to be empty.';
          _isParsing = false;
        });
        return;
      }

      final headers = rows[0].map((h) => h.toLowerCase().trim()).toList();
      for (final req in _requiredHeaders) {
        if (!headers.contains(req)) {
          setState(() {
            _parseError =
                'Missing required column: "$req". Download the template to see the correct format.';
            _isParsing = false;
          });
          return;
        }
      }

      final dataRows = rows.sublist(1);
      if (dataRows.isEmpty) {
        setState(() {
          _parseError = 'No data rows found. The file only has a header row.';
          _isParsing = false;
        });
        return;
      }

      setState(() {
        _headers = headers;
        _parsedRows = dataRows;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _parseError = 'Failed to parse CSV: $e';
        _isParsing = false;
      });
    }
  }

  // ── Import to Supabase ────────────────────────────────────────────────────
  Future<void> _importData() async {
    if (_parsedRows == null || _headers == null) return;
    setState(() {
      _isImporting = true;
      _result = null;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _isImporting = false);
      return;
    }

    String? accountId;
    try {
      final userData = await client
          .from('users')
          .select('account_id')
          .eq('id', user.id)
          .single();
      accountId = userData['account_id'] as String;
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        _showSnack('Authentication error: $e', isError: true);
      }
      return;
    }

    int inserted = 0;
    int skipped = 0;
    final errors = <String>[];

    for (int i = 0; i < _parsedRows!.length; i++) {
      final row = _parsedRows![i];
      final rowNum = i + 2;

      try {
        final Map<String, dynamic> data = {};
        for (int j = 0; j < _headers!.length && j < row.length; j++) {
          final val = row[j].trim();
          if (val.isNotEmpty) data[_headers![j]] = val;
        }

        if ((data['admission_number'] ?? '').toString().isEmpty ||
            (data['first_name'] ?? '').toString().isEmpty ||
            (data['last_name'] ?? '').toString().isEmpty ||
            (data['class'] ?? '').toString().isEmpty) {
          skipped++;
          errors.add('Row $rowNum: Missing required field(s) — skipped.');
          continue;
        }

        data['account_id'] = accountId;

        await client.from('students').upsert(
          data,
          onConflict: 'account_id,admission_number',
          ignoreDuplicates: false,
        );
        inserted++;
      } catch (e) {
        skipped++;
        errors.add('Row $rowNum: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isImporting = false;
        _result = _ImportResult(
          inserted: inserted,
          skipped: skipped,
          errors: errors,
        );
      });
    }
  }

  void _reset() {
    setState(() {
      _parsedRows = null;
      _headers = null;
      _result = null;
      _parseError = null;
      _showPasteMode = false;
      _csvPasteController.clear();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Import Data',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isDownloadingTemplate ? null : _downloadTemplate,
            icon: _isDownloadingTemplate
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.download_rounded,
                    size: 16, color: AppColors.primary),
            label: Text(
              'Template',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result state
            if (_result != null) ...[
              _buildResultBanner(),
              const SizedBox(height: 16),
              _buildResetButton(),
            ],

            // Normal state
            if (_result == null) ...[
              _buildHero(),
              const SizedBox(height: 24),
              if (!_showPasteMode) _buildActionButtons(),
              if (_showPasteMode) _buildPasteArea(),
              const SizedBox(height: 16),
              if (_parseError != null) _buildErrorBanner(_parseError!),
              if (_parsedRows != null) ...[
                _buildPreviewTable(),
                const SizedBox(height: 20),
                _buildImportButton(),
              ],
              const SizedBox(height: 28),
              _buildFormatsCard(),
              const SizedBox(height: 16),
              _buildHowItWorks(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: Color(0xFF10B981),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Import Your Data',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a spreadsheet with your students. Download the template, fill it in, paste the CSV content, and we handle the rest.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons (before paste mode) ────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showPasteMode = true),
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: Text(
              'Paste CSV Content',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDownloadingTemplate ? null : _downloadTemplate,
            icon: _isDownloadingTemplate
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : Icon(Icons.download_rounded,
                    size: 18, color: AppColors.primary),
            label: Text(
              'Download Template',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Paste area ────────────────────────────────────────────────────────────
  Widget _buildPasteArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASTE CSV CONTENT',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _showPasteMode = false;
                _csvPasteController.clear();
                _parsedRows = null;
                _parseError = null;
              }),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _csvPasteController,
          maxLines: 10,
          minLines: 6,
          onChanged: (_) {
            if (_parseError != null) {
              setState(() => _parseError = null);
            }
          },
          style: GoogleFonts.robotoMono(
              fontSize: 12, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText:
                'admission_number,first_name,last_name,class\nADM001,Aarav,Kumar,10',
            hintStyle:
                GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textHint),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: const Color(0xFF10B981), width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainer.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isParsing
                ? null
                : () {
                    final content = _csvPasteController.text.trim();
                    if (content.isEmpty) {
                      setState(() => _parseError =
                          'Please paste some CSV content first.');
                      return;
                    }
                    _parseContent(content);
                  },
            icon: _isParsing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimaryContainer,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _isParsing ? 'Validating…' : 'Validate & Preview',
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Preview table ─────────────────────────────────────────────────────────
  Widget _buildPreviewTable() {
    final rows = _parsedRows!;
    final headers = _headers!;
    final preview = rows.length > 5 ? rows.sublist(0, 5) : rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PREVIEW',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${rows.length} row${rows.length == 1 ? '' : 's'} ready',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.surfaceContainer.withValues(alpha: 0.6),
                ),
                dataRowColor:
                    WidgetStateProperty.all(Colors.transparent),
                columnSpacing: 20,
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                dataTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                columns:
                    headers.map((h) => DataColumn(label: Text(h))).toList(),
                rows: preview.map((row) {
                  return DataRow(
                    cells: List.generate(headers.length, (i) {
                      return DataCell(Text(i < row.length ? row[i] : ''));
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (rows.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Showing 5 of ${rows.length} rows',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }

  // ── Import button ─────────────────────────────────────────────────────────
  Widget _buildImportButton() {
    final count = _parsedRows?.length ?? 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isImporting ? null : _importData,
        icon: _isImporting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimaryContainer,
                ),
              )
            : const Icon(Icons.cloud_upload_rounded, size: 20),
        label: Text(
          _isImporting
              ? 'Importing $count records…'
              : 'Import $count Students',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Result banner ─────────────────────────────────────────────────────────
  Widget _buildResultBanner() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          gradientColors: [
            const Color(0xFF10B981).withValues(alpha: 0.06),
            const Color(0xFF10B981).withValues(alpha: 0.06),
          ],
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 44),
              const SizedBox(height: 12),
              Text(
                'Import Complete',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statChip('${r.inserted}', 'Imported',
                      const Color(0xFF10B981)),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                  _statChip('${r.skipped}', 'Skipped', AppColors.error),
                ],
              ),
            ],
          ),
        ),
        if (r.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'IMPORT ISSUES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            borderColor: AppColors.error.withValues(alpha: 0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: r.errors
                  .take(10)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _reset,
        icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
        label: Text(
          'Import Another File',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formats card ──────────────────────────────────────────────────────────
  Widget _buildFormatsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Supported Formats',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _formatRow('CSV (.csv)',
              'Comma-separated file with headers in the first row'),
          const SizedBox(height: 10),
          _formatRow('Required columns',
              'admission_number, first_name, last_name, class'),
          const SizedBox(height: 10),
          _formatRow('Optional columns',
              'section, gender, date_of_birth, parent_name, parent_phone, parent_email, address'),
          const SizedBox(height: 10),
          _formatRow('Duplicate handling',
              'Re-importing a row with the same admission_number will update the record'),
        ],
      ),
    );
  }

  Widget _formatRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded,
            color: const Color(0xFF10B981), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── How it works ──────────────────────────────────────────────────────────
  Widget _buildHowItWorks() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _stepRow(
              1, 'Tap "Template" to download & share the CSV template'),
          const SizedBox(height: 12),
          _stepRow(2,
              'Fill in your student data using Excel or Google Sheets'),
          const SizedBox(height: 12),
          _stepRow(3, 'Copy all rows, tap "Paste CSV Content" and paste'),
          const SizedBox(height: 12),
          _stepRow(
              4, '"Validate & Preview" checks for errors before import'),
          const SizedBox(height: 12),
          _stepRow(5,
              '"Import" sends all records to your Supabase account securely'),
        ],
      ),
    );
  }

  Widget _stepRow(int num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$num',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
