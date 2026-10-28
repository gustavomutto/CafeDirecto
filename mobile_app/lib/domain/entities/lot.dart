// Lotes de café publicados por los caficultores.
import '../../core/utils/media.dart';
import 'user.dart';

class LotFarm {
  final String name, region, municipality, producer;
  final String? producerPhoto;
  final int altitude;
  final double hectares;
  final RatingSummary rating;
  const LotFarm({
    required this.name,
    required this.region,
    required this.municipality,
    required this.producer,
    this.producerPhoto,
    required this.altitude,
    required this.hectares,
    required this.rating,
  });
}

/// Resumen de la subasta abierta de un lote (si tiene una).
/// phase: 'live' (recibe ofertas) | 'ended' (terminó, falta elegir ganador)
class LotAuction {
  final int id;
  final int endsAt;
  final double basePriceLb, minIncrementLb;
  final int sacks;
  final String phase;
  final double? highest;
  final int bids, bidders;
  const LotAuction({
    required this.id,
    required this.endsAt,
    required this.basePriceLb,
    required this.minIncrementLb,
    required this.sacks,
    required this.phase,
    this.highest,
    required this.bids,
    required this.bidders,
  });

  bool get isLive => phase == 'live';
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
  final LotAuction? auction;

  /// Cuántos compradores lo han visto (solo llega para el dueño del lote).
  final int? interest;

  const Lot({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.variety,
    required this.process,
    required this.harvest,
    required this.sacks,
    required this.sca,
    required this.priceLb,
    this.priceCarga,
    required this.notes,
    this.photo,
    required this.createdAt,
    required this.isNew,
    required this.farm,
    required this.certifications,
    this.auction,
    this.interest,
  });

  /// Id de la foto (las direcciones son '/images/ID?s=FIRMA').
  int? get photoId => imageIdFromUrl(photo);
}

/// Datos para publicar o editar un lote.
class LotInput {
  final String name, variety, process, harvest;
  final int sacks;
  final double sca, priceLb;
  final int? priceCarga, photoId;
  final List<String> notes;
  const LotInput({
    required this.name,
    required this.variety,
    required this.process,
    required this.harvest,
    required this.sacks,
    required this.sca,
    required this.priceLb,
    this.priceCarga,
    this.photoId,
    required this.notes,
  });
}

/// Filtros de búsqueda de lotes.
class LotQuery {
  final int? farmerId;
  final Set<String> regions, processes, varieties;
  final double? minSca, minAlt;
  final String text;
  final bool onlyAuctions;
  const LotQuery({
    this.farmerId,
    this.regions = const {},
    this.processes = const {},
    this.varieties = const {},
    this.minSca,
    this.minAlt,
    this.text = '',
    this.onlyAuctions = false,
  });
}

/// Comprador que vio un lote (para el caficultor).
class InterestedBuyer {
  final AppUser user;
  final String company, city, country;
  final int views, firstAt, lastAt;
  const InterestedBuyer({
    required this.user,
    required this.company,
    required this.city,
    required this.country,
    required this.views,
    required this.firstAt,
    required this.lastAt,
  });

  String get display => company.isNotEmpty ? company : user.name;
}
