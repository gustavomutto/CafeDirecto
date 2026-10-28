import '../../core/utils/json.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;
  ChatRepositoryImpl(this._remote);

  @override
  Future<List<Conversation>> conversations() async => (await _remote.conversations()).map((d) => d.toEntity()).toList();

  @override
  Future<Conversation> conversation(int id) async => (await _remote.conversation(id)).toEntity();

  @override
  Future<Conversation> start(int userId, {int? lotId}) async => (await _remote.start(userId, lotId: lotId)).toEntity();

  @override
  Future<List<ChatMessage>> messages(int convId, {int after = 0}) async =>
      (await _remote.messages(convId, after: after)).map((d) => d.toEntity()).toList();

  @override
  Future<ChatMessage> sendText(int convId, String text, {required String lang, bool viaVoice = false}) async =>
      (await _remote.send(convId, {'type': 'text', 'text': text, 'lang': lang, 'viaVoice': viaVoice})).toEntity();

  @override
  Future<ChatMessage> sendPhoto(int convId, int photoId, {String text = '', required String lang}) async =>
      (await _remote.send(convId, {'type': 'photo', 'photoId': photoId, 'text': text, 'lang': lang})).toEntity();

  @override
  Future<void> markRead(int convId, int lastId) => _remote.markRead(convId, lastId);

  @override
  Future<ChatMessage> sendQuote(int convId, {required int lotId, required double priceLb, required int sacks, required String incoterm}) async =>
      (await _remote.sendQuote(convId, {'lotId': lotId, 'priceLb': priceLb, 'sacks': sacks, 'incoterm': incoterm})).toEntity();

  @override
  Future<void> quoteAction(int messageId, String action, {double? priceLb, int? sacks}) => _remote.quoteAction(messageId, {
        'action': action,
        if (priceLb != null) 'priceLb': priceLb,
        if (sacks != null) 'sacks': sacks,
      });

  @override
  Future<UnreadCounts> unread() async {
    final j = await _remote.unread();
    return UnreadCounts(asInt(j['unread']), asInt(j['notifications']), asInt(j['latestNotificationId']));
  }
}
