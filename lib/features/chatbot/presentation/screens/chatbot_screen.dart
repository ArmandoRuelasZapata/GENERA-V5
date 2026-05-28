import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../widgets/chatbot_view.dart';

class ChatbotScreen extends ConsumerWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy_outlined),
            const SizedBox(width: 8),
            Text('Asistente Virtual', style: AppTypography.titleMedium),
          ],
        ),
      ),
      body: const ChatbotView(),
    );
  }
}
