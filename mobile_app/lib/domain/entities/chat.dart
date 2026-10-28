// Conversaciones, mensajes y cotizaciones del chat.
import 'bi.dart';
import 'lot.dart';

class QuoteStep {
  final String by;
  final double priceLb;
  final int sacks;
  const QuoteStep({required this.by, required this.priceLb, required this.sacks});
}

/// status: 'open' | 'accepted' | 'agreed' | 'superseded'
class Quote {
  final int lotId;
  final String lotName, variety, process, incoterm, lastBy, status;
  final double priceLb;
  final int sacks;
  final List<QuoteStep> history;
  final String? acceptedBy;
  final int? agreementId;
  const Quote({
    required this.lotId,
    required this.lotName,
    required this.variety,
    required this.process,
    required this.incoterm,
    required this.lastBy,
    required this.status,
    required this.priceLb,
    required this.sacks,
    required this.history,
    this.acceptedBy,
    this.agreementId,
  });
}

/// type: 'text' | 'photo' | 'quote' | 'agreement' | 'system'
class ChatMessage {
  final int id;
  final int conversationId;
  final int? senderId;
  final String? from; // 'farmer' | 'buyer'
  final String type;
  final String? text, lang, translation, photo;
  final bool viaVoice;
  final Quote? quote;
  final int? agreementId;
  final Bi? sys;
  final int createdAt;
  final bool pending; // enviado desde el teléfono pero aún sin confirmar

  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.from,
    required this.type,
    this.text,
    this.lang,
    this.translation,
    this.photo,
    this.viaVoice = false,
    this.quote,
    this.agreementId,
    this.sys,
    required this.createdAt,
    this.pending = false,
  });
}

class ChatPeer {
  final int id;
  final String role, name, sub, lang;
  final String? photo;
  const ChatPeer({required this.id, required this.role, required this.name, required this.sub, required this.lang, this.photo});
}

class Conversation {
  final int id, farmerId, buyerId, unread, updatedAt;
  final Lot? lot;
  final ChatPeer other;
  final ChatMessage? last;
  const Conversation({
    required this.id,
    required this.farmerId,
    required this.buyerId,
    required this.unread,
    required this.updatedAt,
    this.lot,
    required this.other,
    this.last,
  });
}
