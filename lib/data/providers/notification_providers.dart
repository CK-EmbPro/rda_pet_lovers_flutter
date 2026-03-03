import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

// ── Service provider ─────────────────────────────
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(DioClient());
});

// ── Notifications list provider (auto-refreshes) ─────────────────────────────
final notificationsProvider =
    AutoDisposeAsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  Timer? _pollTimer;

  @override
  Future<List<NotificationModel>> build() async {
    // Cancel previous timer if any
    ref.onDispose(() => _pollTimer?.cancel());

    // Start polling every 30 seconds for new notifications
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshSilently();
    });

    return _fetch();
  }

  Future<List<NotificationModel>> _fetch() async {
    final service = ref.read(notificationServiceProvider);
    return service.getAll(limit: 50);
  }

  /// Refresh without showing loading state (for background polling)
  Future<void> _refreshSilently() async {
    try {
      final notifications = await _fetch();
      state = AsyncValue.data(notifications);
    } catch (_) {
      // Silently ignore polling errors — don't break the UI
    }
  }

  /// Force refresh (user-triggered, e.g. pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  /// Mark a single notification as read (optimistic update)
  Future<void> markAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);

    // Optimistic update
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true, readAt: DateTime.now()) : n).toList(),
    );

    try {
      await service.markAsRead(id);
      // Also refresh unread count
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      // Revert on failure
      state = AsyncValue.data(current);
    }
  }

  /// Mark all as read (optimistic update)
  Future<void> markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList(),
    );

    try {
      await service.markAllAsRead();
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  /// Delete a notification (optimistic update)
  Future<void> deleteNotification(String id) async {
    final service = ref.read(notificationServiceProvider);

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((n) => n.id != id).toList());

    try {
      await service.delete(id);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}

// ── Unread count provider (lightweight polling) ─────────────────────────────
final unreadNotificationCountProvider =
    AutoDisposeAsyncNotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

class UnreadCountNotifier extends AutoDisposeAsyncNotifier<int> {
  Timer? _pollTimer;

  @override
  Future<int> build() async {
    ref.onDispose(() => _pollTimer?.cancel());

    // Poll unread count every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshSilently();
    });

    return _fetch();
  }

  Future<int> _fetch() async {
    final service = ref.read(notificationServiceProvider);
    return service.getUnreadCount();
  }

  Future<void> _refreshSilently() async {
    try {
      final count = await _fetch();
      state = AsyncValue.data(count);
    } catch (_) {
      // Silently ignore
    }
  }
}
