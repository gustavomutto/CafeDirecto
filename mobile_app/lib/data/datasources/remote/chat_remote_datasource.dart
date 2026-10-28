// Conversaciones, mensajes y cotizaciones.
import '../../../core/network/api_client.dart';
import '../../dtos/chat_dto.dart';

class ChatRemoteDataSource {
  final ApiClient _api;
  ChatRemoteDataSource(this._api);

  Future<List<ConversationDto>> conversations() async => (await _api.getList('/conversations')).map(ConversationDto.fromJson).toList();

  Future<ConversationDto> conversation(int id) async => ConversationDto.fromJson(await _api.getMap('/conversations/$id'));

  Future<ConversationDto> start(int userId, {int? lotId}) async =>
      ConversationDto.fromJson(await _api.postMap('/conversations', {'userId': userId, if (lotId != null) 'lotId': lotId}));

  Future<List<ChatMessageDto>> messages(int convId, {int after = 0}) async =>
      (await _api.getList('/conversations/$convId/messages', {'after': '$after'})).map(ChatMessageDto.fromJson).toList();

  Future<ChatMessageDto> send(int convId, Map<String, dynamic> body) async =>
      ChatMessageDto.fromJson(await _api.postMap('/conversations/$convId/messages', body));

  Future<void> markRead(int convId, int lastId) => _api.post('/conversations/$convId/read', {'lastId': lastId});

  Future<ChatMessageDto> sendQuote(int convId, Map<String, dynamic> body) async =>
      ChatMessageDto.fromJson(await _api.postMap('/conversations/$convId/quotes', body));

  Future<void> quoteAction(int messageId, Map<String, dynamic> body) => _api.post('/messages/$messageId/quote', body);

  /// { unread: mensajes sin leer, notifications: avisos sin leer }
  Future<Map<String, dynamic>> unread() => _api.getMap('/unread');
}
