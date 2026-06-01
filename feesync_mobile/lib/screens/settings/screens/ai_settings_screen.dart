import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../models/app_settings.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  bool _aiReminders = true;
  bool _aiPredictions = true;
  bool _ocrEnabled = true;
  
  double _confidenceThreshold = 0.8;
  bool _isInitialized = false;
  bool _isSaving = false;

  void _initFields(AppSettings settings) {
    if (_isInitialized) return;
    _aiReminders = settings.aiRemindersEnabled;
    _aiPredictions = settings.aiPredictionsEnabled;
    _ocrEnabled = settings.ocrEnabled;
    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'ai_reminders_enabled': _aiReminders,
        'ai_predictions_enabled': _aiPredictions,
        'ocr_enabled': _ocrEnabled,
      };

      await ref.read(settingsProvider.notifier).updateMultipleSettings(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Engine parameters updated!',
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
            content: Text('Failed to update AI settings: $e'),
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Intelligence',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err', style: const TextStyle(color: AppColors.error))),
        data: (settings) {
          _initFields(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Smart Automations'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _aiReminders,
                        title: Text('Neural Reminders timing', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Analyze parent activity pattern to schedule WhatsApp alerts when they are most active', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _aiReminders = val),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _aiPredictions,
                        title: Text('Payment Defaulter Prediction', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Generate proactive risk metrics for late payments by scanning invoice delay histories', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: const Icon(Icons.online_prediction_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _aiPredictions = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                _buildSectionHeader('Computer Vision'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _ocrEnabled,
                        title: Text('OCR Bank slip scanner', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Extract check numbers, deposit slips & bank logs directly from device camera snapshots', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _ocrEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                _buildSectionHeader('Confidence & Engine Threshold'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Decision confidence rating',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum safety rating needed before AI triggers automated due date alerts or auto adjustments.',
                        style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.outline.withValues(alpha: 0.2),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _confidenceThreshold,
                          min: 0.5,
                          max: 0.95,
                          divisions: 9,
                          onChanged: (val) => setState(() => _confidenceThreshold = val),
                        ),
                      ),
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
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.onPrimaryContainer, strokeWidth: 2))
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}
