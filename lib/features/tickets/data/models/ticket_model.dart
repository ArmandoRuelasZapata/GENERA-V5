import '../../domain/entities/ticket.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.category,
    required super.priority,
    super.unreadCount = 0,
    required super.lastMessageAt,
    required super.createdAt,
    required super.updatedAt,
    super.closedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Parse created_at first as a safe fallback
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;
    final createdAt =
        createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    final updatedAt =
        updatedAtStr != null ? DateTime.parse(updatedAtStr) : createdAt;

    return TicketModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: _statusFromString(json['status']),
      category: _categoryFromString(json['category']),
      priority: _priorityFromString(json['priority']),
      unreadCount: json['unread_count'] ?? 0,
      lastMessageAt: updatedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt:
          json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
    );
  }

  static TicketStatus _statusFromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUBMITTED':
        return TicketStatus.submitted;
      case 'IN_REVIEW':
        return TicketStatus.inReview;
      case 'NEEDS_INFO':
        return TicketStatus.needsInfo;
      case 'RESOLVED':
        return TicketStatus.resolved;
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        return TicketStatus.submitted;
    }
  }

  static TicketCategory _categoryFromString(String? category) {
    switch (category?.toUpperCase()) {
      case 'ORDER':
        return TicketCategory.order;
      case 'PAYMENT':
        return TicketCategory.payment;
      case 'APP':
        return TicketCategory.app;
      default:
        return TicketCategory.other;
    }
  }

  static TicketPriority _priorityFromString(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'LOW':
        return TicketPriority.low;
      case 'HIGH':
        return TicketPriority.high;
      case 'MEDIUM':
      default:
        return TicketPriority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': _statusToString(status),
      'category': _categoryToString(category),
      'priority': _priorityToString(priority),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return 'SUBMITTED';
      case TicketStatus.inReview:
        return 'IN_REVIEW';
      case TicketStatus.needsInfo:
        return 'NEEDS_INFO';
      case TicketStatus.resolved:
        return 'RESOLVED';
      case TicketStatus.closed:
        return 'CLOSED';
    }
  }

  // Define helpers for Category/Priority string conversion if needed for POST
  static String _categoryToString(TicketCategory category) {
    switch (category) {
      case TicketCategory.order:
        return 'ORDER';
      case TicketCategory.payment:
        return 'PAYMENT';
      case TicketCategory.app:
        return 'APP';
      case TicketCategory.other:
        return 'OTHER';
    }
  }

  static String _priorityToString(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'LOW';
      case TicketPriority.medium:
        return 'MEDIUM';
      case TicketPriority.high:
        return 'HIGH';
    }
  }
}
