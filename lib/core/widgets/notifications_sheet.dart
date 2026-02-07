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

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
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
class NotificationsSheet extends StatefulWidget {
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
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(mockNotifications);
  }

  void _markAllRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
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
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount new messages',
                        style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: unreadCount > 0 ? _markAllRead : null,
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: unreadCount > 0 ? AppColors.secondary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return GestureDetector(
                  onTap: () => _markAsRead(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.white : AppColors.secondary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: notification.isRead ? AppColors.inputFill : AppColors.secondary.withOpacity(0.1)),
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
                                        fontSize: 15,
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
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.done_all, size: 18, color: AppColors.secondary),
                                onPressed: () => _markAsRead(index),
                                tooltip: 'Mark as read',
                              ),
                            ],
                          ),
                      ],
                    ),
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
