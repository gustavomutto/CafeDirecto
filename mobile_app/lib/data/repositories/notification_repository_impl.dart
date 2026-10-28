import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local/session_local_datasource.dart';
import '../datasources/remote/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  NotificationRepositoryImpl(this._remote, this._local);

  @override
  Future<NotificationPage> latest({int limit = 50}) async => (await _remote.list(limit: limit)).toEntity();

  @override
  Future<List<AppNotification>> newerThan(int afterId) async => (await _remote.list(after: afterId, limit: 20)).toEntity().items;

  @override
  Future<int> markRead(List<int> ids) => _remote.markRead(ids: ids);

  @override
  Future<int> markAllRead() => _remote.markRead(all: true);

  @override
  Future<int> lastAlertedId() => _local.readLastNotifiedId();

  @override
  Future<void> saveLastAlertedId(int id) => _local.saveLastNotifiedId(id);
}
