import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../models/app_settings.dart';

class InstitutionSettingsScreen extends ConsumerStatefulWidget {
  const InstitutionSettingsScreen({super.key});

  @override
  ConsumerState<InstitutionSettingsScreen> createState() => _InstitutionSettingsScreenState();
}

class _InstitutionSettingsScreenState extends ConsumerState<InstitutionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _gstinController;
  
  String? _academicYear;
  String? _currency;
  String? _timezone;
  bool _gstEnabled = false;
  bool _parentPortal = false;
  
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _addressController.dispose();
      _phoneController.dispose();
      _emailController.dispose();
      _websiteController.dispose();
      _gstinController.dispose();
    }
    super.dispose();
  }

  void _initFields(AppSettings settings) {
    if (_isInitialized) return;
    _nameController = TextEditingController(text: settings.centerName);
    _addressController = TextEditingController(text: settings.centerAddress ?? '');
    _phoneController = TextEditingController(text: settings.centerPhone ?? '');
    _emailController = TextEditingController(text: settings.centerEmail ?? '');
    _websiteController = TextEditingController(text: settings.centerWebsite ?? '');
    _gstinController = TextEditingController(text: settings.gstin ?? '');
    
    _academicYear = settings.academicYear;
    _currency = settings.currency;
    _timezone = settings.timezone;
    _gstEnabled = settings.gstEnabled;
    _parentPortal = settings.parentPortalEnabled;
    
    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'center_name': _nameController.text.trim(),
        'center_address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'center_phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'center_email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'center_website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        'gstin': _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        'academic_year': _academicYear,
        'currency': _currency,
        'timezone': _timezone,
        'gst_enabled': _gstEnabled,
        'parent_portal_enabled': _parentPortal,
      };

      await ref.read(settingsProvider.notifier).updateMultipleSettings(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Institution settings updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSuccess),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    
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
          'Institution & Branding',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err', style: TextStyle(color: AppColors.error))),
        data: (settings) {
          _initFields(settings);
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('General Identity'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Center/School Name',
                          icon: Icons.business_rounded,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Physical Address',
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Contact Phone',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Contact Email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website URL',
                          icon: Icons.language_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  _buildSectionHeader('Regional & Fiscal'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDropdownField(
                          label: 'Academic Year',
                          icon: Icons.calendar_today_rounded,
                          value: _academicYear,
                          items: const ['2023-24', '2024-25', '2025-26', '2026-27'],
                          onChanged: (val) => setState(() => _academicYear = val),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Billing Currency',
                          icon: Icons.payments_rounded,
                          value: _currency,
                          items: const ['INR', 'USD', 'EUR', 'GBP'],
                          onChanged: (val) => setState(() => _currency = val),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'System Timezone',
                          icon: Icons.public_rounded,
                          value: _timezone,
                          items: const ['IST', 'GMT', 'EST', 'PST'],
                          onChanged: (val) => setState(() => _timezone = val),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _gstinController,
                          label: 'GSTIN (Tax ID)',
                          icon: Icons.receipt_long_rounded,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  _buildSectionHeader('Operational Controls'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _gstEnabled,
                          title: Text('Enable GST Calculations', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Apply tax on billing receipts automatically', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                          secondary: Icon(Icons.percent_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          onChanged: (val) => setState(() => _gstEnabled = val),
                        ),
                        Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                        SwitchListTile.adaptive(
                          value: _parentPortal,
                          title: Text('Parent Access Portal', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Allow parent accounts to view fee cards online', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                          secondary: Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          onChanged: (val) => setState(() => _parentPortal = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  _buildSaveButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((opt) => DropdownMenuItem(
        value: opt,
        child: Text(opt, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.darkSurface,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isSaving
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.onPrimaryContainer, strokeWidth: 2))
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}