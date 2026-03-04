import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../data/providers/notification_providers.dart';

/// Notifications Sheet — displays real-time notifications from the backend.
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(context, ref, error),
        data: (notifications) =>
            _NotificationsContent(notifications: notifications),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Could not load notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(notificationsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsContent extends ConsumerWidget {
  final List<NotificationModel> notifications;

  const _NotificationsContent({required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount new',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: unreadCount > 0
                    ? () => ref.read(notificationsProvider.notifier).markAllAsRead()
                    : null,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: unreadCount > 0
                        ? AppColors.secondary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notifications List
        Expanded(
          child: notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => ref
                            .read(notificationsProvider.notifier)
                            .deleteNotification(notification.id),
                        child: _NotificationCard(notification: notification),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We'll notify you when something happens",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref
              .read(notificationsProvider.notifier)
              .markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.inputFill
                : AppColors.secondary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ref
                        .read(notificationsProvider.notifier)
                        .markAsRead(notification.id),
                    child: const Icon(
                      Icons.done_all,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'BOOKING_UPDATE':
        return Icons.calendar_today;
      case 'ORDER_STATUS':
        return Icons.shopping_bag;
      case 'PAYMENT_EVENT':
        return Icons.payment;
      case 'SUBSCRIPTION_STATUS':
        return Icons.card_membership;
      case 'ADMIN_ALERT':
        return Icons.admin_panel_settings;
      case 'SYSTEM_WARNING':
        return Icons.info_outline;
      case 'ADOPTION_REQUEST':
      case 'ADOPTION_APPROVED':
        return Icons.pets;
      case 'REVIEW':
        return Icons.star_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'BOOKING_UPDATE':
        return AppColors.secondary;
      case 'ORDER_STATUS':
        return AppColors.warning;
      case 'PAYMENT_EVENT':
        return AppColors.success;
      case 'SUBSCRIPTION_STATUS':
        return AppColors.primary;
      case 'ADMIN_ALERT':
      case 'SYSTEM_WARNING':
        return AppColors.error;
      case 'ADOPTION_REQUEST':
      case 'ADOPTION_APPROVED':
        return AppColors.secondary;
      case 'REVIEW':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
