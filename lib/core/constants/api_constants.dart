import '../config/env.dart';

class ApiConstants {
  // Base URLs (configured via envied)
  static final String baseUrl = Env.authApiBaseUrl;

  // Auth Endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String activateEndpoint = '/api/activate';
  static const String deactivateEndpoint = '/api/deactivate';
  static const String eliminateAccountEndpoint = '/api/eliminate_account';

  // Password Reset Endpoints
  static const String emailResetPassword = '/api/email_reset_password';
  static const String verifyCode = '/api/verify_code';
  static const String changePassword = '/api/change_password';

  // Content API
  static final String contentBaseUrl = Env.contentApiBaseUrl;
  static final String contentApiKey = Env.contentApiKey;
  static final String ticketsApiBaseUrl = Env.ticketsApiBaseUrl;
  static final String ticketsApiKey = Env.contentApiKey;

  // Content Endpoints
  static const String homeContent = '/home';
  static const String homeContentApi = '/api/home';
  static const String homeContentApiV1 = '/api/v1/home';

  // Proxy de IA — la OPENAI_API_KEY vive solo en el servidor.
  // El cliente llama a este proxy; nunca habla con OpenAI directamente.
  static final String aiProxyUrl = Env.aiProxyUrl;

  // As STORE_API_BASE_URL is not strictly protected, we maintain the default logic here statically
  static const String storeApiBaseUrl = 'https://originallabstore.com';

  // Appointments proxy — el servidor llama a Make.com; el cliente no lo sabe.
  // GET  /appointments → agenda actual
  // POST /appointments → crear nueva cita
  static const String appointmentsEndpoint = '/appointments';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration appointmentsTimeout = Duration(seconds: 60);
  // OWASP M5: por defecto deshabilitado en release para no exponer
  // URLs, headers ni cuerpos de peticiones HTTP en logs del sistema.
  // Para activar en debug: configurado via envied.
  static final bool enableNetworkLogs = Env.enableNetworkLogs;
  static const int networkMaxRetries = int.fromEnvironment(
    'NETWORK_MAX_RETRIES',
    defaultValue: 2,
  );

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> get contentHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (contentApiKey.isNotEmpty) {
      headers['apikey'] = contentApiKey;
    }
    return headers;
  }

  static String get resolvedTicketsApiBaseUrl => _normalizeTicketsBaseUrl(
        ticketsApiBaseUrl.isNotEmpty ? ticketsApiBaseUrl : contentBaseUrl,
      );

  static String _normalizeTicketsBaseUrl(String rawUrl) {
    var normalized = rawUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

  static Map<String, String> get ticketsHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final key = ticketsApiKey.isNotEmpty ? ticketsApiKey : contentApiKey;
    if (key.isNotEmpty) {
      headers['apikey'] = key;
    }
    return headers;
  }

  // openAiHeaders eliminado — el cliente usa aiProxyUrl que ya es autenticado
  // por el apikey header del middleware del servidor. La Authorization con Bearer
  // de OpenAI la pone el servidor, nunca el cliente.

  static List<String> get homeContentCandidates {
    final ordered = <String>[homeContent, homeContentApi, homeContentApiV1];
    final deduped = <String>[];
    for (final endpoint in ordered) {
      if (!deduped.contains(endpoint)) {
        deduped.add(endpoint);
      }
    }
    return deduped;
  }
}
