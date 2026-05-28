import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_error_mapper.dart';

/// Service that manages appointments via our server-side proxy API.
/// Make.com webhook URLs are never exposed to the client.
class AppointmentService {
  final Dio _dio;

  AppointmentService({required Dio dio}) : _dio = dio;

  /// Fetches available time slots from the server-side proxy.
  /// The proxy returns a JSON array: [{"date":"...", "name":"..."}, ...]
  Future<String> getAvailableSlots() async {
    try {
      final url =
          '${ApiConstants.contentBaseUrl}${ApiConstants.appointmentsEndpoint}';
      final response = await _dio.get(url);

      // The webhook returns a JSON array directly
      if (response.data is List) {
        return const JsonEncoder.withIndent('  ').convert(response.data);
      } else if (response.data is String) {
        // Try to parse the string as JSON
        try {
          final parsed = jsonDecode(response.data);
          return const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {
          return response.data;
        }
      } else if (response.data is Map) {
        return const JsonEncoder.withIndent('  ').convert(response.data);
      }
      return response.data.toString();
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      throw Exception('No se pudo consultar la agenda: ${mapped.message}');
    }
  }

  /// Schedules an appointment via the server-side proxy.
  Future<Map<String, dynamic>> scheduleAppointment({
    required String nombre,
    required String email,
    required String fecha,
    required String hora,
    required String motivo,
  }) async {
    try {
      // Build the startdate in the format the calendar expects: "YYYY/MM/DD HH:MM:SS"
      final startDate = _formatStartDate(fecha, hora);

      final payload = {
        'name': nombre,
        'email': email,
        'startdate': startDate,
        'interest': motivo,
        'value': '0',
        'number': '',
      };

      final url =
          '${ApiConstants.contentBaseUrl}${ApiConstants.appointmentsEndpoint}';
      final response = await _dio.post(url, data: payload);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        if (response.data.toString().toLowerCase().contains('failed') ||
            response.data.toString().toLowerCase().contains('error')) {
          throw Exception(response.data.toString());
        }
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          return {'status': 'ok', 'message': response.data};
        }
      }
      return {'status': 'ok'};
    } on DioException catch (e) {
      final mapped = NetworkErrorMapper.fromDioException(e);
      throw Exception('No se pudo agendar la cita: ${mapped.message}');
    }
  }

  /// Formats date and time into "YYYY/MM/DD HH:MM:SS" format
  /// that the Make.com calendar scenario expects.
  String _formatStartDate(String fecha, String hora) {
    // fecha could be "YYYY-MM-DD" or similar
    // hora could be "HH:MM" or "10:00 AM" etc.

    final datePart = fecha.replaceAll('-', '/');

    // Clean up hora - extract just HH:MM
    String timePart = hora.replaceAll(RegExp(r'[aApP][mM]'), '').trim();
    // Handle AM/PM conversion
    if (hora.toLowerCase().contains('pm')) {
      final parts = timePart.split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      if (hour < 12) hour += 12;
      timePart = '$hour:${parts.length > 1 ? parts[1] : "00"}';
    } else if (hora.toLowerCase().contains('am')) {
      final parts = timePart.split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      if (hour == 12) hour = 0;
      timePart =
          '${hour.toString().padLeft(2, '0')}:${parts.length > 1 ? parts[1] : "00"}';
    }

    // Ensure time has seconds
    if (timePart.split(':').length == 2) {
      timePart = '$timePart:00';
    }

    return '$datePart $timePart';
  }
}
