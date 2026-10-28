// DTOs de subastas y ofertas.
import '../../core/utils/json.dart';
import '../../domain/entities/auction.dart';
import 'lot_dto.dart';

class BidderDto {
  final int id;
  final String name, company, country;
  final String? photo;
  const BidderDto(this.id, this.name, this.company, this.country, this.photo);
  static BidderDto? fromJson(dynamic v) {
    if (v is! Map) return null;
    return BidderDto(asInt(v['id']), asString(v['name']), asString(v['company']), asString(v['country']), asStringOrNull(v['photo']));
  }

  Bidder toEntity() => Bidder(id: id, name: name, company: company, country: country, photo: photo);
}

class BidDto {
  final int id, at, alias;
  final double priceLb;
  final String status;
  final bool mine;
  final BidderDto? bidder;
  const BidDto({required this.id, required this.at, required this.alias, required this.priceLb, required this.status, required this.mine, this.bidder});

  factory BidDto.fromJson(Map<String, dynamic> j) => BidDto(
        id: asInt(j['id']),
        at: asInt(j['at']),
        alias: asInt(j['alias']),
        priceLb: asDouble(j['priceLb']),
        status: asString(j['status']),
        mine: asBool(j['mine']),
        bidder: BidderDto.fromJson(j['bidder']),
      );

  Bid toEntity() => Bid(id: id, priceLb: priceLb, status: status, at: at, mine: mine, alias: alias, bidder: bidder?.toEntity());
}

class AuctionDto {
  final int id, lotId, farmerId, sacks, endsAt, createdAt, bidders;
  final double basePriceLb, minIncrementLb, minNext;
  final double? highest, myBest;
  final String incoterm, phase;
  final List<BidDto> bids;
  final bool leading;
  final int? winningBidId, agreementId;
  final LotDto? lot;

  const AuctionDto({
    required this.id,
    required this.lotId,
    required this.farmerId,
    required this.sacks,
    required this.endsAt,
    required this.createdAt,
    required this.bidders,
    required this.basePriceLb,
    required this.minIncrementLb,
    required this.minNext,
    this.highest,
    this.myBest,
    required this.incoterm,
    required this.phase,
    required this.bids,
    required this.leading,
    this.winningBidId,
    this.agreementId,
    this.lot,
  });

  factory AuctionDto.fromJson(Map<String, dynamic> j) => AuctionDto(
        id: asInt(j['id']),
        lotId: asInt(j['lotId']),
        farmerId: asInt(j['farmerId']),
        sacks: asInt(j['sacks']),
        endsAt: asInt(j['endsAt']),
        createdAt: asInt(j['createdAt']),
        bidders: asInt(j['bidders']),
        basePriceLb: asDouble(j['basePriceLb']),
        minIncrementLb: asDouble(j['minIncrementLb']),
        minNext: asDouble(j['minNext']),
        highest: asDoubleOrNull(j['highest']),
        myBest: asDoubleOrNull(j['myBest']),
        incoterm: asString(j['incoterm']),
        phase: asString(j['phase']),
        bids: asMapList(j['bids']).map(BidDto.fromJson).toList(),
        leading: asBool(j['leading']),
        winningBidId: asIntOrNull(j['winningBidId']),
        agreementId: asIntOrNull(j['agreementId']),
        lot: j['lot'] is Map ? LotDto.fromJson(asMap(j['lot'])) : null,
      );

  Auction toEntity() => Auction(
        id: id,
        lotId: lotId,
        farmerId: farmerId,
        sacks: sacks,
        endsAt: endsAt,
        createdAt: createdAt,
        basePriceLb: basePriceLb,
        minIncrementLb: minIncrementLb,
        minNext: minNext,
        incoterm: incoterm,
        phase: phase,
        highest: highest,
        myBest: myBest,
        bidders: bidders,
        bids: bids.map((b) => b.toEntity()).toList(),
        leading: leading,
        winningBidId: winningBidId,
        agreementId: agreementId,
        lot: lot?.toEntity(),
      );
}

class AuctionInputDto {
  static Map<String, dynamic> toJson(AuctionInput a) => {
        'basePriceLb': a.basePriceLb,
        'minIncrementLb': a.minIncrementLb,
        'sacks': a.sacks,
        'durationHours': a.durationHours,
        'incoterm': a.incoterm,
      };
}
