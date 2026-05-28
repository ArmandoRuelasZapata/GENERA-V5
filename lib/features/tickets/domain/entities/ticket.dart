import 'package:flutter/material.dart';

enum TicketStatus {
  submitted,
  inReview,
  needsInfo,
  resolved,
  closed;

  String get label {
    switch (this) {
      case TicketStatus.submitted:
        return 'Enviado';
      case TicketStatus.inReview:
        return 'En Revisión';
      case TicketStatus.needsInfo:
        return 'Info Requerida';
      case TicketStatus.resolved:
        return 'Resuelto';
      case TicketStatus.closed:
        return 'Cerrado';
    }
  }

  Color get color {
    switch (this) {
      case TicketStatus.submitted:
        return Colors.grey;
      case TicketStatus.inReview:
        return Colors.blue;
      case TicketStatus.needsInfo:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }
}

enum TicketCategory {
  order,
  payment,
  app,
  other;

  String get label {
    switch (this) {
      case TicketCategory.order:
        return 'Pedido';
      case TicketCategory.payment:
        return 'Pago';
      case TicketCategory.app:
        return 'App';
      case TicketCategory.other:
        return 'Otro';
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Baja';
      case TicketPriority.medium:
        return 'Media';
      case TicketPriority.high:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.medium:
        return Colors.orange;
      case TicketPriority.high:
        return Colors.red;
    }
  }
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketCategory category;
  final TicketPriority priority;
  final int unreadCount;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  bool get canUserSendMessage => status != TicketStatus.closed;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.priority,
    this.unreadCount = 0,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    TicketCategory? category,
    TicketPriority? priority,
    int? unreadCount,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
