// Piezas del mercado que se usan en otras pantallas: la etiqueta de la bienvenida,
// el acceso directo del inicio y la mini gráfica de tendencia.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/format.dart';
import '../../../domain/entities/market.dart';
import '../../providers/app_context.dart';
import '../../providers/market_provider.dart';
import '../../widgets/common.dart';

/// Etiqueta oscura para la pantalla de bienvenida (antes de iniciar sesión).
class MarketRateBadge extends StatefulWidget {
  const MarketRateBadge({super.key});

  @override
  State<MarketRateBadge> createState() => _MarketRateBadgeState();
}

class _MarketRateBadgeState extends State<MarketRateBadge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MarketProvider>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final m = context.watch<MarketProvider>();
    final usd = m.copPerUsd;
    final carga = m.coffee?.internal?.copPerCarga;
    final white = p.text(size: 13, weight: FontWeight.w900, color: Colors.white);
    final dim = p.text(size: 10, color: Colors.white70);
    return Material(
      color: p.dark ? p.surface2 : const Color(0xE61C1410),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/market'),
        child: SizedBox(
          width: 176,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.tr('MERCADO HOY', 'MARKET TODAY'), style: p.text(size: 11, weight: FontWeight.w800, color: Colors.white70)),
              const SizedBox(height: 3),
              if (usd == null && carga == null)
                Text(
                  (m.coffeeError != null && m.ratesError != null) ? app.tr('No disponible', 'Unavailable') : app.tr('Cargando…', 'Loading…'),
                  style: white,
                ),
              if (usd != null) Text('1 USD = ${fmtNum(usd, app.lang, 0)} COP', maxLines: 1, overflow: TextOverflow.ellipsis, style: white),
              if (carga != null) Text('☕ ${fmtCOP(carga)} / carga', maxLines: 1, overflow: TextOverflow.ellipsis, style: white),
              if (m.coffee?.ny != null) Text('NY ${fmtNum(m.coffee!.ny!.usdCentsPerLb, app.lang, 2)} ¢/lb', style: dim),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de acceso al mercado en el inicio (caficultor) y en Explorar (comprador).
class MarketShortcut extends StatefulWidget {
  const MarketShortcut({super.key});

  @override
  State<MarketShortcut> createState() => _MarketShortcutState();
}

class _MarketShortcutState extends State<MarketShortcut> {
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
    final farmer = app.isFarmer;

    String line1;
    String? line2;
    if (c?.internal != null && farmer) {
      line1 = '${fmtCOP(c!.internal!.copPerCarga)} ${app.tr('por carga', 'per load')}${c.internal!.estimated ? ' (${app.tr('estimado', 'estimate')})' : ''}';
      line2 = [
        if (c.ny != null) 'NY ${fmtNum(c.ny!.usdCentsPerLb, lang, 2)} ¢/lb',
        if (c.trm != null) 'TRM ${fmtNum(c.trm!.copPerUsd, lang, 0)}',
      ].join(' · ');
    } else if (c?.ny != null) {
      line1 = 'NY ${fmtUSD(c!.ny!.usdPerLb, lang)}/lb${c.ny!.changePct != null ? '  ${c.ny!.changePct! >= 0 ? '▲' : '▼'} ${fmtNum(c.ny!.changePct!.abs(), lang, 2)}%' : ''}';
      line2 = [
        if (c.derived?.internalUsdPerLbGreen != null) '${app.tr('Colombia', 'Colombia')} ${fmtUSD(c.derived!.internalUsdPerLbGreen!, lang)}/lb',
        if (c.trm != null) 'TRM ${fmtNum(c.trm!.copPerUsd, lang, 0)}',
      ].join(' · ');
    } else if (m.copPerUsd != null) {
      line1 = '1 USD = ${fmtNum(m.copPerUsd!, lang, 0)} COP';
    } else {
      line1 = (m.loadingCoffee || m.loadingRates) ? app.tr('Consultando precios…', 'Loading prices…') : app.tr('Precios no disponibles', 'Prices unavailable');
    }

    final history = farmer && (c?.internalHistory.length ?? 0) >= 2 ? c!.internalHistory : c?.ny?.history ?? const <PricePoint>[];
    return CardBox(
      color: p.warmSoft,
      onTap: () => context.go('/market'),
      child: Row(children: [
        Icon(Icons.trending_up_rounded, size: 28, color: p.warm),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.tr('Precio del café hoy', 'Coffee price today'), style: p.text(weight: FontWeight.w800, color: p.warm)),
            Text(line1, style: p.text(size: 13, weight: FontWeight.w700)),
            if (line2 != null && line2.isNotEmpty) Text(line2, style: p.muted(size: 11)),
          ]),
        ),
        if (history.length >= 2) SizedBox(width: 64, height: 32, child: Sparkline(points: history, color: p.warm)),
        Icon(Icons.chevron_right_rounded, color: p.warm),
      ]),
    );
  }
}

/// Mini gráfica de línea (sin ejes) para ver la tendencia.
class Sparkline extends StatelessWidget {
  final List<PricePoint> points;
  final Color color;
  final double strokeWidth;
  const Sparkline({super.key, required this.points, required this.color, this.strokeWidth = 2});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SparkPainter(points, color, strokeWidth));
}

class _SparkPainter extends CustomPainter {
  final List<PricePoint> points;
  final Color color;
  final double strokeWidth;
  _SparkPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var lo = points.first.v, hi = points.first.v;
    for (final pt in points) {
      if (pt.v < lo) lo = pt.v;
      if (pt.v > hi) hi = pt.v;
    }
    final span = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - (points[i].v - lo) / span * (size.height - strokeWidth) - strokeWidth / 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.points != points || old.color != color;
}
