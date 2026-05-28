import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_thread_item.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

// Repository Provider
final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return ref.watch(ticketsRepositoryDiProvider);
});

// Active Tickets Provider (Filtered by User)
final activeTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(ticketsRepositoryProvider);
  final authState = ref.watch(authProvider);

  String? userId;
  authState.mapOrNull(
    authenticated: (state) {
      userId = state.user.id;
    },
  );

  // If not authenticated, maybe return empty or throw?
  // For now, let's assume if authState is not authenticated, userId is null.
  // BUT we want to filter by userId if it exists.

  if (userId == null) {
    // If we are strict, return empty list or error.
    // But if app allows guest tickets (unlikely), handle that.
    // Let's assume strict auth.
    // return [];
  }

  // Pass userId to filter
  final result = await repository.getActiveTickets(userId: userId);
  return result.fold(
    (error) => throw Exception(error),
    (tickets) => tickets,
  );
});

// History Tickets Provider (Filtered by User)
final historyTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(ticketsRepositoryProvider);
  final authState = ref.watch(authProvider);

  String? userId;
  authState.mapOrNull(
    authenticated: (state) {
      userId = state.user.id;
    },
  );

  final result = await repository.getHistoryTickets(userId: userId);
  return result.fold(
    (error) => throw Exception(error),
    (tickets) => tickets,
  );
});

// Ticket Thread Provider (Family) with optional SenderType
final ticketThreadProvider = StateNotifierProvider.family.autoDispose<
    TicketThreadNotifier, AsyncValue<List<TicketThreadItem>>, String>(
  (ref, ticketId) {
    final repository = ref.watch(ticketsRepositoryProvider);
    return TicketThreadNotifier(repository, ticketId, ref, senderType: 'USER');
  },
);

final adminTicketThreadProvider = StateNotifierProvider.family.autoDispose<
    TicketThreadNotifier, AsyncValue<List<TicketThreadItem>>, String>(
  (ref, ticketId) {
    final repository = ref.watch(ticketsRepositoryProvider);
    return TicketThreadNotifier(repository, ticketId, ref,
        senderType: 'SUPPORT');
  },
);

class TicketThreadNotifier
    extends StateNotifier<AsyncValue<List<TicketThreadItem>>> {
  final TicketsRepository _repository;
  final String _ticketId;
  final String _senderType;
  final Ref _ref;

  Timer? _timer;

  TicketThreadNotifier(this._repository, this._ticketId, this._ref,
      {String senderType = 'USER'})
      : _senderType = senderType,
        super(const AsyncValue.loading()) {
    loadThread();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => loadThread(isPolling: true));
  }

  Future<void> loadThread({bool isPolling = false}) async {
    final result = await _repository.getTicketThread(_ticketId);
    result.fold(
      (error) {
        if (!isPolling) state = AsyncValue.error(error, StackTrace.current);
      },
      (items) => state = AsyncValue.data(items),
    );
  }

  Future<void> sendMessage(String content,
      {List<String>? attachmentPaths}) async {
    // Optimistic update could go here
    final result = await _repository.sendMessage(_ticketId, content,
        attachmentPaths: attachmentPaths, senderType: _senderType);
    result.fold(
      (error) {
        // Handle error
      },
      (newItem) async {
        if (state.hasValue) {
          final currentItems = state.value!;
          if (!currentItems.any((m) => m.id == newItem.id)) {
            state = AsyncValue.data([...currentItems, newItem]);
            // Refresh lists to update last message time / unread count / sorting
            // ignore: unused_result
            _ref.refresh(activeTicketsProvider);
            // ignore: unused_result
            _ref.refresh(historyTicketsProvider);
            // ignore: unused_result
            _ref.refresh(adminAllTicketsProvider);
          }
        }

        // No auto-reply poll for admin? Or yes?
        // For admin, maybe just refresh.
        // For now keep simple.
      },
    );
  }

  Future<bool> updateStatus(TicketStatus status) async {
    final result = await _repository.updateTicketStatus(_ticketId, status);
    return result.fold((error) => false, (updatedTicket) {
      // Invalidate all ticket lists to force refresh
      // ignore: unused_result
      _ref.refresh(activeTicketsProvider);
      // ignore: unused_result
      _ref.refresh(historyTicketsProvider);
      // ignore: unused_result
      _ref.refresh(adminAllTicketsProvider);
      return true;
    });
  }

  Future<bool> deleteTicket() async {
    final result = await _repository.deleteTicket(_ticketId);
    return result.fold((error) => false, (_) {
      // Invalidate all ticket lists
      // ignore: unused_result
      _ref.refresh(activeTicketsProvider);
      // ignore: unused_result
      _ref.refresh(historyTicketsProvider);
      // ignore: unused_result
      _ref.refresh(adminAllTicketsProvider);
      return true;
    });
  }
}

// Create Ticket Provider
final createTicketProvider =
    StateNotifierProvider.autoDispose<CreateTicketNotifier, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(ticketsRepositoryProvider);
    return CreateTicketNotifier(repository, ref);
  },
);

class CreateTicketNotifier extends StateNotifier<AsyncValue<void>> {
  final TicketsRepository _repository;
  final Ref _ref;

  CreateTicketNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
  }) async {
    state = const AsyncValue.loading();

    String? userId;
    final authState = _ref.read(authProvider);
    authState.mapOrNull(
      authenticated: (state) => userId = state.user.id,
    );

    // If userId is null, we might fail or let repo handle it (back to dummy)
    // But for privacy, we want real ID.

    final result = await _repository.createTicket(
      title: title,
      description: description,
      category: category,
      userId: userId,
    );

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (ticket) async {
        // Automatically send the description as the first message
        if (description.isNotEmpty) {
          await _repository.sendMessage(
            ticket.id,
            description,
            senderType: 'USER',
          );
        }

        state = const AsyncValue.data(null);
        // Refresh the list
        // ignore: unused_result
        _ref.refresh(activeTicketsProvider);
      },
    );
  }
}

// Admin: All Tickets Provider (Reuse active/history or make new one?)
// For now, let's just make a provider that fetches ALL (active + history) for admin if needed.
// But the user wants to see "ALL".
final adminAllTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(ticketsRepositoryProvider);

  // Combine active and history tickets to show ALL to admin
  final activeResult = await repository.getActiveTickets();
  final historyResult = await repository.getHistoryTickets();

  final List<Ticket> all = [];

  // If both fail, throw error. If one fails, maybe show what we have?
  // User wants "Server Down" message, so if ANY fails (likely both if server down), throw.

  activeResult.fold((l) => throw Exception(l), (r) => all.addAll(r));

  historyResult.fold((l) => throw Exception(l), (r) => all.addAll(r));

  // Sort by created DESC (or updated)
  all.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt)); // Use updatedAt generally

  return all;
});
