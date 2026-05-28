import 'package:dartz/dartz.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  // In-memory mock data
  List<AppNotification> _notifications = [
    const AppNotification(
      id: '1',
      title: 'Pedido Enviado',
      body: 'Tu pedido #12345 ha sido enviado y está en camino.',
      time: 'Hace 2 horas',
      isRead: false,
      type: 'order',
    ),
    const AppNotification(
      id: '2',
      title: 'Nuevo Ticket Creado',
      body: 'Se ha generado el ticket de soporte #10234 exitosamente.',
      time: 'Ayer',
      isRead: true,
      type: 'ticket',
    ),
    const AppNotification(
      id: '3',
      title: '¡Descuento Especial!',
      body:
          'Aprovecha un 20% de descuento en todos los servicios de mantenimiento.',
      time: 'Hace 3 días',
      isRead: true,
      type: 'promo',
    ),
    const AppNotification(
      id: '4',
      title: 'Actualización de Sistema',
      body: 'Hemos mejorado la aplicación para brindarte un mejor servicio.',
      time: 'Hace 1 semana',
      isRead: true,
      type: 'info',
    ),
  ];

  @override
  Future<Either<String, List<AppNotification>>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_notifications);
  }

  @override
  Future<Either<String, void>> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      return const Right(null);
    }
    return const Left('Notification not found');
  }

  @override
  Future<Either<String, void>> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    return const Right(null);
  }
}
