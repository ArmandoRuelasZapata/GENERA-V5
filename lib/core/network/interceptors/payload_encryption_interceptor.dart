import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';

// ignore_for_file: constant_identifier_names

/// OWASP M5 — Cifrado de Payload AES-256-CTR + HMAC-SHA256
///
/// ## Corrección anti-fuga GET (2026-03)
/// Antes: el interceptor saltaba para peticiones sin body (GET).
/// La cabecera X-Payload-Encrypted nunca se inyectaba.
/// El servidor respondía en texto plano.
///
/// Ahora:
///   1. Siempre se inyecta X-Payload-Encrypted: 1 (en todas las peticiones).
///   2. Los query parameters se cifran y viajan en X-Encrypted-Params: <base64>.
///      La URL se limpia de los queryParameters originales.
///   3. El servidor (Dart Frog) siempre cifra la respuesta si tiene crypto activo,
///      sin depender de este header del cliente.
///
/// ## Protocolo de envoltura
/// Request body cifrado:   { "enc": "<base64(iv + ciphertext + hmac)>" }
/// Query params cifrados:  X-Encrypted-Params: <base64(iv + ciphertext + hmac)>
/// Response cifrada:       { "enc": "<base64(iv + ciphertext + hmac)>" }
///
/// ## Algoritmo
/// AES-256-CTR (HMAC-SHA256 como keystream PRF) + HMAC-SHA256 Encrypt-then-MAC.
/// Mismo algoritmo que PayloadCrypto en Dart Frog.
class PayloadEncryptionInterceptor extends Interceptor {
  /// Clave de cifrado inyectada via envied (.env.prod o .env.dev)
  /// Debe ser exactamente 64 caracteres hex (= 32 bytes = AES-256).
  static String get _rawKey => Env.payloadEncryptionKey;

  /// true cuando el interceptor está operativo (clave configurada correctamente).
  static bool get isEnabled => _rawKey.length == 64 && _keyBytes != null;

  static Uint8List? get _keyBytes {
    if (_rawKey.length != 64) return null;
    try {
      final bytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        bytes[i] = int.parse(_rawKey.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  // Request: cifrar body y query params

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Anti-replay SIEMPRE para mutaciones, aunque el cifrado esté apagado.
    // El backend lo requiere cuando REPLAY_GUARD_ENABLED=true.
    _attachReplayHeaders(options);

    if (!isEnabled) return handler.next(options);
    if (options.extra['skipEncryption'] == true) return handler.next(options);

    try {
      // 1. Siempre señalizar al servidor que esperamos respuesta cifrada
      options.headers['X-Payload-Encrypted'] = '1';

      // 2. Cifrar query parameters (si los hay)
      //    Los movemos a una cabecera cifrada para que no viajen en la URL.
      final queryParams = Map<String, dynamic>.from(options.queryParameters);
      if (queryParams.isNotEmpty) {
        final encryptedParams = _encryptObject(queryParams);
        options.headers['X-Encrypted-Params'] = encryptedParams;
        // Limpiar la URL de los query params originales (no deben viajar en claro)
        options.queryParameters.clear();
      }

      // 3. Cifrar body (solo si hay datos para cifrar)
      if (options.data != null) {
        final plaintext = utf8.encode(jsonEncode(options.data));
        final encrypted = _encryptAesCtrHmac(plaintext);
        options.data = {'enc': base64.encode(encrypted)};
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PayloadEncryption: error cifrando request: $e');
      }
    }

    handler.next(options);
  }

  static void _attachReplayHeaders(RequestOptions options) {
    final method = options.method.toUpperCase();
    final isMutation = method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
    if (!isMutation) return;

    final nowEpochSeconds =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    options.headers['X-Request-Timestamp'] = nowEpochSeconds.toString();
    options.headers['X-Request-Nonce'] = _buildNonce();
  }

  static String _buildNonce() {
    final bytes = _randomBytes(16);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  // Response: descifrar body al recibirlo

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!isEnabled) return handler.next(response);

    // El servidor normaliza headers a minúsculas; Dio puede entregar ambos.
    final encHeader = response.headers.value('X-Payload-Encrypted') ??
        response.headers.value('x-payload-encrypted') ??
        '';
    if (encHeader != '1') return handler.next(response);

    try {
      final data = response.data;
      if (data is Map && data.containsKey('enc')) {
        final ciphertext = base64.decode(data['enc'] as String);
        final plaintext = _decryptAesCtrHmac(ciphertext);
        response.data = jsonDecode(utf8.decode(plaintext));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PayloadEncryption: error descifrando response: $e');
      }
    }

    handler.next(response);
  }

  // Helpers de alto nivel

  /// Cifra un Map/objeto y retorna el base64 del blob.
  static String _encryptObject(Map<String, dynamic> data) {
    final plaintext = utf8.encode(jsonEncode(data));
    final blob = _encryptAesCtrHmac(plaintext);
    return base64.encode(blob);
  }

  // Primitivas criptográficas

  static const int _ivLen = 16; // 128-bit IV
  static const int _macLen = 32; // HMAC-SHA256 = 256 bits

  /// AES-256-CTR (manual) + HMAC-SHA256 → Encrypt-then-MAC
  ///
  /// Formato del blob: [ IV (16) | ciphertext (n) | HMAC (32) ]
  static Uint8List _encryptAesCtrHmac(List<int> plaintext) {
    final key = _keyBytes!;
    final iv = _randomBytes(_ivLen);
    final ciphertext = _aesCtr(key, iv, plaintext);
    final mac = _hmacSha256(key, [...iv, ...ciphertext]);

    final out = Uint8List(_ivLen + ciphertext.length + _macLen);
    out.setRange(0, _ivLen, iv);
    out.setRange(_ivLen, _ivLen + ciphertext.length, ciphertext);
    out.setRange(_ivLen + ciphertext.length, out.length, mac);
    return out;
  }

  /// Verifica MAC y descifra.
  static Uint8List _decryptAesCtrHmac(Uint8List blob) {
    if (blob.length < _ivLen + _macLen) {
      throw const FormatException('Blob cifrado demasiado corto');
    }

    final key = _keyBytes!;
    final iv = blob.sublist(0, _ivLen);
    final ciphertext = blob.sublist(_ivLen, blob.length - _macLen);
    final mac = blob.sublist(blob.length - _macLen);

    // Verificar MAC (constant-time compare)
    final expectedMac = _hmacSha256(key, [...iv, ...ciphertext]);
    if (!_constantTimeEquals(mac, expectedMac)) {
      throw StateError('MAC inválido — posible manipulación del payload');
    }

    return _aesCtr(key, iv, ciphertext);
  }

  // AES-256 en modo CTR (implementación pura Dart)

  static Uint8List _aesCtr(Uint8List key, List<int> iv, List<int> data) {
    final aesKey = _deriveAesKey(key);
    final out = Uint8List(data.length);
    final counter = Uint8List(16)..setRange(0, 16, iv);

    var blockStart = 0;
    while (blockStart < data.length) {
      final keystream = _aesBlock(aesKey, counter);
      final blockLen = min(16, data.length - blockStart);
      for (var i = 0; i < blockLen; i++) {
        out[blockStart + i] = data[blockStart + i] ^ keystream[i];
      }
      _incrementCounter(counter);
      blockStart += 16;
    }
    return out;
  }

  static Uint8List _deriveAesKey(Uint8List masterKey) {
    final info = utf8.encode('aes-ctr-key');
    final hmac = Hmac(sha256, masterKey);
    return Uint8List.fromList(hmac.convert(info).bytes);
  }

  static Uint8List _aesBlock(Uint8List derivedKey, Uint8List counter) {
    final hmac = Hmac(sha256, derivedKey);
    final digest = hmac.convert(counter).bytes;
    return Uint8List.fromList(digest);
  }

  static void _incrementCounter(Uint8List counter) {
    for (var i = counter.length - 1; i >= 0; i--) {
      if (counter[i] == 255) {
        counter[i] = 0;
      } else {
        counter[i]++;
        break;
      }
    }
  }

  // ─── Primitivas de soporte ────────────────────────────────────────────────

  static Uint8List _hmacSha256(Uint8List key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return Uint8List.fromList(hmac.convert(data).bytes);
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  /// Comparación en tiempo constante (evita timing attacks).
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
