import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chatbot_provider.dart';

class ChatbotView extends ConsumerStatefulWidget {
  const ChatbotView({super.key});

  @override
  ConsumerState<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends ConsumerState<ChatbotView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text;
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(chatbotProvider.notifier).sendUserMessage(content);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent +
            100, // Extra scroll for new msg
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(chatbotProvider);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (messages) {
              // Auto-scroll on initial load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients &&
                    _scrollController.offset == 0) {
                  _scrollToBottom();
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  // Typing indicator
                  if (msg.type == MessageType.typing) {
                    return const _TypingIndicator();
                  }

                  // Appointment card
                  if (msg.type == MessageType.appointmentCard) {
                    return _AppointmentCardBubble(
                      message: msg.text,
                      metadata: msg.metadata,
                      timestamp: msg.timestamp,
                    );
                  }

                  // Normal message
                  return _BotMessageBubble(
                    key: ValueKey(msg.id),
                    message: msg.text,
                    isUser: msg.isUser,
                    timestamp: msg.timestamp,
                  );
                },
              );
            },
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(AppSpacing.smallPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu duda...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.smallGap),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: colorScheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    disabledBackgroundColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Typing Indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Text(
            'Asistente',
            style: AppTypography.labelSmall
                .copyWith(fontSize: 10, color: colorScheme.primary),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.33;
                  final t = ((_controller.value + delay) % 1.0 * 2 - 1).abs();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: 0.3 + 0.7 * (1 - t),
                      child: Transform.translate(
                        offset: Offset(0, -3 * (1 - t)),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Appointment Card ────────────────────────────────────────────────────────

class _AppointmentCardBubble extends StatelessWidget {
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const _AppointmentCardBubble({
    required this.message,
    this.metadata,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Text(
            'Asistente',
            style: AppTypography.labelSmall
                .copyWith(fontSize: 10, color: colorScheme.primary),
          ),
        ),
        // Text message
        if (message.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: AppTypography.bodyMedium
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
        // Appointment card
        if (metadata != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cita agendada',
                        style: AppTypography.titleSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _appointmentRow(
                      Icons.person, metadata!['nombre'] ?? '', colorScheme),
                  _appointmentRow(
                      Icons.email, metadata!['email'] ?? '', colorScheme),
                  _appointmentRow(Icons.calendar_today,
                      metadata!['fecha'] ?? '', colorScheme),
                  _appointmentRow(
                      Icons.access_time, metadata!['hora'] ?? '', colorScheme),
                  _appointmentRow(
                      Icons.subject, metadata!['motivo'] ?? '', colorScheme),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _appointmentRow(IconData icon, String text, ColorScheme colorScheme) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Normal Message Bubble ───────────────────────────────────────────────────

class _BotMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const _BotMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor =
        isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    // Different shape for Bot
    final borderRadius = BorderRadius.only(
      topLeft: isUser ? const Radius.circular(16) : Radius.zero,
      topRight: isUser ? Radius.zero : const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (!isUser) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'Asistente',
              style: AppTypography.labelSmall
                  .copyWith(fontSize: 10, color: colorScheme.primary),
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
          ),
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
