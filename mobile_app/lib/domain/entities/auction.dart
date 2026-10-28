// Subastas con fecha límite y sus ofertas (pujas).
import 'lot.dart';

class Bidder {
  final int id;
  final String name, company, country;
  final String? photo;
  const Bidder({required this.id, required this.name, required this.company, required this.country, this.photo});

  String get display => company.isNotEmpty ? company : name;
}

/// status: 'active' | 'won' | 'lost'
class Bid {
  final int id;
  final double priceLb;
  final String status;
  final int at;
  final bool mine;
  final int alias; // "Comprador N" para los demás compradores

  /// Solo lo ve el caficultor (y cada comprador en sus propias ofertas).
  final Bidder? bidder;

  const Bid({required this.id, required this.priceLb, required this.status, required this.at, required this.mine, required this.alias, this.bidder});
}

/// phase: 'live' | 'ended' | 'awarded' | 'cancelled' | 'expired'
class Auction {
  final int id, lotId, farmerId, sacks, endsAt, createdAt;
  final double basePriceLb, minIncrementLb, minNext;
  final String incoterm, phase;
  final double? highest, myBest;
  final int bidders;
  final List<Bid> bids;
  final bool leading;
  final int? winningBidId, agreementId;
  final Lot? lot;

  const Auction({
    required this.id,
    required this.lotId,
    required this.farmerId,
    required this.sacks,
    required this.endsAt,
    required this.createdAt,
    required this.basePriceLb,
    required this.minIncrementLb,
    required this.minNext,
    required this.incoterm,
    required this.phase,
    this.highest,
    this.myBest,
    required this.bidders,
    required this.bids,
    required this.leading,
    this.winningBidId,
    this.agreementId,
    this.lot,
  });

  bool get isLive => phase == 'live';
  bool get isOpen => phase == 'live' || phase == 'ended';
  Duration get remaining => Duration(milliseconds: endsAt - DateTime.now().millisecondsSinceEpoch);
}

/// Datos para abrir una subasta.
class AuctionInput {
  final double basePriceLb, minIncrementLb;
  final int sacks;
  final int durationHours;
  final String incoterm;
  const AuctionInput({
    required this.basePriceLb,
    required this.minIncrementLb,
    required this.sacks,
    required this.durationHours,
    required this.incoterm,
  });
}
