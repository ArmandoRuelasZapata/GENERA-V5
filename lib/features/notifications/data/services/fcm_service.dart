import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_notifications.dart';
import '../../domain/notification_model.dart';
import '../../presentation/providers/notifications_provider.dart';

/// Inicializa Firebase Cloud Messaging usando el [ProviderContainer] global.
///
/// Al usar el container directamente (no un WidgetRef), los listeners FCM
/// sobreviven cualquier cambio de pantalla o rebuild de widgets.
///
/// Llama a [FcmService.initialize] desde [main()] ANTES de [runApp].
class FcmService {
  FcmService._();

  static Future<void> initialize(ProviderContainer container) async {
    try {
      // 1. Permisos
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }

      // 2. FCM token (debug)
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        debugPrint('------------------------------');
        debugPrint('FCM TOKEN:');
        debugPrint(token ?? 'null');
        debugPrint('------------------------------');
      }

      // 3. Banner en foreground
      await LocalNotifications.init(
        onTap: (data) {
          if (kDebugMode) debugPrint('Tap banner: data=$data');
        },
      );

      // 4. App en FOREGROUND: banner + añadir a lista
      FirebaseMessaging.onMessage.listen((msg) async {
        if (kDebugMode) {
          debugPrint('onMessage: ${msg.notification?.title}');
          debugPrint('data: ${msg.data}');
          debugPrint('messageId: ${msg.messageId}');
        }
        await LocalNotifications.showFromRemoteMessage(msg);
        _addToContainer(container, msg);
      });

      // 5. App en BACKGROUND: usuario toca notificación
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        if (kDebugMode) {
          debugPrint('onMessageOpenedApp: ${msg.notification?.title}');
        }
        _addToContainer(container, msg);
      });

      // 6. App TERMINADA (cold start)
      final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMsg != null) {
        if (kDebugMode) {
          debugPrint('getInitialMessage: ${initialMsg.notification?.title}');
        }
        _addToContainer(container, initialMsg);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FcmService.initialize error: $e\n$st');
      }
    }
  }

  // Helpers privados

  static void _addToContainer(ProviderContainer container, RemoteMessage msg) {
    // container.read() es siempre válido mientras el container no sea disposed
    container
        .read(notificationsProvider.notifier)
        .addNotification(_remoteMessageToModel(msg));
  }

  static NotificationModel _remoteMessageToModel(RemoteMessage msg) {
    final title = msg.notification?.title ??
        msg.data['title']?.toString() ??
        'Notificación';
    final body = msg.notification?.body ?? msg.data['body']?.toString() ?? '';
    final typeStr = msg.data['type']?.toString() ?? 'system';

    return NotificationModel(
      id: msg.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: msg.sentTime ?? DateTime.now(),
      type: _parseType(typeStr),
      isRead: false,
    );
  }

  static NotificationType _parseType(String raw) {
    switch (raw.toLowerCase()) {
      case 'order':
        return NotificationType.order;
      case 'promo':
        return NotificationType.promo;
      case 'support':
        return NotificationType.support;
      default:
        return NotificationType.system;
    }
  }
}
