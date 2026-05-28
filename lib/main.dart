import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'shared/providers/providers.dart';

import 'features/notifications/data/services/fcm_service.dart';
import 'features/notifications/data/services/in_app_messaging_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/config_validator.dart';
import 'core/constants/storage_keys.dart';
import 'core/security/device_security.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  ConfigValidator.validate();
  await initializeDateFormatting('es', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final sharedPreferences = await SharedPreferences.getInstance();

  // Fix: persistencia de sesión en iOS tras desinstalar (Keychain)
  if (!sharedPreferences.containsKey(StorageKeys.isFirstRunV2)) {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    await sharedPreferences.setBool(StorageKeys.isFirstRunV2, false);
  }

  // Verificación de dispositivo seguro (Root / Emulator detect)
  final securityBlock = await _checkDeviceSecurity();
  if (securityBlock != null) {
    runApp(securityBlock);
    return;
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  unawaited(FcmService.initialize(container));
  unawaited(InAppMessagingService.initialize());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

Future<Widget?> _checkDeviceSecurity() async {
  if (kDebugMode) return null;

  final isUnsafe = await DeviceSecurity.isRuntimeEnvironmentUnsafe();
  if (isUnsafe) {
    debugPrint(
      'ERROR DE SEGURIDAD: entorno inseguro detectado '
      '(root/jailbreak, emulador o tampering).',
    );
    return const _SecurityBlockScreen();
  }
  return null;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(authProvider.notifier).resetInactivityTimer(),
      onPointerMove: (_) =>
          ref.read(authProvider.notifier).resetInactivityTimer(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Genera',
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('en', 'US'),
            ],
            locale: const Locale('es', 'ES'),
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}

/// Pantalla de bloqueo para entornos inseguros
class _SecurityBlockScreen extends StatelessWidget {
  const _SecurityBlockScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF021024),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: Colors.redAccent, size: 64),
                SizedBox(height: 24),
                Text(
                  'Dispositivo no compatible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Por seguridad, esta app no puede ejecutarse en dispositivos modificados o entornos no autorizados.',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}