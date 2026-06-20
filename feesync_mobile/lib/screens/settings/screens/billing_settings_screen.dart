import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../models/app_settings.dart';

class BillingSettingsScreen extends ConsumerStatefulWidget {
  const BillingSettingsScreen({super.key});

  @override
  ConsumerState<BillingSettingsScreen> createState() => _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends ConsumerState<BillingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _gracePeriodController;
  late TextEditingController _lateFineController;
  
  late TextEditingController _earlyPaymentDiscountPercentController;
  late TextEditingController _earlyPaymentDaysController;
  
  late TextEditingController _taxPercentageController;

  int _defaultDueDay = 5;
  bool _autoDueGeneration = true;
  bool _lateFinesEnabled = true;
  bool _partialPaymentsAllowed = true;
  
  bool _earlyPaymentDiscountEnabled = false;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    if (_isInitialized) {
      _gracePeriodController.dispose();
      _lateFineController.dispose();
      _earlyPaymentDiscountPercentController.dispose();
      _earlyPaymentDaysController.dispose();
      _taxPercentageController.dispose();
    }
    super.dispose();
  }

  void _initFields(AppSettings settings) {
    if (_isInitialized) return;
    _gracePeriodController = TextEditingController(
      text: settings.gracePeriodDays.toString(),
    );
    _lateFineController = TextEditingController(
      text: settings.lateFineAmount.toStringAsFixed(0),
    );
    _earlyPaymentDiscountPercentController = TextEditingController(
      text: settings.earlyPaymentDiscountPercent.toStringAsFixed(1),
    );
    _earlyPaymentDaysController = TextEditingController(
      text: settings.earlyPaymentDays.toString(),
    );
    _taxPercentageController = TextEditingController(
      text: settings.taxPercentage.toStringAsFixed(1),
    );

    _defaultDueDay = settings.defaultDueDay;
    _autoDueGeneration = settings.autoDueGeneration;
    _lateFinesEnabled = settings.lateFinesEnabled;
    _partialPaymentsAllowed = settings.partialPaymentsAllowed;
    
    _earlyPaymentDiscountEnabled = settings.earlyPaymentDiscountEnabled;

    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final gracePeriod = _lateFinesEnabled
          ? (int.tryParse(_gracePeriodController.text.trim()) ?? 3)
          : 0;
      final lateFine = _lateFinesEnabled
          ? (double.tryParse(_lateFineController.text.trim()) ?? 0.0)
          : 0.0;
          
      final earlyPaymentPercent = _earlyPaymentDiscountEnabled
          ? (double.tryParse(_earlyPaymentDiscountPercentController.text.trim()) ?? 0.0)
          : 0.0;
      final earlyPaymentDays = _earlyPaymentDiscountEnabled
          ? (int.tryParse(_earlyPaymentDaysController.text.trim()) ?? 0)
          : 0;
      final taxPercentage = double.tryParse(_taxPercentageController.text.trim()) ?? 18.0;

      final updatedData = {
        'default_due_day': _defaultDueDay,
        'grace_period_days': gracePeriod,
        'late_fine_amount': lateFine,
        'auto_due_generation': _autoDueGeneration,
        'late_fines_enabled': _lateFinesEnabled,
        'partial_payments_allowed': _partialPaymentsAllowed,
        'early_payment_discount_enabled': _earlyPaymentDiscountEnabled,
        'early_payment_discount_percent': earlyPaymentPercent,
        'early_payment_days': earlyPaymentDays,
        'tax_percentage': taxPercentage,
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
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fee & Billing Rules',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading settings: $err',
            style: TextStyle(color: AppColors.error),
          ),
        ),
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
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDueDayDropdown(),
                        const SizedBox(height: 8),
                        Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                        SwitchListTile.adaptive(
                          value: _autoDueGeneration,
                          title: Text(
                            'Auto Due Generation',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Generate monthly fee dues automatically on rollover day',
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          secondary: Icon(Icons.autorenew_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _autoDueGeneration = val),
                        ),
                        Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                        SwitchListTile.adaptive(
                          value: _partialPaymentsAllowed,
                          title: Text(
                            'Allow Partial Payments',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Allow parents to pay dues in multiple installments',
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          secondary: Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _partialPaymentsAllowed = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionHeader('Late Fee Penalty Rules'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile.adaptive(
                          value: _lateFinesEnabled,
                          title: Text(
                            'Enable Late Fines',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Apply penalty when fee is paid after due date + grace period',
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          secondary: Icon(Icons.money_off_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _lateFinesEnabled = val),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 16),
                              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                              const SizedBox(height: 16),
                              _buildNumericTextField(
                                controller: _gracePeriodController,
                                label: 'Grace Period (Days)',
                                icon: Icons.timer_rounded,
                                hint: 'e.g. 3',
                                isInteger: true,
                                enabled: _lateFinesEnabled,
                                validator: (val) {
                                  if (!_lateFinesEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Grace period is required';
                                  final parsed = int.tryParse(val.trim());
                                  if (parsed == null) return 'Must be a whole number';
                                  if (parsed < 0) return 'Cannot be negative';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildNumericTextField(
                                controller: _lateFineController,
                                label: 'Late Fine Penalty Amount',
                                icon: Icons.currency_rupee_rounded,
                                hint: 'e.g. 100',
                                isInteger: false,
                                enabled: _lateFinesEnabled,
                                validator: (val) {
                                  if (!_lateFinesEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Late fine amount is required';
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed == null) return 'Must be a numeric value';
                                  if (parsed < 0) return 'Cannot be negative';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          crossFadeState: _lateFinesEnabled
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Early Payment Incentives'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile.adaptive(
                          value: _earlyPaymentDiscountEnabled,
                          title: Text(
                            'Enable Early Payment Discount',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Reward parents for paying fees before the due date',
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          secondary: Icon(Icons.stars_rounded, color: AppColors.primary),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _earlyPaymentDiscountEnabled = val),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 16),
                              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                              const SizedBox(height: 16),
                              _buildNumericTextField(
                                controller: _earlyPaymentDiscountPercentController,
                                label: 'Discount Percentage (%)',
                                icon: Icons.percent_rounded,
                                hint: 'e.g. 5',
                                isInteger: false,
                                enabled: _earlyPaymentDiscountEnabled,
                                validator: (val) {
                                  if (!_earlyPaymentDiscountEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed == null || parsed < 0 || parsed > 100) return 'Invalid percentage';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildNumericTextField(
                                controller: _earlyPaymentDaysController,
                                label: 'Days Before Due Date',
                                icon: Icons.calendar_today_rounded,
                                hint: 'e.g. 7',
                                isInteger: true,
                                enabled: _earlyPaymentDiscountEnabled,
                                validator: (val) {
                                  if (!_earlyPaymentDiscountEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  final parsed = int.tryParse(val.trim());
                                  if (parsed == null || parsed <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          crossFadeState: _earlyPaymentDiscountEnabled
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionHeader('Tax & Compliance'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNumericTextField(
                          controller: _taxPercentageController,
                          label: 'Default Tax/GST Percentage (%)',
                          icon: Icons.account_balance_wallet_rounded,
                          hint: 'e.g. 18.0',
                          isInteger: false,
                          enabled: true,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed < 0 || parsed > 100) return 'Invalid percentage';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Note: Tax is only applied if GST/Tax is enabled in Institution Settings.',
                          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
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

  Widget _buildDueDayDropdown() {
    final List<int> days = List.generate(28, (i) => i + 1);

    // Clamp value to valid range in case of stale data
    final safeValue = days.contains(_defaultDueDay) ? _defaultDueDay : 5;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      items: days.map((d) => DropdownMenuItem(
        value: d,
        child: Text(
          '$d${_getDaySuffix(d)} of the month',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        ),
      )).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _defaultDueDay = val);
      },
      dropdownColor: AppColors.darkSurface,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Default Monthly Due Day',
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(Icons.calendar_month_rounded, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildNumericTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isInteger,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      inputFormatters: isInteger
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.3),
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
        foregroundColor: AppColors.onPrimaryContainer,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isSaving
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.onPrimaryContainer,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}