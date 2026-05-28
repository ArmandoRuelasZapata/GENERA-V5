import 'dart:convert';
import '../../domain/entities/ticket_thread_item.dart';

class TicketThreadItemModel extends TicketThreadItem {
  const TicketThreadItemModel({
    required super.id,
    required super.ticketId,
    required super.kind,
    required super.senderType,
    super.senderId,
    required super.content,
    required super.type,
    super.attachments = const [],
    super.clientMessageId,
    required super.createdAt,
  });

  factory TicketThreadItemModel.fromJson(Map<String, dynamic> json) {
    // Handle attachments that may come as String (JSON), List, or null
    List<TicketThreadItemAttachment> parsedAttachments = [];
    final rawAttachments = json['attachments'];
    if (rawAttachments != null) {
      List<dynamic> attachmentList;
      if (rawAttachments is String) {
        try {
          attachmentList = jsonDecode(rawAttachments) as List<dynamic>;
        } catch (_) {
          attachmentList = [];
        }
      } else if (rawAttachments is List) {
        attachmentList = rawAttachments;
      } else {
        attachmentList = [];
      }
      parsedAttachments = attachmentList
          .whereType<Map<String, dynamic>>()
          .map((e) => _attachmentFromJson(e))
          .toList();
    }

    return TicketThreadItemModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      kind: TicketThreadItemKind.message,
      senderType: _senderTypeFromString(json['sender_type']),
      content: json['content'] ?? '',
      type: _typeFromString(json['type']),
      attachments: parsedAttachments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static TicketSenderType _senderTypeFromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'USER':
        return TicketSenderType.user;
      case 'SUPPORT':
      case 'ADMIN': // Handle ADMIN as SUPPORT
        return TicketSenderType.support;
      case 'SYSTEM':
        return TicketSenderType.system;
      default:
        return TicketSenderType.user;
    }
  }

  static TicketThreadItemType _typeFromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return TicketThreadItemType.image;
      case 'FILE':
        return TicketThreadItemType.file;
      default:
        return TicketThreadItemType.text;
    }
  }

  static TicketThreadItemAttachment _attachmentFromJson(
      Map<String, dynamic> json) {
    return TicketThreadItemAttachment(
      url: json['url'] ?? '',
      name: json['name'] ?? '',
      mimeType: json['mime_type'] ?? 'application/octet-stream',
      size: json['size'] ?? 0,
    );
  }

  // ToJson for sending message
  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'sender_type': _senderTypeToString(senderType),
      'content': content,
      'type': _typeToString(type),
      'attachments': attachments.map((a) => _attachmentToJson(a)).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _senderTypeToString(TicketSenderType type) {
    switch (type) {
      case TicketSenderType.user:
        return 'USER';
      case TicketSenderType.support:
        return 'SUPPORT';
      case TicketSenderType.system:
        return 'SYSTEM';
    }
  }

  static String _typeToString(TicketThreadItemType type) {
    switch (type) {
      case TicketThreadItemType.text:
        return 'TEXT';
      case TicketThreadItemType.image:
        return 'IMAGE';
      case TicketThreadItemType.file:
        return 'FILE';
    }
  }

  static Map<String, dynamic> _attachmentToJson(
      TicketThreadItemAttachment attachment) {
    return {
      'url': attachment.url,
      'name': attachment.name,
      'mime_type': attachment.mimeType,
      'size': attachment.size,
    };
  }
}
