import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Network Security', () {
    test('Should not contain insecure HTTP links in source code', () async {
      final libDir = Directory('lib');
      if (!libDir.existsSync()) return;

      final sourceFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in sourceFiles) {
        final content = await file.readAsString();

        // Regex to find http:// but ignore comments or localhost/IPs often used in dev
        // Modified to ignore `startsWith('http://')` which is a valid check, not insecure usage.
        final regex = RegExp(
            r"(?<!startsWith\(')http://(?!localhost|127\.0\.0\.1|10\.0\.2\.2)");

        if (regex.hasMatch(content)) {
          // Extract the matching line for context
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            if (regex.hasMatch(lines[i])) {
              violations.add(
                  '${file.path}:${i + 1} contains insecure URL: ${lines[i].trim()}');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        debugPrint('NETWORK SECURITY VIOLATIONS:');
        for (final violation in violations) {
          debugPrint(violation);
        }
      }

      // We expect some violations currently as we saw http:// in some files earlier?
      // Actually, let's make it fail if violations are found to enforce security.
      // For this PoC, we expect it might fail or pass depending on current codebase state.
      // Based on previous grep, we saw https:// mostly.

      expect(violations, isEmpty,
          reason: 'Found insecure HTTP URLs. All traffic must be HTTPS.');
    });
  });
}
