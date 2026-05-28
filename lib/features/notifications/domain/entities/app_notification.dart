class AppNotification {
  final String id;
  final String title;
  final String body;
  final String
      time; // Could be DateTime, keeping String for mock simplicity per existing UI
  final bool isRead;
  final String type; // 'order', 'ticket', 'promo', 'info'

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    bool? isRead,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
