import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../services/openai_chatbot_service.dart';
import '../services/appointment_service.dart';

/// Real chatbot repository that uses OpenAI GPT for responses
/// and Make.com webhooks for appointment scheduling.
///
/// Implements the multi-flow architecture from the WhatsApp bot reference:
/// - Seller flow: default, answers about products/services
/// - Schedule flow: fetches agenda, injects into prompt for availability checking
/// - Confirm flow: GPT collects data step-by-step, triggers webhook when complete
class OpenAiChatbotRepository implements ChatbotRepository {
  final OpenAiChatbotService _chatService;
  final AppointmentService _appointmentService;

  OpenAiChatbotRepository({
    required OpenAiChatbotService chatService,
    required AppointmentService appointmentService,
  })  : _chatService = chatService,
        _appointmentService = appointmentService;

  @override
  Future<Either<String, List<ChatMessage>>> getHistory() async {
    // Start with a welcome message from the bot
    return Right([
      ChatMessage(
        id: 'welcome',
        text:
            'Hola. Soy tu asistente virtual de The Original Lab.\n¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Either<String, ChatMessage>> sendMessage(String text) async {
    try {
      // === SCHEDULE FLOW ===
      // If the user mentions scheduling, fetch current agenda first
      // (mirrors schedule.flow.ts: getCurrentCalendar() → inject into prompt)
      String? agendaData;
      if (_chatService.isScheduleIntent(text)) {
        try {
          agendaData = await _appointmentService.getAvailableSlots();
        } catch (_) {
          // If agenda fetch fails, GPT will work without it
          agendaData = 'No se pudo consultar la agenda en este momento.';
        }
      }

      // Get response from OpenAI (with agenda data if scheduling)
      final response =
          await _chatService.sendMessage(text, agendaData: agendaData);

      // === CONFIRM FLOW ===
      // Check if GPT collected all data and tagged it for scheduling
      // (mirrors confirm.flow.ts: collect data → generateJsonParse → appToCalendar)
      final appointmentData = _extractAppointmentData(response);

      if (appointmentData != null) {
        // Try to schedule the appointment via webhook
        try {
          await _appointmentService.scheduleAppointment(
            nombre: appointmentData['nombre'] ?? '',
            email: appointmentData['email'] ?? '',
            fecha: appointmentData['fecha'] ?? '',
            hora: appointmentData['hora'] ?? '',
            motivo: appointmentData['motivo'] ?? '',
          );

          // Clean the response text (remove the tag)
          final cleanText = _removeAppointmentTag(response);

          return Right(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text:
                cleanText.isNotEmpty ? cleanText : 'Listo. Agendado. Buen dia.',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.appointmentCard,
            metadata: {
              'nombre': appointmentData['nombre'],
              'email': appointmentData['email'],
              'fecha': appointmentData['fecha'],
              'hora': appointmentData['hora'],
              'motivo': appointmentData['motivo'],
              'status': 'confirmed',
            },
          ));
        } catch (e) {
          // Webhook failed — inform user but don't crash
          final cleanText = _removeAppointmentTag(response);
          return Right(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text:
                '$cleanText\n\nHubo un error al agendar el evento. Por favor, intenta nuevamente.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
      }

      // === SELLER FLOW (default) ===
      // Normal text response about products/services
      return Right(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Extracts appointment data from the GPT response if the tag is present.
  /// Mirrors confirm.flow.ts: cleanedText → JSON.parse(cleanedText)
  Map<String, dynamic>? _extractAppointmentData(String response) {
    final regex =
        RegExp(r'\[AGENDAR_CITA\](.*?)\[/AGENDAR_CITA\]', dotAll: true);
    final match = regex.firstMatch(response);
    if (match != null) {
      try {
        final cleaned =
            match.group(1)!.replaceAll(RegExp(r'```json|```'), '').trim();
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Removes the appointment tag from the response text.
  String _removeAppointmentTag(String response) {
    return response
        .replaceAll(
            RegExp(r'\[AGENDAR_CITA\].*?\[/AGENDAR_CITA\]', dotAll: true), '')
        .trim();
  }
}
