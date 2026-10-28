// Subastas.
import '../../../core/network/api_client.dart';
import '../../dtos/auction_dto.dart';

class AuctionRemoteDataSource {
  final ApiClient _api;
  AuctionRemoteDataSource(this._api);

  Future<List<AuctionDto>> list({bool mine = false}) async =>
      (await _api.getList('/auctions', mine ? {'mine': '1'} : null)).map(AuctionDto.fromJson).toList();

  Future<AuctionDto> get(int id) async => AuctionDto.fromJson(await _api.getMap('/auctions/$id'));

  Future<AuctionDto> open(int lotId, Map<String, dynamic> body) async => AuctionDto.fromJson(await _api.postMap('/lots/$lotId/auction', body));

  Future<AuctionDto> bid(int auctionId, double priceLb) async => AuctionDto.fromJson(await _api.postMap('/auctions/$auctionId/bids', {'priceLb': priceLb}));

  Future<({AuctionDto auction, int agreementId})> award(int auctionId, int bidId) async {
    final j = await _api.postMap('/auctions/$auctionId/award', {'bidId': bidId});
    return (auction: AuctionDto.fromJson(Map<String, dynamic>.from(j['auction'] as Map)), agreementId: (j['agreementId'] as num).toInt());
  }

  Future<AuctionDto> cancel(int auctionId) async => AuctionDto.fromJson(await _api.postMap('/auctions/$auctionId/cancel'));
}
