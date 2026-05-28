import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'dart:developer' as developer;

class ConfigValidator {
  static void validate() {
    final missingKeys = <String>[];
    final invalidKeys = <String>[];

    // El chatbot y las citas usan proxies propios (AI_PROXY_URL / contentBaseUrl).
    // No se necesita OPENAI_API_KEY, AGENDA_WEBHOOK_URL ni SCHEDULE_WEBHOOK_URL
    // en el cliente. Si AI_PROXY_URL está vacío, el chatbot mostrará error al usarse.
    final warningKeys = <String>[];
    if (ApiConstants.aiProxyUrl.isEmpty) {
      warningKeys.add('AI_PROXY_URL (chatbot desactivado sin proxy)');
    }

    if (ApiConstants.baseUrl.isEmpty) missingKeys.add('AUTH_API_BASE_URL');
    if (ApiConstants.contentBaseUrl.isEmpty) {
      missingKeys.add('CONTENT_API_BASE_URL');
    }
    if (ApiConstants.contentApiKey.isEmpty) missingKeys.add('CONTENT_API_KEY');

    if (_endsWithApiSegment(ApiConstants.baseUrl)) {
      invalidKeys.add('AUTH_API_BASE_URL (no debe terminar en /api)');
    } else if (!ApiConstants.baseUrl.startsWith('https://')) {
      invalidKeys.add('AUTH_API_BASE_URL (debe usar HTTPS)');
    }

    if (_endsWithApiSegment(ApiConstants.contentBaseUrl)) {
      invalidKeys.add('CONTENT_API_BASE_URL (no debe terminar en /api)');
    } else if (!ApiConstants.contentBaseUrl.startsWith('https://')) {
      invalidKeys.add('CONTENT_API_BASE_URL (debe usar HTTPS)');
    }

    if (ApiConstants.ticketsApiBaseUrl.isNotEmpty) {
      if (_endsWithApiSegment(ApiConstants.ticketsApiBaseUrl)) {
        invalidKeys.add('TICKETS_API_BASE_URL (no debe terminar en /api)');
      }
      if (!ApiConstants.ticketsApiBaseUrl.startsWith('https://')) {
        invalidKeys.add('TICKETS_API_BASE_URL (debe usar HTTPS)');
      }
    }

    // Log non-fatal warnings first (always, not only on error)
    if (warningKeys.isNotEmpty) {
      developer.log(
        'CONFIG WARNING: ${warningKeys.join(', ')}',
        name: 'ConfigValidator',
      );
    }

    if (missingKeys.isNotEmpty || invalidKeys.isNotEmpty) {
      final sections = <String>[];
      if (missingKeys.isNotEmpty) {
        sections
            .add('Faltan configuraciones críticas:\n${missingKeys.join('\n')}');
      }
      if (invalidKeys.isNotEmpty) {
        sections.add(
          'Hay configuraciones inválidas:\n${invalidKeys.join('\n')}\n'
          'Usa base URLs sin sufijo /api, porque los endpoints ya incluyen ese prefijo.',
        );
      }
      final message =
          '${sections.join('\n\n')}\nAsegúrate de ejecutar con --dart-define-from-file=.env.prod.json';

      // Nunca lanzar excepción aquí: crashea la app antes del primer frame
      // en release/TestFlight. En su lugar, loguear el error y dejar que la app
      // inicie; las pantallas de API mostrarán sus propios errores de red.
      developer.log(
        'CONFIG ERROR: $message',
        name: 'ConfigValidator',
        level: 1200, // Level.SHOUT
      );
      // En debug, además imprimimos en consola para visibilidad inmediata.
      if (kDebugMode) {
        developer.log(
          'ADVERTENCIA DE CONFIGURACION:\n$message',
          name: 'ConfigValidator',
        );
      }
    }
  }

  static bool _endsWithApiSegment(String value) {
    var normalized = value.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.endsWith('/api');
  }
}
