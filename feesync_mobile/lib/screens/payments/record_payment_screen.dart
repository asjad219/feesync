import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student.dart';
import '../../providers/providers.dart';
import '../../models/fee.dart';
import '../../core/utils/currency_formatter.dart';

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
    _selectedStudent = widget.student;
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
    );
    if (picked != null && picked != _paymentDate) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _savePayment(List<Due> availableDues) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }
    if (_selectedDueIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one due')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final accountId = ref.read(currentUserProfileProvider).value?.accountId;
      if (accountId == null) throw Exception('Account ID not found');

      final amount = double.parse(_amountController.text);
      
      // Basic allocation logic
      double remaining = amount;
      final allocations = <Map<String, dynamic>>[];
      
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

      final paymentData = {
        'account_id': accountId,
        'student_id': _selectedStudent!.id,
        'amount': amount,
        'payment_method': _paymentMode,
        'payment_date': _paymentDate.toIso8601String(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'status': 'completed',
      };

      await ref.read(paymentRepositoryProvider).createPayment(paymentData, allocations);

      // Refresh data
      ref.invalidate(studentBalancesProvider);
      ref.invalidate(studentPaymentsProvider(_selectedStudent!.id));
      ref.invalidate(studentDuesProvider(_selectedStudent!.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Record Payment',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Manrope'),
              ),
              const SizedBox(height: 32),

              // Student Selection
              _buildLabel('STUDENT NAME'),
              const SizedBox(height: 8),
              studentsAsync.when(
                data: (balances) => _buildStudentDropdown(balances),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              // Dues Selection Section
              if (_selectedStudent != null) ...[
                _buildLabel('SELECT PENDING DUES'),
                const SizedBox(height: 8),
                duesAsync.when(
                  data: (dues) => _buildDuesList(dues),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading dues: $e'),
                ),
                const SizedBox(height: 24),
              ],

              // Amount & Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'AMOUNT',
                      controller: _amountController,
                      hint: '0.00',
                      icon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(v!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('PAYMENT DATE'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textTertiary),
                                const SizedBox(width: 12),
                                Text(
                                  '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Mode
              _buildLabel('PAYMENT MODE'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildModeItem('online', Icons.language, 'Online'),
                  const SizedBox(width: 12),
                  _buildModeItem('cash', Icons.payments, 'Cash'),
                  const SizedBox(width: 12),
                  _buildModeItem('bank_transfer', Icons.account_balance, 'Bank'),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              _buildTextField(
                label: 'NOTES',
                controller: _notesController,
                hint: 'Add optional remarks...',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 48),

              // Submit Button
              duesAsync.when(
                data: (dues) => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _selectedStudent == null ? null : () => _savePayment(dues),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('RECORD PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.textTertiary));

  Widget _buildStudentDropdown(List<StudentBalance> balances) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedStudent?.id,
          hint: const Text('Select a student'),
          dropdownColor: AppColors.darkSurface,
          items: balances.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.fullName} - ${b.studentClass}'))).toList(),
          onChanged: (value) {
            if (value != null) {
              final student = balances.firstWhere((b) => b.id == value);
              setState(() {
                _selectedStudent = Student(id: student.id, accountId: student.accountId, admissionNumber: student.admissionNumber, firstName: student.firstName, lastName: student.lastName, studentClass: student.studentClass, createdAt: DateTime.now(), updatedAt: DateTime.now());
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
    if (dues.isEmpty) return const Text('No pending dues', style: TextStyle(color: AppColors.success));
    return Column(
      children: dues.map((due) {
        final isSelected = _selectedDueIds.contains(due.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedDueIds.add(due.id);
                  final currentAmount = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (currentAmount + due.amountOutstanding).toStringAsFixed(2);
                } else {
                  _selectedDueIds.remove(due.id);
                  final currentAmount = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (currentAmount - due.amountOutstanding).toStringAsFixed(2);
                }
              });
            },
            title: Text('${due.periodName} - ${due.feeStructure?.name ?? 'Fee'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text('Due: ${due.dueDate.day}/${due.dueDate.month}/${due.dueDate.year}', style: const TextStyle(fontSize: 12)),
            secondary: Text(CurrencyFormatter.format(due.amountOutstanding), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            tileColor: AppColors.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildModeItem(String value, IconData icon, String label) {
    final isSelected = _paymentMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
