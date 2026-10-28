// Mercado del café: precio interno en Colombia (FNC), bolsa de Nueva York (contrato C),
// dólar oficial (TRM), prima del café colombiano, calculadora y tasas de cambio por país.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/countries.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/app_context.dart';
import '../../providers/market_provider.dart';
import '../../widgets/common.dart';
import 'market_widgets.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _country = 'CO';
  double _cargas = 1; // calculadora: cargas de 125 kg
  double? _myPriceLb; // calculadora: precio de venta en US$/lb

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MarketProvider>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final m = context.watch<MarketProvider>();
    final c = m.coffee;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Precio del café', 'Coffee prices'), subtitle: app.tr('Colombia y mercado internacional', 'Colombia & world market')),
          Expanded(
            child: RefreshIndicator(
              onRefresh: m.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (c == null && m.loadingCoffee) const Padding(padding: EdgeInsets.all(40), child: LoadingView()),
                  if (c == null && m.coffeeError != null)
                    ErrorRetry(error: m.coffeeError!, onRetry: () => m.loadCoffee(refresh: true)),
                  if (c != null) ...[
                    _internalCard(context, c),
                    const SizedBox(height: 12),
                    _nyCard(context, c),
                    const SizedBox(height: 12),
                    _trmCard(context, c),
                    if (c.derived?.differentialUsdLb != null) ...[
                      const SizedBox(height: 12),
                      _premiumCard(context, c),
                    ],
                    SectionTitle(app.isFarmer ? app.tr('¿Cuánto vale mi café?', 'What is my coffee worth?') : app.tr('Calculadora de precio', 'Price calculator')),
                    _calculator(context, c),
                  ],
                  SectionTitle(app.tr('Dólar en América Latina', 'US dollar in Latin America')),
                  _fxCard(context, m),
                  const SizedBox(height: 14),
                  FinePrint(app.tr(
                    'Precios de referencia con su fuente y fecha. El precio interno lo publica la Federación Nacional de Cafeteros por carga de 125 kg de café pergamino seco (factor 94) y varía según el punto de compra. La bolsa es el contrato C de café arábica (ICE, Nueva York). La TRM es la tasa oficial de la Superintendencia Financiera.',
                    'Reference prices with source and date. The internal price is published by the Colombian Coffee Growers Federation per 125 kg load of dry parchment (factor 94) and varies by buying point. The exchange price is the ICE "C" arabica contract (New York). TRM is the official Colombian exchange rate.',
                  )),
                  if (c != null) Text('${app.tr('Actualizado', 'Updated')} ${fmtTime(c.updatedAt, lang)}', textAlign: TextAlign.center, style: p.muted(size: 11)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Tarjetas ───────────────────────────────────────────────────
  Widget _priceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? unit,
    List<String> lines = const [],
    String? badge,
    Color? badgeColor,
    List<PricePoint> history = const [],
    required String source,
    bool stale = false,
  }) {
    final app = context.app;
    final p = context.pal;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(icon, color: p.warm, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: p.text(weight: FontWeight.w800))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (badgeColor ?? p.accent).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
              child: Text(badge, style: p.text(size: 12, weight: FontWeight.w800, color: badgeColor ?? p.accent)),
            ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: value, style: p.display(size: 28)),
              if (unit != null) TextSpan(text: ' $unit', style: p.muted()),
            ])),
          ),
          if (history.length >= 2) SizedBox(width: 96, height: 40, child: Sparkline(points: history, color: p.warm)),
        ]),
        for (final l in lines) Text(l, style: p.text(size: 13)),
        const SizedBox(height: 6),
        Text('${app.tr('Fuente', 'Source')}: $source${stale ? ' · ${app.tr('último dato disponible', 'last available value')}' : ''}', style: p.muted(size: 11)),
      ]),
    );
  }

  Widget _internalCard(BuildContext context, CoffeeMarket c) {
    final app = context.app;
    final p = context.pal;
    final i = c.internal;
    if (i == null) {
      return _priceCard(context,
          icon: Icons.local_cafe_outlined,
          title: app.tr('Precio interno en Colombia', 'Colombian internal price'),
          value: '—',
          source: 'FNC',
          lines: [app.tr('No disponible por ahora.', 'Not available right now.')]);
    }
    final d = c.derived;
    return _priceCard(
      context,
      icon: Icons.local_cafe_outlined,
      title: app.tr('Precio interno de referencia', 'Colombian reference price'),
      value: fmtCOP(i.copPerCarga),
      unit: app.tr('/ carga 125 kg', '/ 125 kg load'),
      badge: i.estimated ? app.tr('Estimado', 'Estimate') : i.date,
      badgeColor: i.estimated ? p.danger : p.accent,
      lines: [
        if (d != null) '${fmtCOP(d.copPerKg)} / kg  ·  ${fmtCOP(d.copPerArroba)} / ${app.tr('arroba (12,5 kg)', 'arroba (12.5 kg)')}',
        app.tr('Café pergamino seco, factor de rendimiento 94.', 'Dry parchment coffee, yield factor 94.'),
      ],
      history: c.internalHistory,
      source: i.source,
      stale: i.stale,
    );
  }

  Widget _nyCard(BuildContext context, CoffeeMarket c) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final n = c.ny;
    if (n == null) {
      return _priceCard(context,
          icon: Icons.public_rounded,
          title: app.tr('Bolsa de Nueva York', 'New York exchange'),
          value: '—',
          source: 'ICE',
          lines: [app.tr('No disponible por ahora.', 'Not available right now.')]);
    }
    final ch = n.changePct;
    return _priceCard(
      context,
      icon: Icons.public_rounded,
      title: app.tr('Bolsa de Nueva York · contrato C', 'New York · "C" contract'),
      value: fmtNum(n.usdCentsPerLb, lang, 2),
      unit: app.tr('centavos US\$/lb', 'US¢/lb'),
      badge: ch == null ? n.date : '${ch >= 0 ? '▲' : '▼'} ${fmtNum(ch.abs(), lang, 2)}%',
      badgeColor: ch == null ? null : (ch >= 0 ? p.accent : p.danger),
      lines: [
        '= ${fmtUSD(n.usdPerLb, lang)} ${app.tr('por libra de café verde', 'per pound of green coffee')}',
        if (c.trm != null) '≈ ${fmtCOP(n.usdPerLb * c.trm!.copPerUsd * lbPerKg)} ${app.tr('por kg de café verde', 'per kg of green coffee')}',
      ],
      history: n.history,
      source: n.source,
      stale: n.stale,
    );
  }

  Widget _trmCard(BuildContext context, CoffeeMarket c) {
    final app = context.app;
    final lang = app.lang;
    final t = c.trm;
    if (t == null) {
      return _priceCard(context, icon: Icons.attach_money_rounded, title: 'TRM', value: '—', source: 'Superfinanciera');
    }
    final h = t.history;
    final prev = h.length >= 2 ? h[h.length - 2].v : null;
    final ch = prev == null ? null : (t.copPerUsd - prev) / prev * 100;
    return _priceCard(
      context,
      icon: Icons.attach_money_rounded,
      title: app.tr('Dólar oficial (TRM)', 'Official dollar rate (TRM)'),
      value: fmtNum(t.copPerUsd, lang, 2),
      unit: 'COP / US\$',
      badge: t.date,
      lines: [
        if (ch != null) '${app.tr('Cambio frente al día anterior', 'Change vs. previous day')}: ${ch >= 0 ? '+' : '−'}${fmtNum(ch.abs(), lang, 2)}%',
      ],
      history: h,
      source: t.source,
      stale: t.stale,
    );
  }

  Widget _premiumCard(BuildContext context, CoffeeMarket c) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final d = c.derived!;
    final diff = d.differentialUsdLb!;
    return CardBox(
      color: p.accentSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(app.tr('Prima del café colombiano', 'Colombian coffee premium'), style: p.text(weight: FontWeight.w800, color: p.accent)),
        const SizedBox(height: 4),
        Text(
          '${diff >= 0 ? '+' : '−'}${fmtUSD(diff.abs(), lang, 3)}/lb ${app.tr('sobre la bolsa', 'over the exchange')}',
          style: p.display(size: 22, color: p.accent),
        ),
        if (d.internalUsdPerLbGreen != null)
          Text(
            app.tr(
              'El precio interno equivale a ${fmtUSD(d.internalUsdPerLbGreen!, lang)} por libra de café verde. Es el piso de referencia: los cafés especiales (80+ puntos) suelen negociarse por encima.',
              'The internal price equals ${fmtUSD(d.internalUsdPerLbGreen!, lang)} per pound of green coffee. It is the reference floor: specialty coffees (80+ points) usually trade above it.',
            ),
            style: p.text(size: 13),
          ),
      ]),
    );
  }

  Widget _calculator(BuildContext context, CoffeeMarket c) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final internal = c.internal?.copPerCarga;
    final trm = c.trm?.copPerUsd;
    final ref = c.derived?.internalUsdPerLbGreen ?? c.ny?.usdPerLb ?? 3.0;
    final myPrice = _myPriceLb ?? round2(ref + 1);
    final myCarga = c.usdLbToCopCarga(myPrice);
    final pct = (internal != null && myCarga != null && internal > 0) ? (myCarga - internal) / internal * 100 : null;

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetLabel(app.tr('Cantidad (cargas de 125 kg de pergamino)', 'Quantity (125 kg parchment loads)')),
        QtyStepper(value: _cargas, step: 1, min: 1, max: 500, onChanged: (v) => setState(() => _cargas = v), label: app.tr('cargas', 'loads')),
        if (internal != null)
          TotalBox(app.tr('A precio interno FNC', 'At FNC internal price'), fmtCOP(internal * _cargas)),
        SheetLabel(app.tr('Si lo vendes a este precio (US\$/lb de café verde)', 'If you sell at this price (US\$/lb green)')),
        QtyStepper(value: myPrice, step: 0.05, min: 0.5, max: 40, onChanged: (v) => setState(() => _myPriceLb = round2(v)), format: (v) => fmtUSD(v, lang), label: 'US\$/lb'),
        if (myCarga != null) ...[
          TotalBox(app.tr('Recibirías aprox.', 'You would get approx.'), fmtCOP(myCarga * _cargas)),
          Text(
            '${fmtCOP(myCarga)} ${app.tr('por carga', 'per load')}'
            '${pct == null ? '' : ' · ${pct >= 0 ? '+' : '−'}${fmtNum(pct.abs(), lang, 1)}% ${app.tr('frente al precio interno', 'vs. internal price')}'}',
            style: p.text(size: 13, weight: FontWeight.w700, color: pct == null ? p.ink : (pct >= 0 ? p.accent : p.danger)),
          ),
        ],
        if (trm == null) Text(app.tr('Se necesita la TRM para convertir.', 'The TRM is needed to convert.'), style: p.muted(size: 12)),
        const SizedBox(height: 6),
        Text(
          app.tr('1 carga ≈ ${fmtNum(c.lbGreenPerCarga, lang, 1)} lb de café verde. No incluye costos de trilla, transporte ni comisiones.',
              '1 load ≈ ${fmtNum(c.lbGreenPerCarga, lang, 1)} lb of green coffee. Excludes milling, transport and fees.'),
          style: p.muted(size: 11),
        ),
      ]),
    );
  }

  Widget _fxCard(BuildContext context, MarketProvider m) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final snap = m.rates;
    final country = latinAmericanCountries.firstWhere((x) => x.code == _country);
    final rate = snap?.rates[country.currency];
    final ny = m.coffee?.ny?.usdPerLb;

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(
          initialValue: _country,
          decoration: InputDecoration(labelText: app.tr('País', 'Country'), prefixIcon: const Icon(Icons.public_rounded)),
          items: [
            for (final x in latinAmericanCountries) DropdownMenuItem(value: x.code, child: Text('${x.name(lang)} (${x.currency})')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _country = v);
          },
        ),
        const SizedBox(height: 10),
        if (snap == null && m.loadingRates) const LoadingView(),
        if (snap == null && m.ratesError != null)
          ErrorRetry(error: m.ratesError!, onRetry: () => m.loadRates(refresh: true)),
        if (rate != null) ...[
          Text('1 US\$ = ${fmtNum(rate, lang, 2)} ${country.currency}', style: p.display(size: 24)),
          Text(country.currencyName(lang), style: p.muted(size: 12)),
          if (ny != null)
            Text(
              '${app.tr('Bolsa NY en', 'NY exchange in')} ${country.currency}: ${fmtNum(ny * rate, lang, 2)} / lb · ${fmtNum(ny * rate * lbPerKg, lang, 0)} / kg',
              style: p.text(size: 13, weight: FontWeight.w700),
            ),
          Text('${app.tr('Actualizado', 'Updated')} ${fmtDate(snap!.updatedAt.millisecondsSinceEpoch, lang)} · ExchangeRate-API', style: p.muted(size: 11)),
        ],
      ]),
    );
  }
}
