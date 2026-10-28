// Precios del café (los reúne el servidor desde la FNC, la bolsa de NY y la TRM).
import '../../../core/network/api_client.dart';
import '../../dtos/market_dto.dart';

class MarketRemoteDataSource {
  final ApiClient _api;
  MarketRemoteDataSource(this._api);

  Future<CoffeeMarketDto> coffee() async => CoffeeMarketDto.fromJson(await _api.getMap('/market/coffee'));
}
