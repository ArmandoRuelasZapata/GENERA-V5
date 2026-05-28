import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/chatbot_view.dart';
import '../providers/chatbot_provider.dart';

class ChatbotFloatingButton extends ConsumerStatefulWidget {
  const ChatbotFloatingButton({super.key});

  @override
  ConsumerState<ChatbotFloatingButton> createState() =>
      _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState extends ConsumerState<ChatbotFloatingButton> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // Check if intro has already been shown
    final introShown = ref.read(chatbotIntroShownProvider);

    // Initialize state based on provider
    _isExpanded = !introShown;

    if (!introShown) {
      // If first time, collapse after 3 seconds and mark as shown
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
          ref.read(chatbotIntroShownProvider.notifier).state = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Ancho: 170 expandido, 48 colapsado
    final double width = _isExpanded ? 170 : 48;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          // Changed to Modal Bottom Sheet for "Bubble" feel
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows custom height
            backgroundColor: Colors.transparent, // Handle blur/color in child
            builder: (context) => _ChatbotSheet(),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          width: width,
          height: 48,
          margin: const EdgeInsets.only(
              right: 16, bottom: 16), // Restored original position
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Icono: Se mueve de la izquierda al centro
              AnimatedAlign(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                alignment:
                    _isExpanded ? Alignment.centerLeft : Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(left: _isExpanded ? 12.0 : 0),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: colorScheme.onTertiaryContainer,
                    size: 24,
                  ),
                ),
              ),

              // Texto: Se desvanece
              Positioned(
                left: 48, // Espacio reservado para el icono
                right: 0,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  duration:
                      const Duration(milliseconds: 300), // Desvanece más rápido
                  opacity: _isExpanded ? 1.0 : 0.0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Asistente Virtual',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Account for keyboard height so chat input is always visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // Use more height when keyboard is open so user can see messages
    final sheetHeight =
        keyboardHeight > 0 ? screenHeight * 0.95 : screenHeight * 0.75;

    return Padding(
      // Push the entire sheet up above the keyboard
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: sheetHeight - keyboardHeight,
        decoration: BoxDecoration(
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Asistente Virtual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Disclaimer
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'El asistente puede cometer errores. Verifica la información importante.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Body
              const Expanded(child: ChatbotView()),
            ],
          ),
        ),
      ),
    );
  }
}
