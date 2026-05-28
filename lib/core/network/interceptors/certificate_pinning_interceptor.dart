import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// OWASP M5 — Certificate Pinning real usando SecurityContext.
///
/// El certificado DER del servidor está embebido directamente en el binario.
/// En producción, el HttpClient solo aceptará el certificado cuyo DER coincida
/// con los bytes almacenados aquí. Cualquier otro certificado (incluso uno
/// válido emitido por otra CA) será rechazado.
///
/// MANTENIMIENTO CRITICO:
/// Cuando Easypanel rota el certificado (actualmente expira 2026-06-22):
/// 1. Ejecutar: openssl s_client -connect HOST:443 | openssl x509 -outform DER > server.der
/// 2. Regenerar los bytes: python3 -c "data=open('server.der','rb').read(); print([hex(b) for b in data])"
/// 3. Actualizar _serverCertDer con los nuevos bytes ANTES de que expire el cert.
/// 4. Publicar nueva versión de la app con la fecha de rotación planificada.
///
/// Recomendación pro:
/// - Mantén **2 certs** en _pinnedCertsPem durante la ventana de rotación:
///   el actual y el siguiente. Así evitas caídas si el cert rota temprano.
///
/// Servidor: *.m0oqwu.easypanel.host (Let's Encrypt E7)
/// Expira: 2026-06-22
// ignore_for_file: prefer_collection_literals
const List<String> _pinnedCertsPem = [
  '''-----BEGIN CERTIFICATE-----
MIIDrjCCAzSgAwIBAgISBlhNDYRu1NBqWGi6tkmqOfpbMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
NzAeFw0yNjAzMjQwNTQzNDlaFw0yNjA2MjIwNTQzNDhaMCIxIDAeBgNVBAMMFyou
bTBvcXd1LmVhc3lwYW5lbC5ob3N0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
qGO/bODgymk7Z+Te6mxOXEP4ozkPk6SOURfUkwfZz++NTitJIOHRq28nQJzt9Ocd
CdDZlVIsIoi5Di9goVtSDKOCAjgwggI0MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE
DDAKBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBQsXD83i+vDHsBq
t5IBvuEBEqTtczAfBgNVHSMEGDAWgBSuSJ7chx1EoG/aouVgdAR4wpwAgDAyBggr
BgEFBQcBAQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly9lNy5pLmxlbmNyLm9yZy8w
OQYDVR0RBDIwMIIXKi5tMG9xd3UuZWFzeXBhbmVsLmhvc3SCFW0wb3F3dS5lYXN5
cGFuZWwuaG9zdDATBgNVHSAEDDAKMAgGBmeBDAECATAtBgNVHR8EJjAkMCKgIKAe
hhxodHRwOi8vZTcuYy5sZW5jci5vcmcvOTIuY3JsMIIBCgYKKwYBBAHWeQIEAgSB
+wSB+AD2AHUASZybad4dfOz8Nt7Nh2SmuFuvCoeAGdFVUvvp6ynd+MMAAAGdHpR2
CQAABAMARjBEAiB5YTb95nzlHKGO2kebP4hKghr2J4jVIF7f67W0IlfdWQIgHO2V
L0FMcQZ/1uCfqn6DoBhiYmdH02g6C9OFJVXSMiIAfQCoJsvjCsY1EkZTP+Bl8U8Z
2W4ZCBPEHdlteQCzEjxVJwAAAZ0elHbqAAgAAAUABBnkTAQDAEYwRAIgP0LTNEnM
eXCfkmZMakw6a2SzQCMm+9DIccZZ5Oc81awCICCy6RRu1mErusy6IDigaxxKgeFH
18DZDYgbdVnT3MyHMAoGCCqGSM49BAMDA2gAMGUCMAYuZ7B8B5E8Jb/nImcL3/Xj
GJH4Y9S8gim04jGj8tyIKPp8496RSTokqdz4HlAVNwIxAIrHmW4k4aPpRPnkHUpW
X+srdhmMNWvptRTTCc6Ujzp7FI5kiOCsFyTRoip3b11GGA==
-----END CERTIFICATE-----''',
];

/// Construye un [Dio] con Certificate Pinning **real** usando [SecurityContext].
///
/// A diferencia de [badCertificateCallback] (que solo se invoca para certs
/// ya rechazados por el OS), [SecurityContext.setTrustedCertificatesBytes]
/// reemplaza completamente el almacén de confianza: solo el certificado
/// embebido es aceptado, sin importar si otra CA válida firmó el cert del servidor.
///
/// - En **release**: usa SecurityContext con el cert embebido → pinning real.
/// - En **debug**: usa el contexto por defecto → acepta todas las CAs del sistema.
Dio buildPinnedDio(BaseOptions options) {
  final dio = Dio(options);

  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    // En modo debug/test, saltar el pinning para facilitar el desarrollo
    // con proxies como Charles o mitmproxy.
    assert(() {
      return true;
    }());

    final context = SecurityContext(withTrustedRoots: false);
    for (final pem in _pinnedCertsPem) {
      context.setTrustedCertificatesBytes(utf8.encode(pem));
    }

    final client = HttpClient(context: context);
    // No aceptar certs inválidos incluso con el contexto restrictivo
    client.badCertificateCallback = (_, __, ___) => false;
    return client;
  };

  return dio;
}

/// Versión debug/test que acepta cualquier certificado del sistema.
Dio buildDefaultDio(BaseOptions options) => Dio(options);
