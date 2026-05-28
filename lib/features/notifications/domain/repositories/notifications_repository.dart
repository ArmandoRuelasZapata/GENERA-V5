import 'package:dartz/dartz.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<String, List<AppNotification>>> getNotifications();
  Future<Either<String, void>> markAsRead(String id);
  Future<Either<String, void>> markAllAsRead();
}
