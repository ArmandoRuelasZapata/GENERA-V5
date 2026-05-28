import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:theoriginallab_v2/core/error/failures.dart';
import 'package:theoriginallab_v2/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:theoriginallab_v2/features/tickets/domain/entities/ticket.dart';

import 'tickets_repository_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
void main() {
  late ApiTicketsRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = ApiTicketsRepository(dio: mockDio);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // getActiveTickets
  // ───────────────────────────────────────────────────────────────────────────
  group('getActiveTickets', () {
    const tUserId = 'user-001';

    test('returns list of active tickets on success', () async {
      when(mockDio.get(
        '/tickets',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
            data: {
              'tickets': [
                {
                  'id': 'abc',
                  'user_id': tUserId,
                  'title': 'Ticket activo',
                  'description': 'desc',
                  'status': 'SUBMITTED',
                  'category': 'APP',
                  'priority': 'MEDIUM',
                  'created_at': '2026-01-01T10:00:00.000Z',
                  'updated_at': '2026-01-01T10:00:00.000Z',
                  'unread_count': 0,
                }
              ]
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/tickets'),
          ));

      final result = await repository.getActiveTickets(userId: tUserId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (tickets) {
          expect(tickets, isNotEmpty);
          expect(tickets.first, isA<Ticket>());
          expect(tickets.first.status, TicketStatus.submitted);
        },
      );
    });

    test('returns NetworkFailure on DioException connection error', () async {
      when(mockDio.get(
        '/tickets',
        queryParameters: anyNamed('queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/tickets'),
        type: DioExceptionType.connectionError,
      ));

      final result = await repository.getActiveTickets(userId: tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns ServerFailure on 405 (wrong backend URL)', () async {
      when(mockDio.get(
        '/tickets',
        queryParameters: anyNamed('queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/tickets'),
        response: Response(
          statusCode: 405,
          data: {},
          requestOptions: RequestOptions(path: '/tickets'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final result = await repository.getActiveTickets(userId: tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('filters out resolved and closed tickets', () async {
      when(mockDio.get(
        '/tickets',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
            data: {
              'tickets': [
                {
                  'id': 'active-1',
                  'user_id': tUserId,
                  'title': 'Activo',
                  'description': 'desc',
                  'status': 'SUBMITTED',
                  'category': 'APP',
                  'priority': 'MEDIUM',
                  'created_at': '2026-01-01T10:00:00.000Z',
                  'updated_at': '2026-01-01T10:00:00.000Z',
                  'unread_count': 0,
                },
                {
                  'id': 'resolved-1',
                  'user_id': tUserId,
                  'title': 'Resuelto',
                  'description': 'desc',
                  'status': 'RESOLVED',
                  'category': 'APP',
                  'priority': 'LOW',
                  'created_at': '2026-01-01T10:00:00.000Z',
                  'updated_at': '2026-01-01T10:00:00.000Z',
                  'unread_count': 0,
                }
              ]
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/tickets'),
          ));

      final result = await repository.getActiveTickets(userId: tUserId);

      result.fold(
        (l) => fail('Expected Right'),
        (tickets) {
          expect(tickets.length, 1);
          expect(tickets.first.id, 'active-1');
        },
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // createTicket
  // ───────────────────────────────────────────────────────────────────────────
  group('createTicket', () {
    test('returns Ticket on success', () async {
      when(mockDio.post('/tickets', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {
                  'id': 'new-ticket-001',
                  'user_id': 'user-001',
                  'title': 'Nuevo ticket',
                  'description': 'Descripción',
                  'status': 'SUBMITTED',
                  'category': 'APP',
                  'priority': 'MEDIUM',
                  'created_at': '2026-01-01T10:00:00.000Z',
                  'updated_at': '2026-01-01T10:00:00.000Z',
                  'unread_count': 0,
                },
                statusCode: 201,
                requestOptions: RequestOptions(path: '/tickets'),
              ));

      final result = await repository.createTicket(
        title: 'Nuevo ticket',
        description: 'Descripción',
        category: TicketCategory.app,
        userId: 'user-001', // ← userId obligatorio en producción
      );

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (ticket) {
          expect(ticket.title, 'Nuevo ticket');
          expect(ticket.status, TicketStatus.submitted);
        },
      );
    });

    test('returns ServerFailure when userId is null (no session)', () async {
      final result = await repository.createTicket(
        title: 'Ticket sin sesión',
        description: 'Esto no debería crearse',
        category: TicketCategory.app,
        userId: null, // Sin sesión activa
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );

      // Verificar que NO se hizo ninguna llamada a la API
      verifyNever(mockDio.post('/tickets', data: anyNamed('data')));
    });

    test('returns ServerFailure on 500', () async {
      when(mockDio.post('/tickets', data: anyNamed('data')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/tickets'),
        response: Response(
          statusCode: 500,
          data: {'message': 'Internal Server Error'},
          requestOptions: RequestOptions(path: '/tickets'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final result = await repository.createTicket(
        title: 'Ticket',
        description: 'Desc',
        category: TicketCategory.app,
        userId: 'user-001',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // sendMessage
  // ───────────────────────────────────────────────────────────────────────────
  group('sendMessage', () {
    const tTicketId = 'ticket-xyz';
    const tContent = 'Hola, necesito ayuda';

    test('returns TicketThreadItem on success', () async {
      when(mockDio.post(
        '/tickets/$tTicketId/messages',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {
              'id': 'msg-001',
              'ticket_id': tTicketId,
              'kind': 'MESSAGE',
              'sender_type': 'USER',
              'content': tContent,
              'type': 'TEXT',
              'attachments': [],
              'created_at': '2026-01-01T11:00:00.000Z',
            },
            statusCode: 201,
            requestOptions:
                RequestOptions(path: '/tickets/$tTicketId/messages'),
          ));

      final result = await repository.sendMessage(tTicketId, tContent);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (item) => expect(item.content, tContent),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // deleteTicket
  // ───────────────────────────────────────────────────────────────────────────
  group('deleteTicket', () {
    const tTicketId = 'del-ticket-001';

    test('returns Right(null) on success', () async {
      when(mockDio.delete('/tickets/$tTicketId'))
          .thenAnswer((_) async => Response(
                statusCode: 200,
                requestOptions: RequestOptions(path: '/tickets/$tTicketId'),
              ));

      final result = await repository.deleteTicket(tTicketId);

      expect(result.isRight(), true);
    });

    test('returns UnauthorizedFailure on 401', () async {
      when(mockDio.delete('/tickets/$tTicketId')).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/tickets/$tTicketId'),
        response: Response(
          statusCode: 401,
          data: {'message': 'Unauthorized'},
          requestOptions: RequestOptions(path: '/tickets/$tTicketId'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final result = await repository.deleteTicket(tTicketId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
