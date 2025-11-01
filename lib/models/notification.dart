// lib/models/notification.dart

class AppNotification {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final String navigationRoute;
  final Map<String, dynamic>? routeArguments;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.navigationRoute,
    this.routeArguments,
    this.isRead = false,
  });

  // <<< ADD THIS METHOD INSIDE YOUR AppNotification CLASS >>>
  AppNotification copyWith({
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    String? navigationRoute,
    Map<String, dynamic>? routeArguments,
    bool? isRead,
  }) {
    return AppNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      navigationRoute: navigationRoute ?? this.navigationRoute,
      routeArguments: routeArguments ?? this.routeArguments,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Your enum can remain the same
enum NotificationType { vaccination, environment, feed, general }