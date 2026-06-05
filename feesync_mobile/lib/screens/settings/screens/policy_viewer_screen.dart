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
              'Usage details: In-app activities, error reports, and feature configurations.',
            ],
          ),
          const _PolicySection(
            title: '2. How We Use Your Information',
            body: 'We use the collected information to operate and improve the FeeSync system. Specifically, your data helps us to:',
            bullets: [
              'Manage your institution\'s classes, student lists, and monthly collections.',
              'Deliver notifications (WhatsApp, SMS, Email reminders) that you initiate.',
              'Provide secure cloud database backup and multi-device real-time sync.',
              'Troubleshoot bugs and ensure high application stability.',
            ],
          ),
          const _PolicySection(
            title: '3. Row-Level Security & Storage',
            body: 'All student details and payment logs are saved in a secure remote database. Every database row is restricted by Row-Level Security (RLS) policies based on your user ID. This ensures your data is only visible to your authenticated account and remains completely isolated from other schools.',
          ),
          const _PolicySection(
            title: '4. Third-Party Integrations',
            body: 'FeeSync works with reliable third parties to provide essential services:',
            bullets: [
              'Google Play Services: Used for managing app subscription purchases and payments.',
              'Supabase: Provides secure cloud storage, auth systems, and databases.',
              'WhatsApp & SMS Gateways: Used to deliver reminders and payment receipts.',
            ],
          ),
          const _PolicySection(
            title: '5. Your Rights and Control',
            body: 'You retain full control over your school records. You can export student records and payment details to CSV files at any time. You can also request complete account deletion from the Security settings page, which permanently purges all records after 30 days.',
          ),
          const _PolicySection(
            title: '6. Updates and Contacts',
            body: 'We may update this policy periodically. If we make significant changes, we will notify you through an in-app banner. For any questions regarding privacy, reach out to support@feesync.com.',
          ),
        ];

      case 'refund':
        return [
          const _PolicySection(
            title: '1. Google Play Subscriptions',
            body: 'For subscriptions purchased inside the Android mobile app, all transactions are processed securely via Google Play Billing. Refunds for these transactions are subject to Google Play Refund Policies. You can request a refund directly from Google Play within 48 hours of purchase.',
          ),
          const _PolicySection(
            title: '2. Web Dashboard Subscriptions',
            body: 'For plans purchased on the FeeSync web dashboard using Razorpay/UPI/Cards, we offer a hassle-free 7-day money-back guarantee. If you are not satisfied with our service within the first 7 days, you can request a full refund.',
          ),
          const _PolicySection(
            title: '3. Prorated Annual Refunds',
            body: 'Annual plans can be refunded on a prorated basis within the first 14 days of purchase. The refund amount will subtract the cost of standard monthly usage for the active period, plus standard payment processing gateway charges.',
          ),
          const _PolicySection(
            title: '4. Refund Request Process',
            body: 'To request a refund, please follow these methods:',
            bullets: [
              'For Android: Go to your Google Play Account -> Budget and Order History -> Request a refund next to FeeSync.',
              'For Web Dashboard: Email us at support@feesync.com with your institution registration details and the invoice number.',
            ],
          ),
          const _PolicySection(
            title: '5. Account Status After Refund',
            body: 'Upon receiving a refund, your account will immediately revert to the Free tier. If your active student count exceeds the Free plan limit (20 students), you will not be able to add new student records or record payments until you upgrade or delete excess records.',
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
            title: '3. User Accounts & Security',
            body: 'You are responsible for keeping your login credentials confidential and secure. You agree to provide accurate and updated information when setting up your school profile. Any activity under your account is your sole responsibility.',
          ),
          const _PolicySection(
            title: '4. Appropriate Use',
            body: 'You agree to use FeeSync in compliance with all local laws. Specifically, you agree not to:',
            bullets: [
              'Use the notification engine to send spam, unsolicited advertisements, or abusive messages.',
              'Upload malware, corrupted files, or data containing harmful software.',
              'Attempt to breach database row security or circumvent system limitations.',
            ],
          ),
          const _PolicySection(
            title: '5. Subscriptions and Payments',
            body: 'Billing is managed on a monthly or annual cycle. Failure to complete subscription renewals will lead to account restrictions, reversion to the Free tier, and potential read-only limitations.',
          ),
          const _PolicySection(
            title: '6. Limitation of Liability',
            body: 'FeeSync and its developers will not be liable for any indirect, incidental, or consequential damages arising from the use of, or inability to use, this application, including lost collections or communication delivery errors.',
          ),
          const _PolicySection(
            title: '7. Contact Info',
            body: 'For inquiries, legal notices, or feedback regarding these terms, contact us at legal@feesync.com or support@feesync.com.',
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
