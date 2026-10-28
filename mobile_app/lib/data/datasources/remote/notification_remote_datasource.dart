// Notificaciones de la campanita.
import '../../../core/network/api_client.dart';
import '../../dtos/notification_dto.dart';

class NotificationRemoteDataSource {
  final ApiClient _api;
  NotificationRemoteDataSource(this._api);

  Future<NotificationPageDto> list({int? after, int? before, int limit = 50}) async => NotificationPageDto.fromJson(await _api.getMap('/notifications', {
        if (after != null) 'after': '$after',
        if (before != null) 'before': '$before',
        'limit': '$limit',
      }));

  Future<int> markRead({List<int>? ids, bool all = false}) async {
    final j = await _api.postMap('/notifications/read', {if (ids != null) 'ids': ids, if (all) 'all': true});
    return (j['unread'] as num?)?.toInt() ?? 0;
  }
}
