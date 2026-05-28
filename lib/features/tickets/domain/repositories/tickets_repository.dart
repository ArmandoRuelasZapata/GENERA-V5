import 'package:dartz/dartz.dart';
import 'package:theoriginallab_v2/core/error/failures.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket_thread_item.dart';
import '../entities/ticket.dart';

abstract class TicketsRepository {
  Future<Either<Failure, List<Ticket>>> getActiveTickets({String? userId});
  Future<Either<Failure, List<Ticket>>> getHistoryTickets({String? userId});
  Future<Either<Failure, List<TicketThreadItem>>> getTicketThread(
      String ticketId);
  Future<Either<Failure, TicketThreadItem>> sendMessage(
      String ticketId, String content,
      {List<String>? attachmentPaths, String? senderType});
  Future<Either<Failure, void>> markAsRead(String ticketId);
  Future<Either<Failure, Ticket>> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    String? userId,
  });
  // Admin / Support methods
  Future<Either<Failure, Ticket>> updateTicketStatus(
      String ticketId, TicketStatus status);
  Future<Either<Failure, void>> deleteTicket(String ticketId);
}
