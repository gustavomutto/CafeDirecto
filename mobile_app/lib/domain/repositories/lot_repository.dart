import '../entities/lot.dart';

abstract class LotRepository {
  Future<List<Lot>> search(LotQuery query);
  Future<List<Lot>> byFarmer(int farmerId);
  Future<Lot> get(int id);
  Future<Lot> create(LotInput input);
  Future<Lot> update(int id, LotInput input);
  Future<void> remove(int id);

  /// Compradores que vieron el lote (solo el dueño).
  Future<List<InterestedBuyer>> interestedBuyers(int lotId);
}
