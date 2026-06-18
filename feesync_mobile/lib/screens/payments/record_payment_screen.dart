import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/student.dart';
import '../../models/batch.dart';
import '../../models/fee.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../../core/widgets/paywall_dialog.dart';
import '../../core/billing/feature_gate.dart';
import '../../core/utils/receipt_service.dart';
import '../../core/widgets/student_avatar.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final Student? student;

  const RecordPaymentScreen({super.key, this.student});

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Student? _selectedStudent;
  String? _selectedBatchId;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'online';
  bool _isAdvancePayment = false;
  
  final List<String> _selectedDueIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _selectedStudent = widget.student;
      _selectedBatchId = widget.student!.batchId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: AppColors.isDarkMode
              ? ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: AppColors.onPrimary,
                  surface: AppColors.surfaceContainer,
                  onSurface: AppColors.textPrimary,
                )
              : ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceContainer,
                  onSurface: AppColors.textPrimary,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _savePayment(List<Due> availableDues) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (availableDues.isNotEmpty) {
      _isAdvancePayment = false;
      if (_selectedDueIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one pending due period.')),
        );
        return;
      }
    } else {
      if (!_isAdvancePayment) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please turn on Advance Payment to proceed.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final accountId = ref.read(currentUserProfileProvider).value?.accountId;
      if (accountId == null) throw Exception('Account ID not found');

      double remaining = amount;
      final allocations = <Map<String, dynamic>>[];
      
      if (_selectedDueIds.isNotEmpty) {
        for (final dueId in _selectedDueIds) {
          final due = availableDues.firstWhere((d) => d.id == dueId);
          final paymentForDue = remaining > due.dueAmount ? due.dueAmount : remaining;
          if (paymentForDue > 0) {
            allocations.add({
              'fee_structure_id': due.feeStructureId,
              'due_id': due.id,
              'amount': paymentForDue,
            });
            remaining -= paymentForDue;
          }
        }
      }

      String dbPaymentMethod = 'other';
      if (_paymentMode == 'online') {
        dbPaymentMethod = 'mobile_money';
      } else if (_paymentMode == 'cash') {
        dbPaymentMethod = 'cash';
      } else if (_paymentMode == 'bank') {
        dbPaymentMethod = 'bank_transfer';
      }

      final paymentData = {
        'account_id': accountId,
        'student_id': _selectedStudent!.id,
        'amount': amount,
        'payment_method': dbPaymentMethod,
        'payment_date': _paymentDate.toIso8601String(),
        'notes': _notesController.text.trim().isEmpty 
            ? (_selectedDueIds.isEmpty ? 'Advance Payment' : null) 
            : _notesController.text.trim(),
        'status': 'completed',
      };

      await ref.read(paymentNotifierProvider.notifier).createPayment(paymentData, allocations);
      ref.invalidate(studentBalancesProvider);
      ref.invalidate(studentPaymentsProvider(_selectedStudent!.id));
      if (_selectedStudent != null) ref.invalidate(studentDuesProvider(_selectedStudent!.id));
      ref.invalidate(batchNotifierProvider);
      ref.invalidate(batchByIdProvider);
      invalidateDashboardAnalytics(ref);

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String error) {
    // Sanitize technical errors slightly for better UX
    String displayError = error;
    if (error.contains('PostgrestException')) {
      displayError = 'A database error occurred while saving the payment. Please try again.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Payment Failed', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(
              displayError,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('TRY AGAIN', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    final settings = ref.read(settingsProvider).value;
    final currencyFormatter = CurrencyFormatter.numberFormat(settings?.currency, decimalDigits: 0);
    final canShareReceipt = (settings?.autoReceiptEnabled ?? true) && (settings?.whatsappEnabled ?? true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Payment Recorded!', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('${currencyFormatter.format(amount)} received from ${_selectedStudent!.fullName}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
            const SizedBox(height: 32),
            if (canShareReceipt) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _shareReceipt(amount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'SEND', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: Text('DONE', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReceipt(double amount) async {
    final FeatureGate featureGate = ref.read(featureGateProvider).valueOrNull ?? await ref.read(featureGateProvider.future);
    if (!featureGate.canSendWhatsappReceipt) {
      if (mounted) {
        await showPaywallDialog(
          context,
          ref,
          trigger: PaywallTrigger.whatsappReceiptLimit,
        );
      }
      return;
    }

    final student = _selectedStudent!;
    final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    setState(() => _isLoading = true);
    try {
      final accountProfile = ref.read(accountProfileProvider).value;
      final institutionName = accountProfile?.schoolName ?? accountProfile?.name ?? 'Institution';

      final textReceipt = ReceiptService.generateTextReceipt(
        student: student,
        amount: amount,
        paymentMode: _paymentMode,
        date: _paymentDate,
        invoiceNo: invoiceNo,
        institutionName: institutionName,
      );

      final pdfFile = await ReceiptService.generatePdfReceipt(
        student: student,
        amount: amount,
        paymentMode: _paymentMode,
        date: _paymentDate,
        invoiceNo: invoiceNo,
        institutionName: institutionName,
      );

      String cleanPhone = (student.parentPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }

      await ReceiptService.shareToWhatsApp(
        phone: cleanPhone,
        text: textReceipt,
        pdfFile: pdfFile,
      );

      // Record WhatsApp usage!
      await ref.read(usageRepositoryProvider).recordWhatsappReceipt();
      ref.invalidate(currentMonthUsageProvider);
      ref.invalidate(featureGateProvider);
      ref.invalidate(subscriptionScreenDataProvider);

      if (mounted) {
        Navigator.pop(context);
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing receipt: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentBalancesProvider);
    final batchesAsync = ref.watch(batchNotifierProvider);
    final duesAsync = _selectedStudent != null 
        ? ref.watch(studentDuesProvider(_selectedStudent!.id)) 
        : const AsyncValue<List<Due>>.data([]);
    final currencyCode = ref.watch(settingsProvider).value?.currency;
    final currencySymbol = CurrencyFormatter.symbolFor(currencyCode);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Record Payment', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Transaction Details', subtitle: 'Link payment to a student and select due periods'),
              const SizedBox(height: 32),

              _buildLabel('BATCH / CLASS'),
              const SizedBox(height: 12),
              batchesAsync.when(
                data: (batches) => _buildBatchPicker(batches),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              
              _buildLabel('STUDENT NAME'),
              const SizedBox(height: 12),
              studentsAsync.when(
                data: (balances) => _buildStudentPicker(balances),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),

              if (_selectedStudent != null) ...[
                _buildLabel('SELECT PENDING DUES'),
                const SizedBox(height: 12),
                duesAsync.when(
                  data: (dues) => _buildDuesList(dues),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading dues'),
                ),
                const SizedBox(height: 32),
              ],

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'AMOUNT ($currencySymbol)',
                      controller: _amountController,
                      hint: '0',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildLabel('PAYMENT MODE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildModeToggle('online', Icons.account_balance_wallet_rounded, 'Online'),
                  const SizedBox(width: 12),
                  _buildModeToggle('cash', Icons.payments_rounded, 'Cash'),
                  const SizedBox(width: 12),
                  _buildModeToggle('bank', Icons.account_balance_rounded, 'Bank'),
                ],
              ),
              const SizedBox(height: 32),

              _buildField(
                label: 'NOTES (OPTIONAL)',
                controller: _notesController,
                hint: 'Internal remarks...',
                icon: Icons.notes_rounded,
                maxLines: 2,
                isRequired: false,
              ),
              const SizedBox(height: 64),

              _buildSubmitButton(duesAsync.value ?? [], duesAsync.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary));

  Widget _buildBatchPicker(List<Batch> batches) {
    final bool isDark = AppColors.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedBatchId,
          hint: const Text('All Batches / Classes'),
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Batches / Classes'),
            ),
            ...batches.map((b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text('${b.name} (${b.subject})'),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedBatchId = value;
              // Reset selected student if they do not belong to the selected batch
              if (_selectedStudent != null) {
                final balances = ref.read(studentBalancesProvider).value ?? [];
                final existsInBatch = balances.any((b) => b.id == _selectedStudent!.id && (value == null || b.batchId == value));
                if (!existsInBatch) {
                  _selectedStudent = null;
                  _selectedDueIds.clear();
                  _isAdvancePayment = false;
                  _amountController.clear();
                }
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildStudentPicker(List<StudentBalance> balances) {
    final bool isDark = AppColors.isDarkMode;
    final displayName = _selectedStudent != null 
        ? '${_selectedStudent!.fullName} (${_selectedStudent!.studentClass})'
        : 'Select a student';
    return InkWell(
      onTap: () => _showStudentSearchBottomSheet(balances),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: _selectedStudent != null ? FontWeight.w600 : FontWeight.w400,
                  color: _selectedStudent != null ? AppColors.textPrimary : AppColors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showStudentSearchBottomSheet(List<StudentBalance> balances) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _StudentSearchBottomSheet(
        balances: balances,
        selectedBatchId: _selectedBatchId,
        onStudentSelected: (studentBalance) {
          setState(() {
            _selectedStudent = Student(
              id: studentBalance.id,
              accountId: studentBalance.accountId,
              admissionNumber: studentBalance.admissionNumber,
              firstName: studentBalance.firstName,
              lastName: studentBalance.lastName,
              studentClass: studentBalance.studentClass,
              rollNumber: studentBalance.rollNumber,
              parentPhone: studentBalance.parentPhone,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _selectedDueIds.clear();
            _isAdvancePayment = false;
            _amountController.clear();
          });
        },
      ),
    );
  }

  Widget _buildDuesList(List<Due> dues) {
    final bool isDark = AppColors.isDarkMode;
    if (dues.isEmpty) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('No pending dues for this student', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record as Advance Payment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Since there are no pending dues, this payment will be added to the student\'s advance balance.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Switch(
                  value: _isAdvancePayment,
                  onChanged: (v) => setState(() => _isAdvancePayment = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    final currencyCode = ref.read(settingsProvider).value?.currency;
    final currencyFormatter = CurrencyFormatter.numberFormat(currencyCode, decimalDigits: 0);

    return Column(
      children: dues.map((due) {
        final isSelected = _selectedDueIds.contains(due.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDueIds.remove(due.id);
                  final current = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (current - due.dueAmount).toStringAsFixed(0);
                } else {
                  _selectedDueIds.add(due.id);
                  final current = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (current + due.dueAmount).toStringAsFixed(0);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.1) 
                    : (isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary.withValues(alpha: 0.3) 
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
                ),
                boxShadow: isSelected ? null : (isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(due.periodName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('Due: ${DateFormat('MMM d, yyyy').format(due.dueDate)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Text(currencyFormatter.format(due.dueAmount), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    final bool isDark = AppColors.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
            fillColor: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          validator: isRequired ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final bool isDark = AppColors.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('PAYMENT DATE'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Text(DateFormat('MMM d, yyyy').format(_paymentDate), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle(String value, IconData icon, String label) {
    final isSelected = _paymentMode == value;
    final bool isDark = AppColors.isDarkMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.1) 
                : (isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.3) 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 24),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(List<Due> availableDues, bool isDuesLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading || _selectedStudent == null || isDuesLoading ? null : () => _savePayment(availableDues),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _isLoading ? 'RECORDING...' : 'RECORD PAYMENT',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800, 
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
      ],
    );
  }
}

class _StudentSearchBottomSheet extends StatefulWidget {
  final List<StudentBalance> balances;
  final String? selectedBatchId;
  final ValueChanged<StudentBalance> onStudentSelected;

  const _StudentSearchBottomSheet({
    required this.balances,
    this.selectedBatchId,
    required this.onStudentSelected,
  });

  @override
  State<_StudentSearchBottomSheet> createState() => _StudentSearchBottomSheetState();
}

class _StudentSearchBottomSheetState extends State<_StudentSearchBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter balances by batch
    final batchFiltered = widget.balances.where((b) {
      if (widget.selectedBatchId != null && b.batchId != widget.selectedBatchId) {
        return false;
      }
      return true;
    }).toList();

    // Filter by search query
    final filtered = batchFiltered.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.fullName.toLowerCase().contains(q) ||
          b.admissionNumber.toLowerCase().contains(q) ||
          (b.rollNumber ?? '').toLowerCase().contains(q);
    }).toList();

    final isDark = AppColors.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Student',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Search Input
              TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name, roll, or admission no...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  fillColor: isDark
                      ? AppColors.surfaceContainerLow.withValues(alpha: 0.6)
                      : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
              // Filter count
              Text(
                'Showing ${filtered.length} of ${batchFiltered.length} students',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No students found',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          final balanceText = student.balance > 0
                              ? 'Balance: ₹${student.balance.toStringAsFixed(0)}'
                              : 'No dues';
                          final balanceColor = student.balance > 0
                              ? AppColors.error
                              : AppColors.success;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: isDark
                                  ? AppColors.surfaceContainerLow.withValues(alpha: 0.3)
                                  : Colors.white,
                              leading: StudentAvatar(
                                studentId: student.id,
                                firstName: student.firstName,
                                gender: student.gender,
                                radius: 22,
                              ),
                              title: Text(
                                student.fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Class: ${student.studentClass} • Roll: ${student.rollNumber ?? 'N/A'}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balanceText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: balanceColor,
                                    ),
                                  ),
                                  if (student.admissionNumber.isNotEmpty)
                                    Text(
                                      'ID: ${student.admissionNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                widget.onStudentSelected(student);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
