import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/exchange_rates.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class MarketRateBadge extends StatefulWidget {
  const MarketRateBadge({super.key});

  @override
  State<MarketRateBadge> createState() => _MarketRateBadgeState();
}

class _MarketRateBadgeState extends State<MarketRateBadge> {
  ExchangeRateSnapshot? _snapshot;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    loadExchangeRates().then<void>((snapshot) {
      if (mounted) setState(() => _snapshot = snapshot);
    }, onError: (Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final value = _snapshot?.rates['COP'];
    return Material(
      color: const Color(0xE61C1410),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/market'),
        child: SizedBox(
          width: 166,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('USD / COP',
                  style: p.text(
                      size: 12,
                      weight: FontWeight.w800,
                      color: Colors.white70)),
              const SizedBox(height: 3),
              Text(
                value == null
                    ? (_failed
                        ? app.tr('Tasa no disponible', 'Rate unavailable')
                        : app.tr('Cargando…', 'Loading…'))
                    : '1 USD = ${fmtNum(value, app.lang, 0)} COP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: p.text(
                    size: 13, weight: FontWeight.w900, color: Colors.white),
              ),
              if (value != null)
                Text(
                  app.tr('Peso colombiano', 'Colombian peso'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p.text(size: 10, color: Colors.white70),
                ),
              if (_snapshot != null)
                Text(
                  '${app.tr('Actualizado', 'Updated')} ${fmtDate(_snapshot!.updatedAt.millisecondsSinceEpoch, app.lang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p.text(size: 10, color: Colors.white70),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class MarketShortcut extends StatefulWidget {
  const MarketShortcut({super.key});

  @override
  State<MarketShortcut> createState() => _MarketShortcutState();
}

class _MarketShortcutState extends State<MarketShortcut> {
  ExchangeRateSnapshot? _snapshot;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    loadExchangeRates().then<void>((snapshot) {
      if (mounted) setState(() => _snapshot = snapshot);
    }, onError: (Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    return CardBox(
      color: p.warmSoft,
      onTap: () => context.go('/market'),
      child: Row(children: [
        Icon(Icons.currency_exchange_rounded, size: 28, color: p.warm),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.tr('Dólar de hoy · USD/COP', 'Today’s dollar · USD/COP'),
                style: p.text(weight: FontWeight.w800, color: p.warm)),
            Text(
              _snapshot == null
                  ? app.tr(
                      _failed
                          ? 'No se pudo cargar la tasa'
                          : 'Consultando cotización…',
                      _failed
                          ? 'Could not load the rate'
                          : 'Loading exchange rate…')
                  : '1 USD = COP ${fmtNum(_snapshot!.rates['COP']!, app.lang, 0)}',
              style: p.text(size: 12),
            ),
            if (_snapshot != null)
              Text(
                app.tr('Peso colombiano', 'Colombian peso'),
                style: p.muted(size: 11),
              ),
            if (_snapshot != null)
              Text(
                '${app.tr('Actualizado', 'Updated')} ${fmtDate(_snapshot!.updatedAt.millisecondsSinceEpoch, app.lang)}',
                style: p.muted(size: 11),
              ),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: p.warm),
      ]),
    );
  }
}

class _MarketScreenState extends State<MarketScreen> {
  ExchangeRateSnapshot? _snapshot;
  String _selectedCountryCode = 'CO';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final snapshot = await loadExchangeRates(refresh: refresh);
      if (mounted) {
        setState(() => _snapshot = snapshot);
      }
    } on TimeoutException {
      if (mounted) {
        setState(
            () => _error = 'La consulta tardó demasiado. Intenta de nuevo.');
      }
    } on http.ClientException catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo consultar la fuente: ${e.message}');
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } on ExchangeRateException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final country = latinAmericanCountries
        .firstWhere((item) => item.code == _selectedCountryCode);
    final rate = _snapshot?.rates[country.currency];

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(
              title: app.tr('Dólar y precios de mercado',
                  'Exchange rate & market prices')),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadRates(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Text(
                      app.tr('Dólar y café en América',
                          'Dollar and coffee in the Americas'),
                      style: p.display(size: 26)),
                  const SizedBox(height: 4),
                  Text(
                    app.tr(
                      'Mostramos solo cotizaciones con fuente y fecha verificables.',
                      'Only quotes with a verifiable source and date are shown.',
                    ),
                    style: p.muted(),
                  ),
                  SectionTitle(app.tr('Elige un país', 'Choose a country')),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCountryCode,
                    decoration: InputDecoration(
                      labelText: app.tr(
                          'País de América Latina', 'Latin American country'),
                      prefixIcon: const Icon(Icons.public_rounded),
                    ),
                    items: [
                      for (final item in latinAmericanCountries)
                        DropdownMenuItem(
                          value: item.code,
                          child: Text('${item.name(lang)} (${item.currency})'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCountryCode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  CardBox(
                    color: p.accentSoft,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.currency_exchange_rounded,
                                color: p.accent, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  app.tr('Dólar en ${country.name(lang)}',
                                      'US dollar in ${country.name(lang)}'),
                                  style: p.text(
                                      weight: FontWeight.w800,
                                      color: p.accent)),
                            ),
                            if (_loading && _snapshot == null)
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            if (rate != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '${country.currency} ${fmtNum(rate, lang, 2)}',
                                      style:
                                          p.display(size: 23, color: p.accent)),
                                  Text(
                                    country.currencyName(lang),
                                    style: p.muted(size: 11),
                                  ),
                                ],
                              ),
                          ]),
                          if (rate == null && !_loading)
                            Text(
                                app.tr(
                                    'Tasa no disponible.', 'Rate unavailable.'),
                                style: p.text(weight: FontWeight.w700)),
                          if (_snapshot != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${app.tr('Actualizado', 'Updated')} ${fmtDate(_snapshot!.updatedAt.millisecondsSinceEpoch, lang)}',
                                style: p.muted(size: 12),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              app.tr(
                                'Referencia de cambio de ExchangeRate-API. La fuente gratuita actualiza diariamente, no es una cotización en tiempo real.',
                                'ExchangeRate-API reference rate. The free source updates daily; it is not a real-time quote.',
                              ),
                              style: p.muted(size: 12),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: p.text(size: 13, color: p.danger)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _loadRates(refresh: true),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(app.tr('Reintentar', 'Retry')),
                              ),
                            ),
                          ],
                        ]),
                  ),
                  SectionTitle(app.tr('Precio local del café por país',
                      'Local coffee prices by country')),
                  CardBox(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.coffee_rounded, color: p.warm),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                app.tr('Sin cotizaciones locales verificadas',
                                    'No verified local quotes yet'),
                                style: p.text(weight: FontWeight.w800),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            app.tr(
                              'No hay una fuente pública gratuita integrada que confirme precios locales de café para los países de América. Para evitar cifras engañosas, no mostramos estimaciones como precios de productor.',
                              'There is no integrated free public source verifying local coffee prices across the Americas. To avoid misleading figures, estimates are not shown as producer prices.',
                            ),
                            style: p.muted(size: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.tr(
                              'Cuando haya una fuente local verificable, mostraremos el país, el precio publicado, la fecha y su conversión a COP.',
                              'When a verifiable local source is available, we will show the country, published price, date, and COP conversion.',
                            ),
                            style: p.muted(size: 13),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.tr(
                      'Fuente: ExchangeRate-API · Referencia indicativa, no tasa oficial bancaria.',
                      'Source: ExchangeRate-API · Indicative reference, not an official bank rate.',
                    ),
                    style: p.muted(size: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
