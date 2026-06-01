import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/premium_widgets.dart';

class BillingSettingsScreen extends ConsumerStatefulWidget {
  const BillingSettingsScreen({super.key});

  @override
  ConsumerState<BillingSettingsScreen> createState() => _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends ConsumerState<BillingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _gracePeriodController;
  late TextEditingController _lateFineController;
  
  int _defaultDueDay = 5;
  bool _autoDueGeneration = true;
  bool _lateFinesEnabled = true;
  bool _partialPaymentsAllowed = true;
  
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    if (_isInitialized) {
      _gracePeriodController.dispose();
      _lateFineController.dispose();
    }
    super.dispose();
  }

  void _initFields(settings) {
    if (_isInitialized) return;
    _gracePeriodController = TextEditingController(text: settings.gracePeriodDays.toString());
    _lateFineController = TextEditingController(text: settings.lateFineAmount.toStringAsFixed(0));
    
    _defaultDueDay = settings.defaultDueDay;
    _autoDueGeneration = settings.autoDueGeneration;
    _lateFinesEnabled = settings.lateFinesEnabled;
    _partialPaymentsAllowed = settings.partialPaymentsAllowed;
    
    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'default_due_day': _defaultDueDay,
        'grace_period_days': int.tryParse(_gracePeriodController.text) ?? 3,
        'late_fine_amount': double.tryParse(_lateFineController.text) ?? 100.0,
        'auto_due_generation': _autoDueGeneration,
        'late_fines_enabled': _lateFinesEnabled,
        'partial_payments_allowed': _partialPaymentsAllowed,
      };

      await ref.read(settingsProvider.notifier).updateMultipleSettings(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Billing & Fees engine configuration saved!',
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
            content: Text('Failed to update billing settings: $e'),
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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fee & Billing Rules',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err', style: const TextStyle(color: Colors.white))),
        data: (settings) {
          _initFields(settings);
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Billing Cycle & Rollover'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDropdownField(
                          label: 'Default Monthly Due Day',
                          icon: Icons.calendar_month_rounded,
                          value: _defaultDueDay,
                          items: List.generate(28, (i) => i + 1),
                          onChanged: (val) => setState(() => _defaultDueDay = val ?? 5),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          value: _autoDueGeneration,
                          title: Text('Auto Due Generation', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Generate monthly fee dues automatically on rollover day', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                          secondary: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _autoDueGeneration = val),
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.white.withOpacity(0.05), height: 1),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: _partialPaymentsAllowed,
                          title: Text('Allow Partial Payments', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Allow parents to pay dues in multiple installments', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                          secondary: const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _partialPaymentsAllowed = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  _buildSectionHeader('Late Fee Penalty Rules'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _lateFinesEnabled,
                          title: Text('Enable Late Fines', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Apply penalty when fee is paid after due date + grace period', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                          secondary: const Icon(Icons.money_off_rounded, color: AppColors.primary),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _lateFinesEnabled = val),
                        ),
                        if (_lateFinesEnabled) ...[
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withOpacity(0.05), height: 1),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _gracePeriodController,
                            label: 'Grace Period (Days)',
                            icon: Icons.timer_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Grace period is required';
                              if (int.tryParse(val) == null) return 'Must be a whole number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _lateFineController,
                            label: 'Late Fine Penalty Amount',
                            icon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Late fine amount is required';
                              if (double.tryParse(val) == null) return 'Must be a numeric value';
                              return null;
                            },
                          ),
                        ],
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required int value,
    required List<int> items,
    required void Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: items.map((opt) => DropdownMenuItem(
        value: opt,
        child: Text('$opt${_getDaySuffix(opt)} of the month', style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.darkSurface,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}
