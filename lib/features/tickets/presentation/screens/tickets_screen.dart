import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../widgets/ticket_card.dart';
import '../providers/tickets_provider.dart';
import 'ticket_detail_screen.dart';
import 'ticket_create_screen.dart';
import '../../domain/entities/ticket.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTicketsAsync = ref.watch(activeTicketsProvider);
    final historyTicketsAsync = ref.watch(historyTicketsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for depth effect
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TicketCreateScreen(),
            ),
          );
        },
        icon: const Icon(Icons.edit_square),
        label: const Text('Nuevo Ticket'),
      ),
      body: TabBarView(
        children: [
          _buildTicketList(context, ref, activeTicketsAsync),
          _buildTicketList(context, ref, historyTicketsAsync),
        ],
      ),
    );
  }

  Future<void> _refreshTickets(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(activeTicketsProvider.future),
      ref.refresh(historyTicketsProvider.future),
    ]);
  }

  Widget _buildTicketList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Ticket>> ticketsAsync,
  ) {
    // MediaQuery.padding.top ya incluye la altura del AppBar (64) y del TabBar (48)
    // porque el Scaffold padre tiene extendBodyBehindAppBar: true
    final topPadding = MediaQuery.of(context).padding.top + 16.0;

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Center(
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
            ),
          ).animate().fade(duration: 500.ms).scale(delay: 200.ms);
        }

        return RefreshIndicator(
          onRefresh: () => _refreshTickets(ref),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              topPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
            ),
            itemCount: tickets.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                id: ticket.id,
                title: ticket.title,
                description: ticket.description,
                status: ticket.status,
                category: ticket.category,
                priority: ticket.priority,
                unreadCount: ticket.unreadCount,
                date: ticket.updatedAt,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TicketDetailScreen(ticket: ticket),
                    ),
                  );
                },
              )
                  .animate()
                  .fade(duration: 400.ms, delay: (50 * index).ms)
                  .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final isConnectionError =
            error.toString().contains('SocketException') ||
                error.toString().contains('Connection refused') ||
                error.toString().contains('ClientException');

        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ErrorStateWidget(
                message: isConnectionError
                    ? 'No se pudo conectar con el servidor.\nRevisa tu conexión o intenta más tarde.'
                    : 'Ocurrió un error inesperado.\nIntenta nuevamente.',
                onRetry: () => _refreshTickets(ref),
              ),
            ),
          ),
        );
      },
    );
  }
}
