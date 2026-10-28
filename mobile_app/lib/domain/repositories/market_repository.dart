import '../entities/exchange_rate.dart';
import '../entities/market.dart';

abstract class MarketRepository {
  Future<CoffeeMarket> coffee({bool refresh = false});
  Future<ExchangeRateSnapshot> exchangeRates({bool refresh = false});
}
