import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/user_provider.dart';

class BatchCreationScreen extends ConsumerStatefulWidget {
  const BatchCreationScreen({super.key});

  @override
  ConsumerState<BatchCreationScreen> createState() => _BatchCreationScreenState();
}

class _BatchCreationScreenState extends ConsumerState<BatchCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Data
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');
  final _feeController = TextEditingController(text: '1000');
  String _selectedColor = '#2563EB';
  String _feeType = 'monthly';
  final List<int> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 30);

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surfaceContainerHigh,
              hourMinuteColor: AppColors.surfaceContainerLow,
              hourMinuteTextColor: Colors.white,
              dialBackgroundColor: AppColors.surfaceContainerLow,
              dialHandColor: AppColors.primary,
              dialTextColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
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

    // Implement creation logic
    final newBatch = {
      'account_id': userProfile.accountId,
      'name': _nameController.text,
      'subject': _subjectController.text,
      'teacher_name': _teacherController.text,
      'max_capacity': int.tryParse(_capacityController.text) ?? 20,
      'monthly_fee': double.tryParse(_feeController.text) ?? 1000.0,
      'color_hex': _selectedColor,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await ref.read(batchNotifierProvider.notifier).createBatch(newBatch);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('New Batch'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildScheduleStep(),
                _buildCapacityFeeStep(),
                _buildVisualsStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
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

  Widget _buildBasicInfoStep() {
    return _StepWrapper(
      title: 'Basic Information',
      subtitle: 'Identify your coaching batch with a name and teacher.',
      child: Column(
        children: [
          _buildTextField('Batch Name', _nameController, Icons.layers_outlined),
          const SizedBox(height: 20),
          _buildTextField('Subject / Course', _subjectController, Icons.book_outlined),
          const SizedBox(height: 20),
          _buildTextField('Teacher Name', _teacherController, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return _StepWrapper(
      title: 'Schedule Setup',
      subtitle: 'Define when classes will be held.',
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Select Days',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                          } else {
                            _selectedDays.add(index);
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ] : null,
                        ),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.black : Colors.white,
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
          GestureDetector(
            onTap: () => _selectTime(true),
            child: _buildTimePicker('Start Time', _formatTime(_startTime)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _selectTime(false),
            child: _buildTimePicker('End Time', _formatTime(_endTime)),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityFeeStep() {
    return _StepWrapper(
      title: 'Capacity & Fees',
      subtitle: 'Set enrollment limits and fee structure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypableNumberInput('Maximum Students', _capacityController, Icons.group_outlined),
          const SizedBox(height: 24),
          _buildTypableNumberInput('Fee Amount (₹)', _feeController, Icons.payments_outlined),
          const SizedBox(height: 24),
          Text(
            'Fee Frequency',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChoiceChip('Monthly', _feeType == 'monthly', () => setState(() => _feeType = 'monthly')),
              const SizedBox(width: 12),
              _buildChoiceChip('Course Wise', _feeType == 'course_wise', () => setState(() => _feeType = 'course_wise')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypableNumberInput(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            hintText: 'Enter value',
          ),
        ),
      ],
    );
  }

  Widget _buildVisualsStep() {
    return _StepWrapper(
      title: 'Visual Identity',
      subtitle: 'Pick a theme color for the batch card.',
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              '#2563EB', '#7C3AED', '#DB2777', '#EA580C', '#16A34A', '#0891B2'
            ].map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return _StepWrapper(
      title: 'Review & Confirm',
      subtitle: 'Verify the batch details before creating.',
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildReviewRow('Batch', _nameController.text),
            _buildReviewRow('Subject', _subjectController.text),
            _buildReviewRow('Teacher', _teacherController.text),
            _buildReviewRow('Schedule', _selectedDays.isEmpty 
              ? 'Not set' 
              : '${_selectedDays.length} days (${_formatTime(_startTime)} - ${_formatTime(_endTime)})'),
            _buildReviewRow('Capacity', '${_capacityController.text} Students'),
            _buildReviewRow('Fee', '₹${_feeController.text} (${_feeType == 'monthly' ? 'Monthly' : 'Course-wise'})'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI: No schedule clashes detected.',
                      style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
                child: const Text('Back'),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: Text(_currentStep == 4 ? 'Create Batch' : 'Next Step'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, String time) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Row(
            children: [
              Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_drop_down, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
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
