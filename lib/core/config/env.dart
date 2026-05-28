import 'package:envied/envied.dart';
import 'package:flutter/foundation.dart';

part 'env.g.dart';

@Envied(path: '.env.prod', requireEnvFile: true)
abstract class EnvProd {
  @EnviedField(varName: 'AUTH_API_BASE_URL', obfuscate: true)
  static final String authApiBaseUrl = _EnvProd.authApiBaseUrl;

  @EnviedField(varName: 'CONTENT_API_BASE_URL', obfuscate: true)
  static final String contentApiBaseUrl = _EnvProd.contentApiBaseUrl;

  @EnviedField(varName: 'TICKETS_API_BASE_URL', obfuscate: true)
  static final String ticketsApiBaseUrl = _EnvProd.ticketsApiBaseUrl;

  @EnviedField(varName: 'CONTENT_API_KEY', obfuscate: true)
  static final String contentApiKey = _EnvProd.contentApiKey;

  @EnviedField(varName: 'AI_PROXY_URL', obfuscate: true)
  static final String aiProxyUrl = _EnvProd.aiProxyUrl;

  @EnviedField(varName: 'MAPS_API_KEY', obfuscate: true)
  static final String mapsApiKey = _EnvProd.mapsApiKey;

  @EnviedField(varName: 'PAYLOAD_ENCRYPTION_KEY', obfuscate: true)
  static final String payloadEncryptionKey = _EnvProd.payloadEncryptionKey;

  @EnviedField(varName: 'ENABLE_NETWORK_LOGS', defaultValue: false)
  static const bool enableNetworkLogs = _EnvProd.enableNetworkLogs;
}

@Envied(path: '.env.dev', requireEnvFile: true)
abstract class EnvDev {
  @EnviedField(varName: 'AUTH_API_BASE_URL', obfuscate: true)
  static final String authApiBaseUrl = _EnvDev.authApiBaseUrl;

  @EnviedField(varName: 'CONTENT_API_BASE_URL', obfuscate: true)
  static final String contentApiBaseUrl = _EnvDev.contentApiBaseUrl;

  @EnviedField(varName: 'TICKETS_API_BASE_URL', obfuscate: true)
  static final String ticketsApiBaseUrl = _EnvDev.ticketsApiBaseUrl;

  @EnviedField(varName: 'CONTENT_API_KEY', obfuscate: true)
  static final String contentApiKey = _EnvDev.contentApiKey;

  @EnviedField(varName: 'AI_PROXY_URL', obfuscate: true)
  static final String aiProxyUrl = _EnvDev.aiProxyUrl;

  @EnviedField(varName: 'MAPS_API_KEY', obfuscate: true)
  static final String mapsApiKey = _EnvDev.mapsApiKey;

  @EnviedField(varName: 'PAYLOAD_ENCRYPTION_KEY', obfuscate: true)
  static final String payloadEncryptionKey = _EnvDev.payloadEncryptionKey;

  @EnviedField(varName: 'ENABLE_NETWORK_LOGS', defaultValue: true)
  static const bool enableNetworkLogs = _EnvDev.enableNetworkLogs;
}

class Env {
  static String get authApiBaseUrl =>
      kReleaseMode ? EnvProd.authApiBaseUrl : EnvDev.authApiBaseUrl;
  static String get contentApiBaseUrl =>
      kReleaseMode ? EnvProd.contentApiBaseUrl : EnvDev.contentApiBaseUrl;
  static String get ticketsApiBaseUrl =>
      kReleaseMode ? EnvProd.ticketsApiBaseUrl : EnvDev.ticketsApiBaseUrl;
  static String get contentApiKey =>
      kReleaseMode ? EnvProd.contentApiKey : EnvDev.contentApiKey;
  static String get aiProxyUrl =>
      kReleaseMode ? EnvProd.aiProxyUrl : EnvDev.aiProxyUrl;
  static String get mapsApiKey =>
      kReleaseMode ? EnvProd.mapsApiKey : EnvDev.mapsApiKey;
  static String get payloadEncryptionKey =>
      kReleaseMode ? EnvProd.payloadEncryptionKey : EnvDev.payloadEncryptionKey;
  static bool get enableNetworkLogs {
    // Permite override por --dart-define / --dart-define-from-file sin
    // regenerar env.g.dart (Envied). Útil para activar logs en release.
    const override =
        String.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: '');
    if (override.isNotEmpty) {
      final normalized = override.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return kReleaseMode ? EnvProd.enableNetworkLogs : EnvDev.enableNetworkLogs;
  }
}
