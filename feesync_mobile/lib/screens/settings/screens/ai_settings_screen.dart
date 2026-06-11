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
  bool _aiPredictions = true;
  bool _smartFormatting = true;
  
  bool _isInitialized = false;
  bool _isSaving = false;

  void _initFields(AppSettings settings) {
    if (_isInitialized) return;
    _aiPredictions = settings.aiPredictionsEnabled;
    _smartFormatting = settings.ocrEnabled; // Repurposed unused OCR boolean for smart formatting
    
    _isInitialized = true;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'ai_predictions_enabled': _aiPredictions,
        'ocr_enabled': _smartFormatting,
      };

      await ref.read(settingsProvider.notifier).updateMultipleSettings(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Smart features updated!',
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
          'Smart Features',
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
                _buildSectionHeader('Automated Analysis'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _aiPredictions,
                        title: Text('Defaulter Risk Profiling', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Automatically analyze pending balances to flag High Risk and Medium Risk accounts in the student list.', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: Icon(Icons.online_prediction_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _aiPredictions = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                _buildSectionHeader('Data Integrity Engine'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _smartFormatting,
                        title: Text('Smart Auto-Capitalization', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Automatically correct lowercase letters and format names to Title Case during student data entry to keep records clean.', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                        secondary: Icon(Icons.text_format_rounded, color: AppColors.primary),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _smartFormatting = val),
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
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.onPrimaryContainer, strokeWidth: 2))
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}