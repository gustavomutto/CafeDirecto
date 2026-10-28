import '../../domain/entities/lot.dart';
import '../../domain/repositories/lot_repository.dart';
import '../datasources/remote/lot_remote_datasource.dart';
import '../dtos/lot_dto.dart';

class LotRepositoryImpl implements LotRepository {
  final LotRemoteDataSource _remote;
  LotRepositoryImpl(this._remote);

  @override
  Future<List<Lot>> search(LotQuery query) async => (await _remote.search(LotQueryDto.toQuery(query))).map((d) => d.toEntity()).toList();

  @override
  Future<List<Lot>> byFarmer(int farmerId) => search(LotQuery(farmerId: farmerId));

  @override
  Future<Lot> get(int id) async => (await _remote.get(id)).toEntity();

  @override
  Future<Lot> create(LotInput input) async => (await _remote.create(LotInputDto.toJson(input))).toEntity();

  @override
  Future<Lot> update(int id, LotInput input) async => (await _remote.update(id, LotInputDto.toJson(input))).toEntity();

  @override
  Future<void> remove(int id) => _remote.remove(id);

  @override
  Future<List<InterestedBuyer>> interestedBuyers(int lotId) async => (await _remote.interest(lotId)).map((d) => d.toEntity()).toList();
}
