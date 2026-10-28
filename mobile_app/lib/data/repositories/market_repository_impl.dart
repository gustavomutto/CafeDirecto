import '../../domain/entities/exchange_rate.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/remote/exchange_rate_remote_datasource.dart';
import '../datasources/remote/market_remote_datasource.dart';

/// Guarda en memoria los precios unos minutos para no consultar la red en cada pantalla.
class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource _coffee;
  final ExchangeRateRemoteDataSource _fx;
  MarketRepositoryImpl(this._coffee, this._fx);

  static const _ttl = Duration(minutes: 5);

  Future<CoffeeMarket>? _coffeeCache;
  DateTime? _coffeeAt;
  Future<ExchangeRateSnapshot>? _fxCache;
  DateTime? _fxAt;

  bool _fresh(DateTime? at) => at != null && DateTime.now().difference(at) < _ttl;

  @override
  Future<CoffeeMarket> coffee({bool refresh = false}) async {
    if (!refresh && _coffeeCache != null && _fresh(_coffeeAt)) return _coffeeCache!;
    final request = _coffee.coffee().then((d) => d.toEntity());
    _coffeeCache = request;
    _coffeeAt = DateTime.now();
    try {
      return await request;
    } catch (_) {
      if (identical(_coffeeCache, request)) {
        _coffeeCache = null;
        _coffeeAt = null;
      }
      rethrow;
    }
  }

  @override
  Future<ExchangeRateSnapshot> exchangeRates({bool refresh = false}) async {
    if (!refresh && _fxCache != null && _fresh(_fxAt)) return _fxCache!;
    final request = _fx.fetchLatest();
    _fxCache = request;
    _fxAt = DateTime.now();
    try {
      return await request;
    } catch (_) {
      if (identical(_fxCache, request)) {
        _fxCache = null;
        _fxAt = null;
      }
      rethrow;
    }
  }
}
