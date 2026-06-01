import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/student.dart';
import '../../models/fee.dart';
import '../../providers/providers.dart';
import '../../core/utils/receipt_service.dart';

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
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.surfaceContainer,
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

    if (_selectedDueIds.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          title: const Text('Record as Advance?'),
          content: const Text('No specific fee periods selected. This will be recorded as an advance payment for future dues.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('PROCEED', style: TextStyle(color: AppColors.primary))),
          ],
        ),
      );
      if (confirm != true) return;
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
          final paymentForDue = remaining > due.amountOutstanding ? due.amountOutstanding : remaining;
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

      final paymentData = {
        'account_id': accountId,
        'student_id': _selectedStudent!.id,
        'amount': amount,
        'payment_method': _paymentMode,
        'payment_date': _paymentDate.toIso8601String(),
        'notes': _notesController.text.trim().isEmpty 
            ? (_selectedDueIds.isEmpty ? 'Advance Payment' : null) 
            : _notesController.text.trim(),
        'status': 'completed',
      };

      await ref.read(paymentRepositoryProvider).createPayment(paymentData, allocations);
      ref.invalidate(studentBalancesProvider);
      ref.invalidate(studentPaymentsProvider(_selectedStudent!.id));
      if (_selectedStudent != null) ref.invalidate(studentDuesProvider(_selectedStudent!.id));

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                child: ElevatedButton.icon(
                  onPressed: () => _shareReceipt(amount),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('SEND RECEIPT VIA WHATSAPP'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
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
    final student = _selectedStudent!;
    final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    setState(() => _isLoading = true);
    try {
      final textReceipt = ReceiptService.generateTextReceipt(
        student: student,
        amount: amount,
        paymentMode: _paymentMode,
        date: _paymentDate,
        invoiceNo: invoiceNo,
      );

      final pdfFile = await ReceiptService.generatePdfReceipt(
        student: student,
        amount: amount,
        paymentMode: _paymentMode,
        date: _paymentDate,
        invoiceNo: invoiceNo,
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Transaction Details', subtitle: 'Link payment to a student and select due periods'),
              const SizedBox(height: 32),
              
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
                label: 'NOTES',
                controller: _notesController,
                hint: 'Internal remarks...',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 64),

              _buildSubmitButton(duesAsync.value ?? []),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary));

  Widget _buildStudentPicker(List<StudentBalance> balances) {
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
          value: _selectedStudent?.id,
          hint: const Text('Select a student'),
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          items: balances.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.fullName} (${b.studentClass})'))).toList(),
          onChanged: (value) {
            if (value != null) {
              final student = balances.firstWhere((b) => b.id == value);
              setState(() {
                _selectedStudent = Student(
                  id: student.id, 
                  accountId: student.accountId, 
                  admissionNumber: student.admissionNumber, 
                  firstName: student.firstName, 
                  lastName: student.lastName, 
                  studentClass: student.studentClass, 
                  rollNumber: student.rollNumber,
                  parentPhone: student.parentPhone,
                  createdAt: DateTime.now(), 
                  updatedAt: DateTime.now()
                );
                _selectedDueIds.clear();
                _amountController.clear();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDuesList(List<Due> dues) {
    if (dues.isEmpty) {
      return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text('No pending dues for this student', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600))),
    );
    }
    
    final bool isDark = AppColors.isDarkMode;
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
                  _amountController.text = (current - due.amountOutstanding).toStringAsFixed(0);
                } else {
                  _selectedDueIds.add(due.id);
                  final current = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (current + due.amountOutstanding).toStringAsFixed(0);
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
                  Text(currencyFormatter.format(due.amountOutstanding), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType}) {
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
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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

  Widget _buildSubmitButton(List<Due> availableDues) {
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
        onPressed: _isLoading || _selectedStudent == null ? null : () => _savePayment(availableDues),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: Text(_isLoading ? 'RECORDING...' : 'RECORD PAYMENT'),
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