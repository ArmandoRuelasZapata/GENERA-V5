import 'package:flutter/material.dart';

enum NotificationType {
  order,
  promo,
  support,
  system;

  String get label {
    switch (this) {
      case NotificationType.order:
        return 'Pedido';
      case NotificationType.promo:
        return 'Promoción';
      case NotificationType.support:
        return 'Soporte';
      case NotificationType.system:
        return 'Sistema';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.support:
        return Icons.support_agent;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.promo:
        return Colors.purple;
      case NotificationType.support:
        return Colors.orange;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String get rawValue => name; // 'order', 'promo', 'support', 'system'

  static NotificationType fromRaw(String raw) {
    return NotificationType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'type': type.rawValue,
        'isRead': isRead,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: NotificationType.fromRaw(json['type'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
