// Precios del café y tasas de cambio, compartidos por las tarjetas de inicio y la pantalla de mercado.
import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';

class MarketProvider extends ChangeNotifier {
  MarketProvider(this._repo);
  final MarketRepository _repo;

  CoffeeMarket? coffee;
  ExchangeRateSnapshot? rates;
  Object? coffeeError, ratesError;
  bool loadingCoffee = false, loadingRates = false;

  /// Carga si todavía no hay datos (se puede llamar desde varias pantallas sin repetir consultas).
  Future<void> ensureLoaded() async {
    final tasks = <Future<void>>[];
    if (coffee == null && !loadingCoffee) tasks.add(loadCoffee());
    if (rates == null && !loadingRates) tasks.add(loadRates());
    await Future.wait(tasks);
  }

  Future<void> refresh() => Future.wait([loadCoffee(refresh: true), loadRates(refresh: true)]);

  Future<void> loadCoffee({bool refresh = false}) async {
    loadingCoffee = true;
    coffeeError = null;
    notifyListeners();
    try {
      coffee = await _repo.coffee(refresh: refresh);
    } catch (e) {
      coffeeError = e;
      AppLogger.w('Precios del café no disponibles: $e', tag: 'Mercado');
    } finally {
      loadingCoffee = false;
      notifyListeners();
    }
  }

  Future<void> loadRates({bool refresh = false}) async {
    loadingRates = true;
    ratesError = null;
    notifyListeners();
    try {
      rates = await _repo.exchangeRates(refresh: refresh);
    } catch (e) {
      ratesError = e;
      AppLogger.w('Tasas de cambio no disponibles: $e', tag: 'Mercado');
    } finally {
      loadingRates = false;
      notifyListeners();
    }
  }

  /// Dólar oficial (TRM); si no hay, el de la fuente de tasas.
  double? get copPerUsd => coffee?.trm?.copPerUsd ?? rates?.rates['COP'];
}
