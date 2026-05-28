enum MessageType {
  text,
  typing,
  appointmentCard,
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true: User, false: Bot
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>?
      metadata; // Extra data for appointment cards, etc.

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });
}
