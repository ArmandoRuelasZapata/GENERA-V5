enum TicketThreadItemKind { message, event }

enum TicketSenderType { user, support, system }

enum TicketThreadItemType { text, image, file }

class TicketThreadItemAttachment {
  final String url;
  final String name;
  final String mimeType;
  final int size;

  const TicketThreadItemAttachment({
    required this.url,
    required this.name,
    required this.mimeType,
    required this.size,
  });
}

class TicketThreadItem {
  final String id;
  final String ticketId;
  final TicketThreadItemKind kind;
  final TicketSenderType senderType;
  final String? senderId;
  final String content;
  final TicketThreadItemType type;
  final List<TicketThreadItemAttachment> attachments;
  final String? clientMessageId;
  final DateTime createdAt;

  const TicketThreadItem({
    required this.id,
    required this.ticketId,
    required this.kind,
    required this.senderType,
    this.senderId,
    required this.content,
    required this.type,
    this.attachments = const [],
    this.clientMessageId,
    required this.createdAt,
  });

  bool get isUser => senderType == TicketSenderType.user;
  bool get isSystem =>
      senderType == TicketSenderType.system ||
      kind == TicketThreadItemKind.event;
}
