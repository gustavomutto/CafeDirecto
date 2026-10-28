// Acuerdos registrados (por cotización en el chat o por subasta).
import 'bi.dart';

class Rating {
  final int stars;
  final List<String> tags;
  final Bi? comment;
  const Rating({required this.stars, required this.tags, this.comment});
}

/// status: 1 confirmado · 2 enviado · 3 entregado
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

  const Agreement({
    required this.id,
    required this.code,
    this.conversationId,
    this.lotId,
    required this.farmerId,
    required this.buyerId,
    required this.lotName,
    required this.variety,
    required this.process,
    required this.incoterm,
    required this.sca,
    required this.priceLb,
    required this.sacks,
    required this.status,
    required this.createdAt,
    required this.history,
    required this.farmerName,
    required this.farmName,
    required this.farmRegion,
    this.farmerPhoto,
    this.buyerPhoto,
    required this.buyerName,
    required this.buyerCompany,
    required this.buyerCity,
    required this.buyerCountry,
    this.byFarmer,
    this.byBuyer,
  });

  Rating? ratingBy(String role) => role == 'farmer' ? byFarmer : byBuyer;
  String get buyerDisplay => buyerCompany.isNotEmpty ? buyerCompany : buyerName;
  String get farmDisplay => farmName.isNotEmpty ? farmName : farmerName;
}
