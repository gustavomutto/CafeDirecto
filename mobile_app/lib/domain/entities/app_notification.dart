// Avisos de la campanita.
import 'bi.dart';

class AppNotification {
  final int id;
  final String type;
  final Bi title, body;
  final Map<String, dynamic> data;
  final bool read;
  final int createdAt;
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  int? _int(String k) => data[k] is num ? (data[k] as num).toInt() : null;
  int? get lotId => _int('lotId');
  int? get userId => _int('userId');
  int? get auctionId => _int('auctionId');
  int? get conversationId => _int('conversationId');
  int? get agreementId => _int('agreementId');

  /// A qué pantalla lleva al tocarla.
  String? get route {
    if (agreementId != null && (type == 'auction_won' || type.startsWith('agreement') || type == 'rating_new')) return '/orders/$agreementId';
    if (auctionId != null) return '/auction/$auctionId';
    if (conversationId != null) return '/chat/$conversationId';
    if (type == 'lot_interest' && userId != null) return '/user/$userId';
    if (lotId != null) return '/lot/$lotId';
    return null;
  }
}

class NotificationPage {
  final List<AppNotification> items;
  final int unread;
  const NotificationPage(this.items, this.unread);
}

class UnreadCounts {
  final int messages, notifications;
  const UnreadCounts(this.messages, this.notifications);
}
