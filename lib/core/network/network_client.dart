import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/certificate_pinning_interceptor.dart';
import 'interceptors/payload_encryption_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/unauthorized_interceptor.dart';

class AppNetworkClient {
  final AuthTokenReader readToken;

  /// Callback invocado cuando el servidor responde con 401 (token expirado).
  /// Si es null, la sesión no se cierra automáticamente.
  final OnUnauthorized? onUnauthorized;

  final Map<String, Dio> _clients = {};

  AppNetworkClient({
    required this.readToken,
    this.onUnauthorized,
  });

  /// [usePinning]: activa Certificate Pinning en release.
  /// Pásalo como `false` solo para clientes que hablan con CDNs o servicios
  /// externos (Firebase, Google Maps, etc.) que tienen su propio cert.
  ///
  /// [useEncryption]: activa payload AES-256-CTR+HMAC. Solo activar en
  /// clientes que apuntan a TU API (que tiene el middleware de descifrado).
  /// Dejar en `false` para APIs externas (auth, OpenAI, webhooks, tienda).
  Dio createClient({
    required String baseUrl,
    Map<String, String>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool enableAuth = true,
    bool enableRetry = true,
    bool skipAuthByDefault = false,
    bool usePinning = true,
    bool useEncryption = false,
  }) {
    final resolvedConnectTimeout =
        connectTimeout ?? ApiConstants.connectTimeout;
    final resolvedReceiveTimeout =
        receiveTimeout ?? ApiConstants.receiveTimeout;
    final resolvedHeaders = <String, String>{
      ...ApiConstants.defaultHeaders,
      ...?headers,
    };

    final key = _clientKey(
      baseUrl: baseUrl,
      headers: resolvedHeaders,
      connectTimeout: resolvedConnectTimeout,
      receiveTimeout: resolvedReceiveTimeout,
      enableAuth: enableAuth,
      enableRetry: enableRetry,
      skipAuthByDefault: skipAuthByDefault,
      usePinning: usePinning,
      useEncryption: useEncryption,
    );

    final cached = _clients[key];
    if (cached != null) {
      return cached;
    }

    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: resolvedConnectTimeout,
      sendTimeout: resolvedConnectTimeout,
      receiveTimeout: resolvedReceiveTimeout,
      headers: resolvedHeaders,
      extra: {'skipAuth': skipAuthByDefault},
    );

    // OWASP M5: Certificate Pinning habilitado en modo release.
    // En release: SecurityContext solo confía en el cert DER embebido.
    //   → Burp Suite, mitmproxy y cualquier CA externa son rechazados.
    // En debug: usa Dio estándar para permitir proxies durante desarrollo.
    final dio = (usePinning && !kDebugMode)
        ? buildPinnedDio(options)
        : buildDefaultDio(options);

    // Cifrado de payload AES-256-CTR+HMAC — activo solo en clientes que
    // apuntan a nuestra API propia (la que tiene el middleware de descifrado).
    // useEncryption=false en auth, OpenAI y servicios externos.
    if (useEncryption) {
      dio.interceptors.add(PayloadEncryptionInterceptor());
    }

    if (enableAuth) {
      dio.interceptors.add(AuthInterceptor(readToken: readToken));
      // Detecta 401 (token expirado) y ejecuta el cierre de sesión automático
      if (onUnauthorized != null) {
        dio.interceptors.add(
          UnauthorizedInterceptor(onUnauthorized: onUnauthorized!),
        );
      }
    }

    if (enableRetry) {
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: ApiConstants.networkMaxRetries,
          initialDelay: const Duration(milliseconds: 300),
        ),
      );
    }

    // Permitir logs también en release si se habilita explícitamente por env.
    final loggingEnabled = ApiConstants.enableNetworkLogs;
    if (loggingEnabled) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }

    _clients[key] = dio;
    return dio;
  }

  String _clientKey({
    required String baseUrl,
    required Map<String, String> headers,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required bool enableAuth,
    required bool enableRetry,
    required bool skipAuthByDefault,
    required bool usePinning,
    required bool useEncryption,
  }) {
    final sortedHeaderKeys = headers.keys.toList()..sort();
    final headerPart =
        sortedHeaderKeys.map((k) => '$k=${headers[k]}').join('&');
    return [
      baseUrl,
      'ct=${connectTimeout.inMilliseconds}',
      'rt=${receiveTimeout.inMilliseconds}',
      'auth=$enableAuth',
      'retry=$enableRetry',
      'skipAuth=$skipAuthByDefault',
      'pin=$usePinning',
      'enc=$useEncryption',
      'headers:$headerPart',
    ].join('|');
  }
}
