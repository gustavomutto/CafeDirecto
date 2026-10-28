// DTOs de lotes.
import '../../core/utils/json.dart';
import '../../domain/entities/lot.dart';
import 'user_dto.dart';

class LotFarmDto {
  final String name, region, municipality, producer;
  final String? producerPhoto;
  final int altitude;
  final double hectares;
  final RatingSummaryDto rating;
  const LotFarmDto({
    required this.name,
    required this.region,
    required this.municipality,
    required this.producer,
    this.producerPhoto,
    required this.altitude,
    required this.hectares,
    required this.rating,
  });

  factory LotFarmDto.fromJson(Map<String, dynamic> j) => LotFarmDto(
        name: asString(j['name']),
        region: asString(j['region']),
        municipality: asString(j['municipality']),
        producer: asString(j['producer']),
        producerPhoto: asStringOrNull(j['producerPhoto']),
        altitude: asInt(j['altitude']),
        hectares: asDouble(j['hectares']),
        rating: RatingSummaryDto.fromJson(j['rating']),
      );

  LotFarm toEntity() => LotFarm(
        name: name,
        region: region,
        municipality: municipality,
        producer: producer,
        producerPhoto: producerPhoto,
        altitude: altitude,
        hectares: hectares,
        rating: rating.toEntity(),
      );
}

class LotAuctionDto {
  final int id, endsAt, sacks, bids, bidders;
  final double basePriceLb, minIncrementLb;
  final double? highest;
  final String phase;
  const LotAuctionDto({
    required this.id,
    required this.endsAt,
    required this.sacks,
    required this.bids,
    required this.bidders,
    required this.basePriceLb,
    required this.minIncrementLb,
    this.highest,
    required this.phase,
  });

  static LotAuctionDto? fromJson(dynamic v) {
    if (v is! Map) return null;
    final j = Map<String, dynamic>.from(v);
    return LotAuctionDto(
      id: asInt(j['id']),
      endsAt: asInt(j['endsAt']),
      sacks: asInt(j['sacks']),
      bids: asInt(j['bids']),
      bidders: asInt(j['bidders']),
      basePriceLb: asDouble(j['basePriceLb']),
      minIncrementLb: asDouble(j['minIncrementLb']),
      highest: asDoubleOrNull(j['highest']),
      phase: asString(j['phase']),
    );
  }

  LotAuction toEntity() => LotAuction(
        id: id,
        endsAt: endsAt,
        basePriceLb: basePriceLb,
        minIncrementLb: minIncrementLb,
        sacks: sacks,
        phase: phase,
        highest: highest,
        bids: bids,
        bidders: bidders,
      );
}

class LotDto {
  final int id, farmerId, sacks, createdAt;
  final String name, variety, process, harvest;
  final double sca, priceLb;
  final int? priceCarga, interest;
  final List<String> notes, certifications;
  final String? photo;
  final bool isNew;
  final LotFarmDto farm;
  final LotAuctionDto? auction;

  const LotDto({
    required this.id,
    required this.farmerId,
    required this.sacks,
    required this.createdAt,
    required this.name,
    required this.variety,
    required this.process,
    required this.harvest,
    required this.sca,
    required this.priceLb,
    this.priceCarga,
    this.interest,
    required this.notes,
    required this.certifications,
    this.photo,
    required this.isNew,
    required this.farm,
    this.auction,
  });

  factory LotDto.fromJson(Map<String, dynamic> j) => LotDto(
        id: asInt(j['id']),
        farmerId: asInt(j['farmerId']),
        sacks: asInt(j['sacks']),
        createdAt: asInt(j['createdAt']),
        name: asString(j['name']),
        variety: asString(j['variety']),
        process: asString(j['process']),
        harvest: asString(j['harvest']),
        sca: asDouble(j['sca']),
        priceLb: asDouble(j['priceLb']),
        priceCarga: asIntOrNull(j['priceCarga']),
        interest: asIntOrNull(j['interest']),
        notes: asStringList(j['notes']),
        certifications: asStringList(j['certifications']),
        photo: asStringOrNull(j['photo']),
        isNew: asBool(j['isNew']),
        farm: LotFarmDto.fromJson(asMap(j['farm'])),
        auction: LotAuctionDto.fromJson(j['auction']),
      );

  Lot toEntity() => Lot(
        id: id,
        farmerId: farmerId,
        name: name,
        variety: variety,
        process: process,
        harvest: harvest,
        sacks: sacks,
        sca: sca,
        priceLb: priceLb,
        priceCarga: priceCarga,
        notes: notes,
        photo: photo,
        createdAt: createdAt,
        isNew: isNew,
        farm: farm.toEntity(),
        certifications: certifications,
        auction: auction?.toEntity(),
        interest: interest,
      );
}

class InterestedBuyerDto {
  final UserDto user;
  final String company, city, country;
  final int views, firstAt, lastAt;
  const InterestedBuyerDto({
    required this.user,
    required this.company,
    required this.city,
    required this.country,
    required this.views,
    required this.firstAt,
    required this.lastAt,
  });

  factory InterestedBuyerDto.fromJson(Map<String, dynamic> j) => InterestedBuyerDto(
        user: UserDto.fromJson(asMap(j['user'])),
        company: asString(j['company']),
        city: asString(j['city']),
        country: asString(j['country']),
        views: asInt(j['views']),
        firstAt: asInt(j['firstAt']),
        lastAt: asInt(j['lastAt']),
      );

  InterestedBuyer toEntity() => InterestedBuyer(
        user: user.toEntity(),
        company: company,
        city: city,
        country: country,
        views: views,
        firstAt: firstAt,
        lastAt: lastAt,
      );
}

// ── Envío ────────────────────────────────────────────────────────
class LotInputDto {
  static Map<String, dynamic> toJson(LotInput l) => {
        'name': l.name,
        'variety': l.variety,
        'process': l.process,
        'sacks': l.sacks,
        'sca': l.sca,
        'priceLb': l.priceLb,
        'priceCarga': l.priceCarga,
        'notes': l.notes,
        'harvest': l.harvest,
        'photoId': l.photoId,
      };
}

class LotQueryDto {
  static Map<String, String> toQuery(LotQuery q) => {
        if (q.farmerId != null) 'farmerId': '${q.farmerId}',
        if (q.regions.isNotEmpty) 'region': q.regions.join(','),
        if (q.processes.isNotEmpty) 'process': q.processes.join(','),
        if (q.varieties.isNotEmpty) 'variety': q.varieties.join(','),
        if (q.minSca != null) 'minSca': q.minSca!.toStringAsFixed(0),
        if (q.minAlt != null) 'minAlt': q.minAlt!.toStringAsFixed(0),
        if (q.text.trim().isNotEmpty) 'q': q.text.trim(),
        if (q.onlyAuctions) 'auction': '1',
      };
}
