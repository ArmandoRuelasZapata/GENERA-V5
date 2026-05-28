import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_error_mapper.dart';
import '../../domain/entities/time_slot.dart';

/// Service for the booking flow screens to schedule and read appointments.
/// Communicates with our own API proxy — Make.com webhook URLs are never
/// exposed to the client.
class BookingWebhookService {
  final Dio _dio;

  BookingWebhookService({required Dio dio}) : _dio = dio;

  /// Fetches existing appointments from the server-side proxy.
  /// Returns them as DateTime objects for conflict checking.
  Future<List<DateTime>> getOccupiedSlots() async {
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
        developer.log(
            'Webhook returned unexpected type: ${response.data.runtimeType}',
            name: 'BookingWebhookService');
        return [];
      }

      developer.log('Agenda webhook returned ${data.length} items',
          name: 'BookingWebhookService');

      final occupiedDates = <DateTime>[];
      for (final item in data) {
        final map = item as Map<String, dynamic>;

        // Try multiple possible field names for the date
        final dateStr = map['date'] as String? ??
            map['startDate'] as String? ??
            map['start'] as String? ??
            map['fecha'] as String? ??
            '';

        if (dateStr.isEmpty) {
          developer.log('Item has no date field. Keys: ${map.keys.toList()}',
              name: 'BookingWebhookService');
          continue;
        }

        try {
          final date = _parseFlexibleDate(dateStr);
          occupiedDates.add(date);
          developer.log('Parsed occupied slot: $date from "$dateStr"',
              name: 'BookingWebhookService');
        } catch (e) {
          developer.log('FAILED to parse date: "$dateStr" — $e',
              name: 'BookingWebhookService');
          continue;
        }
      }

      developer.log(
          'Successfully parsed ${occupiedDates.length} occupied slots out of ${data.length} items',
          name: 'BookingWebhookService');

      return occupiedDates;
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      developer.log('Webhook request failed: ${mapped.message}',
          name: 'BookingWebhookService');
      throw Exception('No se pudo consultar la agenda: ${mapped.message}');
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'BookingWebhookService');
      throw Exception('No se pudo consultar la agenda: $e');
    }
  }

  /// Generates time slots for a given date from 08:00 to 18:00 (1h each),
  /// marking slots as unavailable if they conflict with occupied slots.
  ///
  /// IMPORTANT: If the agenda fetch fails, this throws instead of silently
  /// returning all slots as available (which would allow double-booking).
  Future<List<TimeSlot>> getTimeSlotsForDate(DateTime date) async {
    // Don't silently swallow errors — if we can't check the agenda,
    // we shouldn't show all slots as available.
    final occupied = await getOccupiedSlots();

    final slots = <TimeSlot>[];
    const slotDuration = 60; // minutes per slot

    for (int hour = 8; hour < 18; hour++) {
      final start = DateTime(date.year, date.month, date.day, hour, 0);
      final end = start.add(const Duration(minutes: slotDuration));

      // Skip if in the past
      if (start.isBefore(DateTime.now())) continue;

      // Check if any occupied slot conflicts with this time slot
      final isOccupied = occupied.any((occ) {
        // Same day check
        if (occ.year == date.year &&
            occ.month == date.month &&
            occ.day == date.day) {
          // Conflict if the occupied appointment's time overlaps with this slot
          // Assume each existing appointment is ~60 minutes
          final occupiedStart =
              DateTime(occ.year, occ.month, occ.day, occ.hour, occ.minute);
          final occupiedEnd = occupiedStart.add(const Duration(minutes: 60));
          return start.isBefore(occupiedEnd) && end.isAfter(occupiedStart);
        }
        return false;
      });

      slots.add(TimeSlot(
        startTime: start,
        endTime: end,
        isAvailable: !isOccupied,
      ));
    }

    return slots;
  }

  /// Schedules an appointment via the server-side proxy.
  Future<void> scheduleAppointment({
    required String name,
    required String email,
    required DateTime startTime,
    required String interest,
    String phone = '',
  }) async {
    final startDate =
        '${DateFormat('yyyy/MM/dd').format(startTime)} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';

    final payload = {
      'name': name,
      'email': email,
      'startdate': startDate,
      'interest': interest,
      'value': '0',
      'number': phone,
    };

    try {
      final url =
          '${ApiConstants.contentBaseUrl}${ApiConstants.appointmentsEndpoint}';
      final response = await _dio.post(url, data: payload);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final responseStr = response.data?.toString() ?? '';
      if (responseStr.toLowerCase().contains('failed')) {
        throw Exception('El escenario de agendamiento falló.');
      }
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      if (mapped.statusCode == 500) {
        throw Exception(
            'Error en el servidor de agendamiento. Intenta de nuevo.');
      }
      throw Exception('No se pudo agendar: ${mapped.message}');
    }
  }

  /// Parses dates in many possible formats from the webhook.
  /// The Make.com webhook could return dates in various formats depending
  /// on the Google Calendar locale and configuration.
  DateTime _parseFlexibleDate(String dateStr) {
    // Try standard DateFormat patterns
    final formats = [
      'M/d/yyyy H:mm:ss',
      'M/d/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy H:mm:ss',
      'd/M/yyyy HH:mm:ss', // European format
      'd/M/yyyy H:mm:ss',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss', // ISO 8601
      'M/d/yyyy',
      'yyyy-MM-dd',
      'MM/dd/yyyy',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(dateStr);
      } catch (_) {
        continue;
      }
    }

    // Try Dart's built-in ISO parser as last resort
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // ignore
    }

    throw FormatException('Cannot parse date: $dateStr');
  }
}
