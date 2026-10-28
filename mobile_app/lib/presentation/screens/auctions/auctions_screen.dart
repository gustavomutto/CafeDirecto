// Subastas: las activas (para pujar) y las mías (las que abrí o en las que pujé).
import 'package:flutter/material.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auction_repository.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../widgets/auction_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  String _tab = 'live';
  int _reload = 0;

  /// El caficultor elige cuál de sus lotes subastar.
  Future<void> _pickLot() async {
    final app = context.session;
    final lots = context.repo<LotRepository>();
    List<Lot> mine;
    try {
      mine = (await lots.byFarmer(app.user!.id)).where((l) => l.sacks > 0 && l.auction == null).toList();
    } catch (e) {
      app.showError(e);
      return;
    }
    if (!mounted) return;
    if (mine.isEmpty) {
      app.showToast(app.tr('Publica un lote con sacos disponibles (y sin subasta abierta)', 'Publish a lot with bags available (and no open auction)'), '📦');
      return;
    }
    final chosen = await showAppSheet<int>(
      context,
      title: app.tr('¿Qué lote quieres subastar?', 'Which lot do you want to auction?'),
      body: (ctx, _) {
        final p = ctx.pal;
        return Column(children: [
          for (final l in mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardBox(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(ctx).pop(l.id),
                child: Row(children: [
                  NetImg(l.photo, width: 52, height: 52, radius: BorderRadius.circular(10)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.name, style: p.text(weight: FontWeight.w800)),
                      Text('${l.variety} · ${l.sacks} ${app.tr('sacos', 'bags')}', style: p.muted(size: 13)),
                    ]),
                  ),
                  Icon(Icons.gavel_rounded, color: p.warm),
                ]),
              ),
            ),
        ]);
      },
    );
    if (chosen != null && mounted) {
      await context.go('/lot/$chosen/auction');
      setState(() => _reload++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final repo = context.repo<AuctionRepository>();

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Subastas', 'Auctions'), subtitle: app.tr('Puja de precios con fecha de cierre', 'Price bidding with a closing date')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Segmented(
              options: {
                'live': app.tr('Activas', 'Live'),
                'mine': app.isFarmer ? app.tr('Mis subastas', 'My auctions') : app.tr('Mis pujas', 'My bids'),
              },
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
          ),
          Expanded(
            child: Loader<List<Auction>>(
              reloadKey: '$_tab-$_reload-${app.dataVersion}',
              load: () => _tab == 'live' ? repo.live() : repo.mine(),
              builder: (context, list, reload) => RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (app.isFarmer) ...[
                      CardBox(
                        color: p.warmSoft,
                        onTap: _pickLot,
                        child: Row(children: [
                          Icon(Icons.add_circle_outline_rounded, color: p.warm, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(app.tr('Subastar un lote', 'Auction a lot'), style: p.text(weight: FontWeight.w800, color: p.warm)),
                              Text(app.tr('Varios compradores ofertan y tú eliges la mejor oferta.', 'Several buyers bid and you choose the best offer.'), style: p.text(size: 13)),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (list.isEmpty)
                      EmptyState(
                        icon: '🔨',
                        title: _tab == 'live' ? app.tr('No hay subastas activas', 'No live auctions') : app.tr('Aún no tienes subastas', 'No auctions yet'),
                        text: _tab == 'live'
                            ? app.tr('Cuando un caficultor abra una subasta aparecerá aquí.', 'When a farmer opens an auction it will show up here.')
                            : (app.isFarmer
                                ? app.tr('Abre una subasta desde uno de tus lotes.', 'Open an auction from one of your lots.')
                                : app.tr('Puja en una subasta activa para verla aquí.', 'Bid on a live auction to see it here.')),
                      ),
                    for (final a in list) AuctionCard(auction: a),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
