import '../entities/app_notification.dart';
import '../entities/chat.dart';

abstract class ChatRepository {
  Future<List<Conversation>> conversations();
  Future<Conversation> conversation(int id);

  /// Abre (o reutiliza) la conversación con otra persona.
  Future<Conversation> start(int userId, {int? lotId});

  Future<List<ChatMessage>> messages(int convId, {int after = 0});
  Future<ChatMessage> sendText(int convId, String text, {required String lang, bool viaVoice = false});
  Future<ChatMessage> sendPhoto(int convId, int photoId, {String text = '', required String lang});
  Future<void> markRead(int convId, int lastId);

  Future<ChatMessage> sendQuote(int convId, {required int lotId, required double priceLb, required int sacks, required String incoterm});

  /// action: 'counter' | 'accept' | 'confirm'
  Future<void> quoteAction(int messageId, String action, {double? priceLb, int? sacks});

  Future<UnreadCounts> unread();
}
