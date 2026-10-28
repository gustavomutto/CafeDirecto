// DTOs de notificaciones.
import '../../core/utils/json.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/bi.dart';
import 'user_dto.dart';

class NotificationDto {
  final int id, createdAt;
  final String type;
  final BiDto? title, body;
  final Map<String, dynamic> data;
  final bool read;
  const NotificationDto({required this.id, required this.createdAt, required this.type, this.title, this.body, required this.data, required this.read});

  factory NotificationDto.fromJson(Map<String, dynamic> j) => NotificationDto(
        id: asInt(j['id']),
        createdAt: asInt(j['createdAt']),
        type: asString(j['type']),
        title: BiDto.fromJson(j['title']),
        body: BiDto.fromJson(j['body']),
        data: asMap(j['data']),
        read: asBool(j['read']),
      );

  AppNotification toEntity() => AppNotification(
        id: id,
        type: type,
        title: title?.toEntity() ?? Bi.empty,
        body: body?.toEntity() ?? Bi.empty,
        data: data,
        read: read,
        createdAt: createdAt,
      );
}

class NotificationPageDto {
  final List<NotificationDto> items;
  final int unread;
  const NotificationPageDto(this.items, this.unread);
  factory NotificationPageDto.fromJson(Map<String, dynamic> j) =>
      NotificationPageDto(asMapList(j['items']).map(NotificationDto.fromJson).toList(), asInt(j['unread']));
  NotificationPage toEntity() => NotificationPage(items.map((n) => n.toEntity()).toList(), unread);
}
