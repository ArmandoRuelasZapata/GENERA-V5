import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security Static Analysis', () {
    test(
        'Should detect insecure SharedPreferences usage for potential sensitive data',
        () async {
      final libDir = Directory('lib');
      final sensitiveKeywords = ['apikey', 'password', 'auth', 'secret'];

      if (!libDir.existsSync()) {
        return;
      }

      final sourceFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in sourceFiles) {
        if (file.path.endsWith('main.dart')) {
          continue; // Skip main.dart (valid use of SharedPreferences + FCM tokens)
        }

        if (file.path.contains('notifications_provider.dart')) {
          continue; // Skip notifications (valid use of SharedPreferences to store non-sensitive boolean seen status)
        }

        final content = await file.readAsString();

        // Naive check: SharedPreferences usage combined with sensitive keywords in the same file
        if (content.contains('SharedPreferences') ||
            content.contains('shared_preferences')) {
          for (final keyword in sensitiveKeywords) {
            if (content.toLowerCase().contains(keyword) &&
                !content.contains('flutter_secure_storage')) {
              violations.add(
                  '${file.path} uses SharedPreferences but mentions "$keyword". Consider using flutter_secure_storage.');
              break; // One report per file is enough
            }
          }
        }
      }

      // El test falla si se detecta uso de SharedPreferences con datos sensibles
      expect(
        violations,
        isEmpty,
        reason:
            'Violaciones de almacenamiento inseguro encontradas:\n${violations.join("\n")}',
      );

      if (violations.isNotEmpty) {
        debugPrint('SECURITY WARNINGS FOUND:');
        for (final violation in violations) {
          debugPrint(violation);
        }
      }
    });
  });
}
