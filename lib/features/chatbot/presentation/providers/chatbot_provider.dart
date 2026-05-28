import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ref.watch(chatbotRepositoryDiProvider);
});

/// Tracks if the Chatbot FAB intro animation has already been shown in this session.
final chatbotIntroShownProvider = StateProvider<bool>((ref) => false);

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, AsyncValue<List<ChatMessage>>>(
        (ref) {
  final repository = ref.watch(chatbotRepositoryProvider);
  return ChatbotNotifier(repository);
});

class ChatbotNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatbotRepository _repository;

  ChatbotNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final result = await _repository.getHistory();
    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (messages) => state = AsyncValue.data(messages),
    );
  }

  Future<void> sendUserMessage(String text) async {
    // 1. Add User Message immediately
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, userMsg]);
    }

    // 2. Add typing indicator
    final typingMsg = ChatMessage(
      id: 'typing',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.typing,
    );

    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, typingMsg]);
    }

    // 3. Fetch Bot Response
    final result = await _repository.sendMessage(text);

    // 4. Remove typing indicator and add bot response
    result.fold(
      (error) {
        if (state.hasValue) {
          final messages =
              state.value!.where((m) => m.type != MessageType.typing).toList();
          // Add error message as bot response
          messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Error: $error',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          state = AsyncValue.data(messages);
        }
      },
      (botMsg) {
        if (state.hasValue) {
          final messages =
              state.value!.where((m) => m.type != MessageType.typing).toList();
          messages.add(botMsg);
          state = AsyncValue.data(messages);
        }
      },
    );
  }
}
