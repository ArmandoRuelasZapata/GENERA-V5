import 'package:dartz/dartz.dart';
import '../entities/chat_message.dart';

abstract class ChatbotRepository {
  Future<Either<String, List<ChatMessage>>> getHistory();
  Future<Either<String, ChatMessage>> sendMessage(String text);
}
