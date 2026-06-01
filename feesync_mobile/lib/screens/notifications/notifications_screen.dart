import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(
          'Activity Log',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
            icon: Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) return _EmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification.status != NotificationStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.surfaceContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? Colors.white.withValues(alpha: 0.02)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onLongPress: () => _showOptions(context, ref),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTitle(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (notification.studentFullName != 'N/A') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Student: ${notification.studentFullName}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (notification.type) {
      case NotificationType.paymentReminder:
        return 'Payment Reminder';
      case NotificationType.paymentConfirmation:
        return 'Payment Confirmation';
      case NotificationType.welcome:
        return 'Welcome';
      case NotificationType.feeUpdate:
        return 'Fee Update';
    }
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    
    switch (notification.type) {
      case NotificationType.paymentReminder:
        icon = Icons.alarm_rounded;
        color = AppColors.pending;
        break;
      case NotificationType.paymentConfirmation:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case NotificationType.welcome:
        icon = Icons.handshake_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.feeUpdate:
        icon = Icons.info_rounded;
        color = Colors.blue;
        break;
    }

    if (notification.channel == NotificationChannel.sms || notification.channel == NotificationChannel.both) {
       // Optional: customize icon based on channel
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(date);
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notification.status == NotificationStatus.pending)
                ListTile(
                  leading: Icon(Icons.done_all_rounded, color: AppColors.success),
                  title: const Text('Mark as Sent'),
                  onTap: () {
                    ref.read(notificationNotifierProvider.notifier).markAsSent(notification.id);
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Delete Log Entry'),
                onTap: () {
                  ref.read(notificationNotifierProvider.notifier).deleteNotification(notification.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 24),
          Text(
            'No new activity',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity logs will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}