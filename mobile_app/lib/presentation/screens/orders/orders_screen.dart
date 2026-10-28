// Mis acuerdos — RF-18.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/agreement_repository.dart';
import '../../../domain/repositories/auction_repository.dart';
import '../../providers/app_context.dart';
import '../../providers/notifications_provider.dart';
import '../../../core/utils/format.dart';
import '../../widgets/auction_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import '../../widgets/status_timeline.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Loader<({List<Agreement> agreements, List<Auction> auctions})>(
          reloadKey: '${app.dataVersion}-${context.watch<NotificationsProvider>().unreadNotifications}',
          load: () async {
            final agreements = context.repo<AgreementRepository>().list();
            final auctions = context.repo<AuctionRepository>().mine();
            return (agreements: await agreements, auctions: await auctions);
          },
          builder: (context, data, reload) {
            final mine = data.agreements;
            final openAuctions = data.auctions.where((a) => a.isOpen).toList();
            final active = mine.where((a) => a.status < 3).toList();
            final done = mine.where((a) => a.status >= 3).toList();
            final totalValue = mine.fold<double>(0, (s, a) => s + quoteTotal(a.priceLb, a.sacks));

            Widget card(Agreement a) {
              final name = app.isFarmer ? a.buyerDisplay : a.farmDisplay;
              final photo = app.isFarmer ? a.buyerPhoto : a.farmerPhoto;
              final needsRating = a.status == 3 && a.ratingBy(app.role) == null;
              final pillColors = [p.warm, p.primary2, const Color(0xFF2F6B9A), p.accent];
              final st = a.status.clamp(0, 3).toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CardBox(
                  onTap: () async {
                    await context.go('/orders/${a.id}');
                    reload();
                  },
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Avatar(src: photo, name: name, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(weight: FontWeight.w800)),
                          Text('${a.code} · ${fmtDate(a.createdAt, lang)}', style: p.muted(size: 12)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: pillColors[st].withValues(alpha: 0.13), borderRadius: BorderRadius.circular(99)),
                        child: Text(statusSteps[st].of(lang), style: p.text(size: 12, weight: FontWeight.w800, color: pillColors[st])),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text('${a.lotName} · ${a.sacks} × 70 kg', style: p.text(size: p.fs - 2))),
                      Text(fmtUSD(quoteTotal(a.priceLb, a.sacks), lang, 0), style: p.text(weight: FontWeight.w900)),
                    ]),
                    StatusTimeline(status: st),
                    if (needsRating)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: p.warmSoft, borderRadius: BorderRadius.circular(p.radiusSm)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.star_rounded, size: 17, color: Color(0xFFE0A030)),
                          const SizedBox(width: 6),
                          Text(app.tr('Califica este negocio', 'Rate this deal'), style: p.text(size: 14, weight: FontWeight.w800, color: p.warm)),
                        ]),
                      ),
                  ]),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Text(app.tr('Mis acuerdos', 'Orders & agreements'), style: p.display(size: 30)),
                  const SizedBox(height: 4),
                  Text('${mine.length} ${app.tr('acuerdos', 'agreements')} · ${fmtUSD(totalValue, lang, 0)} ${app.tr('en total', 'total')}', style: p.muted(size: 14)),
                  const SizedBox(height: 14),
                  // Dos formas de cerrar un negocio: negociar 1 a 1 en el chat o abrir una puja con varios compradores.
                  CardBox(
                    color: p.warmSoft,
                    onTap: () async {
                      await context.go('/auctions');
                      reload();
                    },
                    child: Row(children: [
                      Icon(Icons.gavel_rounded, size: 30, color: p.warm),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.isFarmer ? app.tr('Subasta tu café', 'Auction your coffee') : app.tr('Subastas activas', 'Live auctions'),
                              style: p.text(weight: FontWeight.w800, color: p.warm)),
                          Text(
                            app.isFarmer
                                ? app.tr('Pon precio base y fecha de cierre; los compradores pujan y tú eliges.',
                                    'Set a base price and closing date; buyers bid and you choose.')
                                : app.tr('Puja por lotes de origen; el caficultor elige la mejor oferta.',
                                    'Bid on origin lots; the farmer picks the best offer.'),
                            style: p.text(size: 13),
                          ),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.warm),
                    ]),
                  ),
                  if (openAuctions.isNotEmpty) ...[
                    SectionTitle(app.isFarmer ? app.tr('Mis subastas abiertas', 'My open auctions') : app.tr('Subastas en las que participo', 'Auctions I joined')),
                    for (final a in openAuctions) AuctionCard(auction: a),
                  ],
                  if (mine.isEmpty)
                    EmptyState(
                      icon: '🤝',
                      title: app.tr('Todavía no tienes acuerdos', 'No agreements yet'),
                      text: app.tr('Cuando ambas partes confirmen un precio en el chat o se adjudique una subasta, aparecerá aquí.',
                          'When both parties confirm a quote in chat or an auction is awarded, it will appear here.'),
                    ),
                  if (active.isNotEmpty) SectionTitle(app.tr('En curso', 'In progress')),
                  ...active.map(card),
                  if (done.isNotEmpty) SectionTitle(app.tr('Entregados', 'Delivered')),
                  ...done.map(card),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
