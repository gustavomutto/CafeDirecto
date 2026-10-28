import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<NotificationPage> latest({int limit = 50});

  /// Solo las que llegaron después de `afterId` (para mostrar el aviso en el teléfono).
  Future<List<AppNotification>> newerThan(int afterId);

  Future<int> markRead(List<int> ids);
  Future<int> markAllRead();

  Future<int> lastAlertedId();
  Future<void> saveLastAlertedId(int id);
}
