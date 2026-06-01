import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  final String? studentId;
  final String? initialBatchId;

  const AddEditStudentScreen({super.key, this.studentId, this.initialBatchId});

  @override
  ConsumerState<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  DateTime _joiningDate = DateTime.now();

  String? _selectedBatchId;
  Gender _gender = Gender.male;

  @override
  void initState() {
    super.initState();
    // Pre-load batches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchNotifierProvider.notifier).loadBatches();
    });
    if (widget.studentId != null) {
      _loadStudentData();
    } else if (widget.initialBatchId != null) {
      _selectedBatchId = widget.initialBatchId;
    }
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final student = await ref.read(studentRepositoryProvider).getStudentById(widget.studentId!);
      if (student != null) {
        _firstNameController.text = student.firstName;
        _lastNameController.text = student.lastName;
        _selectedBatchId = student.batchId;
        _parentNameController.text = student.parentName ?? '';
        _parentPhoneController.text = student.parentPhone ?? '';
        _parentEmailController.text = student.parentEmail ?? '';
        _addressController.text = student.address ?? '';
        _rollNumberController.text = student.rollNumber ?? '';
        _discountController.text = student.discountAmount.toString();
        if (student.joiningDate != null) _joiningDate = student.joiningDate!;
        if (student.gender != null) _gender = student.gender!;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _addressController.dispose();
    _rollNumberController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final accountId = ref.read(currentUserProfileProvider).value?.accountId;
      if (accountId == null) throw Exception('Account ID not found');

      final batches = ref.read(batchNotifierProvider).value ?? [];
      final selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);

      final parentPhone = _parentPhoneController.text.trim();
      String? formattedPhone;
      if (parentPhone.isNotEmpty) {
        // Remove all non-numeric characters
        final cleanPhone = parentPhone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.length == 10) {
          formattedPhone = '+91$cleanPhone';
        } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
          formattedPhone = '+$cleanPhone';
        } else {
          formattedPhone = parentPhone.startsWith('+') ? parentPhone : '+$cleanPhone';
        }
      }

      final data = {
        'account_id': accountId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'admission_number': DateTime.now().millisecondsSinceEpoch.toString(), // Internal ID
        'class': selectedBatch.name,
        'batch_id': _selectedBatchId,
        'parent_name': _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
        'parent_phone': formattedPhone,
        'parent_email': _parentEmailController.text.trim().isEmpty ? null : _parentEmailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'roll_number': _rollNumberController.text.trim().isEmpty ? null : _rollNumberController.text.trim(),
        'joining_date': _joiningDate.toIso8601String().split('T')[0],
        'discount_amount': double.tryParse(_discountController.text) ?? 0,
        'gender': _gender.name,
      };

      if (widget.studentId == null) {
        await ref.read(studentRepositoryProvider).createStudent(data);
      } else {
        await ref.read(studentRepositoryProvider).updateStudent(widget.studentId!, data);
      }

      ref.invalidate(studentBalancesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student saved successfully')));
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
    final isEdit = widget.studentId != null;
    final batchesAsync = ref.watch(batchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add New Student', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(onPressed: _saveStudent, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Personal Identity', subtitle: 'Administrative records and identity detail'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildField(label: 'FIRST NAME', controller: _firstNameController, hint: 'First name', icon: Icons.person_outline_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(label: 'LAST NAME', controller: _lastNameController, hint: 'Last name', icon: Icons.person_outline_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildField(label: 'ROLL NO', controller: _rollNumberController, hint: 'Roll number', icon: Icons.tag_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBatchDropdown(batchesAsync)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDatePicker(label: 'JOINING DATE', date: _joiningDate, onTap: _selectJoiningDate)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(label: 'DISCOUNT (₹)', controller: _discountController, hint: '0', icon: Icons.percent_rounded, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              _buildGenderPicker(),
              const SizedBox(height: 48),
              _SectionHeader(title: 'Parent/Guardian', subtitle: 'Primary contact for fee reminders and updates'),
              const SizedBox(height: 24),
              _buildField(label: 'PARENT NAME', controller: _parentNameController, hint: 'Full name', icon: Icons.family_restroom_rounded),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildField(label: 'PHONE', controller: _parentPhoneController, hint: 'Phone no.', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(label: 'EMAIL', controller: _parentEmailController, hint: 'Email address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(label: 'ADDRESS', controller: _addressController, hint: 'Residential address', icon: Icons.location_on_outlined, maxLines: 3),
              const SizedBox(height: 64),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerHigh,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Widget _buildDatePicker({required String label, required DateTime date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchDropdown(AsyncValue<List<Batch>> batchesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BATCH / CLASS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        batchesAsync.when(
          data: (batches) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBatchId,
                hint: Text('Select Batch', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                isExpanded: true,
                dropdownColor: AppColors.surfaceContainerHigh,
                items: batches.map((b) => DropdownMenuItem(
                  value: b.id.toString(),
                  child: Text(b.name, style: const TextStyle(color: Colors.white, fontSize: 15)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedBatchId = val),
              ),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Error loading batches', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
            fillColor: AppColors.surfaceContainer.withOpacity(0.5),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GENDER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Row(
          children: Gender.values.map((g) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChipButton(
              label: g.name.toUpperCase(),
              isSelected: _gender == g,
              onTap: () => setState(() => _gender = g),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveStudent,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: Text(_isLoading ? 'SAVING...' : (widget.studentId == null ? 'CREATE STUDENT' : 'SAVE CHANGES')),
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
        Text(title, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
      ],
    );
  }
}
