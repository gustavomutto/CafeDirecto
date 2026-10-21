// Modelos que llegan de la API (JSON → Dart).

int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
double _d(dynamic v, [double d = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? d;
String _s(dynamic v) => v == null ? '' : '$v';
String? _sn(dynamic v) => v == null ? null : '$v';
List<String> _ls(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];

/// Texto bilingüe.
class Bi {
  final String es;
  final String en;
  const Bi(this.es, this.en);

  String of(String lang) {
    final v = lang == 'es' ? es : en;
    return v.isNotEmpty ? v : (lang == 'es' ? en : es);
  }

  bool get isEmpty => es.isEmpty && en.isEmpty;

  static Bi? fromJson(dynamic j) => j is Map ? Bi(_s(j['es']), _s(j['en'])) : null;
  static Bi req(dynamic j) => fromJson(j) ?? const Bi('', '');
}

class RatingSummary {
  final double avg;
  final int count;
  const RatingSummary(this.avg, this.count);
  factory RatingSummary.fromJson(dynamic j) => j is Map ? RatingSummary(_d(j['avg']), _i(j['count'])) : const RatingSummary(0, 0);
}

class Review {
  final String by;
  final int stars;
  final Bi? text;
  final bool verified;
  const Review({required this.by, required this.stars, this.text, this.verified = false});
  factory Review.fromJson(Map j) => Review(by: _s(j['by']), stars: _i(j['stars']), text: Bi.fromJson(j['text']), verified: j['verified'] == true);
}

class AppUser {
  final int id;
  final String role; // 'farmer' | 'buyer'
  final String name;
  final String lang; // 'es' | 'en'
  final String? photo;
  final String email;
  final String phone;
  const AppUser({required this.id, required this.role, required this.name, required this.lang, this.photo, this.email = '', this.phone = ''});

  bool get isFarmer => role == 'farmer';

  factory AppUser.fromJson(Map j) => AppUser(
        id: _i(j['id']),
        role: _s(j['role']),
        name: _s(j['name']),
        lang: _s(j['lang']) == 'en' ? 'en' : 'es',
        photo: _sn(j['photo']),
        email: _s(j['email']),
        phone: _s(j['phone']),
      );
}

class FarmProfile {
  final int userId;
  final String producer;
  final String? producerPhoto;
  final String name, region, municipality;
  final int altitude;
  final double hectares;
  final List<String> varieties, processes, notes, certifications;
  final double sca;
  final int? since;
  final Bi story, quote;
  final String? cover;
  final List<String> gallery;
  final RatingSummary rating;
  final List<Review> reviews;

  FarmProfile.fromJson(Map j)
      : userId = _i(j['userId']),
        producer = _s(j['producer']),
        producerPhoto = _sn(j['producerPhoto']),
        name = _s(j['name']),
        region = _s(j['region']),
        municipality = _s(j['municipality']),
        altitude = _i(j['altitude']),
        hectares = _d(j['hectares']),
        varieties = _ls(j['varieties']),
        processes = _ls(j['processes']),
        notes = _ls(j['notes']),
        certifications = _ls(j['certifications']),
        sca = _d(j['sca']),
        since = j['since'] == null ? null : _i(j['since']),
        story = Bi.req(j['story']),
        quote = Bi.req(j['quote']),
        cover = _sn(j['cover']),
        gallery = _ls(j['gallery']),
        rating = RatingSummary.fromJson(j['rating']),
        reviews = (j['reviews'] as List? ?? []).map((e) => Review.fromJson(e as Map)).toList();

  String get displayName => name.isNotEmpty ? name : producer;
}

class BuyerProfile {
  final int userId;
  final String contact;
  final String? contactPhoto;
  final String company, city, country, type, volume;
  final int? since;
  final Bi about, looking;
  final String? cover;
  final bool verified;
  final RatingSummary rating;
  final List<Review> reviews;

  BuyerProfile.fromJson(Map j)
      : userId = _i(j['userId']),
        contact = _s(j['contact']),
        contactPhoto = _sn(j['contactPhoto']),
        company = _s(j['company']),
        city = _s(j['city']),
        country = _s(j['country']),
        type = _s(j['type']),
        volume = _s(j['volume']),
        since = j['since'] == null ? null : _i(j['since']),
        about = Bi.req(j['about']),
        looking = Bi.req(j['looking']),
        cover = _sn(j['cover']),
        verified = j['verified'] == true,
        rating = RatingSummary.fromJson(j['rating']),
        reviews = (j['reviews'] as List? ?? []).map((e) => Review.fromJson(e as Map)).toList();

  String get displayName => company.isNotEmpty ? company : contact;
}

class LotFarm {
  final String name, region, municipality, producer;
  final String? producerPhoto;
  final int altitude;
  final double hectares;
  final RatingSummary rating;
  LotFarm.fromJson(Map j)
      : name = _s(j['name']),
        region = _s(j['region']),
        municipality = _s(j['municipality']),
        producer = _s(j['producer']),
        producerPhoto = _sn(j['producerPhoto']),
        altitude = _i(j['altitude']),
        hectares = _d(j['hectares']),
        rating = RatingSummary.fromJson(j['rating']);
}

class Lot {
  final int id;
  final int farmerId;
  final String name, variety, process, harvest;
  final int sacks;
  final double sca, priceLb;
  final int? priceCarga;
  final List<String> notes;
  final String? photo;
  final int createdAt;
  final bool isNew;
  final LotFarm farm;
  final List<String> certifications;

  Lot.fromJson(Map j)
      : id = _i(j['id']),
        farmerId = _i(j['farmerId']),
        name = _s(j['name']),
        variety = _s(j['variety']),
        process = _s(j['process']),
        harvest = _s(j['harvest']),
        sacks = _i(j['sacks']),
        sca = _d(j['sca']),
        priceLb = _d(j['priceLb']),
        priceCarga = j['priceCarga'] == null ? null : _i(j['priceCarga']),
        notes = _ls(j['notes']),
        photo = _sn(j['photo']),
        createdAt = _i(j['createdAt']),
        isNew = j['isNew'] == true,
        farm = LotFarm.fromJson((j['farm'] as Map?) ?? {}),
        certifications = _ls(j['certifications']);
}

class QuoteStep {
  final String by;
  final double priceLb;
  final int sacks;
  QuoteStep.fromJson(Map j)
      : by = _s(j['by']),
        priceLb = _d(j['priceLb']),
        sacks = _i(j['sacks']);
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

  Quote.fromJson(Map j)
      : lotId = _i(j['lotId']),
        lotName = _s(j['lotName']),
        variety = _s(j['variety']),
        process = _s(j['process']),
        incoterm = _s(j['incoterm']),
        lastBy = _s(j['lastBy']),
        status = _s(j['status']),
        priceLb = _d(j['priceLb']),
        sacks = _i(j['sacks']),
        history = (j['history'] as List? ?? []).map((e) => QuoteStep.fromJson(e as Map)).toList(),
        acceptedBy = _sn(j['acceptedBy']),
        agreementId = j['agreementId'] == null ? null : _i(j['agreementId']);
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

  ChatMessage({
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

  factory ChatMessage.fromJson(Map j) => ChatMessage(
        id: _i(j['id']),
        conversationId: _i(j['conversationId']),
        senderId: j['senderId'] == null ? null : _i(j['senderId']),
        from: _sn(j['from']),
        type: _s(j['type']),
        text: _sn(j['text']),
        lang: _sn(j['lang']),
        translation: _sn(j['translation']),
        photo: _sn(j['photo']),
        viaVoice: j['viaVoice'] == true,
        quote: j['quote'] is Map ? Quote.fromJson(j['quote'] as Map) : null,
        agreementId: j['agreementId'] == null ? null : _i(j['agreementId']),
        sys: Bi.fromJson(j['sys']),
        createdAt: _i(j['createdAt']),
      );
}

class ChatPeer {
  final int id;
  final String role, name, sub, lang;
  final String? photo;
  ChatPeer.fromJson(Map j)
      : id = _i(j['id']),
        role = _s(j['role']),
        name = _s(j['name']),
        sub = _s(j['sub']),
        lang = _s(j['lang']),
        photo = _sn(j['photo']);
}

class Conversation {
  final int id, farmerId, buyerId, unread, updatedAt;
  final Lot? lot;
  final ChatPeer other;
  final ChatMessage? last;

  Conversation.fromJson(Map j)
      : id = _i(j['id']),
        farmerId = _i(j['farmerId']),
        buyerId = _i(j['buyerId']),
        unread = _i(j['unread']),
        updatedAt = _i(j['updatedAt']),
        lot = j['lot'] is Map ? Lot.fromJson(j['lot'] as Map) : null,
        other = ChatPeer.fromJson(j['other'] as Map),
        last = j['last'] is Map ? ChatMessage.fromJson(j['last'] as Map) : null;
}

class Rating {
  final int stars;
  final List<String> tags;
  final Bi? comment;
  Rating.fromJson(Map j)
      : stars = _i(j['stars']),
        tags = _ls(j['tags']),
        comment = Bi.fromJson(j['comment']);
}

/// status: 1 confirmado · 2 enviado · 3 entregado (0 = cotizado)
class Agreement {
  final int id;
  final String code;
  final int? conversationId, lotId;
  final int farmerId, buyerId;
  final String lotName, variety, process, incoterm;
  final double sca, priceLb;
  final int sacks, status, createdAt;
  final List<int> history;
  final String farmerName, farmName, farmRegion;
  final String? farmerPhoto, buyerPhoto;
  final String buyerName, buyerCompany, buyerCity, buyerCountry;
  final Rating? byFarmer, byBuyer;

  Agreement.fromJson(Map j)
      : id = _i(j['id']),
        code = _s(j['code']),
        conversationId = j['conversationId'] == null ? null : _i(j['conversationId']),
        lotId = j['lotId'] == null ? null : _i(j['lotId']),
        farmerId = _i(j['farmerId']),
        buyerId = _i(j['buyerId']),
        lotName = _s(j['lotName']),
        variety = _s(j['variety']),
        process = _s(j['process']),
        incoterm = _s(j['incoterm']),
        sca = _d(j['sca']),
        priceLb = _d(j['priceLb']),
        sacks = _i(j['sacks']),
        status = _i(j['status']),
        createdAt = _i(j['createdAt']),
        history = (j['history'] as List? ?? []).map((e) => _i(e)).toList(),
        farmerName = _s((j['farmer'] as Map?)?['name']),
        farmName = _s((j['farmer'] as Map?)?['farmName']),
        farmRegion = _s((j['farmer'] as Map?)?['region']),
        farmerPhoto = _sn((j['farmer'] as Map?)?['photo']),
        buyerName = _s((j['buyer'] as Map?)?['name']),
        buyerCompany = _s((j['buyer'] as Map?)?['company']),
        buyerCity = _s((j['buyer'] as Map?)?['city']),
        buyerCountry = _s((j['buyer'] as Map?)?['country']),
        buyerPhoto = _sn((j['buyer'] as Map?)?['photo']),
        byFarmer = (j['ratings'] as Map?)?['byFarmer'] is Map ? Rating.fromJson((j['ratings'] as Map)['byFarmer'] as Map) : null,
        byBuyer = (j['ratings'] as Map?)?['byBuyer'] is Map ? Rating.fromJson((j['ratings'] as Map)['byBuyer'] as Map) : null;

  Rating? ratingBy(String role) => role == 'farmer' ? byFarmer : byBuyer;
  String get buyerDisplay => buyerCompany.isNotEmpty ? buyerCompany : buyerName;
  String get farmDisplay => farmName.isNotEmpty ? farmName : farmerName;
}
