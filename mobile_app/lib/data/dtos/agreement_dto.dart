// DTOs de acuerdos y calificaciones.
import '../../core/utils/json.dart';
import '../../domain/entities/agreement.dart';
import 'user_dto.dart';

class RatingDto {
  final int stars;
  final List<String> tags;
  final BiDto? comment;
  const RatingDto(this.stars, this.tags, this.comment);
  static RatingDto? fromJson(dynamic v) {
    if (v is! Map) return null;
    return RatingDto(asInt(v['stars']), asStringList(v['tags']), BiDto.fromJson(v['comment']));
  }

  Rating toEntity() => Rating(stars: stars, tags: tags, comment: comment?.toEntity());
}

class AgreementDto {
  final int id, farmerId, buyerId, sacks, status, createdAt;
  final int? conversationId, lotId;
  final String code, lotName, variety, process, incoterm;
  final double sca, priceLb;
  final List<int> history;
  final Map<String, dynamic> farmer, buyer;
  final RatingDto? byFarmer, byBuyer;

  const AgreementDto({
    required this.id,
    required this.farmerId,
    required this.buyerId,
    required this.sacks,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.lotId,
    required this.code,
    required this.lotName,
    required this.variety,
    required this.process,
    required this.incoterm,
    required this.sca,
    required this.priceLb,
    required this.history,
    required this.farmer,
    required this.buyer,
    this.byFarmer,
    this.byBuyer,
  });

  factory AgreementDto.fromJson(Map<String, dynamic> j) {
    final ratings = asMap(j['ratings']);
    return AgreementDto(
      id: asInt(j['id']),
      farmerId: asInt(j['farmerId']),
      buyerId: asInt(j['buyerId']),
      sacks: asInt(j['sacks']),
      status: asInt(j['status']),
      createdAt: asInt(j['createdAt']),
      conversationId: asIntOrNull(j['conversationId']),
      lotId: asIntOrNull(j['lotId']),
      code: asString(j['code']),
      lotName: asString(j['lotName']),
      variety: asString(j['variety']),
      process: asString(j['process']),
      incoterm: asString(j['incoterm']),
      sca: asDouble(j['sca']),
      priceLb: asDouble(j['priceLb']),
      history: (j['history'] is List ? j['history'] as List : const []).map((e) => asInt(e)).toList(),
      farmer: asMap(j['farmer']),
      buyer: asMap(j['buyer']),
      byFarmer: RatingDto.fromJson(ratings['byFarmer']),
      byBuyer: RatingDto.fromJson(ratings['byBuyer']),
    );
  }

  Agreement toEntity() => Agreement(
        id: id,
        code: code,
        conversationId: conversationId,
        lotId: lotId,
        farmerId: farmerId,
        buyerId: buyerId,
        lotName: lotName,
        variety: variety,
        process: process,
        incoterm: incoterm,
        sca: sca,
        priceLb: priceLb,
        sacks: sacks,
        status: status,
        createdAt: createdAt,
        history: history,
        farmerName: asString(farmer['name']),
        farmName: asString(farmer['farmName']),
        farmRegion: asString(farmer['region']),
        farmerPhoto: asStringOrNull(farmer['photo']),
        buyerName: asString(buyer['name']),
        buyerCompany: asString(buyer['company']),
        buyerCity: asString(buyer['city']),
        buyerCountry: asString(buyer['country']),
        buyerPhoto: asStringOrNull(buyer['photo']),
        byFarmer: byFarmer?.toEntity(),
        byBuyer: byBuyer?.toEntity(),
      );
}
