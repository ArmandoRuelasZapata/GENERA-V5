import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security - Certificate Pinning Live Check', () {
    test('Server certificate should not expire in the next 30 days', () async {
      final client = HttpClient();
      bool isExpiringSoon = false;
      DateTime? expiryDate;

      // Usamos el callback para capturar el certificado vivo validado por el SO
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        expiryDate = cert.endValidity;

        final daysLeft = cert.endValidity.difference(DateTime.now()).inDays;
        // print('Certificate for $host expires on: $expiryDate ($daysLeft days left)');

        if (daysLeft < 30) {
          isExpiringSoon = true;
        }

        return true;
      };

      try {
        final request =
            await client.getUrl(Uri.parse('https://m0oqwu.easypanel.host'));
        final response = await request.close();

        // Si el certificado es validado exitosamente sin llamar a badCertificateCallback (confianza del SO),
        // recuperamos el cert usando la respuesta.
        if (response.certificate != null) {
          expiryDate = response.certificate!.endValidity;
          final daysLeft = response.certificate!.endValidity
              .difference(DateTime.now())
              .inDays;
          if (daysLeft < 30) {
            isExpiringSoon = true;
          }
        }
      } catch (e) {
        // Ignorar posibles errores de HTTP, solo queremos checar el Handshake/TLS
      } finally {
        client.close();
      }

      expect(expiryDate, isNotNull,
          reason:
              'No se pudo obtener el certificado del servidor m0oqwu.easypanel.host. Servidor inaccesible.');

      expect(isExpiringSoon, isFalse,
          reason:
              'ALERTA M5: El certificado TLS expira pronto ($expiryDate). Debes renovar el certificado y actualizar los bytes en _serverCertDer dentro del interceptor para evitar una caída total de la app por SSL Pinning estricto.');
    });
  });
}
