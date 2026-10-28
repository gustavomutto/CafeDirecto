// Lotes de café.
import '../../../core/network/api_client.dart';
import '../../dtos/lot_dto.dart';

class LotRemoteDataSource {
  final ApiClient _api;
  LotRemoteDataSource(this._api);

  Future<List<LotDto>> search(Map<String, String> query) async => (await _api.getList('/lots', query)).map(LotDto.fromJson).toList();

  Future<LotDto> get(int id) async => LotDto.fromJson(await _api.getMap('/lots/$id'));

  Future<LotDto> create(Map<String, dynamic> body) async => LotDto.fromJson(await _api.postMap('/lots', body));

  Future<LotDto> update(int id, Map<String, dynamic> body) async => LotDto.fromJson(await _api.putMap('/lots/$id', body));

  Future<void> remove(int id) => _api.delete('/lots/$id');

  Future<List<InterestedBuyerDto>> interest(int id) async => (await _api.getList('/lots/$id/interest')).map(InterestedBuyerDto.fromJson).toList();
}
