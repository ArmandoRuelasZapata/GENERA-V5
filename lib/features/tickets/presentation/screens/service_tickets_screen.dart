import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../widgets/ticket_card.dart';
import '../providers/tickets_provider.dart';
import 'service_ticket_detail_screen.dart'; // To be created

import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class ServiceTicketsScreen extends ConsumerWidget {
  const ServiceTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the admin provider that returns ALL tickets
    final allTicketsAsync = ref.watch(adminAllTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Soporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminAllTicketsProvider),
          )
        ],
      ),
      body: allTicketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tickets',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                id: ticket.id,
                title: ticket.title,
                description: ticket.description,
                status: ticket.status,
                category: ticket.category,
                priority: ticket.priority,
                unreadCount:
                    ticket.unreadCount, // Maybe always 0 for admin for now
                date: ticket.updatedAt,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ServiceTicketDetailScreen(ticket: ticket),
                    ),
                  );
                },
              )
                  .animate()
                  .fade(duration: 400.ms, delay: (50 * index).ms)
                  .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final isConnectionError =
              error.toString().contains('SocketException') ||
                  error.toString().contains('Connection refused') ||
                  error.toString().contains('ClientException');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ErrorStateWidget(
                message: isConnectionError
                    ? 'No se pudo conectar con el servidor.\nRevisa tu conexión.'
                    : 'Error al cargar tickets.',
                onRetry: () => ref.refresh(adminAllTicketsProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}
