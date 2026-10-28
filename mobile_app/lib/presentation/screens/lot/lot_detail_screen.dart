// Detalle del lote con su finca y certificaciones (solo lectura) — RF-08, RF-23.
import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/auction_widgets.dart';
import '../../widgets/loader.dart';

class LotDetailScreen extends StatelessWidget {
  final int lotId;
  const LotDetailScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    return Loader<Lot>(
      reloadKey: app.dataVersion,
      load: () => context.repo<LotRepository>().get(lotId),
      frame: (c) => Scaffold(backgroundColor: p.bg, body: SafeArea(child: Column(children: [const TopBar(), Expanded(child: c)]))),
      builder: (context, lot, _) => _LotView(lot: lot),
    );
  }
}

class _LotView extends StatefulWidget {
  final Lot lot;
  const _LotView({required this.lot});

  @override
  State<_LotView> createState() => _LotViewState();
}

class _LotViewState extends State<_LotView> {
  bool _busy = false;

  Future<void> _contact({bool sample = false}) async {
    final app = context.session;
    setState(() => _busy = true);
    try {
      final chat = context.repo<ChatRepository>();
      final cid = (await chat.start(widget.lot.farmerId, lotId: widget.lot.id)).id;
      if (sample) {
        await chat.sendText(
          cid,
          app.tr('¿Podría enviar una muestra de 300 g del lote ${widget.lot.name}?', 'Could you send a 300 g sample of ${widget.lot.name}?'),
          lang: app.lang,
        );
      }
      if (mounted) context.go('/chat/$cid');
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final app = context.session;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(app.tr('¿Quitar este lote?', 'Remove this lot?')),
        content: Text(app.tr('Dejará de aparecer para los compradores.', 'Buyers will no longer see it.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('Quitar', 'Remove'))),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final lots = context.repo<LotRepository>();
    try {
      await lots.remove(widget.lot.id);
      app.touch();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      app.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lot = widget.lot;
    final lang = app.lang;
    final farm = lot.farm;
    final proc = processes[lot.process];
    final isOwn = app.user?.id == lot.farmerId;

    final specs = [
      Spec(Icons.grain_rounded, app.tr('Variedad', 'Variety'), lot.variety),
      Spec(Icons.eco_outlined, app.tr('Proceso', 'Process'), '${proc?.icon ?? ''} ${proc?.of(lang) ?? lot.process}'),
      if (farm.altitude > 0) Spec(Icons.terrain_rounded, app.tr('Altitud', 'Altitude'), '${fmtNum(farm.altitude, lang)} m'),
      Spec(Icons.inventory_2_outlined, app.tr('Disponible', 'Available'), '${lot.sacks} × 70 kg'),
      if (lot.harvest.isNotEmpty) Spec(Icons.schedule_rounded, app.tr('Cosecha', 'Harvest'), lot.harvest),
      if (farm.region.isNotEmpty) Spec(Icons.place_outlined, app.tr('Origen', 'Origin'), [farm.municipality, farm.region].where((s) => s.isNotEmpty).join(', ')),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: Stack(fit: StackFit.expand, children: [
              NetImg(lot.photo),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x00000000), Color(0xCC000000)],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
              const SafeArea(child: Align(alignment: Alignment.topLeft, child: TopBar(transparent: true))),
              Positioned(
                left: 18,
                right: 110,
                bottom: 18,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (farm.region.isNotEmpty)
                    Text('${farm.region.toUpperCase()} · COLOMBIA', style: p.text(size: 12, weight: FontWeight.w800, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(lot.name, style: p.display(size: 30, color: Colors.white)),
                  Text('${lot.variety} · ${proc?.of(lang) ?? lot.process}', style: p.text(color: Colors.white, weight: FontWeight.w600)),
                ]),
              ),
              Positioned(right: 18, bottom: 18, child: ScoreBadge(sca: lot.sca, large: true)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              CardBox(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.tr('Precio de referencia', 'Reference price'), style: p.muted(size: 12)),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: fmtUSD(lot.priceLb, lang), style: p.display(size: 26)),
                        TextSpan(text: ' / lb', style: p.muted()),
                      ])),
                      if (lot.priceCarga != null) Text('${fmtCOP(lot.priceCarga!)} / carga', style: p.muted(size: 12)),
                    ]),
                  ),
                  Text(app.tr('Negociable\nen el chat', 'Negotiable\nin chat'), textAlign: TextAlign.right, style: p.muted(size: 12)),
                ]),
              ),
              if (lot.auction != null) ...[
                const SizedBox(height: 12),
                LotAuctionBanner(auction: lot.auction!, own: isOwn),
              ],
              if (isOwn) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: CardBox(
                      onTap: () => context.go('/lot/${lot.id}/interest'),
                      child: Row(children: [
                        Icon(Icons.visibility_outlined, color: p.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${lot.interest ?? 0}', style: p.display(size: 22)),
                            Text(app.tr('compradores interesados', 'interested buyers'), style: p.muted(size: 12)),
                          ]),
                        ),
                        Icon(Icons.chevron_right_rounded, color: p.ink2),
                      ]),
                    ),
                  ),
                  if (lot.auction == null && lot.sacks > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: CardBox(
                        color: p.warmSoft,
                        onTap: () => context.go('/lot/${lot.id}/auction'),
                        child: Row(children: [
                          Icon(Icons.gavel_rounded, color: p.warm),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(app.tr('Abrir subasta', 'Start auction'), style: p.text(weight: FontWeight.w800, color: p.warm)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ],
              const SizedBox(height: 12),
              CardBox(
                onTap: () => context.go('/user/${lot.farmerId}'),
                child: Row(children: [
                  Avatar(src: farm.producerPhoto, name: farm.producer, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(farm.name.isNotEmpty ? farm.name : farm.producer, style: p.text(weight: FontWeight.w800)),
                      Text([farm.producer, if (farm.hectares > 0) '${fmtNum(farm.hectares, lang, farm.hectares % 1 == 0 ? 0 : 1)} ha'].join(' · '),
                          style: p.muted(size: 13)),
                      Stars(value: farm.rating.avg, size: 12, showValue: farm.rating.count > 0, count: farm.rating.count),
                    ]),
                  ),
                  Text(app.tr('Ver finca', 'Farm story'), style: p.text(size: 13, weight: FontWeight.w800, color: p.warm)),
                  Icon(Icons.chevron_right_rounded, size: 18, color: p.warm),
                ]),
              ),
              const SizedBox(height: 12),
              SpecGrid(specs),
              if (lot.notes.isNotEmpty) ...[
                SectionTitle(app.tr('Notas de catación', 'Cupping notes')),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final n in lot.notes) NoteChip(notesCatalog[n]?.of(lang) ?? n)]),
              ],
              if (lot.certifications.isNotEmpty) ...[
                SectionTitle(app.tr('Certificaciones de origen', 'Origin certifications')),
                for (final c in lot.certifications) CertRow(name: c),
                FinePrint(app.tr('Solo visualización. CaféDirecto no emite ni gestiona certificaciones.',
                    'View only. CaféDirecto does not issue or manage certifications.')),
              ],
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: isOwn
          ? ScreenFooter(children: [
              Btn(app.tr('Quitar', 'Remove'), icon: Icons.delete_outline_rounded, kind: BtnKind.ghost, onPressed: _delete),
              Expanded(
                child: Btn(app.tr('Editar lote', 'Edit lot'), icon: Icons.edit_outlined, block: true, onPressed: () async {
                  await Navigator.of(context).pushNamed('/publish/${lot.id}');
                }),
              ),
            ])
          : (!app.isFarmer
              ? ScreenFooter(children: [
                  if (lot.auction?.isLive ?? false) ...[
                    Btn(app.tr('Escribir', 'Message'), icon: Icons.chat_bubble_outline_rounded, kind: BtnKind.outline, onPressed: _busy ? null : () => _contact()),
                    Expanded(
                      child: Btn(app.tr('Pujar en la subasta', 'Bid in auction'),
                          icon: Icons.gavel_rounded, block: true, onPressed: () => context.go('/auction/${lot.auction!.id}')),
                    ),
                  ] else ...[
                    Btn(app.tr('Pedir muestra', 'Request sample'), icon: Icons.inventory_2_outlined, kind: BtnKind.outline, onPressed: _busy ? null : () => _contact(sample: true)),
                    Expanded(
                      child: Btn('${app.tr('Escribir a', 'Message')} ${firstName(farm.producer)}',
                          icon: Icons.chat_bubble_outline_rounded, block: true, onPressed: _busy ? null : () => _contact()),
                    ),
                  ],
                ])
              : null),
    );
  }
}

/// Fila de certificación (también se usa en el perfil de finca).
class CertRow extends StatelessWidget {
  final String name;
  final String? sub;
  const CertRow({super.key, required this.name, this.sub});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardBox(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(Icons.verified_user_outlined, size: 22, color: p.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: p.text(size: p.fs - 2, weight: FontWeight.w800)),
              if (sub != null) Text(sub!, style: p.muted(size: 12)),
            ]),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: p.ink2),
        ]),
      ),
    );
  }
}
