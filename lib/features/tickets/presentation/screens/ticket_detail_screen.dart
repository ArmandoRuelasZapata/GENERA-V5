import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket_thread_item.dart';
import '../providers/tickets_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSending = false;

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final List<XFile> validImages = [];
        bool hasLargeFile = false;

        for (var image in images) {
          final sizeInBytes = await image.length();
          final sizeInMb = sizeInBytes / (1024 * 1024);
          if (sizeInMb <= 5) {
            validImages.add(image);
          } else {
            hasLargeFile = true;
          }
        }

        if (hasLargeFile && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Algunos archivos exceden el límite de 5MB y no fueron agregados.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validImages);
          });
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _selectedImages.isEmpty) ||
        _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final content = _messageController.text;
    final images = List<String>.from(_selectedImages.map((e) => e.path));

    _messageController.clear();
    setState(() {
      _selectedImages.clear();
    });

    await ref
        .read(ticketThreadProvider(widget.ticket.id).notifier)
        .sendMessage(content, attachmentPaths: images);

    if (mounted) {
      setState(() {
        _isSending = false;
        // Keep chat open
      });

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to ticket updates from lists
    final activeList = ref.watch(activeTicketsProvider).asData?.value ?? [];
    final historyList = ref.watch(historyTicketsProvider).asData?.value ?? [];

    // Find the most consistent version of the ticket
    final currentTicket = [...activeList, ...historyList].firstWhere(
      (t) => t.id == widget.ticket.id,
      orElse: () => widget.ticket,
    );

    final canInput = currentTicket.status != TicketStatus.closed;
    final threadAsync = ref.watch(ticketThreadProvider(widget.ticket.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket #${currentTicket.id}',
              style: AppTypography.titleMedium,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentTicket.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currentTicket.status.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner for status
          if (!canInput)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusMessage(currentTicket.status),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Thread Area
          Expanded(
            child: threadAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                final isConnectionError =
                    error.toString().contains('SocketException') ||
                        error.toString().contains('Connection refused') ||
                        error.toString().contains('ClientException');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ErrorStateWidget(
                      message: isConnectionError
                          ? 'No se pudo conectar con el chat.\nRevisa tu conexión.'
                          : 'Error al cargar mensajes.\nIntenta nuevamente.',
                      onRetry: () =>
                          ref.refresh(ticketThreadProvider(widget.ticket.id)),
                    ),
                  ),
                );
              },
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay actividad aún.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                // Jump to bottom initially
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.offset == 0) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(ticketThreadProvider(widget.ticket.id).notifier)
                        .loadThread();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ThreadItemWidget(item: item);
                    },
                  ),
                );
              },
            ),
          ),

          // Input Area
          if (canInput)
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.close,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.attach_file),
                          color: colorScheme.onSurfaceVariant,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Escribe una respuesta...',
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
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smallGap),
                        IconButton(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          color: colorScheme.primary,
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            disabledBackgroundColor: colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusMessage(TicketStatus status) {
    switch (status) {
      case TicketStatus.inReview:
        return 'El equipo de soporte está revisando tu caso.';
      case TicketStatus.resolved:
        return 'Este ticket ha sido resuelto.';
      case TicketStatus.closed:
        return 'Este ticket está cerrado.';
      case TicketStatus.submitted:
        return 'Tu ticket ha sido enviado.';
      case TicketStatus.needsInfo:
        return 'Se requiere información adicional.';
    }
  }
}

class _ThreadItemWidget extends StatelessWidget {
  final TicketThreadItem item;

  const _ThreadItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.kind == TicketThreadItemKind.event) {
      return _SystemEventWidget(text: item.content);
    }

    // Message
    return _MessageBubble(
      message: item.content,
      isUser: item.isUser,
      timestamp: item.createdAt,
      attachments: item.attachments,
    );
  }
}

class _SystemEventWidget extends StatelessWidget {
  final String text;

  const _SystemEventWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<TicketThreadItemAttachment> attachments;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor =
        isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (attachments.isNotEmpty)
          ...attachments.map((att) => Container(
                margin: const EdgeInsets.only(bottom: 4, top: 4),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  maxHeight: 200,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: att.url,
                            isNetwork: att.url.startsWith('http'),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: att.url,
                      child: att.url.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: att.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              memCacheWidth: 900,
                              maxWidthDiskCache: 1200,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 200,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            )
                          : Image.file(
                              File(att.url),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              )),
        if (message.isNotEmpty)
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
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _formatTime(timestamp),
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
