// Tarjeta de lote: versión grande (catálogo del comprador) y compacta (listas).
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import 'common.dart';

class LotCard extends StatelessWidget {
  final Lot lot;
  final bool compact;
  final VoidCallback? onTap;
  const LotCard({super.key, required this.lot, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final proc = processes[lot.process];
    final procLabel = proc?.of(lang) ?? lot.process;
    final farm = lot.farm;
    final open = onTap ?? () => context.go('/lot/${lot.id}');

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CardBox(
          padding: const EdgeInsets.all(10),
          onTap: open,
          child: Row(
            children: [
              NetImg(lot.photo, width: 64, height: 64, radius: BorderRadius.circular(p.radiusSm)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lot.name, style: p.text(weight: FontWeight.w800)),
                    Text('${lot.variety} · $procLabel', style: p.text(size: p.fs - 3)),
                    Text('${lot.sacks} ${app.tr('sacos', 'bags')} · ${fmtUSD(lot.priceLb, lang)}/lb', style: p.muted(size: p.fs - 3)),
                  ],
                ),
              ),
              ScoreBadge(sca: lot.sca),
            ],
          ),
        ),
      );
    }

    Widget metaChip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(8)),
          child: DefaultTextStyle(style: p.text(size: 12, weight: FontWeight.w600), child: child),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CardBox(
        padding: EdgeInsets.zero,
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImg(lot.photo),
                  Positioned(top: 12, right: 12, child: ScoreBadge(sca: lot.sca)),
                  if (lot.isNew)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: p.warm, borderRadius: BorderRadius.circular(99)),
                        child: Text(app.tr('NUEVO', 'NEW'), style: p.text(size: 11, weight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  if (farm.region.isNotEmpty)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.place_outlined, size: 13, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(farm.region, style: p.text(size: 12, weight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farm.name.isNotEmpty ? farm.name : lot.name, style: p.display(size: 19)),
                            const SizedBox(height: 2),
                            Text([farm.producer, farm.municipality].where((s) => s.isNotEmpty).join(' · '), style: p.muted(size: 13)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmtUSD(lot.priceLb, lang), style: p.text(size: 16, weight: FontWeight.w800)),
                          Text('/lb FOB', style: p.muted(size: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    metaChip(Text(lot.variety)),
                    metaChip(Text('${proc?.icon ?? ''} $procLabel')),
                    if (farm.altitude > 0)
                      metaChip(Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.terrain_rounded, size: 13, color: p.ink2),
                        const SizedBox(width: 3),
                        Text('${fmtNum(farm.altitude, lang)} m'),
                      ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Stars(value: farm.rating.avg, size: 13, showValue: farm.rating.count > 0, count: farm.rating.count),
                    const Spacer(),
                    Text('${lot.sacks} × 70 kg', style: p.muted(size: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
