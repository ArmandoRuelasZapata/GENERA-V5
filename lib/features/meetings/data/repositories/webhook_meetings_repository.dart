import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_error_mapper.dart';
import '../../domain/entities/meeting_request.dart';
import '../../domain/repositories/meetings_repository.dart';

/// Real meetings repository that communicates with our server-side proxy API
/// to read the agenda and create appointments in Google Calendar.
/// Make.com webhook URLs are never exposed to the client.
class WebhookMeetingsRepository implements MeetingsRepository {
  final Dio _dio;
  final String userName;
  final String userEmail;

  WebhookMeetingsRepository({
    required Dio dio,
    required this.userName,
    required this.userEmail,
  }) : _dio = dio;

  @override
  Future<Either<String, List<MeetingRequest>>> getMeetings() async {
    try {
      final url =
          '${ApiConstants.contentBaseUrl}${ApiConstants.appointmentsEndpoint}';
      final response = await _dio.get(url);

      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as List<dynamic>;
      } else {
        return const Right([]);
      }

      // ── Filtrado defensivo por email/nombre ───────────────────────────────
      // El proxy puede devolver todas las citas si el escenario de Make.com
      // no implementa filtro server-side. Filtramos aquí como capa adicional.
      final filteredData = data.where((item) {
        if (item is! Map<String, dynamic>) return false;
        final itemEmail = (item['email'] as String?)?.trim().toLowerCase();
        final itemName = (item['name'] as String?)?.trim().toLowerCase();

        final currentUserEmail = userEmail.trim().toLowerCase();
        final currentUserName = userName.trim().toLowerCase();

        final matchesEmail =
            currentUserEmail.isNotEmpty && itemEmail == currentUserEmail;
        final matchesName =
            currentUserName.isNotEmpty && itemName == currentUserName;

        return matchesEmail || matchesName;
      }).toList();

      final meetings = filteredData.map((item) {
        final map = item as Map<String, dynamic>;
        final dateStr = map['date'] as String? ?? '';
        final name = map['name'] as String? ?? '';

        // Parse date format: "M/d/yyyy H:mm:ss" or "M/d/yyyy HH:mm:ss"
        DateTime parsedDate;
        TimeOfDay parsedTime;
        try {
          // Try multiple formats
          parsedDate = _parseFlexibleDate(dateStr);
          parsedTime = TimeOfDay(
            hour: parsedDate.hour,
            minute: parsedDate.minute,
          );
        } catch (_) {
          parsedDate = DateTime.now();
          parsedTime = const TimeOfDay(hour: 9, minute: 0);
        }

        return MeetingRequest(
          id: '${name}_${dateStr.hashCode}',
          topic: MeetingTopic.consulting,
          date: parsedDate,
          time: parsedTime,
          status: parsedDate.isAfter(DateTime.now())
              ? MeetingStatus.confirmed
              : MeetingStatus.completed,
          createdAt: parsedDate,
          clientName: name,
        );
      }).toList();

      // Sort by date descending
      meetings.sort((a, b) => b.date.compareTo(a.date));

      return Right(meetings);
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      return Left('No se pudo cargar la agenda: ${mapped.message}');
    } catch (e) {
      return Left('Error al procesar la agenda: $e');
    }
  }

  @override
  Future<Either<String, MeetingRequest>> createMeeting({
    required MeetingTopic topic,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    try {
      // Format startdate as "YYYY/MM/DD HH:MM:SS" for the webhook
      final startDate =
          '${DateFormat('yyyy/MM/dd').format(date)} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

      final payload = {
        'name': userName,
        'email': userEmail,
        'startdate': startDate,
        'interest': topic.label,
        'value': '0',
        'number': '',
      };

      final url =
          '${ApiConstants.contentBaseUrl}${ApiConstants.appointmentsEndpoint}';
      final response = await _dio.post(url, data: payload);

      // Check for errors
      if (response.statusCode != null && response.statusCode! >= 400) {
        return Left('Error del servidor: ${response.statusCode}');
      }

      final responseStr = response.data?.toString() ?? '';
      if (responseStr.toLowerCase().contains('failed') ||
          responseStr.toLowerCase().contains('error')) {
        return Left('Error al agendar: $responseStr');
      }

      final newMeeting = MeetingRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: topic,
        date: date,
        time: time,
        status: MeetingStatus.confirmed,
        createdAt: DateTime.now(),
        clientName: userName,
      );

      return Right(newMeeting);
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      return Left('No se pudo agendar la reunion: ${mapped.message}');
    } catch (e) {
      return Left('Error inesperado: $e');
    }
  }

  /// Parses dates in various formats from the webhook.
  DateTime _parseFlexibleDate(String dateStr) {
    // Formats from webhook: "M/d/yyyy H:mm:ss", "M/d/yyyy HH:mm:ss"
    final formats = [
      'M/d/yyyy H:mm:ss',
      'M/d/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm:ss',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(dateStr);
      } catch (_) {
        continue;
      }
    }
    throw FormatException('Cannot parse date: $dateStr');
  }
}
