// Detalle de una subasta: tiempo restante, ofertas en vivo (se actualizan cada 5 s),
// pujar (comprador) o elegir ganador / cancelar (caficultor).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auction_repository.dart';
import '../../providers/app_context.dart';
import '../../providers/auction_detail_controller.dart';
import '../../widgets/auction_widgets.dart';
import '../../widgets/common.dart';

class AuctionDetailScreen extends StatelessWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuctionDetailController(ctx.read<AuctionRepository>(), auctionId)..load(),
      child: const _AuctionView(),
    );
  }
}

class _AuctionView extends StatelessWidget {
  const _AuctionView();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final ctrl = context.watch<AuctionDetailController>();
    final a = ctrl.auction;
    if (a == null) {
      return Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(children: [
            const TopBar(),
            Expanded(child: ctrl.error != null ? ErrorRetry(error: ctrl.error!, onRetry: ctrl.load) : const LoadingView()),
          ]),
        ),
      );
    }
    return _AuctionBody(auction: a, ctrl: ctrl);
  }
}

class _AuctionBody extends StatelessWidget {
  final Auction auction;
  final AuctionDetailController ctrl;
  const _AuctionBody({required this.auction, required this.ctrl});

  Future<void> _openBid(BuildContext context) async {
    final app = context.session;
    final lang = app.lang;
    final a = auction;
    var price = a.minNext;
    final ok = await showAppSheet<bool>(
      context,
      title: app.tr('Tu oferta', 'Your offer'),
      body: (ctx, setSheet) {
        final p = ctx.pal;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            a.highest == null
                ? '${app.tr('Precio base', 'Base price')}: ${fmtUSD(a.basePriceLb, lang)}/lb'
                : '${app.tr('Oferta más alta', 'Highest offer')}: ${fmtUSD(a.highest!, lang)}/lb · ${app.tr('mínimo', 'minimum')} ${fmtUSD(a.minNext, lang)}',
            style: p.muted(),
          ),
          SheetLabel(app.tr('Precio por libra (US\$)', 'Price per pound (US\$)')),
          QtyStepper(
            value: price,
            step: a.minIncrementLb,
            min: a.minNext,
            max: a.basePriceLb * 5,
            onChanged: (v) => setSheet(() => price = round2(v)),
            format: (v) => fmtUSD(v, lang),
            label: 'US\$/lb',
          ),
          TotalBox(app.tr('Total por ${a.sacks} sacos', 'Total for ${a.sacks} bags'), fmtUSD(quoteTotal(price, a.sacks), lang, 0)),
          FinePrint(app.tr('Tu oferta es un compromiso de compra si el caficultor la elige.', 'Your offer is a purchase commitment if the farmer chooses it.')),
        ]);
      },
      footer: (ctx, _) => Btn(app.tr('Ofertar', 'Place bid'), icon: Icons.gavel_rounded, large: true, block: true, onPressed: () => Navigator.of(ctx).pop(true)),
    );
    if (ok != true) return;
    try {
      await ctrl.bid(price);
      app.showToast(app.tr('¡Oferta enviada! Vas ganando.', 'Bid placed! You are leading.'), '🔨');
    } catch (e) {
      app.showError(e);
      await ctrl.load();
    }
  }

  Future<void> _award(BuildContext context, Bid bid) async {
    final app = context.session;
    final lang = app.lang;
    final who = bid.bidder?.display ?? '${app.tr('Comprador', 'Buyer')} ${bid.alias}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(app.tr('¿Elegir esta oferta?', 'Choose this offer?')),
        content: Text(app.tr(
          'Se registra el acuerdo con $who: ${auction.sacks} sacos a ${fmtUSD(bid.priceLb, lang)}/lb. La subasta se cierra y avisamos a todos.',
          'An agreement with $who is recorded: ${auction.sacks} bags at ${fmtUSD(bid.priceLb, lang)}/lb. The auction closes and everyone is notified.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('Confirmar', 'Confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final agreementId = await ctrl.award(bid.id);
      app.showToast(app.tr('¡Acuerdo registrado!', 'Agreement recorded!'), '🤝');
      app.touch();
      if (context.mounted) await context.go('/orders/$agreementId');
    } catch (e) {
      app.showError(e);
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final app = context.session;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(app.tr('¿Cancelar la subasta?', 'Cancel the auction?')),
        content: Text(app.tr('Se cierra sin ganador y avisamos a quienes ofertaron.', 'It closes without a winner and bidders are notified.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('Volver', 'Back'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('Cancelar subasta', 'Cancel auction'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ctrl.cancel();
      app.touch();
    } catch (e) {
      app.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final a = auction;
    final lot = a.lot;
    final isOwner = app.user?.id == a.farmerId;
    final proc = lot == null ? null : processes[lot.process];

    Widget bidTile(Bid b, int rank) {
      final won = b.status == 'won' || b.id == a.winningBidId;
      final name = b.bidder?.display ?? '${app.tr('Comprador', 'Buyer')} ${b.alias}';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CardBox(
          padding: const EdgeInsets.all(12),
          color: won ? p.accentSoft : (b.mine ? p.warmSoft : null),
          child: Row(children: [
            SizedBox(width: 28, child: Text('$rank', style: p.display(size: 18, color: rank == 1 ? p.warm : p.ink2))),
            if (b.bidder != null) ...[Avatar(src: b.bidder!.photo, name: b.bidder!.name, size: 36), const SizedBox(width: 10)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b.mine ? '${app.tr('Tú', 'You')} · ' : ''}$name', style: p.text(weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [if (b.bidder != null && b.bidder!.country.isNotEmpty) b.bidder!.country, fmtAgo(b.at, lang)].join(' · '),
                  style: p.muted(size: 12),
                ),
                if (won) Text('🏆 ${app.tr('Ganadora', 'Winner')}', style: p.text(size: 12, weight: FontWeight.w800, color: p.accent)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtUSD(b.priceLb, lang), style: p.text(weight: FontWeight.w900, color: p.primary)),
              Text('/lb', style: p.muted(size: 11)),
            ]),
            if (isOwner && a.isOpen) ...[
              const SizedBox(width: 8),
              Btn(app.tr('Elegir', 'Choose'), small: true, onPressed: ctrl.busy ? null : () => _award(context, b)),
            ],
          ]),
        ),
      );
    }

    final statusText = switch (a.phase) {
      'live' => null,
      'ended' => isOwner
          ? app.tr('El tiempo terminó. Elige la oferta ganadora (tienes 7 días).', 'Time is up. Choose the winning offer (you have 7 days).')
          : app.tr('El tiempo terminó. El caficultor está eligiendo la oferta ganadora.', 'Time is up. The farmer is choosing the winning offer.'),
      'awarded' => app.tr('Subasta adjudicada: se registró el acuerdo.', 'Auction awarded: the agreement was recorded.'),
      'cancelled' => app.tr('El caficultor canceló esta subasta.', 'The farmer cancelled this auction.'),
      'expired' => app.tr('La subasta venció sin ganador.', 'The auction expired without a winner.'),
      _ => null,
    };

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Subasta', 'Auction'), subtitle: lot?.name),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ctrl.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (lot != null)
                    CardBox(
                      padding: const EdgeInsets.all(10),
                      onTap: () => context.go('/lot/${lot.id}'),
                      child: Row(children: [
                        NetImg(lot.photo, width: 70, height: 70, radius: BorderRadius.circular(p.radiusSm)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(lot.name, style: p.text(weight: FontWeight.w800)),
                            Text('${lot.variety} · ${proc?.of(lang) ?? lot.process} · ${fmtSca(lot.sca)} SCA', style: p.muted(size: 13)),
                            Text([lot.farm.name, lot.farm.region].where((s) => s.isNotEmpty).join(' · '), style: p.muted(size: 12)),
                          ]),
                        ),
                        Icon(Icons.chevron_right_rounded, color: p.ink2),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  CardBox(
                    color: a.isLive ? p.warmSoft : p.surface2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(auctionPhaseLabel(a.phase, lang).toUpperCase(), style: p.text(size: 12, weight: FontWeight.w900, color: a.isLive ? p.warm : p.ink2)),
                      const SizedBox(height: 4),
                      if (a.isLive) Countdown(endsAt: a.endsAt, prefix: app.tr('Cierra en', 'Closes in'), style: p.display(size: 26)),
                      if (!a.isLive) Text('${app.tr('Cerró el', 'Closed on')} ${fmtTime(a.endsAt, lang)}', style: p.text(weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _Stat(label: a.highest == null ? app.tr('Precio base', 'Base price') : app.tr('Oferta más alta', 'Highest offer'), value: '${fmtUSD(a.highest ?? a.basePriceLb, lang)}/lb')),
                        Expanded(child: _Stat(label: app.tr('Ofertas', 'Offers'), value: '${a.bids.length} · ${a.bidders} ${app.tr('compr.', 'buyers')}')),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _Stat(label: app.tr('Cantidad', 'Quantity'), value: '${a.sacks} × 70 kg')),
                        Expanded(child: _Stat(label: app.tr('Entrega', 'Delivery'), value: incoterms[a.incoterm]?.of(lang) ?? a.incoterm)),
                      ]),
                      if (!isOwner && a.myBest != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          a.leading
                              ? '★ ${app.tr('Vas ganando con', 'You are leading with')} ${fmtUSD(a.myBest!, lang)}/lb'
                              : '${app.tr('Te superaron. Tu mejor oferta', 'You were outbid. Your best offer')}: ${fmtUSD(a.myBest!, lang)}/lb',
                          style: p.text(weight: FontWeight.w800, color: a.leading ? p.accent : p.danger),
                        ),
                      ],
                    ]),
                  ),
                  if (statusText != null) ...[
                    const SizedBox(height: 10),
                    Text(statusText, style: p.text(weight: FontWeight.w700)),
                  ],
                  if (a.agreementId != null && (isOwner || a.bids.any((b) => b.mine && b.status == 'won'))) ...[
                    const SizedBox(height: 10),
                    Btn(app.tr('Ver el acuerdo', 'View agreement'), icon: Icons.handshake_outlined, kind: BtnKind.outline, block: true,
                        onPressed: () => context.go('/orders/${a.agreementId}')),
                  ],
                  SectionTitle(app.tr('Ofertas', 'Offers')),
                  if (a.bids.isEmpty)
                    Text(isOwner ? app.tr('Todavía no hay ofertas.', 'No offers yet.') : app.tr('Sé el primero en ofertar.', 'Be the first to bid.'), style: p.muted()),
                  for (var i = 0; i < a.bids.length; i++) bidTile(a.bids[i], i + 1),
                  if (!isOwner && a.bids.isNotEmpty)
                    FinePrint(app.tr('Por justicia, los demás compradores aparecen como "Comprador 1, 2…".', 'For fairness, other buyers are shown as "Buyer 1, 2…".')),
                ],
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: isOwner
          ? (a.isOpen
              ? ScreenFooter(children: [
                  Expanded(
                    child: Btn(app.tr('Cancelar subasta', 'Cancel auction'), icon: Icons.close_rounded, kind: BtnKind.ghost, block: true,
                        onPressed: ctrl.busy ? null : () => _cancel(context)),
                  ),
                ])
              : null)
          : (a.isLive && !app.isFarmer
              ? ScreenFooter(children: [
                  Expanded(
                    child: Btn(
                      a.leading ? app.tr('Subir mi oferta', 'Raise my offer') : '${app.tr('Ofertar desde', 'Bid from')} ${fmtUSD(a.minNext, lang)}',
                      icon: Icons.gavel_rounded,
                      large: true,
                      block: true,
                      onPressed: ctrl.busy ? null : () => _openBid(context),
                    ),
                  ),
                ])
              : null),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: p.muted(size: 11)),
      Text(value, style: p.text(weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}
