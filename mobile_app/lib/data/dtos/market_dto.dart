// DTO del mercado del café (/market/coffee).
import '../../core/utils/json.dart';
import '../../domain/entities/market.dart';

List<PricePoint> _points(dynamic v) =>
    asMapList(v).map((p) => PricePoint(asInt(p['t']), asDouble(p['v']))).where((p) => p.t > 0 && p.v > 0).toList();

class CoffeeMarketDto {
  final Map<String, dynamic> internal, ny, trm, derived, constants;
  final List<PricePoint> internalHistory;
  final int updatedAt;
  const CoffeeMarketDto({
    required this.internal,
    required this.ny,
    required this.trm,
    required this.derived,
    required this.constants,
    required this.internalHistory,
    required this.updatedAt,
  });

  factory CoffeeMarketDto.fromJson(Map<String, dynamic> j) => CoffeeMarketDto(
        internal: asMap(j['internal']),
        ny: asMap(j['ny']),
        trm: asMap(j['trm']),
        derived: asMap(j['derived']),
        constants: asMap(j['constants']),
        internalHistory: _points(j['internalHistory']),
        updatedAt: asInt(j['updatedAt']),
      );

  CoffeeMarket toEntity() => CoffeeMarket(
        updatedAt: updatedAt,
        internal: internal.isEmpty
            ? null
            : InternalPrice(
                copPerCarga: asInt(internal['copPerCarga']),
                date: asString(internal['date']),
                source: asString(internal['source']),
                estimated: asBool(internal['estimated']),
                stale: asBool(internal['stale']),
                url: asStringOrNull(internal['url']),
              ),
        ny: ny.isEmpty
            ? null
            : NyPrice(
                usdCentsPerLb: asDouble(ny['usdCentsPerLb']),
                date: asString(ny['date']),
                source: asString(ny['source']),
                changePct: asDoubleOrNull(ny['changePct']),
                stale: asBool(ny['stale']),
                history: _points(ny['history']),
              ),
        trm: trm.isEmpty
            ? null
            : TrmRate(
                copPerUsd: asDouble(trm['copPerUsd']),
                date: asString(trm['date']),
                source: asString(trm['source']),
                stale: asBool(trm['stale']),
                history: _points(trm['history']),
              ),
        derived: derived.isEmpty
            ? null
            : MarketDerived(
                copPerKg: asInt(derived['copPerKg']),
                copPerArroba: asInt(derived['copPerArroba']),
                internalUsdPerLbGreen: asDoubleOrNull(derived['internalUsdPerLbGreen']),
                differentialUsdLb: asDoubleOrNull(derived['differentialUsdLb']),
              ),
        internalHistory: internalHistory,
        lbGreenPerCarga: asDouble(constants['lbGreenPerCarga'], 205.2),
      );
}
