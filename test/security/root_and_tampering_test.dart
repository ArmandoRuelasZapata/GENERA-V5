import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// T-14: Root Detection / Emulator Detection / Tampering Detection
///
/// Este test valida la lógica de detección de forma estática (caja blanca),
/// comprobando que:
///   1. Todos los paths de root binaries están en la lista de DeviceSecurity.
///   2. Los paths de apps de root conocidas están cubiertos (Magisk, SuperSU, KingRoot, KernelSU).
///   3. Los archivos de emulador QEMU/Genymotion están cubiertos.
///   4. La detección de Frida/Xposed/Objection existe en el código fuente.
///   5. La función isRuntimeEnvironmentUnsafe() está implementada y usa las tres comprobaciones.
void main() {
  group('T-14 — Root & Tampering Detection (Static Analysis)', () {
    late String deviceSecuritySource;

    setUpAll(() {
      final file = File('lib/core/security/device_security.dart');
      expect(file.existsSync(), isTrue,
          reason: 'device_security.dart debe existir en lib/core/security/');
      deviceSecuritySource = file.readAsStringSync();
    });

    // ── 1. Binarios de root ────────────────────────────────────────────────

    test('Cubre binario su en /sbin, /system/bin y /system/xbin', () {
      expect(deviceSecuritySource, contains('/sbin/su'));
      expect(deviceSecuritySource, contains('/system/bin/su'));
      expect(deviceSecuritySource, contains('/system/xbin/su'));
    });

    test('Cubre paths de Magisk', () {
      expect(
        deviceSecuritySource,
        contains('magisk'),
        reason: 'Debe haber al menos un path relacionado con Magisk',
      );
    });

    test('Cubre apps root conocidas: SuperSU, KingRoot, KernelSU, Magisk APK',
        () {
      expect(deviceSecuritySource, contains('eu.chainfire.supersu'));
      expect(deviceSecuritySource, contains('com.topjohnwu.magisk'));
      expect(deviceSecuritySource, contains('com.kingroot.kinguser'));
      expect(deviceSecuritySource, contains('me.weishu.kernelsu'));
    });

    // ── 2. Entorno de emulador ─────────────────────────────────────────────

    test('Detecta emuladores QEMU via archivos de sistema', () {
      expect(deviceSecuritySource, contains('/dev/socket/qemud'));
      expect(deviceSecuritySource, contains('/dev/qemu_pipe'));
    });

    test(
        'Detecta emuladores por propiedades del sistema (ro.kernel.qemu, goldfish, ranchu)',
        () {
      expect(deviceSecuritySource, contains('ro.kernel.qemu'));
      expect(deviceSecuritySource, contains('goldfish'));
      expect(deviceSecuritySource, contains('ranchu'));
    });

    test('Detecta Genymotion', () {
      expect(deviceSecuritySource, contains('genymotion'),
          reason: 'Genymotion debe estar en las heurísticas de emulador');
    });

    // ── 3. Tampering / Dynamic Instrumentation ────────────────────────────

    test('Detecta Frida en /proc/self/maps', () {
      expect(deviceSecuritySource, contains('frida'),
          reason: 'Debe detectar la presencia de frida-gadget en memoria');
    });

    test('Detecta Xposed Framework', () {
      expect(deviceSecuritySource, contains('xposed'),
          reason: 'Debe detectar Xposed/LSPosed como framework de hooking');
    });

    test('Lee TracerPid de /proc/self/status para detectar debugger', () {
      expect(deviceSecuritySource, contains('TracerPid'));
      expect(deviceSecuritySource, contains('/proc/self/status'));
    });

    test('Detecta ro.debuggable=1 (build no oficial / debug)', () {
      expect(deviceSecuritySource, contains('ro.debuggable'));
    });

    // ── 4. Función consolidada ─────────────────────────────────────────────

    test('isRuntimeEnvironmentUnsafe() llama a las tres comprobaciones', () {
      expect(deviceSecuritySource, contains('isDeviceCompromised'));
      expect(deviceSecuritySource, contains('isProbablyEmulator'));
      expect(deviceSecuritySource, contains('isAppTampered'));
      expect(deviceSecuritySource, contains('isRuntimeEnvironmentUnsafe'));
    });

    // ── 5. Integración en main.dart ───────────────────────────────────────

    test('main.dart llama _checkDeviceSecurity() antes de runApp()', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final mainSource = mainFile.readAsStringSync();
      expect(mainSource, contains('_checkDeviceSecurity'));
      expect(mainSource, contains('DeviceSecurity.isRuntimeEnvironmentUnsafe'));
      // Verificar que la llamada es ANTES de runApp
      final checkIdx = mainSource.indexOf('_checkDeviceSecurity');
      final runAppIdx = mainSource.indexOf('runApp(');
      expect(checkIdx, lessThan(runAppIdx),
          reason:
              '_checkDeviceSecurity() debe invocarse antes de runApp() en main()');
    });

    // ── 6. Solo activo en modo Release ────────────────────────────────────

    test(
        'La verificación de seguridad se salta en kDebugMode (evita falsos positivos en dev)',
        () {
      final mainFile = File('lib/main.dart');
      final mainSource = mainFile.readAsStringSync();
      // La verificación debe estar dentro de un if (!kDebugMode)
      expect(mainSource, contains('kDebugMode'),
          reason:
              'La seguridad no debe bloquear el emulador de dev; debe omitirse en kDebugMode');
    });
  });

  group('T-12 — Almacenamiento Seguro (Static Analysis)', () {
    test(
        'auth_local_datasource.dart usa SOLO flutter_secure_storage para datos sensibles',
        () {
      final file =
          File('lib/features/auth/data/datasources/auth_local_datasource.dart');
      expect(file.existsSync(), isTrue);
      final source = file.readAsStringSync();

      // Debe importar flutter_secure_storage
      expect(source, contains('flutter_secure_storage'));

      // NO debe usar SharedPreferences para datos de sesión
      expect(source, isNot(contains('SharedPreferences')),
          reason:
              'El datasource de auth NO debe usar SharedPreferences — deben usarse flutter_secure_storage');
    });

    test(
        'Todos los storage keys apuntan a datos que se guardan en secure storage',
        () {
      final storageKeysFile = File('lib/core/constants/storage_keys.dart');
      expect(storageKeysFile.existsSync(), isTrue);
      final source = storageKeysFile.readAsStringSync();

      // Todos los campos son strings (llaves), no contienen valores hardcodeados
      // Verificar que están declaradas como constantes (no valores sensibles en claro)
      expect(source, contains('static const String accessToken'));
      expect(source, contains('static const String userId'));
    });

    test('env.dart usa obfuscate: true para todas las llaves sensibles', () {
      final envFile = File('lib/core/config/env.dart');
      expect(envFile.existsSync(), isTrue);
      final source = envFile.readAsStringSync();

      // PAYLOAD_ENCRYPTION_KEY, API keys y URLs deben estar obfuscadas
      final obfuscateCount = 'obfuscate: true'.allMatches(source).length;
      expect(obfuscateCount, greaterThanOrEqualTo(6),
          reason:
              'Deben haber al menos 6 campos con obfuscate: true (prod + dev de las 3 claves principales)');
    });

    test('No hay hardcoded secrets en el direktorio lib/', () {
      final libDir = Directory('lib');
      // Palabras que no deben aparecer como valores literales largos en el código
      final suspiciousPatterns = [
        RegExp(r'(sk-[a-zA-Z0-9_\-]{20,})'),
        RegExp(r'AIza[a-zA-Z0-9_\-]{20,}'),
        // Para PAYLOAD_ENCRYPTION_KEY usamos contains directo más abajo
      ];

      final violations = <String>[];
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.contains('.g.dart')) continue; // skip generated
        // firebase_options.dart es generado por Firebase CLI: la AIza key es pública e intencionada
        if (file.path.contains('firebase_options.dart')) continue;
        final content = file.readAsStringSync();
        for (final pattern in suspiciousPatterns) {
          if (pattern.hasMatch(content)) {
            violations.add(file.path);
            break;
          }
        }
      }

      expect(violations, isEmpty,
          reason:
              'Posibles secrets hardcodeados encontrados en: ${violations.join(', ')}');
    });
  });
}
