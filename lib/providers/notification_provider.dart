// lib/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/models/notification.dart';

// Changed from StateNotifier to Notifier
class NotificationNotifier extends Notifier<List<AppNotification>> {
  // Removed super() constructor

  // build() method replaces constructor
  @override
  List<AppNotification> build() {
    return []; // Initial state
  }

  // Method to add a new notification (called from other services)
  void add(AppNotification notification) {
    // To prevent duplicate notifications, check if a similar one already exists
    // Read state directly
    final exists = state.any((n) =>
        n.title == notification.title &&
        n.body == notification.body &&
        n.type == notification.type);

    if (!exists) {
      // Update state directly
      state = [notification, ...state];
    }
  }

  // Method to mark all notifications as read
  void markAllAsRead() {
    // Read and update state
    state = [
      for (final notification in state)
        // This line is now corrected using the copyWith method
        if (notification.isRead) notification else notification.copyWith(isRead: true)
    ];
  }

  // A computed property to easily check for unread notifications
  // This logic is fine, but it's better to use the separate provider below
  bool get hasUnread => state.any((n) => !n.isRead);
}

// Changed from StateNotifierProvider to NotifierProvider
final notificationProvider =
    NotifierProvider<NotificationNotifier, List<AppNotification>>(() {
  return NotificationNotifier();
});

// A simple provider that just exposes the boolean hasUnread property for easy access
final hasUnreadProvider = Provider<bool>((ref) {
  // Watch the full list to rebuild when it changes
  final notifications = ref.watch(notificationProvider);
  return notifications.any((n) => !n.isRead);
});
