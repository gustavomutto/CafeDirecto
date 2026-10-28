import '../../domain/entities/auction.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/remote/auction_remote_datasource.dart';
import '../dtos/auction_dto.dart';

class AuctionRepositoryImpl implements AuctionRepository {
  final AuctionRemoteDataSource _remote;
  AuctionRepositoryImpl(this._remote);

  @override
  Future<List<Auction>> live() async => (await _remote.list()).map((d) => d.toEntity()).toList();

  @override
  Future<List<Auction>> mine() async => (await _remote.list(mine: true)).map((d) => d.toEntity()).toList();

  @override
  Future<Auction> get(int id) async => (await _remote.get(id)).toEntity();

  @override
  Future<Auction> open(int lotId, AuctionInput input) async => (await _remote.open(lotId, AuctionInputDto.toJson(input))).toEntity();

  @override
  Future<Auction> bid(int auctionId, double priceLb) async => (await _remote.bid(auctionId, priceLb)).toEntity();

  @override
  Future<int> award(int auctionId, int bidId) async => (await _remote.award(auctionId, bidId)).agreementId;

  @override
  Future<Auction> cancel(int auctionId) async => (await _remote.cancel(auctionId)).toEntity();
}
