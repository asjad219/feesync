import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  bool _exportStudents = true;
  bool _exportPayments = true;
  bool _exportFeeStructures = true;

  bool _isExporting = false;
  String _statusMessage = '';
  String? _errorMessage;

  // Export Results
  int? _studentsCount;
  int? _paymentsCount;
  int? _feeStructuresCount;
  final List<String> _exportedFiles = [];
  bool _exportCompleted = false;

  String _escapeCsv(dynamic value) {
    if (value == null) return '';
    String str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      str = str.replaceAll('"', '""');
      return '"$str"';
    }
    return str;
  }

  Future<void> _startExport() async {
    if (!_exportStudents && !_exportPayments && !_exportFeeStructures) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one data type to export',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _statusMessage = 'Initializing export...';
      _errorMessage = null;
      _exportedFiles.clear();
      _exportCompleted = false;
      _studentsCount = null;
      _paymentsCount = null;
      _feeStructuresCount = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found. Please log in.');
      }

      // Fetch account_id
      setState(() => _statusMessage = 'Verifying authentication...');
      final userData = await client
          .from('users')
          .select('account_id')
          .eq('id', user.id)
          .single();
      final accountId = userData['account_id'] as String;

      final now = DateTime.now();
      final timestamp = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final dir = await getApplicationDocumentsDirectory();

      // 1. Export Students
      if (_exportStudents) {
        setState(() => _statusMessage = 'Fetching Students data from Supabase...');
        final res = await client
            .from('students')
            .select()
            .eq('account_id', accountId)
            .order('last_name');
        
        final list = res as List<dynamic>;
        _studentsCount = list.length;

        setState(() => _statusMessage = 'Generating Students CSV...');
        final fallbackHeaders = [
          'id', 'admission_number', 'first_name', 'last_name', 'class',
          'section', 'gender', 'date_of_birth', 'parent_name',
          'parent_phone', 'parent_email', 'address', 'created_at'
        ];

        final headers = list.isNotEmpty
            ? list.first.keys.toList()
            : fallbackHeaders;

        final csvBuffer = StringBuffer();
        csvBuffer.writeln(headers.join(','));

        for (final row in list) {
          final rowMap = row as Map<String, dynamic>;
          final line = headers.map((h) => _escapeCsv(rowMap[h])).join(',');
          csvBuffer.writeln(line);
        }

        final file = File('${dir.path}/feesync_students_$timestamp.csv');
        await file.writeAsString(csvBuffer.toString());
        _exportedFiles.add(file.path);
      }

      // 2. Export Payments
      if (_exportPayments) {
        setState(() => _statusMessage = 'Fetching Payments data from Supabase...');
        final res = await client
            .from('payments')
            .select()
            .eq('account_id', accountId)
            .order('payment_date');

        final list = res as List<dynamic>;
        _paymentsCount = list.length;

        setState(() => _statusMessage = 'Generating Payments CSV...');
        final fallbackHeaders = [
          'id', 'student_id', 'amount', 'payment_method',
          'transaction_id', 'payment_date', 'notes', 'receipt_number',
          'status', 'created_at'
        ];

        final headers = list.isNotEmpty
            ? list.first.keys.toList()
            : fallbackHeaders;

        final csvBuffer = StringBuffer();
        csvBuffer.writeln(headers.join(','));

        for (final row in list) {
          final rowMap = row as Map<String, dynamic>;
          final line = headers.map((h) => _escapeCsv(rowMap[h])).join(',');
          csvBuffer.writeln(line);
        }

        final file = File('${dir.path}/feesync_payments_$timestamp.csv');
        await file.writeAsString(csvBuffer.toString());
        _exportedFiles.add(file.path);
      }

      // 3. Export Fee Structures
      if (_exportFeeStructures) {
        setState(() => _statusMessage = 'Fetching Fee Structures from Supabase...');
        final res = await client
            .from('fee_structures')
            .select()
            .eq('account_id', accountId)
            .order('name');

        final list = res as List<dynamic>;
        _feeStructuresCount = list.length;

        setState(() => _statusMessage = 'Generating Fee Structures CSV...');
        final fallbackHeaders = [
          'id', 'category_id', 'name', 'amount', 'class', 'due_date',
          'description', 'is_active', 'plan_type', 'late_fine',
          'grace_days', 'gst_percent', 'created_at'
        ];

        final headers = list.isNotEmpty
            ? list.first.keys.toList()
            : fallbackHeaders;

        final csvBuffer = StringBuffer();
        csvBuffer.writeln(headers.join(','));

        for (final row in list) {
          final rowMap = row as Map<String, dynamic>;
          final line = headers.map((h) => _escapeCsv(rowMap[h])).join(',');
          csvBuffer.writeln(line);
        }

        final file = File('${dir.path}/feesync_fee_structures_$timestamp.csv');
        await file.writeAsString(csvBuffer.toString());
        _exportedFiles.add(file.path);
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportCompleted = true;
        });

        // Trigger Share sheet automatically
        if (_exportedFiles.isNotEmpty) {
          final xFiles = _exportedFiles
              .map((path) => XFile(path, mimeType: 'text/csv'))
              .toList();
          await Share.shareXFiles(
            xFiles,
            subject: 'FeeSync Data Export - $timestamp',
            text: 'Exported CSV files containing FeeSync records.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _exportCompleted = false;
      _errorMessage = null;
      _exportedFiles.clear();
      _studentsCount = null;
      _paymentsCount = null;
      _feeStructuresCount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Export Data',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isExporting) _buildExportingProgress(),
            if (!_isExporting && _exportCompleted) _buildCompletionScreen(),
            if (!_isExporting && !_exportCompleted) ...[
              _buildHero(),
              const SizedBox(height: 24),
              _sectionHeader('Select Data to Export'),
              const SizedBox(height: 12),
              _buildSelectionGroup(),
              const SizedBox(height: 24),
              if (_errorMessage != null) _buildErrorBanner(_errorMessage!),
              _buildExportButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Color(0xFF8B5CF6),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Export Your Data',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which data categories you would like to export. We will compile them into CSV sheets and prompt you to download or share.',
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

  Widget _buildSelectionGroup() {
    return Column(
      children: [
        _buildSelectionCard(
          icon: Icons.people_rounded,
          iconColor: AppColors.primary,
          title: 'Students Profile',
          subtitle: 'Admission details, classes, parent contact information',
          value: _exportStudents,
          onChanged: (val) => setState(() => _exportStudents = val ?? false),
        ),
        const SizedBox(height: 12),
        _buildSelectionCard(
          icon: Icons.payment_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Payments Ledger',
          subtitle: 'Transaction IDs, recorded amounts, payment methods, dates',
          value: _exportPayments,
          onChanged: (val) => setState(() => _exportPayments = val ?? false),
        ),
        const SizedBox(height: 12),
        _buildSelectionCard(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Fee Structures',
          subtitle: 'Assigned fees, class-wise structures, late fine rules',
          value: _exportFeeStructures,
          onChanged: (val) => setState(() => _exportFeeStructures = val ?? false),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        checkColor: AppColors.onPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startExport,
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text(
          'Export to CSV',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildExportingProgress() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Exporting Data...',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
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
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Data Export Complete',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_studentsCount != null)
                    _statChip('$_studentsCount', 'Students', AppColors.primary),
                  if (_paymentsCount != null)
                    _statChip('$_paymentsCount', 'Payments', const Color(0xFF10B981)),
                  if (_feeStructuresCount != null)
                    _statChip('$_feeStructuresCount', 'Fees', const Color(0xFFF59E0B)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader('Exported Files'),
        const SizedBox(height: 10),
        Column(
          children: _exportedFiles.map((path) {
            final fileName = path.split('/').last.split('\\').last;
            return Card(
              color: AppColors.surfaceContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.insert_drive_file_rounded,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    Share.shareXFiles(
                      [XFile(path, mimeType: 'text/csv')],
                      subject: 'FeeSync Export - $fileName',
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Export Again',
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      );
}
