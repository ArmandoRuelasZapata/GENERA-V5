import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket_thread_item.dart';
import '../providers/tickets_provider.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class ServiceTicketDetailScreen extends ConsumerStatefulWidget {
  final Ticket ticket;

  const ServiceTicketDetailScreen({super.key, required this.ticket});

  @override
  ConsumerState<ServiceTicketDetailScreen> createState() =>
      _ServiceTicketDetailScreenState();
}

class _ServiceTicketDetailScreenState
    extends ConsumerState<ServiceTicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  late Ticket _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSending = false;

  Future<void> _pickImage() async {
    // Same image logic
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
              content: Text('Algunos exceden 5MB.'),
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

    // Use ADMIN provider
    await ref
        .read(adminTicketThreadProvider(widget.ticket.id).notifier)
        .sendMessage(content, attachmentPaths: images);

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _changeStatus() async {
    final newStatus = await showDialog<TicketStatus>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Cambiar Estado'),
            children: TicketStatus.values.map((s) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, s),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        color: s.color,
                        margin: const EdgeInsets.only(right: 8)),
                    Text(s.label),
                  ],
                ),
              );
            }).toList(),
          );
        });

    if (newStatus != null && newStatus != _currentTicket.status) {
      final success = await ref
          .read(adminTicketThreadProvider(widget.ticket.id).notifier)
          .updateStatus(newStatus);

      if (success) {
        setState(() {
          _currentTicket = _currentTicket.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estado actualizado correctamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error al actualizar estado'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ticket'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar este ticket?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(adminTicketThreadProvider(widget.ticket.id).notifier)
          .deleteTicket();

      if (success) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Go back to list
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket eliminado correctamente')),
        );
      } else {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final threadAsync = ref.watch(adminTicketThreadProvider(widget.ticket.id));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _changeStatus,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentTicket.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ticket.title,
                      style: AppTypography.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_currentTicket.status.label} (Toque para cambiar)',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
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
                  child: ErrorStateWidget(
                    message: isConnectionError
                        ? 'No se pudo conectar con el chat.\nRevisa tu conexión.'
                        : 'Error al cargar mensajes.',
                    onRetry: () => ref
                        .refresh(adminTicketThreadProvider(widget.ticket.id)),
                  ),
                );
              },
              data: (items) {
                // Jump logic
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.offset == 0) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (items.isEmpty) {
                  return const Center(child: Text('Sin mensajes'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ThreadItemWidget(item: item);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(AppSpacing.smallPadding),
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
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Respuesta de soporte...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
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
}

// Polished Message Bubble
class _ThreadItemWidget extends StatelessWidget {
  final TicketThreadItem item;

  const _ThreadItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.kind == TicketThreadItemKind.event) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.content,
            style: AppTypography.labelSmall.copyWith(fontSize: 10),
          ),
        ),
      );
    }

    // Logic:
    // item.isUser == true (Client) -> LEFT (Them)
    // item.isUser == false (Support/Me) -> RIGHT (Me)
    final bool isMe = !item.isUser;

    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.attachments.isNotEmpty)
              ...item.attachments.map((att) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      maxHeight: 200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                                        child:
                                            Icon(Icons.broken_image, size: 40),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  )),
            Text(
              item.content,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(item.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
