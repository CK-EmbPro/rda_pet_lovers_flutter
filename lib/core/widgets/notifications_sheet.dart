import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Notification model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // appointment, order, message, system
  final DateTime createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}

/// Mock notifications
final List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: '1',
    title: 'Appointment Confirmed',
    message: 'Your appointment with Dr. Telesifori has been confirmed for tomorrow at 10:00 AM',
    type: 'appointment',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  NotificationItem(
    id: '2',
    title: 'Order Shipped',
    message: 'Your order #12345 from Pawfect Bites has been shipped',
    type: 'order',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  NotificationItem(
    id: '3',
    title: 'New Message',
    message: 'You have a new message from Pet Paradise shop',
    type: 'message',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  NotificationItem(
    id: '4',
    title: 'Vaccination Reminder',
    message: 'Das is due for vaccination next week. Book an appointment now!',
    type: 'system',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
];

/// Notifications Sheet
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'appointment': return Icons.calendar_today;
      case 'order': return Icons.shopping_bag;
      case 'message': return Icons.message;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'appointment': return AppColors.secondary;
      case 'order': return Colors.orange;
      case 'message': return Colors.green;
      default: return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
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
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${mockNotifications.where((n) => !n.isRead).length} new',
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: mockNotifications.length,
              itemBuilder: (context, index) {
                final notification = mockNotifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notification.isRead ? Colors.white : AppColors.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inputFill),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconColor(notification.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
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
                                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(notification.createdAt),
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
