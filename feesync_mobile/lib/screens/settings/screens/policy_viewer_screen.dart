import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String type; // 'terms' | 'privacy' | 'refund'

  const PolicyViewerScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = _getTitle();
    final content = _getContent();

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
          title,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last updated: June 2026',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                color: AppColors.outline.withValues(alpha: 0.1),
                height: 1,
              ),
              const SizedBox(height: 20),
              ...content.map((section) => _buildSection(section)),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case 'privacy':
        return 'Privacy Policy';
      case 'refund':
        return 'Refund Policy';
      default:
        return 'Terms of Service';
    }
  }

  IconData _getIcon() {
    switch (type) {
      case 'privacy':
        return Icons.privacy_tip_rounded;
      case 'refund':
        return Icons.monetization_on_rounded;
      default:
        return Icons.gavel_rounded;
    }
  }

  Widget _buildSection(_PolicySection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (section.bullets != null && section.bullets!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...section.bullets!.map((bullet) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bullet,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  List<_PolicySection> _getContent() {
    switch (type) {
      case 'privacy':
        return [
          const _PolicySection(
            title: '1. Information We Collect',
            body: 'We collect information you provide directly to us when creating an account, setting up your institution, or adding students and payments. This includes:',
            bullets: [
              'Account information: Your full name, business name, and email address.',
              'Operational data: Names of your student records, fees structure, and payment logs.',
            ],
          ),
          const _PolicySection(
            title: '2. How We Use Your Information',
            body: 'We use the collected information to operate and improve the FeeSync system. Specifically, your data helps us to:',
            bullets: [
              'Manage your institution\'s records and fee collections.',
              'Deliver notifications (WhatsApp, SMS, Email reminders) that you initiate.',
              'Provide secure cloud database backup and synchronization.',
            ],
          ),
          const _PolicySection(
            title: '3. Data Storage and Security',
            body: 'All details and payment logs are saved securely. We utilize Supabase with Row-Level Security (RLS) policies based on your authenticated user ID. This ensures your data remains completely isolated and is only visible to your account.',
          ),
          const _PolicySection(
            title: '4. Third-Party Services',
            body: 'FeeSync integrates with reliable third parties to provide essential services:',
            bullets: [
              'Google Play Services: Used for managing app subscription purchases.',
              'Supabase: Provides secure cloud storage, authentication systems, and databases.',
              'Messaging Gateways: Used to deliver reminders and payment receipts.',
            ],
          ),
          const _PolicySection(
            title: '5. Data Retention and Deletion',
            body: 'You retain control over your records and can export them to CSV files. You can request complete account deletion from the Security settings page, which permanently purges all records within 30 days.',
          ),
          const _PolicySection(
            title: '6. Contact Us',
            body: 'For privacy concerns or questions regarding our policy, reach out to artexplore764@gmail.com.',
          ),
        ];

      case 'refund':
        return [
          const _PolicySection(
            title: '1. Android App Subscriptions',
            body: 'For subscriptions purchased inside the Android mobile app, all transactions are processed securely via Google Play Billing. Refunds for these transactions are subject to Google Play Refund Policies. You can request a refund directly from Google Play within 48 hours of purchase.',
          ),
          const _PolicySection(
            title: '2. Web Dashboard Subscriptions',
            body: 'Direct web-based subscription payments are currently in development (coming soon). Once activated, refunds for web purchases will be governed by a 7-day money-back guarantee.',
          ),
          const _PolicySection(
            title: '3. Prorated Annual Refunds',
            body: 'Annual plans purchased directly (non-Google Play) may be refunded on a prorated basis within 14 days, minus gateway charges.',
          ),
          const _PolicySection(
            title: '4. Account Status After Refund',
            body: 'Upon refund, the account reverts to the Free plan. If your active student count exceeds the Free plan limit (20 students), you will not be able to add new records until you upgrade or delete excess records.',
          ),
          const _PolicySection(
            title: '5. Contact for Refunds',
            body: 'For refund inquiries, please email artexplore764@gmail.com with your institution registration details.',
          ),
        ];

      default: // 'terms'
        return [
          const _PolicySection(
            title: '1. Acceptance of Terms',
            body: 'By creating a FeeSync account, you agree to comply with and be bound by these Terms of Service. If you do not agree, please do not use the application.',
          ),
          const _PolicySection(
            title: '2. Description of Service',
            body: 'FeeSync is a school fee management system designed to track student tuition payments, send automatic receipts, generate reminders, and manage fee cycles. The service is provided on an "as is" and "as available" basis.',
          ),
          const _PolicySection(
            title: '3. User Responsibilities',
            body: 'You are responsible for keeping your login credentials confidential and secure. You agree to provide accurate information when setting up your profile.',
          ),
          const _PolicySection(
            title: '4. Acceptable Use',
            body: 'You agree to use FeeSync in compliance with all local laws. Specifically, you agree not to:',
            bullets: [
              'Use the notification engine to send spam, unsolicited advertisements, or abusive messages.',
              'Upload malware or corrupted files.',
              'Attempt to circumvent system limitations or security mechanisms.',
            ],
          ),
          const _PolicySection(
            title: '5. Subscriptions and Billing',
            body: 'FeeSync offers Free, Starter, Growth, and Institute plans. Failure to renew paid subscriptions will restrict access back to Free tier limits.',
          ),
          const _PolicySection(
            title: '6. Service Availability',
            body: 'We do not guarantee 100% uptime and the service may occasionally experience maintenance windows.',
          ),
          const _PolicySection(
            title: '7. Limitation of Liability',
            body: 'FeeSync and its developers will not be liable for any indirect, incidental, or consequential damages arising from the use of this application, including lost collections or communication delivery errors.',
          ),
          const _PolicySection(
            title: '8. Termination',
            body: 'We reserve the right to suspend or terminate accounts that violate these Terms of Service.',
          ),
          const _PolicySection(
            title: '9. Governing Law',
            body: 'These terms are governed by the laws of India.',
          ),
          const _PolicySection(
            title: '10. Contact Info',
            body: 'For legal inquiries, contact us at artexplore764@gmail.com.',
          ),
        ];
    }
  }
}

class _PolicySection {
  final String title;
  final String body;
  final List<String>? bullets;

  const _PolicySection({
    required this.title,
    required this.body,
    this.bullets,
  });
}
