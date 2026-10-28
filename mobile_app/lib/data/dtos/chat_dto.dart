// DTOs del chat: conversaciones, mensajes y cotizaciones.
import '../../core/utils/json.dart';
import '../../domain/entities/chat.dart';
import 'lot_dto.dart';
import 'user_dto.dart';

class QuoteStepDto {
  final String by;
  final double priceLb;
  final int sacks;
  const QuoteStepDto(this.by, this.priceLb, this.sacks);
  factory QuoteStepDto.fromJson(Map<String, dynamic> j) => QuoteStepDto(asString(j['by']), asDouble(j['priceLb']), asInt(j['sacks']));
  QuoteStep toEntity() => QuoteStep(by: by, priceLb: priceLb, sacks: sacks);
}

class QuoteDto {
  final int lotId, sacks;
  final String lotName, variety, process, incoterm, lastBy, status;
  final double priceLb;
  final List<QuoteStepDto> history;
  final String? acceptedBy;
  final int? agreementId;
  const QuoteDto({
    required this.lotId,
    required this.sacks,
    required this.lotName,
    required this.variety,
    required this.process,
    required this.incoterm,
    required this.lastBy,
    required this.status,
    required this.priceLb,
    required this.history,
    this.acceptedBy,
    this.agreementId,
  });

  factory QuoteDto.fromJson(Map<String, dynamic> j) => QuoteDto(
        lotId: asInt(j['lotId']),
        sacks: asInt(j['sacks']),
        lotName: asString(j['lotName']),
        variety: asString(j['variety']),
        process: asString(j['process']),
        incoterm: asString(j['incoterm']),
        lastBy: asString(j['lastBy']),
        status: asString(j['status']),
        priceLb: asDouble(j['priceLb']),
        history: asMapList(j['history']).map(QuoteStepDto.fromJson).toList(),
        acceptedBy: asStringOrNull(j['acceptedBy']),
        agreementId: asIntOrNull(j['agreementId']),
      );

  Quote toEntity() => Quote(
        lotId: lotId,
        lotName: lotName,
        variety: variety,
        process: process,
        incoterm: incoterm,
        lastBy: lastBy,
        status: status,
        priceLb: priceLb,
        sacks: sacks,
        history: history.map((h) => h.toEntity()).toList(),
        acceptedBy: acceptedBy,
        agreementId: agreementId,
      );
}

class ChatMessageDto {
  final int id, conversationId, createdAt;
  final int? senderId, agreementId;
  final String type;
  final String? from, text, lang, translation, photo;
  final bool viaVoice;
  final QuoteDto? quote;
  final BiDto? sys;
  const ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.createdAt,
    this.senderId,
    this.agreementId,
    required this.type,
    this.from,
    this.text,
    this.lang,
    this.translation,
    this.photo,
    required this.viaVoice,
    this.quote,
    this.sys,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> j) => ChatMessageDto(
        id: asInt(j['id']),
        conversationId: asInt(j['conversationId']),
        createdAt: asInt(j['createdAt']),
        senderId: asIntOrNull(j['senderId']),
        agreementId: asIntOrNull(j['agreementId']),
        type: asString(j['type']),
        from: asStringOrNull(j['from']),
        text: asStringOrNull(j['text']),
        lang: asStringOrNull(j['lang']),
        translation: asStringOrNull(j['translation']),
        photo: asStringOrNull(j['photo']),
        viaVoice: asBool(j['viaVoice']),
        quote: j['quote'] is Map ? QuoteDto.fromJson(asMap(j['quote'])) : null,
        sys: BiDto.fromJson(j['sys']),
      );

  ChatMessage toEntity() => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        from: from,
        type: type,
        text: text,
        lang: lang,
        translation: translation,
        photo: photo,
        viaVoice: viaVoice,
        quote: quote?.toEntity(),
        agreementId: agreementId,
        sys: sys?.toEntity(),
        createdAt: createdAt,
      );
}

class ChatPeerDto {
  final int id;
  final String role, name, sub, lang;
  final String? photo;
  const ChatPeerDto({required this.id, required this.role, required this.name, required this.sub, required this.lang, this.photo});
  factory ChatPeerDto.fromJson(Map<String, dynamic> j) => ChatPeerDto(
        id: asInt(j['id']),
        role: asString(j['role']),
        name: asString(j['name']),
        sub: asString(j['sub']),
        lang: asString(j['lang']),
        photo: asStringOrNull(j['photo']),
      );
  ChatPeer toEntity() => ChatPeer(id: id, role: role, name: name, sub: sub, lang: lang, photo: photo);
}

class ConversationDto {
  final int id, farmerId, buyerId, unread, updatedAt;
  final LotDto? lot;
  final ChatPeerDto other;
  final ChatMessageDto? last;
  const ConversationDto({
    required this.id,
    required this.farmerId,
    required this.buyerId,
    required this.unread,
    required this.updatedAt,
    this.lot,
    required this.other,
    this.last,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> j) => ConversationDto(
        id: asInt(j['id']),
        farmerId: asInt(j['farmerId']),
        buyerId: asInt(j['buyerId']),
        unread: asInt(j['unread']),
        updatedAt: asInt(j['updatedAt']),
        lot: j['lot'] is Map ? LotDto.fromJson(asMap(j['lot'])) : null,
        other: ChatPeerDto.fromJson(asMap(j['other'])),
        last: j['last'] is Map ? ChatMessageDto.fromJson(asMap(j['last'])) : null,
      );

  Conversation toEntity() => Conversation(
        id: id,
        farmerId: farmerId,
        buyerId: buyerId,
        unread: unread,
        updatedAt: updatedAt,
        lot: lot?.toEntity(),
        other: other.toEntity(),
        last: last?.toEntity(),
      );
}
