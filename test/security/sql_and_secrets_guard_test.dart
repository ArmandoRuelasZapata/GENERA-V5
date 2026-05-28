import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security Guard - SQL & Secrets', () {
    test('No local SQL engine usage or raw SQL statements in app source',
        () async {
      final libDir = Directory('lib');
      if (!libDir.existsSync()) return;

      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final riskyPatterns = <RegExp>[
        RegExp(r'\bsqflite\b'),
        RegExp(r'\bsqlite3?\b'),
        RegExp(r'\bdrift\b'),
        RegExp(r'\bmoor\b'),
        RegExp(r'\brawQuery\s*\('),
        RegExp(r'\brawInsert\s*\('),
        RegExp(r'\brawUpdate\s*\('),
        RegExp(r'\brawDelete\s*\('),
        RegExp(r'\bselect\s+.+\s+from\b', caseSensitive: false),
        RegExp(r'\binsert\s+into\b', caseSensitive: false),
        RegExp(r'\bupdate\s+\w+\s+set\b', caseSensitive: false),
        RegExp(r'\bdelete\s+from\b', caseSensitive: false),
      ];

      final violations = <String>[];
      for (final file in files) {
        final content = await file.readAsString();
        for (final pattern in riskyPatterns) {
          if (pattern.hasMatch(content)) {
            violations.add('${file.path} matched ${pattern.pattern}');
            break;
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Se detectaron patrones de SQL/local DB no permitidos:\n${violations.join('\n')}',
      );
    });

    test('No obvious hardcoded high-risk secrets in lib/', () async {
      final libDir = Directory('lib');
      if (!libDir.existsSync()) return;

      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final secretPatterns = <RegExp>[
        RegExp(r'sk-proj-[A-Za-z0-9_-]{20,}'), // OpenAI project key
        RegExp(r'AIza[0-9A-Za-z\-_]{20,}'), // Google API key style
        RegExp(
          r'-----BEGIN (RSA |EC |)PRIVATE KEY-----',
          caseSensitive: false,
        ),
        // Detecta claves API hardcodeadas como defaultValue en --dart-define.
        // Patrón: string de 8+ chars alfanuméricos con guiones bajos que no sea URL.
        // Captura: 'dev_key_2026', 'abc123def456'
        // Ignora: 'gpt-4o-mini' (tiene guión), 'https://...', ''
        RegExp(r"defaultValue:\s*'(?!https?://)[A-Za-z0-9][A-Za-z0-9_]{7,}'"),
      ];

      final violations = <String>[];
      for (final file in files) {
        if (file.path.endsWith('firebase_options.dart')) {
          // Firebase Web API key no es secreto por diseño.
          continue;
        }
        final content = await file.readAsString();
        for (final pattern in secretPatterns) {
          if (pattern.hasMatch(content)) {
            violations.add('${file.path} matched ${pattern.pattern}');
            break;
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Se detectaron posibles secretos hardcodeados en lib/:\n${violations.join('\n')}',
      );
    });
  });
}
