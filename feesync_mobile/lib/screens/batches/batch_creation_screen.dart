import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paywall_dialog.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/settings_provider.dart';

class BatchCreationScreen extends ConsumerStatefulWidget {
  final String? batchId;
  const BatchCreationScreen({super.key, this.batchId});

  @override
  ConsumerState<BatchCreationScreen> createState() => _BatchCreationScreenState();
}

class _BatchCreationScreenState extends ConsumerState<BatchCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.batchId != null) {
        _loadBatchData();
      } else {
        // ── Paywall check (create-new mode only) ────────────────────────────
        final data = await ref.read(subscriptionScreenDataProvider.future);
        if (!data.canAddBatch && mounted) {
          await showPaywallDialog(
            context,
            ref,
            trigger: PaywallTrigger.batchLimit,
          );
          if (mounted) context.pop();
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _teacherController.dispose();
    _capacityController.dispose();
    _feeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadBatchData() {
    final batches = ref.read(batchNotifierProvider).value ?? [];
    try {
      final batch = batches.firstWhere((b) => b.id == widget.batchId);
      _nameController.text = batch.name;
      _subjectController.text = batch.subject;
      _teacherController.text = batch.teacherName;
      _capacityController.text = batch.maxCapacity.toString();
      _feeController.text = batch.monthlyFee.toString();
      _selectedColor = batch.colorHex ?? '#2563EB';
      _autoRollNumber = batch.autoRollNumber;
      _collectParentDetails = batch.collectParentDetails;
      _feeType = batch.feeType;
      _useGlobalBilling = batch.useGlobalBilling;
      _customDueDay = batch.customDueDay ?? 5;
      _customAutoDueGeneration = batch.customAutoDueGeneration ?? true;
      
      // Load Schedule
      _selectedDays.clear();
      _daySchedules.clear();
      
      if (batch.schedules.isNotEmpty) {
        for (var s in batch.schedules) {
          _selectedDays.add(s.dayOfWeek);
          final startParts = s.startTime.split(':');
          final endParts = s.endTime.split(':');
          _daySchedules[s.dayOfWeek] = {
            'start': TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
            'end': TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
          };
        }
      } else {
        // Fallback for legacy data
        _selectedDays.addAll(batch.scheduleDays);
        TimeOfDay defaultStart = const TimeOfDay(hour: 16, minute: 0);
        TimeOfDay defaultEnd = const TimeOfDay(hour: 17, minute: 30);
        if (batch.startTime.contains(':')) {
          final parts = batch.startTime.split(':');
          defaultStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        if (batch.endTime.contains(':')) {
          final parts = batch.endTime.split(':');
          defaultEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        for (var day in _selectedDays) {
          _daySchedules[day] = {
            'start': defaultStart,
            'end': defaultEnd,
          };
        }
      }

      setState(() {});
    } catch (_) {
      // batch not found
    }
  }

  // Form Data
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');
  final _feeController = TextEditingController(text: '1000');
  String _selectedColor = '#2563EB';
  String _feeType = 'monthly';
  bool _autoRollNumber = false;
  bool _collectParentDetails = true;
  bool _useGlobalBilling = true;
  int _customDueDay = 5;
  bool _customAutoDueGeneration = true;
  final List<int> _selectedDays = [];
  final Map<int, Map<String, TimeOfDay>> _daySchedules = {};

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _selectTime(int day, bool isStart) async {
    final bool isDark = AppColors.isDarkMode;
    final currentTime = _daySchedules[day]![isStart ? 'start' : 'end']!;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
              hourMinuteColor: isDark ? const Color(0xFF12121F) : const Color(0xFFF1F5F9),
              hourMinuteTextColor: isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A),
              dialBackgroundColor: isDark ? const Color(0xFF12121F) : const Color(0xFFF1F5F9),
              dialHandColor: isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB),
              dialTextColor: isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _daySchedules[day]![isStart ? 'start' : 'end'] = picked;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User profile not found')),
        );
      }
      return;
    }

    try {
      final schedulesJson = _selectedDays.map((day) {
        final times = _daySchedules[day]!;
        final startStr = '${times['start']!.hour.toString().padLeft(2, '0')}:${times['start']!.minute.toString().padLeft(2, '0')}';
        final endStr = '${times['end']!.hour.toString().padLeft(2, '0')}:${times['end']!.minute.toString().padLeft(2, '0')}';
        return {
          'day_of_week': day,
          'start_time': startStr,
          'end_time': endStr,
        };
      }).toList();

      if (widget.batchId == null) {
        final featureGate = await ref.read(featureGateProvider.future);
        if (!featureGate.canAddBatch) {
          if (mounted) {
            await showPaywallDialog(context, ref, trigger: PaywallTrigger.batchLimit);
          }
          return;
        }

        final newBatch = {
          'account_id': userProfile.accountId,
          'name': _nameController.text,
          'subject': _subjectController.text,
          'teacher_name': _teacherController.text,
          'max_capacity': int.tryParse(_capacityController.text) ?? 20,
          'monthly_fee': double.tryParse(_feeController.text) ?? 1000.0,
          'color_hex': _selectedColor,
          'status': 'active',
          'schedules': schedulesJson,
          'schedule_days': _selectedDays.join(','), // Fallback
          'start_time': schedulesJson.isNotEmpty ? schedulesJson.first['start_time'] : '16:00', // Fallback
          'end_time': schedulesJson.isNotEmpty ? schedulesJson.first['end_time'] : '17:30', // Fallback
          'room': 'Room 101',
          'auto_roll_number': _autoRollNumber,
          'collect_parent_details': _collectParentDetails,
          'fee_type': _feeType,
          'use_global_billing': _useGlobalBilling,
          'custom_due_day': _useGlobalBilling ? null : _customDueDay,
          'custom_auto_due_generation': _useGlobalBilling ? null : _customAutoDueGeneration,
          'created_at': DateTime.now().toIso8601String(),
        };
        await ref.read(batchNotifierProvider.notifier).createBatch(newBatch);
        ref.invalidate(activeBatchCountProvider);
        ref.invalidate(subscriptionScreenDataProvider);
        ref.invalidate(featureGateProvider);
        invalidateDashboardAnalytics(ref);
      } else {
        final updatedData = {
          'name': _nameController.text,
          'subject': _subjectController.text,
          'teacher_name': _teacherController.text,
          'max_capacity': int.tryParse(_capacityController.text) ?? 20,
          'monthly_fee': double.tryParse(_feeController.text) ?? 1000.0,
          'color_hex': _selectedColor,
          'schedules': schedulesJson,
          'schedule_days': _selectedDays.join(','), // Fallback
          'start_time': schedulesJson.isNotEmpty ? schedulesJson.first['start_time'] : '16:00', // Fallback
          'end_time': schedulesJson.isNotEmpty ? schedulesJson.first['end_time'] : '17:30', // Fallback
          'auto_roll_number': _autoRollNumber,
          'collect_parent_details': _collectParentDetails,
          'fee_type': _feeType,
          'use_global_billing': _useGlobalBilling,
          'custom_due_day': _useGlobalBilling ? null : _customDueDay,
          'custom_auto_due_generation': _useGlobalBilling ? null : _customAutoDueGeneration,
        };
        await ref.read(batchNotifierProvider.notifier).updateBatch(widget.batchId!, updatedData);
        ref.invalidate(activeBatchCountProvider);
        ref.invalidate(subscriptionScreenDataProvider);
        ref.invalidate(featureGateProvider);
        invalidateDashboardAnalytics(ref);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.batchId == null ? 'Batch created successfully' : 'Batch updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(widget.batchId == null ? 'New Batch' : 'Edit Batch', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: textPrimaryColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(isDark, primaryColor),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(isDark, textPrimaryColor, primaryColor),
                _buildScheduleStep(isDark, textPrimaryColor, primaryColor),
                _buildCapacityFeeStep(isDark, textPrimaryColor, primaryColor),
                _buildSettingsStep(isDark, textPrimaryColor, primaryColor),
                _buildVisualsStep(isDark, textPrimaryColor),
                _buildConfirmationStep(isDark, textPrimaryColor),
              ],
            ),
          ),
          _buildBottomNav(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep(bool isDark, Color textPrimaryColor, Color primaryColor) {
    return _StepWrapper(
      title: 'Basic Information',
      subtitle: 'Identify your coaching batch with a name and teacher.',
      child: Column(
        children: [
          _buildTextField('Batch Name', _nameController, Icons.layers_outlined, isDark, textPrimaryColor, primaryColor),
          const SizedBox(height: 20),
          _buildTextField('Subject / Course', _subjectController, Icons.book_outlined, isDark, textPrimaryColor, primaryColor),
          const SizedBox(height: 20),
          _buildTextField('Teacher Name', _teacherController, Icons.person_outline, isDark, textPrimaryColor, primaryColor),
        ],
      ),
    );
  }

  Widget _buildScheduleStep(bool isDark, Color textPrimaryColor, Color primaryColor) {
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    return _StepWrapper(
      title: 'Schedule Setup',
      subtitle: 'Define when classes will be held.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Select Days',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final isSelected = _selectedDays.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(index);
                            _daySchedules.remove(index);
                          } else {
                            _selectedDays.add(index);
                            // Set default times or reuse first available if any
                            TimeOfDay defaultStart = const TimeOfDay(hour: 16, minute: 0);
                            TimeOfDay defaultEnd = const TimeOfDay(hour: 17, minute: 30);
                            if (_daySchedules.isNotEmpty) {
                              defaultStart = _daySchedules.values.first['start']!;
                              defaultEnd = _daySchedules.values.first['end']!;
                            }
                            _daySchedules[index] = {
                              'start': defaultStart,
                              'end': defaultEnd,
                            };
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ] : null,
                        ),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected 
                                ? (isDark ? const Color(0xFF0F172A) : Colors.white) 
                                : textTertiaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedDays.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Set Timings',
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedDays.map((day) {
              final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
                    child: Text(
                      days[day],
                      style: GoogleFonts.inter(
                        color: textPrimaryColor, 
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(day, true),
                          child: _buildTimePicker('Start', _formatTime(_daySchedules[day]!['start']!), isDark, textPrimaryColor, surfaceColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(day, false),
                          child: _buildTimePicker('End', _formatTime(_daySchedules[day]!['end']!), isDark, textPrimaryColor, surfaceColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCapacityFeeStep(bool isDark, Color textPrimaryColor, Color primaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final settingsAsync = ref.watch(settingsProvider);
    final defaultDueDay = settingsAsync.valueOrNull?.defaultDueDay ?? 5;
    final defaultAutoDue = settingsAsync.valueOrNull?.autoDueGeneration ?? true;

    return _StepWrapper(
      title: 'Capacity & Fees',
      subtitle: 'Set enrollment limits and fee structure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypableNumberInput('Maximum Students', _capacityController, Icons.group_outlined, isDark, textPrimaryColor, primaryColor),
          const SizedBox(height: 24),
          _buildTypableNumberInput('Fee Amount (₹)', _feeController, Icons.payments_outlined, isDark, textPrimaryColor, primaryColor),
          const SizedBox(height: 24),
          Text(
            'Fee Frequency',
            style: GoogleFonts.inter(
              color: textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChoiceChip('Monthly', _feeType == 'monthly', () => setState(() => _feeType = 'monthly'), isDark, primaryColor),
              const SizedBox(width: 8),
              _buildChoiceChip('Quarterly', _feeType == 'quarterly', () => setState(() => _feeType = 'quarterly'), isDark, primaryColor),
              const SizedBox(width: 8),
              _buildChoiceChip('Course Wise', _feeType == 'course_wise', () => setState(() => _feeType = 'course_wise'), isDark, primaryColor),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Billing & Rollover Rules',
            style: GoogleFonts.inter(
              color: textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Global Settings',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimaryColor, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Apply institution default billing rules.',
                            style: GoogleFonts.inter(color: textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useGlobalBilling,
                      activeThumbColor: primaryColor,
                      onChanged: (val) => setState(() => _useGlobalBilling = val),
                    ),
                  ],
                ),
                if (_useGlobalBilling) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Default: Due on the ${defaultDueDay}th of the month. Auto-Rollover is ${defaultAutoDue ? 'ON' : 'OFF'}.',
                            style: GoogleFonts.inter(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'Custom Due Day',
                    style: GoogleFonts.inter(color: textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _customDueDay,
                    items: List.generate(28, (i) => i + 1).map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('$d of the month', style: GoogleFonts.inter(color: textPrimaryColor, fontSize: 14)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _customDueDay = val);
                    },
                    dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Auto Generate Dues (Rollover)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimaryColor, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: _customAutoDueGeneration,
                        activeThumbColor: primaryColor,
                        onChanged: (val) => setState(() => _customAutoDueGeneration = val),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap, bool isDark, Color primaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected 
                  ? (isDark ? const Color(0xFF0F172A) : Colors.white) 
                  : textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypableNumberInput(String label, TextEditingController controller, IconData icon, bool isDark, Color textPrimaryColor, Color primaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textTertiaryColor, size: 20),
            hintText: 'Enter value',
            hintStyle: TextStyle(color: textTertiaryColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualsStep(bool isDark, Color textPrimaryColor) {
    return _StepWrapper(
      title: 'Visual Identity',
      subtitle: 'Pick a theme color for the batch card.',
      child: Column(
        children: [
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                '#2563EB', '#7C3AED', '#DB2777', '#EA580C', '#16A34A', '#0891B2'
              ].map((color) {
                final isSelected = _selectedColor.toUpperCase() == color.toUpperCase();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: textPrimaryColor, width: 3) : null,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStep(bool isDark, Color textPrimaryColor, Color primaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    return _StepWrapper(
      title: 'Batch Settings',
      subtitle: 'Configure roll number generation and parent contact requirements.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Generate Roll Numbers',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimaryColor, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatically assign roll numbers when adding students.',
                        style: GoogleFonts.inter(color: textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoRollNumber,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => setState(() => _autoRollNumber = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collect Parent Details',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimaryColor, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Turn this OFF for adult students (e.g., Yoga class) to use the student\'s own phone number for due alerts and communication.',
                        style: GoogleFonts.inter(color: textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _collectParentDetails,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => setState(() => _collectParentDetails = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(bool isDark, Color textPrimaryColor) {
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    return _StepWrapper(
      title: 'Review & Confirm',
      subtitle: 'Verify the batch details before creating.',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            _buildReviewRow('Batch', _nameController.text, isDark, textPrimaryColor),
            _buildReviewRow('Subject', _subjectController.text, isDark, textPrimaryColor),
            _buildReviewRow('Teacher', _teacherController.text, isDark, textPrimaryColor),
            _buildReviewRow('Schedule', _selectedDays.isEmpty 
              ? 'Not set' 
              : '${_selectedDays.length} days selected (Various timings)', isDark, textPrimaryColor),
            _buildReviewRow('Capacity', '${_capacityController.text} Students', isDark, textPrimaryColor),
            _buildReviewRow('Fee', '₹${_feeController.text} (${_feeType == 'monthly' ? 'Monthly' : 'Course-wise'})', isDark, textPrimaryColor),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI: No schedule clashes detected.',
                      style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, Color primaryColor) {
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
                style: TextButton.styleFrom(
                  foregroundColor: textTertiaryColor,
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(
                _currentStep == 5 ? (widget.batchId == null ? 'Create Batch' : 'Save Changes') : 'Next Step',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, Color textPrimaryColor, Color primaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(color: textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: textPrimaryColor, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textTertiaryColor, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, String time, bool isDark, Color textPrimaryColor, Color surfaceColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondaryColor, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Text(time, style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
              Icon(Icons.arrow_drop_down_rounded, color: textTertiaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, bool isDark, Color textPrimaryColor) {
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondaryColor, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                color: textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            child,
          ],
        ),
      ),
    );
  }
}
