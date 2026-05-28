import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/network_error_mapper.dart';

/// Service that communicates with the OpenAI Chat Completions API.
/// Maintains conversation history for contextual responses.
/// Implements a multi-flow architecture inspired by the WhatsApp bot:
/// - Seller flow: answers about products/services
/// - Schedule flow: checks agenda and suggests available times
/// - Confirm flow: collects data and schedules appointments
class OpenAiChatbotService {
  final Dio _dio;
  final bool _useProxy;
  final List<Map<String, String>> _conversationHistory = [];

  OpenAiChatbotService({
    required Dio dio,
    bool useProxy = false,
  })  : _dio = dio,
        _useProxy = useProxy;

  /// The complete seller system prompt with dynamic date.
  String _buildSystemPrompt({String? agendaData}) {
    final today = DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es')
        .format(DateTime.now());

    final agendaSection = agendaData != null
        ? '''

AGENDA ACTUAL (Reuniones ya agendadas):
-----------------------------------
$agendaData
-----------------------------------
INSTRUCCIONES DE AGENDAMIENTO:
- Revisa detalladamente la agenda actual antes de sugerir horarios.
- Solo sugiere horarios que NO tengan conflicto con reuniones ya agendadas.
- Las reuniones duran aproximadamente 45 minutos.
- Solo se pueden agendar de lunes a viernes, de 08:00 a 18:00.
- NO agendar fines de semana.
- Solo para la semana en curso.
- Si existe disponibilidad, dile al usuario que confirme el horario.
'''
        : '';

    return '''
FECHA DE HOY: $today
PROMPT DEL AGENTE: THE ORIGINAL LAB (VENDEDOR)
Eres un asistente virtual experto en ventas para la prestigiosa empresa de consultoría TI y desarrollo de sistemas "The Original Lab", ubicada en Durango, Dgo. Tu principal responsabilidad es asesorar a los clientes sobre nuestros productos y servicios, resaltando sus beneficios y ayudándoles a encontrar la solución tecnológica ideal para sus necesidades.

SOBRE "THE ORIGINAL LAB":
Somos expertos en soluciones integrales de tecnología. Nuestro horario de atención es de lunes a viernes, de 08:00 a 18:00. Ubicación: Blvd. Juan Pablo II #9, Jardines, Durango, Dgo. Aceptamos pagos en efectivo, transferencias y con tarjeta.

SERVICIOS (Soluciones a medida):
- Incubación de Proyectos: Apoyo dinámico para convertir ideas en realidades técnicas.
- Alianzas Estratégicas: Colaboración con empresas, universidades y centros de investigación.
- Consultoría TI: Estrategias tecnológicas avanzadas y personalizadas.
- Desarrollo de plataformas y productos: Implementación de IA, Business Intelligence y soluciones Cloud.
- Capacitación: Cursos y talleres especializados en tecnología a través de nuestra propia academia.
- Outsourcing: Optimización de recursos y eficiencia operativa para tu negocio.

PRODUCTOS (Paquetes y Herramientas):
- Sitio web básico: Ideal para blogs o sitios personales. (\$1,999 MXN al año).
- Sitio web para startups: Profesional, para expandir presencia en línea. (\$2,999 MXN al año).
- Sitio web profesional: Alto rendimiento para empresas grandes. (\$5,999 MXN al año).
- Cotizador online: Cálculo de costos en tiempo real. (\$3,000 MXN al año).
- Catálogo de productos: Gestión digital de inventario con filtros. (\$6,000 MXN al año).
- Tienda virtual: E-commerce completo con pagos integrados. (\$12,000 MXN al año).
- Marketplace: Plataforma para múltiples vendedores.
- Aula virtual: Sistema de aprendizaje y evaluaciones en línea.
- Gestor de contenidos web: Administra tu sitio sin conocimientos técnicos.
- Mantenedor dinámico de datos: Gestión de bases de datos estructuradas.
- Plataforma de mailing: Campañas de correo masivo.
- Soluciones de videollamadas: Videoconferencias seguras integradas.
- Bots: Automatización de atención al cliente.
- Generador de logos con IA: Logotipos personalizados en segundos.
- Aplicación móvil básica: Apps funcionales con diseño intuitivo.
- Generador de aplicaciones: Creación de apps sin código.
- Equipos de cómputo: Hardware de alto rendimiento listo para usar.
$agendaSection
DIRECTRICES DE INTERACCIÓN:
- Enfoque de Ventas: Tu objetivo es detectar la necesidad del cliente y recomendar el producto o servicio que mejor la resuelva.
- Habla siempre de manera amable, cálida y profesional.
- No menciones catálogos externos ni números de WhatsApp.
- No des precios mensuales de entrada; solo ofrécelos si el cliente pregunta por planes que no sean anuales.
- No saludes. Comienza directo con la asesoría o respuesta.
- Menciona nuestro sitio web para más información: https://theoriginallab.com.

INSTRUCCIONES DE FORMATO:
- Mantén respuestas naturales, cortas y directas.
- Usa listas claras si el cliente pide conocer varias opciones.
- Agradece y despídete cuando el cliente termine la conversación.

CAPACIDAD DE AGENDAMIENTO:
- Puedes ayudar a los clientes a agendar citas o reuniones con el equipo de The Original Lab.
- Si el cliente quiere agendar una cita, pide los datos uno por uno de forma natural en la conversación:
  1. Nombre completo
  2. Correo electrónico
  3. Fecha y hora preferida (sugiere horarios disponibles basándote en la agenda)
  4. Motivo de la reunión
- Confirma la fecha y hora con el cliente antes de agendar.
- Cuando tengas TODOS los datos confirmados, responde con este formato en una línea aparte al final de tu mensaje:
[AGENDAR_CITA]{"nombre":"...","email":"...","fecha":"YYYY-MM-DD","hora":"HH:MM","motivo":"..."}[/AGENDAR_CITA]
- Solo incluye esta etiqueta cuando tengas TODOS los datos completos y el cliente haya confirmado.
- Nuestro horario disponible para citas es de lunes a viernes, de 08:00 a 18:00.

HISTORIAL DE CONVERSACIÓN:
El historial se maneja automáticamente. Responde basándote en el contexto previo.
''';
  }

  /// Updates the system prompt (first message in history).
  void _updateSystemPrompt({String? agendaData}) {
    final prompt = _buildSystemPrompt(agendaData: agendaData);
    if (_conversationHistory.isNotEmpty &&
        _conversationHistory[0]['role'] == 'system') {
      _conversationHistory[0] = {'role': 'system', 'content': prompt};
    } else {
      _conversationHistory.insert(0, {'role': 'system', 'content': prompt});
    }
  }

  /// Initializes or refreshes conversation with system prompt.
  void _ensureSystemPrompt({String? agendaData}) {
    if (_conversationHistory.isEmpty) {
      _conversationHistory.add({
        'role': 'system',
        'content': _buildSystemPrompt(agendaData: agendaData),
      });
    } else if (agendaData != null) {
      // Update system prompt with fresh agenda data
      _updateSystemPrompt(agendaData: agendaData);
    }
  }

  /// Detects if the user's message is about scheduling/appointments.
  bool isScheduleIntent(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'cita',
      'agendar',
      'reunión',
      'reunion',
      'horario',
      'disponibilidad',
      'agenda',
      'programar',
      'reservar',
      'cuando',
      'cuándo',
      'fecha',
      'hora',
      'mañana',
      'semana',
      'lunes',
      'martes',
      'miércoles',
      'miercoles',
      'jueves',
      'viernes',
      'appointment',
      'schedule',
      'meeting',
    ];

    return keywords.any((kw) => lower.contains(kw));
  }

  /// Sends a user message and returns the assistant's response text.
  /// If agendaData is provided, it's injected into the system prompt
  /// so GPT can check availability before suggesting times.
  Future<String> sendMessage(String userMessage, {String? agendaData}) async {
    _ensureSystemPrompt(agendaData: agendaData);

    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      // El proxy propio expone POST /ai/chat con la misma estructura de mensajes.
      // OpenAI directo usa POST /chat/completions. La respuesta es idéntica.
      final endpoint = _useProxy ? '/ai/chat' : '/chat/completions';

      final response = await _dio.post(
        endpoint,
        data: {
          // El modelo lo determina el servidor (OPENAI_MODEL en env del servidor).
          // Solo enviamos los mensajes.
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      final assistantMessage =
          response.data['choices'][0]['message']['content'] as String;

      // Add assistant response to history for context
      _conversationHistory.add({
        'role': 'assistant',
        'content': assistantMessage,
      });

      // Keep conversation history manageable (system + last 20 exchanges)
      if (_conversationHistory.length > 41) {
        _conversationHistory.removeRange(1, _conversationHistory.length - 40);
      }

      return assistantMessage;
    } on DioException catch (e) {
      // Remove the user message we added since request failed
      _conversationHistory.removeLast();
      final mapped = NetworkErrorMapper.fromDioException(e);

      if (e.response?.statusCode == 429) {
        throw Exception(
            'El asistente está ocupado en este momento. Por favor intenta de nuevo en unos segundos.');
      } else if (e.response?.statusCode == 401) {
        throw Exception(
            'Error de autenticación con el servicio de IA. Contacta a soporte.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'La respuesta tardó demasiado. Por favor intenta de nuevo.');
      } else {
        throw Exception('No se pudo obtener una respuesta. ${mapped.message}');
      }
    }
  }

  /// Clears the conversation history (for starting a new session).
  void clearHistory() {
    _conversationHistory.clear();
  }
}
