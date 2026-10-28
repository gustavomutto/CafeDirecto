// Precios del café: precio interno (FNC), bolsa de Nueva York y TRM.

class PricePoint {
  final int t; // milisegundos
  final double v;
  const PricePoint(this.t, this.v);
}

class InternalPrice {
  final int copPerCarga;
  final String date, source;
  final bool estimated, stale;
  final String? url;
  const InternalPrice({required this.copPerCarga, required this.date, required this.source, required this.estimated, required this.stale, this.url});
}

class NyPrice {
  final double usdCentsPerLb;
  final String date, source;
  final double? changePct;
  final bool stale;
  final List<PricePoint> history;
  const NyPrice({required this.usdCentsPerLb, required this.date, required this.source, this.changePct, required this.stale, required this.history});

  double get usdPerLb => usdCentsPerLb / 100;
}

class TrmRate {
  final double copPerUsd;
  final String date, source;
  final bool stale;
  final List<PricePoint> history;
  const TrmRate({required this.copPerUsd, required this.date, required this.source, required this.stale, required this.history});
}

class MarketDerived {
  final int copPerKg, copPerArroba;
  final double? internalUsdPerLbGreen, differentialUsdLb;
  const MarketDerived({required this.copPerKg, required this.copPerArroba, this.internalUsdPerLbGreen, this.differentialUsdLb});
}

class CoffeeMarket {
  final int updatedAt;
  final InternalPrice? internal;
  final NyPrice? ny;
  final TrmRate? trm;
  final MarketDerived? derived;
  final List<PricePoint> internalHistory;
  final double lbGreenPerCarga;
  const CoffeeMarket({
    required this.updatedAt,
    this.internal,
    this.ny,
    this.trm,
    this.derived,
    required this.internalHistory,
    required this.lbGreenPerCarga,
  });

  bool get isEmpty => internal == null && ny == null && trm == null;

  /// Convierte un precio de US$/lb de café verde a pesos por carga (125 kg de pergamino).
  double? usdLbToCopCarga(double usdLb) => trm == null ? null : usdLb * lbGreenPerCarga * trm!.copPerUsd;
}
