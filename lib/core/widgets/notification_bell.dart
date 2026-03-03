import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/providers/notification_providers.dart';
import 'notifications_sheet.dart';

/// Reusable notification bell icon with live unread badge.
/// Watches [unreadNotificationCountProvider] for real-time count.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => NotificationsSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: unreadCount > 0
            ? Badge(
                label: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
              )
            : const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
              ),
      ),
    );
  }
}
