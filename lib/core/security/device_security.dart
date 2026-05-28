import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// OWASP M3 — Detección de dispositivo comprometido.
///
/// Implementación propia sin dependencias externas (compatible con AGP 8+).
/// Detecta indicadores comunes de root en Android:
///   - Binarios `su` en paths estándar
///   - Aplicaciones de root conocidas (Magisk, SuperSU, KingRoot, etc.)
///   - Propiedades del sistema que delatan modo debug/unlock
///
/// Implementa heurísticas nativas en iOS (Jailbreak Detection) vía MethodChannel.
class DeviceSecurity {
  DeviceSecurity._();

  static const MethodChannel _securityChannel =
      MethodChannel('com.originallab/security');

  // Paths de binarios de root

  static const _rootBinaryPaths = [
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/su/xbin/su',
    // Magisk
    '/magisk/.core/bin/su',
    '/sbin/.magisk/mirror/system/bin/su',
    '/sbin/.core/bin/su',
    // KingRoot / Towelroot
    '/system/app/KingRoot.apk',
    '/system/app/Superuser.apk',
    '/system/xbin/daemonsu',
    // Indicadores genéricos
    '/cache/recovery/',
    '/data/adb/magisk',
  ];

  // APKs de root conocidas

  static const _rootAppPaths = [
    '/data/app/com.kingroot.kinguser',
    '/data/app/eu.chainfire.supersu',
    '/data/app/com.noshufou.android.su',
    '/data/app/com.topjohnwu.magisk',
    '/data/app/me.weishu.kernelsu',
    '/data/data/com.kingroot.kinguser',
    '/data/data/eu.chainfire.supersu',
    '/data/data/com.topjohnwu.magisk',
  ];

  static const _emulatorFiles = [
    '/dev/socket/qemud',
    '/dev/qemu_pipe',
    '/system/lib/libc_malloc_debug_qemu.so',
    '/sys/qemu_trace',
  ];

  /// Devuelve `true` si el dispositivo parece estar rooteado o modificado.
  ///
  /// En Android verifica binarios su y apps root.
  /// En iOS invoca al canal nativo para verificar paths de Cydia, bash y test fuera de sandbox.
  static Future<bool> isDeviceCompromised() async {
    if (Platform.isIOS) {
      try {
        final bool isJailbroken =
            await _securityChannel.invokeMethod('isJailBroken');
        return isJailbroken;
      } catch (_) {
        return false;
      }
    }

    if (!Platform.isAndroid) {
      return false;
    }

    // 1. Verificar binarios de root
    for (final path in _rootBinaryPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }

    // 2. Verificar apps de root instaladas
    for (final path in _rootAppPaths) {
      if (Directory(path).existsSync() || File('$path.apk').existsSync()) {
        return true;
      }
    }

    // 3. Verificar si el build está marcado como test-keys (firmware no oficial)
    try {
      final buildTags = await _readBuildProp('ro.build.tags');
      if (buildTags != null && buildTags.contains('test-keys')) {
        return true;
      }
    } catch (_) {
      // Ignorar errores de lectura de propiedades
    }

    return false;
  }

  /// Devuelve `true` si se detecta ejecución en emulador/simulador.
  static Future<bool> isProbablyEmulator() async {
    if (Platform.isIOS) {
      try {
        final bool isSimulator =
            await _securityChannel.invokeMethod('isSimulator');
        return isSimulator;
      } catch (_) {
        return false;
      }
    }

    if (!Platform.isAndroid) {
      return false;
    }

    for (final path in _emulatorFiles) {
      if (File(path).existsSync()) {
        return true;
      }
    }

    final qemu = (await _readBuildProp('ro.kernel.qemu'))?.toLowerCase() ?? '';
    if (qemu == '1') return true;

    final hardware = (await _readBuildProp('ro.hardware'))?.toLowerCase() ?? '';
    if (hardware.contains('goldfish') ||
        hardware.contains('ranchu') ||
        hardware.contains('vbox')) {
      return true;
    }

    final model =
        (await _readBuildProp('ro.product.model'))?.toLowerCase() ?? '';
    if (model.contains('sdk') ||
        model.contains('emulator') ||
        model.contains('android sdk built for x86')) {
      return true;
    }

    final brand =
        (await _readBuildProp('ro.product.brand'))?.toLowerCase() ?? '';
    final device =
        (await _readBuildProp('ro.product.device'))?.toLowerCase() ?? '';
    if (brand.startsWith('generic') || device.startsWith('generic')) {
      return true;
    }

    final manufacturer =
        (await _readBuildProp('ro.product.manufacturer'))?.toLowerCase() ?? '';
    if (manufacturer.contains('genymotion') ||
        manufacturer.contains('unknown')) {
      return true;
    }

    return false;
  }

  /// Devuelve `true` si hay señales de manipulación dinámica (hook/debugger).
  static Future<bool> isAppTampered() async {
    if (Platform.isIOS) {
      try {
        final bool tampered = await _securityChannel.invokeMethod('isTampered');
        return tampered;
      } catch (_) {
        return false;
      }
    }

    if (!Platform.isAndroid) {
      return false;
    }

    final debuggable =
        (await _readBuildProp('ro.debuggable'))?.toLowerCase() ?? '';
    if (debuggable == '1') {
      return true;
    }

    final secure = (await _readBuildProp('ro.secure'))?.toLowerCase() ?? '';
    if (secure == '0') {
      return true;
    }

    try {
      final status = await File('/proc/self/status').readAsString();
      final tracerLine = status.split('\n').firstWhere(
          (line) => line.startsWith('TracerPid:'),
          orElse: () => '');
      final tracerPid =
          int.tryParse(tracerLine.replaceAll('TracerPid:', '').trim()) ?? 0;
      if (tracerPid > 0) {
        return true;
      }
    } catch (_) {
      // Ignorar lectura no disponible
    }

    try {
      final maps = await File('/proc/self/maps').readAsString();
      final lowered = maps.toLowerCase();
      if (lowered.contains('frida') ||
          lowered.contains('gum-js-loop') ||
          lowered.contains('xposed')) {
        return true;
      }
    } catch (_) {
      // Ignorar lectura no disponible
    }

    return false;
  }

  /// Evaluación consolidada del entorno antes de iniciar la app.
  ///
  /// En `kProfileMode` (builds de TestFlight/staging) se omite la verificación
  /// para evitar falsos positivos que bloqueen a los testers en dispositivos normales.
  static Future<bool> isRuntimeEnvironmentUnsafe() async {
    // Profile mode = TestFlight / builds de profiling con herramientas de dev.
    // Estas heurísticas pueden dar falsos positivos en ese contexto.
    if (kProfileMode) return false;

    if (await isDeviceCompromised()) return true;
    if (await isProbablyEmulator()) return true;
    if (await isAppTampered()) return true;
    return false;
  }

  /// Lee una propiedad del sistema Android via /system/build.prop.
  static Future<String?> _readBuildProp(String key) async {
    try {
      final result = await Process.run('getprop', [key]);
      final output = result.stdout.toString().trim();
      return output.isNotEmpty ? output : null;
    } catch (_) {
      return null;
    }
  }
}
