// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/models/notification.dart';
import 'package:poultryguard/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago; // A great package for "5m ago" timestamps

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  // Helper method to get a specific icon and color for each notification type
  Widget _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.vaccination:
        return const Icon(Icons.vaccines, color: Colors.blue);
      case NotificationType.environment:
        return const Icon(Icons.thermostat, color: Colors.orange);
      case NotificationType.feed:
        return const Icon(Icons.food_bank_outlined, color: Colors.brown);
      case NotificationType.general:
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the list of notifications
    final notifications = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          // "Mark all as read" button
          if (notifications.any((n) => !n.isRead)) // Only show if there are unread items
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: "Mark all as read",
              onPressed: () {
                notificationNotifier.markAllAsRead();
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          // 1. The "Empty State" UI
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "All caught up!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          // 2. The Notification List UI
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Material(
                  color: notification.isRead ? Colors.white : Colors.orange.shade50,
                  child: InkWell(
                    onTap: () {
                      // Mark this specific notification as read
                      notification.isRead = true;
                      // Manually trigger a state update
                      notificationNotifier.markAllAsRead(); // This is a bit of a hack to force rebuild, a better way would be a specific markOneAsRead method.
                      
                      // Deep link to the relevant screen
                      if (notification.navigationRoute.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          notification.navigationRoute,
                          arguments: notification.routeArguments,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: _getIconForType(notification.type),
                        title: Row(
                          children: [
                            // Show a blue dot for unread notifications
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (!notification.isRead) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(notification.body),
                        ),
                        trailing: Text(
                          timeago.format(notification.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}