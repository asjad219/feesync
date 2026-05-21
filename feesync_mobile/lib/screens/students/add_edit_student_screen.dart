import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student.dart';
import '../../providers/providers.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const AddEditStudentScreen({super.key, this.studentId});

  @override
  ConsumerState<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _addressController = TextEditingController();

  Gender _gender = Gender.male;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _loadStudentData();
    }
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final student = await ref.read(studentRepositoryProvider).getStudentById(widget.studentId!);
      if (student != null) {
        _firstNameController.text = student.firstName;
        _lastNameController.text = student.lastName;
        _admissionNumberController.text = student.admissionNumber;
        _classController.text = student.studentClass;
        _sectionController.text = student.section ?? '';
        _parentNameController.text = student.parentName ?? '';
        _parentPhoneController.text = student.parentPhone ?? '';
        _parentEmailController.text = student.parentEmail ?? '';
        _addressController.text = student.address ?? '';
        if (student.gender != null) {
          _gender = student.gender!;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _admissionNumberController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final accountId = ref.read(currentUserProfileProvider).value?.accountId;
      if (accountId == null) throw Exception('Account ID not found');

      final data = {
        'account_id': accountId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'admission_number': _admissionNumberController.text.trim(),
        'class': _classController.text.trim(),
        'section': _sectionController.text.trim().isEmpty ? null : _sectionController.text.trim(),
        'parent_name': _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
        'parent_email': _parentEmailController.text.trim().isEmpty ? null : _parentEmailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'gender': _gender.name,
      };

      if (widget.studentId == null) {
        await ref.read(studentRepositoryProvider).createStudent(data);
      } else {
        await ref.read(studentRepositoryProvider).updateStudent(widget.studentId!, data);
      }

      // Refresh student list
      ref.invalidate(studentBalancesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student ${widget.studentId == null ? 'created' : 'updated'} successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving student: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.studentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveStudent,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: _isLoading && isEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Text(
                      'Personal Identity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update administrative records and financial obligations.',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 32),

                    // Name Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'FIRST NAME',
                            controller: _firstNameController,
                            hint: 'First name',
                            icon: Icons.person_outline,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'LAST NAME',
                            controller: _lastNameController,
                            hint: 'Last name',
                            icon: Icons.person_outline,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      label: 'ADMISSION NUMBER',
                      controller: _admissionNumberController,
                      hint: 'e.g. ADM-2024-001',
                      icon: Icons.badge_outlined,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Academic Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'CLASS',
                            controller: _classController,
                            hint: 'e.g. 10',
                            icon: Icons.school_outlined,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'SECTION',
                            controller: _sectionController,
                            hint: 'e.g. A',
                            icon: Icons.grid_view_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gender Section
                    const Text(
                      'GENDER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: Gender.values.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g.name.toUpperCase()),
                            selected: _gender == g,
                            onSelected: (selected) {
                              if (selected) setState(() => _gender = g);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Contact Section
                    Text(
                      'Parent/Guardian Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                          ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      label: 'PARENT NAME',
                      controller: _parentNameController,
                      hint: 'Full name',
                      icon: Icons.family_restroom_outlined,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'PHONE',
                            controller: _parentPhoneController,
                            hint: '+1...',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'EMAIL',
                            controller: _parentEmailController,
                            hint: 'parent@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      label: 'ADDRESS',
                      controller: _addressController,
                      hint: 'Residential address',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 48),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEdit ? 'SAVE CHANGES' : 'CREATE STUDENT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
