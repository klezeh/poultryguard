import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultryguard/providers/notification_provider.dart';

class NotificationIcon extends ConsumerWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the hasUnreadProvider for changes
    final hasUnread = ref.watch(hasUnreadProvider);

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            hasUnread ? Icons.notifications : Icons.notifications_none_outlined,
            size: 28,
          ),
          onPressed: () {
            // When tapped, mark all as read and navigate
            ref.read(notificationProvider.notifier).markAllAsRead();
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (hasUnread)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
            ),
          ),
      ],
    );
  }
}