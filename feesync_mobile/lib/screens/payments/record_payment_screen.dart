import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
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
import '../../core/widgets/permission_guard.dart';

import 'widgets/payment_form_fields.dart';
import 'widgets/payment_selection_widgets.dart';
import 'widgets/student_search_bottom_sheet.dart';

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
      if (_selectedDueIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one pending due period.')),
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

      final idempotencyKey = const Uuid().v4();
      final bool isAdvancePayment = availableDues.isEmpty || amount > allocations.fold(0.0, (sum, a) => sum + (a['amount'] as double));

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
        'idempotency_key': idempotencyKey,
      };

      await ref.read(paymentNotifierProvider.notifier).createPayment(paymentData, allocations);
      ref.invalidate(studentBalancesProvider);
      ref.invalidate(studentPaymentsProvider(_selectedStudent!.id));
      if (_selectedStudent != null) ref.invalidate(studentDuesProvider(_selectedStudent!.id));
      ref.invalidate(batchNotifierProvider);
      ref.invalidate(batchByIdProvider);
      
      ref.read(dashboardStatsProvider.notifier).fetch();
      ref.read(monthlyCollectionDataProvider.notifier).fetch();
      ref.read(recentTransactionsProvider.notifier).fetch();
      ref.read(classCollectionDataProvider.notifier).fetch();

      if (mounted) {
        _showSuccessDialog(amount, isAdvancePayment);
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String error) {
    String displayError = error;
    if (error.contains('DatabaseException')) {
      displayError = 'A database error occurred while saving the payment. Please try again.';
    } else if (error.contains('NetworkException')) {
      displayError = 'A network error occurred. Please check your connection.';
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

  void _showSuccessDialog(double amount, bool isAdvancePayment) {
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
                  onPressed: () => _shareReceipt(amount, isAdvancePayment),
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

  void _shareReceipt(double amount, bool isAdvancePayment) async {
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
        isAdvance: isAdvancePayment,
      );

      final pdfFile = await ReceiptService.generatePdfReceipt(
        student: student,
        amount: amount,
        paymentMode: _paymentMode,
        date: _paymentDate,
        invoiceNo: invoiceNo,
        institutionName: institutionName,
        isAdvance: isAdvancePayment,
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

  void _showStudentSearchBottomSheet(List<StudentBalance> balances) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StudentSearchBottomSheet(
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
            _amountController.clear();
          });
        },
      ),
    );
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

    return PermissionGuard(
      permission: 'manage_payments',
      child: Scaffold(
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
                const PaymentSectionHeader(title: 'Transaction Details', subtitle: 'Link payment to a student and select due periods'),
                const SizedBox(height: 32),
  
                const PaymentFormLabel(text: 'BATCH / CLASS'),
                const SizedBox(height: 12),
                batchesAsync.when(
                  data: (batches) => BatchSelectionDropdown(
                    batches: batches,
                    selectedBatchId: _selectedBatchId,
                    onChanged: (value) {
                      setState(() {
                        _selectedBatchId = value;
                        if (_selectedStudent != null) {
                          final balances = ref.read(studentBalancesProvider).value ?? [];
                          final existsInBatch = balances.any((b) => b.id == _selectedStudent!.id && (value == null || b.batchId == value));
                          if (!existsInBatch) {
                            _selectedStudent = null;
                            _selectedDueIds.clear();
                            _amountController.clear();
                          }
                        }
                      });
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
                
                const PaymentFormLabel(text: 'STUDENT NAME'),
                const SizedBox(height: 12),
                studentsAsync.when(
                  data: (balances) => StudentSelectionButton(
                    selectedStudent: _selectedStudent,
                    onTap: () => _showStudentSearchBottomSheet(balances),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 32),
  
                if (_selectedStudent != null) ...[
                  const PaymentFormLabel(text: 'SELECT PENDING DUES'),
                  const SizedBox(height: 12),
                  duesAsync.when(
                    data: (dues) => PendingDuesSelector(
                      dues: dues,
                      selectedDueIds: _selectedDueIds,
                      currencyCode: currencyCode,
                      onDueToggled: (due, isSelected) {
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
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Error loading dues'),
                  ),
                  const SizedBox(height: 32),
                ],
  
                Row(
                  children: [
                    Expanded(
                      child: PaymentTextField(
                        label: 'AMOUNT ($currencySymbol)',
                        controller: _amountController,
                        hint: '0',
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PaymentDatePicker(
                        date: _paymentDate,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
  
                const PaymentFormLabel(text: 'PAYMENT MODE'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PaymentModeToggle(
                      value: 'online', 
                      icon: Icons.account_balance_wallet_rounded, 
                      label: 'Online',
                      selectedMode: _paymentMode,
                      onSelected: (v) => setState(() => _paymentMode = v),
                    ),
                    const SizedBox(width: 12),
                    PaymentModeToggle(
                      value: 'cash', 
                      icon: Icons.payments_rounded, 
                      label: 'Cash',
                      selectedMode: _paymentMode,
                      onSelected: (v) => setState(() => _paymentMode = v),
                    ),
                    const SizedBox(width: 12),
                    PaymentModeToggle(
                      value: 'bank', 
                      icon: Icons.account_balance_rounded, 
                      label: 'Bank',
                      selectedMode: _paymentMode,
                      onSelected: (v) => setState(() => _paymentMode = v),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
  
                PaymentTextField(
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
