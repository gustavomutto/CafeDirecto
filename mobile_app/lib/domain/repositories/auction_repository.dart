import '../entities/auction.dart';

abstract class AuctionRepository {
  /// Subastas activas (para compradores).
  Future<List<Auction>> live();

  /// Mis subastas (caficultor) o en las que pujé (comprador).
  Future<List<Auction>> mine();

  Future<Auction> get(int id);
  Future<Auction> open(int lotId, AuctionInput input);
  Future<Auction> bid(int auctionId, double priceLb);

  /// Elige la oferta ganadora; devuelve el id del acuerdo creado.
  Future<int> award(int auctionId, int bidId);
  Future<Auction> cancel(int auctionId);
}
