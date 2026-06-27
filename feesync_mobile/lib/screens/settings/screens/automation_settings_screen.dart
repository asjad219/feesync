import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/error_dialog.dart';
import '../../../models/app_settings.dart';

// ── Template definition ──────────────────────────────────────────────────────

class _TemplateInfo {
  final String key;
  final String title;
  final String triggerLabel;
  final IconData icon;
  final Color color;
  final List<String> availableVars;

  const _TemplateInfo({
    required this.key,
    required this.title,
    required this.triggerLabel,
    required this.icon,
    required this.color,
    required this.availableVars,
  });
}

const _templates = [
  _TemplateInfo(
    key: 'fee_reminder',
    title: 'Fee Due Reminder',
    triggerLabel: 'Sent X days before due date',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFFF59E0B),
    availableVars: [
      '{parent_name}',
      '{student_name}',
      '{amount}',
      '{due_date}',
      '{school_name}',
    ],
  ),
  _TemplateInfo(
    key: 'payment_receipt',
    title: 'Payment Received',
    triggerLabel: 'Sent instantly on payment success',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF10B981),
    availableVars: [
      '{parent_name}',
      '{student_name}',
      '{amount}',
      '{receipt_no}',
      '{school_name}',
    ],
  ),
  _TemplateInfo(
    key: 'overdue_notice',
    title: 'Overdue Escalation',
    triggerLabel: 'Sent when fee crosses due date',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFEF4444),
    availableVars: [
      '{parent_name}',
      '{student_name}',
      '{amount}',
      '{days_overdue}',
      '{school_name}',
    ],
  ),
  _TemplateInfo(
    key: 'late_fine_applied',
    title: 'Late Fine Applied',
    triggerLabel: 'Sent when late fine is charged',
    icon: Icons.money_off_rounded,
    color: Color(0xFFEC4899),
    availableVars: [
      '{parent_name}',
      '{student_name}',
      '{amount}',
      '{fine_amount}',
      '{school_name}',
    ],
  ),
  _TemplateInfo(
    key: 'new_fee_generated',
    title: 'New Fee Generated',
    triggerLabel: 'Sent on monthly auto-rollover',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFF8B5CF6),
    availableVars: [
      '{parent_name}',
      '{student_name}',
      '{amount}',
      '{due_date}',
      '{school_name}',
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AutomationSettingsScreen extends ConsumerStatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  ConsumerState<AutomationSettingsScreen> createState() =>
      _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState
    extends ConsumerState<AutomationSettingsScreen> {
  // Notification channels
  bool _whatsappEnabled = true;
  bool _smsFallbackEnabled = true;

  // Receipts
  bool _autoReceiptEnabled = true;

  // Reminder triggers
  bool _sendOnDueDate = true;
  bool _sendOverdueAlert = true;
  int _reminderDaysBefore = 3;

  // Template controllers — keyed by _TemplateInfo.key
  final Map<String, TextEditingController> _tplControllers = {};

  // Which template card is expanded
  String? _expandedTemplate;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _tplControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFields(AppSettings s) {
    if (_isInitialized) return;

    _whatsappEnabled = s.whatsappEnabled;
    _smsFallbackEnabled = s.smsFallbackEnabled;
    _autoReceiptEnabled = s.autoReceiptEnabled;
    _sendOnDueDate = s.aiRemindersEnabled;
    _sendOverdueAlert = s.aiRemindersEnabled;
    _reminderDaysBefore = s.reminderDaysBefore;

    _tplControllers['fee_reminder'] =
        TextEditingController(text: s.tplFeeReminder);
    _tplControllers['payment_receipt'] =
        TextEditingController(text: s.tplPaymentReceipt);
    _tplControllers['overdue_notice'] =
        TextEditingController(text: s.tplOverdueNotice);
    _tplControllers['late_fine_applied'] =
        TextEditingController(text: s.tplLateFineApplied);
    _tplControllers['new_fee_generated'] =
        TextEditingController(text: s.tplNewFeeGenerated);

    _isInitialized = true;
  }

  String _getDbKey(String tplKey) => 'tpl_$tplKey';

  Future<void> _saveSettings() async {
    // Validate all templates are non-empty
    for (final entry in _tplControllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template "${_templates.firstWhere((t) => t.key == entry.key).title}" cannot be empty.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _expandedTemplate = entry.key);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'whatsapp_enabled': _whatsappEnabled,
        'sms_fallback_enabled': _smsFallbackEnabled,
        'auto_receipt_enabled': _autoReceiptEnabled,
        'ai_reminders_enabled': _sendOnDueDate || _sendOverdueAlert,
        'reminder_days_before': _reminderDaysBefore,
      };

      // Add all template texts
      for (final entry in _tplControllers.entries) {
        data[_getDbKey(entry.key)] = entry.value.text.trim();
      }

      await ref.read(settingsProvider.notifier).updateMultipleSettings(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Communication settings & templates saved!',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.onSuccess,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetTemplate(String key, String defaultText) {
    _tplControllers[key]?.text = defaultText;
    setState(() {});
  }

  void _insertVariable(String key, String variable) {
    final controller = _tplControllers[key];
    if (controller == null) return;
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, variable);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + variable.length),
    );
    setState(() {});
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
          'Communications & Sync',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (settings) {
          _initFields(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [




                // ── Reminder Triggers ─────────────────────────────────────────
                _sectionHeader('Reminder Triggers'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _switchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Due Date Reminder',
                        subtitle: 'Notify parents when a fee is approaching',
                        value: _sendOnDueDate,
                        enabled: false,
                        onChanged: null,
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Send reminder this many days before due date:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _reminderDaysPicker(),
                            const SizedBox(height: 12),
                          ],
                        ),
                        crossFadeState: _sendOnDueDate
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                      _divider(),
                      _switchTile(
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Overdue Escalation Alert',
                        subtitle:
                            'Alert parents when fee passes due date unpaid',
                        value: _sendOverdueAlert,
                        enabled: false,
                        onChanged: null,
                      ),
                    ],
                  ),
                ),
                if (!_sendOnDueDate && !_sendOverdueAlert) ...[
                  const SizedBox(height: 8),
                  _infoBanner(
                    'All reminders are off — parents will receive no automated alerts.',
                    icon: Icons.warning_amber_rounded,
                    isWarning: true,
                  ),
                ],
                const SizedBox(height: 28),

                // ── Message Templates ─────────────────────────────────────────
                _sectionHeader('Message Templates'),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 14),
                  child: Text(
                    'Tap a template to edit. Use variable chips to insert dynamic values.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                ..._templates.map((tpl) => _buildTemplateCard(tpl)),

                const SizedBox(height: 36),
                _saveButton(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Template card ─────────────────────────────────────────────────────────
  Widget _buildTemplateCard(_TemplateInfo tpl) {
    final controller = _tplControllers[tpl.key];
    if (controller == null) return const SizedBox.shrink();

    final isExpanded = _expandedTemplate == tpl.key;
    final hasContent = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (always visible) ────────────────────────────────────
            InkWell(
              onTap: () => setState(() =>
                  _expandedTemplate = isExpanded ? null : tpl.key),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tpl.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tpl.icon, color: tpl.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tpl.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tpl.triggerLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Preview badge / expand indicator
                    if (!isExpanded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasContent
                              ? tpl.color.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasContent ? 'SET' : 'EMPTY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: hasContent ? tpl.color : AppColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded body ──────────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: AppColors.outline.withValues(alpha: 0.12),
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Variable chips
                        Text(
                          'INSERT VARIABLE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tpl.availableVars
                              .map((v) => _varChip(tpl.key, v, tpl.color))
                              .toList(),
                        ),
                        const SizedBox(height: 16),

                        // Text editor
                        Text(
                          'MESSAGE TEXT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller,
                          maxLines: 5,
                          minLines: 3,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your message…',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: tpl.color,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                AppColors.surfaceContainer.withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        // Character count + reset
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${controller.text.length} characters',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _resetTemplate(
                                tpl.key,
                                _defaultTextFor(tpl.key),
                              ),
                              icon: Icon(Icons.refresh_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary),
                              label: Text(
                                'Reset to default',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),

                        // Live preview
                        const SizedBox(height: 12),
                        _livePreview(controller.text, tpl.color),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _varChip(String tplKey, String variable, Color color) {
    return GestureDetector(
      onTap: () => _insertVariable(tplKey, variable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              variable,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _livePreview(String text, Color accentColor) {
    // Replace variables with sample values for preview
    final preview = text
        .replaceAll('{parent_name}', 'Rajesh Kumar')
        .replaceAll('{student_name}', 'Aarav Kumar')
        .replaceAll('{amount}', '₹2,500')
        .replaceAll('{due_date}', '10 Jun 2026')
        .replaceAll('{school_name}', 'FeeSync Academy')
        .replaceAll('{receipt_no}', 'RC-20260604')
        .replaceAll('{days_overdue}', '3')
        .replaceAll('{fine_amount}', '₹100');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_rounded,
                  size: 12, color: accentColor.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'LIVE PREVIEW',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: accentColor.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview.isEmpty ? 'Start typing to see preview…' : preview,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: preview.isEmpty
                  ? AppColors.textHint
                  : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _defaultTextFor(String key) {
    const defaults = {
      'fee_reminder':
          'Hi {parent_name}, this is a reminder that a fee of ₹{amount} is due for {student_name} on {due_date}. Please pay on time to avoid late charges. — {school_name}',
      'payment_receipt':
          'Dear {parent_name}, we have received ₹{amount} for {student_name} (Receipt #{receipt_no}). Thank you for your timely payment. — {school_name}',
      'overdue_notice':
          'URGENT: The fee of ₹{amount} for {student_name} is overdue by {days_overdue} day(s). Please clear the dues immediately to avoid further penalties. — {school_name}',
      'late_fine_applied':
          'Dear {parent_name}, a late fine of ₹{fine_amount} has been applied to {student_name}\'s account as the fee was not paid within the grace period. Total due: ₹{amount}. — {school_name}',
      'new_fee_generated':
          'Dear {parent_name}, a new monthly fee of ₹{amount} has been generated for {student_name} due on {due_date}. — {school_name}',
    };
    return defaults[key] ?? '';
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _reminderDaysPicker() {
    const options = [1, 2, 3, 5, 7, 10];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((d) {
        final sel = _reminderDaysBefore == d;
        return GestureDetector(
          onTap: () => setState(() => _reminderDaysBefore = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel
                    ? AppColors.primary
                    : AppColors.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              '$d ${d == 1 ? 'day' : 'days'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel
                    ? AppColors.onPrimaryContainer
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SwitchListTile.adaptive(
        value: value,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 52, top: 2),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
                color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
        activeThumbColor: AppColors.primary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1);

  Widget _infoBanner(String text,
      {required IconData icon, bool isWarning = false}) {
    final color = isWarning ? const Color(0xFFF59E0B) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );

  Widget _saveButton() => ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
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
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
      );
}