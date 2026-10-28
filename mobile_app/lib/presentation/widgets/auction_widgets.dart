// Piezas de interfaz de las subastas: cuenta regresiva, banner en el lote y tarjeta de lista.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import '../../domain/entities/entities.dart';
import '../providers/app_context.dart';
import 'common.dart';

/// Texto que se actualiza cada segundo con el tiempo que falta.
class Countdown extends StatefulWidget {
  final int endsAt;
  final TextStyle? style;
  final String? prefix;
  const Countdown({super.key, required this.endsAt, this.style, this.prefix});

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (widget.endsAt <= nowMs()) _t?.cancel();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.app.lang;
    final text = fmtRemaining(widget.endsAt, lang);
    return Text(widget.prefix == null ? text : '${widget.prefix} $text', style: widget.style);
  }
}

String auctionPhaseLabel(String phase, String lang) {
  final es = lang == 'es';
  return switch (phase) {
    'live' => es ? 'En subasta' : 'Live auction',
    'ended' => es ? 'Terminó · eligiendo ganador' : 'Ended · choosing winner',
    'awarded' => es ? 'Adjudicada' : 'Awarded',
    'cancelled' => es ? 'Cancelada' : 'Cancelled',
    'expired' => es ? 'Vencida' : 'Expired',
    _ => phase,
  };
}

/// Banner del lote cuando tiene una subasta abierta.
class LotAuctionBanner extends StatelessWidget {
  final LotAuction auction;
  final bool own;
  const LotAuctionBanner({super.key, required this.auction, this.own = false});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final best = auction.highest;
    return CardBox(
      color: p.warmSoft,
      onTap: () => context.go('/auction/${auction.id}'),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: p.warm, shape: BoxShape.circle),
          child: const Icon(Icons.gavel_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auctionPhaseLabel(auction.phase, lang).toUpperCase(), style: p.text(size: 11, weight: FontWeight.w900, color: p.warm)),
            Text(
              best == null
                  ? '${app.tr('Precio base', 'Base price')} ${fmtUSD(auction.basePriceLb, lang)}/lb'
                  : '${app.tr('Mejor oferta', 'Best offer')} ${fmtUSD(best, lang)}/lb',
              style: p.text(weight: FontWeight.w800),
            ),
            Text(
              '${auction.bids} ${app.tr('ofertas', 'offers')} · ${auction.bidders} ${app.tr('compradores', 'buyers')} · ${auction.sacks} ${app.tr('sacos', 'bags')}',
              style: p.muted(size: 12),
            ),
            if (auction.isLive) Countdown(endsAt: auction.endsAt, prefix: app.tr('Cierra en', 'Closes in'), style: p.muted(size: 12, weight: FontWeight.w700)),
          ]),
        ),
        Text(own ? app.tr('Ver ofertas', 'See offers') : app.tr('Pujar', 'Bid'), style: p.text(size: 13, weight: FontWeight.w800, color: p.warm)),
        Icon(Icons.chevron_right_rounded, color: p.warm),
      ]),
    );
  }
}

/// Tarjeta de una subasta en las listas.
class AuctionCard extends StatelessWidget {
  final Auction auction;
  const AuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final a = auction;
    final lot = a.lot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBox(
        padding: const EdgeInsets.all(12),
        onTap: () => context.go('/auction/${a.id}'),
        child: Row(children: [
          NetImg(lot?.photo, width: 72, height: 72, radius: BorderRadius.circular(p.radiusSm)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auctionPhaseLabel(a.phase, lang).toUpperCase(), style: p.text(size: 11, weight: FontWeight.w900, color: a.isOpen ? p.warm : p.ink2)),
              Text(lot?.name ?? app.tr('Lote', 'Lot'), style: p.text(weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (lot != null)
                Text([lot.farm.name, lot.farm.region].where((s) => s.isNotEmpty).join(' · '), style: p.muted(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(fmtUSD(a.highest ?? a.basePriceLb, lang), style: p.text(weight: FontWeight.w900, color: p.primary)),
                Text(' /lb · ${a.bids.length} ${app.tr('ofertas', 'offers')}', style: p.muted(size: 12)),
              ]),
              if (a.isLive) Countdown(endsAt: a.endsAt, prefix: app.tr('Cierra en', 'Closes in'), style: p.muted(size: 12, weight: FontWeight.w700)),
              if (a.myBest != null)
                Text(
                  a.leading ? app.tr('★ Vas ganando', '★ You are leading') : '${app.tr('Tu oferta', 'Your offer')}: ${fmtUSD(a.myBest!, lang)}',
                  style: p.text(size: 12, weight: FontWeight.w800, color: a.leading ? p.accent : p.danger),
                ),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: p.ink2),
        ]),
      ),
    );
  }
}
