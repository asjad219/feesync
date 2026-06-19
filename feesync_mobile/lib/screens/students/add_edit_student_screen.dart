import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../core/widgets/paywall_dialog.dart';
import '../../core/billing/feature_gate.dart';
import '../../core/widgets/error_dialog.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../../core/widgets/permission_guard.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ── Paywall check (add-new mode only) ──────────────────────────────────
      if (widget.studentId == null) {
        final data = await ref.read(subscriptionScreenDataProvider.future);
        if (!data.canAddStudent && mounted) {
          await showPaywallDialog(
            context,
            ref,
            trigger: PaywallTrigger.studentLimit,
          );
          // Pop back — the form would be useless without quota
          if (mounted) context.pop();
          return;
        }
      }

      await ref.read(batchNotifierProvider.notifier).loadBatches();
      if (widget.studentId == null && mounted) {
        final batchState = ref.read(batchNotifierProvider);
        final batches = batchState.value ?? [];
        if (batches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showNoBatchesDialog();
            }
          });
        }
      }
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

  void _showNoBatchesDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final Color surfaceColor = AppColors.darkSurface;
        final Color textPrimaryColor = AppColors.textPrimary;
        final Color textSecondaryColor = AppColors.textSecondary;
        final Color textTertiaryColor = AppColors.textTertiary;
        
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Handle ---
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // --- Icon with gradient ---
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.layers_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              // --- Title ---
              Text(
                'Create a Batch First',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // --- Subtitle ---
              Text(
                'Students must be enrolled in a batch to track fees and schedules. Since you don\'t have any batches yet, let\'s create your first one!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  Navigator.of(sheetContext).pop(); // dismiss sheet
                  final FeatureGate gate = ref.read(featureGateProvider).valueOrNull 
                      ?? await ref.read(featureGateProvider.future);
                  if (!mounted) return;
                  if (!gate.canAddBatch) {
                    await showPaywallDialog(
                      context,
                      ref,
                      trigger: PaywallTrigger.batchLimit,
                    );
                    return;
                  }
                  final router = GoRouter.of(context);
                  await router.push('/batches/create'); // navigate to batch creation
                  if (!mounted) return;
                  await ref.read(batchNotifierProvider.notifier).loadBatches();
                  if (!mounted) return;
                  final batches = ref.read(batchNotifierProvider).value ?? [];
                  if (batches.isEmpty) {
                    router.pop(); // go back since they didn't create a batch
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Create New Batch',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Cancel/Back Button ---
              GestureDetector(
                onTap: () {
                  Navigator.of(sheetContext).pop(); // dismiss sheet
                  context.pop(); // go back from add student screen
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textTertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

      // Validate email format
      final email = _parentEmailController.text.trim();
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Validate phone format
      final phone = _parentPhoneController.text.trim();
      if (phone.isNotEmpty) {
        final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid phone number (at least 10 digits).'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Validate discount
      final discount = double.tryParse(_discountController.text) ?? 0;
      if (discount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount amount cannot be negative.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      if (discount > selectedBatch.monthlyFee) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discount cannot exceed the batch monthly fee (₹${selectedBatch.monthlyFee.toStringAsFixed(0)}).'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

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

      String? finalRollNumber = _rollNumberController.text.trim();
      if (selectedBatch.autoRollNumber && widget.studentId == null && finalRollNumber.isEmpty) {
        final prefix = selectedBatch.name.toUpperCase().replaceAll(' ', '');
        finalRollNumber = '$prefix-${selectedBatch.studentCount + 1}';
      }

      String capitalize(String s) => s.isEmpty ? '' : s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
      
      final settings = ref.read(settingsProvider).value;
      final smartFormatting = settings?.ocrEnabled ?? false;

      var fName = _firstNameController.text.trim();
      var lName = _lastNameController.text.trim();
      var pName = _parentNameController.text.trim();
      
      if (smartFormatting) {
        fName = capitalize(fName);
        lName = capitalize(lName);
        pName = capitalize(pName);
      }

      final data = {
        'account_id': accountId,
        'first_name': fName,
        'last_name': lName,
        'admission_number': DateTime.now().millisecondsSinceEpoch.toString(), // Internal ID
        'class': selectedBatch.name,
        'batch_id': _selectedBatchId,
        'parent_name': pName.isEmpty ? null : pName,
        'parent_phone': formattedPhone,
        'parent_email': _parentEmailController.text.trim().isEmpty ? null : _parentEmailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'roll_number': finalRollNumber.isEmpty ? null : finalRollNumber,
        'joining_date': _joiningDate.toIso8601String().split('T')[0],
        'discount_amount': double.tryParse(_discountController.text) ?? 0,
        'gender': _gender.name,
      };

      if (widget.studentId == null) {
        final featureGate = await ref.read(featureGateProvider.future);
        if (!featureGate.canAddStudent) {
          if (mounted) {
            setState(() => _isLoading = false);
            await showPaywallDialog(context, ref, trigger: PaywallTrigger.studentLimit);
          }
          return;
        }
        await ref.read(studentRepositoryProvider).createStudent(data);
        ref.invalidate(activeStudentCountProvider);
        ref.invalidate(subscriptionScreenDataProvider);
        ref.invalidate(featureGateProvider);
      } else {
        await ref.read(studentRepositoryProvider).updateStudent(widget.studentId!, data);
      }

      ref.invalidate(studentBalancesProvider);
      ref.invalidate(batchByIdProvider);
      ref.invalidate(batchNotifierProvider);
      invalidateDashboardAnalytics(ref);

      if (widget.studentId != null) {
        ref.invalidate(studentByIdProvider(widget.studentId!));
        ref.invalidate(studentBalanceByIdProvider(widget.studentId!));
        ref.invalidate(studentBatchesProvider(widget.studentId!));
      }

      if (_selectedBatchId != null) {
        ref.invalidate(batchStudentsProvider(_selectedBatchId!));
        ref.invalidate(batchAnalyticsProvider(_selectedBatchId!));
      }

      if (widget.initialBatchId != null && widget.initialBatchId != _selectedBatchId) {
        ref.invalidate(batchStudentsProvider(widget.initialBatchId!));
        ref.invalidate(batchAnalyticsProvider(widget.initialBatchId!));
      }

      if (mounted) {
        final message = widget.studentId == null ? 'Student saved successfully' : 'Student updated successfully.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.studentId != null;
    final batchesAsync = ref.watch(batchNotifierProvider);

    final bool isDark = AppColors.isDarkMode;
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    final batches = batchesAsync.value ?? [];
    Batch? selectedBatch;
    if (_selectedBatchId != null && batches.isNotEmpty) {
      try {
        selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);
      } catch (_) {}
    }
    final autoRollNumber = selectedBatch?.autoRollNumber ?? false;
    final collectParentDetails = selectedBatch?.collectParentDetails ?? true;

    return PermissionGuard(
      permission: 'manage_students',
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: scaffoldBgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimaryColor),
          title: Text(
            isEdit ? 'Edit Student' : 'Add New Student', 
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: textPrimaryColor)
          ),
          actions: [
            if (_isLoading)
              Center(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))))
            else
              IconButton(
                onPressed: _saveStudent, 
                icon: Icon(Icons.check_rounded, color: textPrimaryColor)
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    Expanded(child: _buildField(
                      label: 'ROLL NO', 
                      controller: _rollNumberController, 
                      hint: autoRollNumber ? 'Auto-generated' : 'Roll number', 
                      icon: Icons.tag_rounded,
                      enabled: !autoRollNumber,
                      isRequired: !autoRollNumber,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBatchDropdown(batchesAsync)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker(label: 'JOINING DATE', date: _joiningDate, onTap: _selectJoiningDate)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(label: 'DISCOUNT (₹)', controller: _discountController, hint: '0', icon: Icons.percent_rounded, keyboardType: TextInputType.number, isRequired: false)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildGenderPicker(),
                const SizedBox(height: 48),
                if (collectParentDetails) ...[
                  _SectionHeader(title: 'Parent/Guardian', subtitle: 'Primary contact for fee reminders and updates'),
                  const SizedBox(height: 24),
                  _buildField(label: 'PARENT NAME', controller: _parentNameController, hint: 'Full name', icon: Icons.family_restroom_rounded, isRequired: false),
                  const SizedBox(height: 24),
                ] else ...[
                  _SectionHeader(title: 'Contact Information', subtitle: 'Primary contact for fee reminders and updates'),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Expanded(child: _buildField(
                      label: collectParentDetails ? 'PHONE' : 'STUDENT PHONE', 
                      controller: _parentPhoneController, 
                      hint: 'Phone no.', 
                      icon: Icons.phone_android_rounded, 
                      keyboardType: TextInputType.phone,
                      isRequired: false,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(
                      label: collectParentDetails ? 'EMAIL' : 'STUDENT EMAIL', 
                      controller: _parentEmailController, 
                      hint: 'Email address', 
                      icon: Icons.email_outlined, 
                      keyboardType: TextInputType.emailAddress,
                      isRequired: false,
                    )),
                  ],
                ),
                const SizedBox(height: 24),
                _buildField(label: 'ADDRESS', controller: _addressController, hint: 'Residential address', icon: Icons.location_on_outlined, maxLines: 3, isRequired: false),
                const SizedBox(height: 64),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectJoiningDate() async {
    final bool isDark = AppColors.isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1E1E2C),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Color(0xFFFFFFFF),
                    onSurface: Colors.black,
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
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isDark ? surfaceColor.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.1)
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: textTertiaryColor),
                const SizedBox(width: 12),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimaryColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchDropdown(AsyncValue<List<Batch>> batchesAsync) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final dropdownBgColor = isDark ? const Color(0xFF292937) : const Color(0xFFFFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BATCH / CLASS', 
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)
        ),
        const SizedBox(height: 8),
        batchesAsync.when(
          data: (batches) {
            // Auto-select if there is exactly 1 batch and nothing is selected yet
            if (_selectedBatchId == null && batches.isNotEmpty) {
              if (batches.length == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedBatchId != batches.first.id) {
                    setState(() {
                      _selectedBatchId = batches.first.id;
                    });
                  }
                });
              }
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? surfaceColor.withValues(alpha: 0.5) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.1)
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBatchId,
                  hint: Text('Select Batch', style: TextStyle(color: textTertiaryColor.withValues(alpha: 0.5), fontSize: 14)),
                  isExpanded: true,
                  dropdownColor: dropdownBgColor,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: textTertiaryColor),
                  items: batches.map((b) => DropdownMenuItem(
                    value: b.id.toString(),
                    child: Text(b.name, style: TextStyle(color: textPrimaryColor, fontSize: 15)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedBatchId = val),
                ),
              ),
            );
          },
          loading: () => const SizedBox(height: 50, child: Center(child: LinearProgressIndicator())),
          error: (_, _) => const Text('Error loading batches', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType, bool enabled = true, bool isRequired = true}) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: enabled ? textPrimaryColor : textTertiaryColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: textTertiaryColor),
            fillColor: isDark ? surfaceColor.withValues(alpha: 0.5) : Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.1)
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.1)
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
            hintStyle: TextStyle(
              color: textTertiaryColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          validator: isRequired ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    final bool isDark = AppColors.isDarkMode;
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER', 
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)
        ),
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
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _isLoading ? 'SAVING...' : (widget.studentId == null ? 'CREATE STUDENT' : 'SAVE CHANGES'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimaryColor)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textTertiaryColor)),
      ],
    );
  }
}
