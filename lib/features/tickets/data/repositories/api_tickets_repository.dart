import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:theoriginallab_v2/core/error/failures.dart';
import 'package:theoriginallab_v2/core/network/network_error_mapper.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_thread_item.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../models/ticket_model.dart';
import '../models/ticket_thread_item_model.dart';

class ApiTicketsRepository implements TicketsRepository {
  final Dio _dio;

  ApiTicketsRepository({required Dio dio}) : _dio = dio;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Failure _mapDioError(DioException e, {String? contextMessage}) {
    final mapped = NetworkErrorMapper.fromDioException(e);
    if (mapped.statusCode == 405) {
      return Failure.server(
        contextMessage ?? 'Verifica la URL del backend de tickets (error 405).',
      );
    }
    if (mapped.statusCode == 401) {
      return Failure.unauthorized(mapped.message);
    }
    if (mapped.type.name == 'network' || mapped.type.name == 'timeout') {
      return Failure.network(mapped.message);
    }
    return Failure.server(mapped.message);
  }

  Failure _mapGenericError(Object e) =>
      Failure.server(NetworkErrorMapper.unknown(e).message);

  static const _invalidResponse =
      Failure.server('Respuesta inválida del servidor.');

  String _safePathSegment(String raw) => Uri.encodeComponent(raw);

  // ─────────────────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Ticket>>> getActiveTickets(
      {String? userId}) async {
    try {
      final response = await _dio.get(
        '/tickets',
        queryParameters: userId != null ? {'user_id': userId} : null,
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        return const Left(_invalidResponse);
      }

      final list = payload['tickets'];
      if (list is! List) {
        return const Left(_invalidResponse);
      }

      final tickets = list
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(
        tickets
            .where(
              (t) =>
                  t.status != TicketStatus.resolved &&
                  t.status != TicketStatus.closed,
            )
            .toList(),
      );
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getHistoryTickets(
      {String? userId}) async {
    try {
      final response = await _dio.get(
        '/tickets',
        queryParameters: userId != null ? {'user_id': userId} : null,
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        return const Left(_invalidResponse);
      }

      final list = payload['tickets'];
      if (list is! List) {
        return const Left(_invalidResponse);
      }

      final tickets = list
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(
        tickets
            .where(
              (t) =>
                  t.status == TicketStatus.resolved ||
                  t.status == TicketStatus.closed,
            )
            .toList(),
      );
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  @override
  Future<Either<Failure, List<TicketThreadItem>>> getTicketThread(
    String ticketId,
  ) async {
    try {
      final safeTicketId = _safePathSegment(ticketId);
      final response = await _dio.get('/tickets/$safeTicketId/messages');

      final list = response.data;
      if (list is! List) {
        return const Left(_invalidResponse);
      }

      final messages = list
          .map((e) => TicketThreadItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(messages);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Ticket>> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return const Left(
        Failure.server(
          'Se requiere sesión activa para crear un ticket. Inicia sesión e intenta de nuevo.',
        ),
      );
    }

    try {
      final body = {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': _categoryToString(category),
        'priority': 'MEDIUM',
        'status': 'SUBMITTED',
      };

      final response = await _dio.post('/tickets', data: body);

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        return const Left(_invalidResponse);
      }

      return Right(TicketModel.fromJson(payload));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  @override
  Future<Either<Failure, TicketThreadItem>> sendMessage(
    String ticketId,
    String content, {
    List<String>? attachmentPaths,
    String? senderType,
  }) async {
    try {
      final safeTicketId = _safePathSegment(ticketId);
      final attachments = <Map<String, dynamic>>[];

      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        for (final path in attachmentPaths) {
          final attachment = await _uploadFile(path);
          if (attachment != null) {
            attachments.add({
              'url': attachment.url,
              'name': attachment.name,
              'mime_type': attachment.mimeType,
              'size': attachment.size,
            });
          }
        }
      }

      final body = {
        'content': content,
        'sender_type': senderType ?? 'USER',
        'type': attachments.isNotEmpty && content.isEmpty ? 'IMAGE' : 'TEXT',
        'attachments': attachments,
      };

      final response =
          await _dio.post('/tickets/$safeTicketId/messages', data: body);

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        return const Left(_invalidResponse);
      }

      return Right(TicketThreadItemModel.fromJson(payload));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String ticketId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Ticket>> updateTicketStatus(
    String ticketId,
    TicketStatus status,
  ) async {
    try {
      final safeTicketId = _safePathSegment(ticketId);
      final response = await _dio.put(
        '/tickets/$safeTicketId',
        data: {'status': _statusToString(status)},
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        return const Left(_invalidResponse);
      }

      return Right(TicketModel.fromJson(payload));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTicket(String ticketId) async {
    try {
      final safeTicketId = _safePathSegment(ticketId);
      await _dio.delete('/tickets/$safeTicketId');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(_mapGenericError(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File upload (internal)
  // ─────────────────────────────────────────────────────────────────────────

  Future<TicketThreadItemAttachment?> _uploadFile(String path) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });

      // skipEncryption: el PayloadEncryptionInterceptor no puede cifrar
      // un FormData multipart como JSON — se le indica explícitamente que
      // deje pasar la petición sin modificar el body.
      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(extra: {'skipEncryption': true}),
      );
      final payload = response.data;

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      return TicketThreadItemAttachment(
        url: payload['url']?.toString() ?? '',
        name: payload['name']?.toString() ?? '',
        mimeType:
            payload['mime_type']?.toString() ?? 'application/octet-stream',
        size: payload['size'] is int
            ? payload['size'] as int
            : int.tryParse(payload['size']?.toString() ?? '0') ?? 0,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Enum → API string converters
  // ─────────────────────────────────────────────────────────────────────────

  String _statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return 'SUBMITTED';
      case TicketStatus.inReview:
        return 'IN_REVIEW';
      case TicketStatus.needsInfo:
        return 'NEEDS_INFO';
      case TicketStatus.resolved:
        return 'RESOLVED';
      case TicketStatus.closed:
        return 'CLOSED';
    }
  }

  String _categoryToString(TicketCategory category) {
    switch (category) {
      case TicketCategory.order:
        return 'ORDER';
      case TicketCategory.payment:
        return 'PAYMENT';
      case TicketCategory.app:
        return 'APP';
      case TicketCategory.other:
        return 'OTHER';
    }
  }
}
