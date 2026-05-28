import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_thread_item.dart';
import '../../domain/repositories/tickets_repository.dart';

class MockTicketsRepository implements TicketsRepository {
  // In-memory messages storage
  final Map<String, List<TicketThreadItem>> _messages = {
    '10234': [
      TicketThreadItem(
        id: 'm1',
        ticketId: '10234',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.user,
        content:
            'No puedo ingresar a mi cuenta desde la web, me dice contraseña incorrecta aunque la restablecí.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TicketThreadItem(
        id: 'm2',
        ticketId: '10234',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.support,
        content:
            'Hola, hemos recibido tu reporte. ¿Podrías confirmarnos si el error aparece en la app móvil también?',
        type: TicketThreadItemType.text,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      ),
      TicketThreadItem(
        id: 'e1',
        ticketId: '10234',
        kind: TicketThreadItemKind.event,
        senderType: TicketSenderType.system,
        content: 'Estado cambiado a Info Requerida',
        type: TicketThreadItemType.text,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      ),
    ],
    '10233': [
      TicketThreadItem(
        id: 'm1',
        ticketId: '10233',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.user,
        content:
            'Intenté realizar el pago de la suscripción pero se quedó cargando y no recibí confirmación.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TicketThreadItem(
        id: 'm2',
        ticketId: '10233',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.support,
        content:
            'Lamentamos el inconveniente. Estamos validando la transacción con el banco.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
    ],
    '10100': [
      TicketThreadItem(
        id: 'm1-10100',
        ticketId: '10100',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.user,
        content:
            'Quisiera saber si tienen planes corporativos para empresas con más de 50 empleados.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      TicketThreadItem(
        id: 'm2-10100',
        ticketId: '10100',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.support,
        content:
            'Hola. Sí, contamos con planes Enterprise. Te hemos enviado la información detallada a tu correo electrónico. ¿Necesitas algo más?',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 14, hours: 2)),
      ),
      TicketThreadItem(
        id: 'e1-10100',
        ticketId: '10100',
        kind: TicketThreadItemKind.event,
        senderType: TicketSenderType.system,
        content: 'Ticket marcado como Resuelto',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ],
    '10089': [
      TicketThreadItem(
        id: 'm1-10089',
        ticketId: '10089',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.user,
        content:
            'La aplicación se cierra inesperadamente al intentar abrir la pestaña de "Perfil" en Android.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      TicketThreadItem(
        id: 'm2-10089',
        ticketId: '10089',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.support,
        content:
            'Gracias por el reporte. Hemos lanzado una actualización (v2.1.1) que corrige este problema. Por favor actualiza la app.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 19, hours: 5)),
      ),
      TicketThreadItem(
        id: 'm3-10089',
        ticketId: '10089',
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.user,
        content: 'Confirmado, ya funciona correctamente. ¡Gracias!',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 19, hours: 1)),
      ),
      TicketThreadItem(
        id: 'e1-10089',
        ticketId: '10089',
        kind: TicketThreadItemKind.event,
        senderType: TicketSenderType.system,
        content: 'Ticket Cerrado',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now().subtract(const Duration(days: 19)),
      ),
    ],
  };

  @override
  Future<Either<Failure, List<Ticket>>> getActiveTickets(
      {String? userId}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return dummy tickets with full details
    return Right(_activeTickets);
  }

  @override
  Future<Either<Failure, List<Ticket>>> getHistoryTickets(
      {String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return Right([
      Ticket(
        id: '10100',
        title: 'Consulta sobre precios',
        description:
            'Quisiera saber si tienen planes corporativos para empresas.',
        status: TicketStatus.resolved,
        category: TicketCategory.other,
        priority: TicketPriority.low,
        unreadCount: 0,
        lastMessageAt: DateTime.now().subtract(const Duration(days: 14)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 14)),
        closedAt: null, // Resolved but not closed yet
      ),
      Ticket(
        id: '10089',
        title: 'Bug en la app móvil',
        description: 'La aplicación se cierra al intentar abrir el perfil.',
        status: TicketStatus.closed,
        category: TicketCategory.app,
        priority: TicketPriority.high,
        unreadCount: 0,
        lastMessageAt: DateTime.now().subtract(const Duration(days: 19)),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 19)),
        closedAt: DateTime.now().subtract(const Duration(days: 19)),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<TicketThreadItem>>> getTicketThread(
      String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(_messages[ticketId] ?? []);
  }

  @override
  Future<Either<Failure, TicketThreadItem>> sendMessage(
      String ticketId, String content,
      {List<String>? attachmentPaths, String? senderType}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final attachments = attachmentPaths?.map((path) {
      final name = path.split('/').last;
      return TicketThreadItemAttachment(
        url: path, // Local path for now
        name: name,
        mimeType: 'image/jpeg', // Mock mime
        size: 1024 * 500, // Mock size 500kb
      );
    }).toList();

    final newMessage = TicketThreadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ticketId: ticketId,
      kind: TicketThreadItemKind.message,
      senderType: senderType == 'SUPPORT'
          ? TicketSenderType.support
          : TicketSenderType.user,
      content: content,
      type: attachments != null && attachments.isNotEmpty
          ? TicketThreadItemType.image
          : TicketThreadItemType.text,
      attachments: attachments ?? [],
      createdAt: DateTime.now(),
    );

    if (!_messages.containsKey(ticketId)) {
      _messages[ticketId] = [];
    }
    _messages[ticketId]!.add(newMessage);

    // Simulate system event: Changed to In Review
    _messages[ticketId]!.add(TicketThreadItem(
      id: 'e-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: ticketId,
      kind: TicketThreadItemKind.event,
      senderType: TicketSenderType.system,
      content: 'Ticket cambiado a En Revisión',
      type: TicketThreadItemType.text,
      createdAt: DateTime.now().add(const Duration(milliseconds: 100)),
    ));

    // Simulate auto-reply for demo
    Future.delayed(const Duration(seconds: 2), () {
      _messages[ticketId]!.add(TicketThreadItem(
        id: 'auto-${DateTime.now().millisecondsSinceEpoch}',
        ticketId: ticketId,
        kind: TicketThreadItemKind.message,
        senderType: TicketSenderType.support,
        content:
            'Gracias. Un asesor revisará tu respuesta pronto y te notificará.',
        type: TicketThreadItemType.text,
        createdAt: DateTime.now(),
      ));
    });

    return Right(newMessage);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right(null);
  }

  @override
  Future<Either<Failure, Ticket>> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final newTicket = Ticket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      status: TicketStatus.submitted,
      category: category,
      priority: TicketPriority.medium, // Default priority set by system
      unreadCount: 0,
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // In a real mock, we should update the list returned by getActiveTickets
    // Since getActiveTickets returns hardcoded list, we need to make it dynamic or
    // just for this session, we won't see it unless we refactor getActiveTickets too.
    // Let's refactor getActiveTickets to use a memory list.

    _activeTickets.add(newTicket);

    return Right(newTicket);
  }

  @override
  Future<Either<Failure, Ticket>> updateTicketStatus(
      String ticketId, TicketStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));

    Ticket? updated;

    for (var i = 0; i < _activeTickets.length; i++) {
      final ticket = _activeTickets[i];
      if (ticket.id == ticketId) {
        updated = ticket.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          closedAt:
              status == TicketStatus.closed ? DateTime.now() : ticket.closedAt,
        );
        _activeTickets[i] = updated;
        break;
      }
    }

    if (updated == null) {
      final historyTicketsResult = await getHistoryTickets();
      historyTicketsResult.fold((_) {}, (historyTickets) {
        for (final ticket in historyTickets) {
          if (ticket.id == ticketId) {
            updated = ticket.copyWith(
              status: status,
              updatedAt: DateTime.now(),
              closedAt: status == TicketStatus.closed
                  ? DateTime.now()
                  : ticket.closedAt,
            );
            break;
          }
        }
      });
    }

    if (updated == null) {
      return const Left(Failure.server('Ticket not found'));
    }

    return Right(updated!);
  }

  @override
  Future<Either<Failure, void>> deleteTicket(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _activeTickets.removeWhere((ticket) => ticket.id == ticketId);
    _messages.remove(ticketId);
    return const Right(null);
  }

  // Internal storage for active tickets
  final List<Ticket> _activeTickets = [
    Ticket(
      id: '10234',
      title: 'Problema con el acceso',
      description:
          'No puedo ingresar a mi cuenta desde la web, me dice contraseña incorrecta.',
      status: TicketStatus.needsInfo,
      category: TicketCategory.app,
      priority: TicketPriority.high,
      unreadCount: 1,
      lastMessageAt:
          DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    Ticket(
      id: '10233',
      title: 'Error en pago',
      description:
          'Intenté realizar el pago de la suscripción pero se quedó cargando.',
      status: TicketStatus.inReview,
      category: TicketCategory.payment,
      priority: TicketPriority.medium,
      // In review
      unreadCount: 0,
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 20)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
  ];
}
