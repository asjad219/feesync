import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../models/app_settings.dart';
import '../widgets/premium_widgets.dart';

class AutomationSettingsScreen extends ConsumerStatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  ConsumerState<AutomationSettingsScreen> createState() => _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends ConsumerState<AutomationSettingsScreen> {
  bool _whatsappEnabled = true;
  bool _smsFallbackEnabled = true;
  bool _autoReceiptEnabled = true;
  
  bool _isInitialized = false;
  bool _isSaving = false;

  void _initFields(AppSettings settings) {
    if (_isInitialized) return;
    _whatsappEnabled = settings.whatsappEnabled;
    _smsFallbackEnabled = settings.smsFallbackEnabled;
    _autoReceiptEnabled = settings.autoReceiptEnabled;
    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'whatsapp_enabled': _whatsappEnabled,
        'sms_fallback_enabled': _smsFallbackEnabled,
        'auto_receipt_enabled': _autoReceiptEnabled,
      };

      await ref.read(settingsProvider.notifier).updateMultipleSettings(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Automation & Notification rules updated!',
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
            content: Text('Failed to save rules: $e'),
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
        error: (err, stack) => Center(child: Text('Error loading settings: $err', style: TextStyle(color: AppColors.error))),
        data: (settings) {
          _initFields(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('WhatsApp Business API'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF10B981), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Meta Cloud Gateway',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Shared Official API Channel',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                GlowingStatusDot(color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        value: _whatsappEnabled,
                        title: Text('WhatsApp Notifications', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Send invoices, late alerts, and receipts directly to parents', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _whatsappEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                _buildSectionHeader('Alternative Delivery & Backup'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _smsFallbackEnabled,
                        title: Text('SMS Fallback Delivery', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Auto-route via transactional SMS if WhatsApp delivery fails', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: Icon(Icons.sms_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _smsFallbackEnabled = val),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _autoReceiptEnabled,
                        title: Text('Auto Receipt Sharing', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Instantly issue & share PDF receipts on payment success', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _autoReceiptEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                _buildSectionHeader('Message Templates (Read-only)'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildTemplateTile('fees_due_reminder', 'Fee Dues Reminder', 'Hi [Parent], fee of ₹[Amount] is due for [Student]...'),
                      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                      _buildTemplateTile('payment_received', 'Payment Confirmed', 'Dear Parent, payment of ₹[Amount] received for [Student]...'),
                      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                      _buildTemplateTile('overdue_escalation', 'Overdue Escalation', 'URGENT: Fee for [Student] has been overdue for [Days] days...'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                
                _buildSaveButton(),
                const SizedBox(height: 32),
              ],
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

  Widget _buildTemplateTile(String id, String name, String snippet) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'APPROVED',
              style: GoogleFonts.inter(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          snippet,
          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: Icon(Icons.description_rounded, color: AppColors.textTertiary),
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