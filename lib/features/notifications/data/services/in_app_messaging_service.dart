import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

class InAppMessagingService {
  InAppMessagingService._();

  static Future<void> initialize() async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseAnalytics.instance.logAppOpen();

      final iam = FirebaseInAppMessaging.instance;
      await iam.setAutomaticDataCollectionEnabled(true);
      await iam.setMessagesSuppressed(false);

      // Evento simple para poder probar campañas por trigger personalizado.
      await iam.triggerEvent('app_launch');

      if (kDebugMode) {
        debugPrint('FIAM inicializado y trigger app_launch enviado');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InAppMessagingService.initialize error: $e\n$st');
      }
    }
  }
}
