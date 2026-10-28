// Detalle del acuerdo: estado del pedido y calificaciones.
import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/agreement_repository.dart';
import '../../providers/app_context.dart';
import '../../widgets/agreement_card.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import '../../widgets/status_timeline.dart';

class OrderDetailScreen extends StatelessWidget {
  final int agreementId;
  const OrderDetailScreen({super.key, required this.agreementId});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Loader<Agreement>(
          reloadKey: app.dataVersion,
          load: () => context.repo<AgreementRepository>().get(agreementId),
          frame: (c) => Column(children: [const TopBar(), Expanded(child: c)]),
          builder: (context, a, reload) {
            final mine = a.ratingBy(app.role);
            final theirs = a.ratingBy(app.isFarmer ? 'buyer' : 'farmer');
            final otherName = app.isFarmer ? a.buyerName : a.farmerName;
            final next = a.status < 3 ? statusSteps[a.status + 1] : null;

            Widget ratingBlock(Rating r, String title) => Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(p.radiusSm)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: p.muted(size: 12, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Stars(value: r.stars.toDouble(), size: 18),
                    if (r.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [for (final t in r.tags) NoteChip(app.pick(ratingTags[t]))]),
                    ],
                    if (r.comment != null && !r.comment!.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text('“${app.pick(r.comment)}”', style: p.text(size: p.fs - 1, weight: FontWeight.w600)),
                    ],
                  ]),
                );

            Future<void> advance() async {
              try {
                await context.repo<AgreementRepository>().advance(a.id);
                app.touch();
              } catch (e) {
                app.showError(e);
              }
            }

            return Column(children: [
              TopBar(title: a.code, subtitle: app.tr('Detalle del acuerdo', 'Agreement detail')),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
                    AgreementCard(agreement: a),
                    SectionTitle(app.tr('Estado del pedido', 'Order status')),
                    CardBox(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        StatusTimeline(status: a.status, history: a.history, vertical: true),
                        if (next != null)
                          Btn('${app.tr('Marcar como', 'Mark as')} “${next.of(app.lang)}”',
                              icon: next.icon, kind: BtnKind.outline, block: true, onPressed: advance),
                        FinePrint(app.tr('Cualquiera de las dos partes puede actualizar el estado. La logística y el pago se gestionan fuera de CaféDirecto.',
                            'Either party can update the status. Logistics and payment are handled outside CaféDirecto.')),
                      ]),
                    ),
                    SectionTitle(app.tr('Calificaciones', 'Ratings')),
                    CardBox(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (a.status < 3)
                          Text(app.tr('Podrán calificarse cuando el café sea entregado.', 'You can rate each other once the coffee is delivered.'), style: p.muted()),
                        if (a.status == 3 && mine == null)
                          Btn(app.tr('Calificar a $otherName', 'Rate $otherName'),
                              icon: Icons.star_outline_rounded, large: true, block: true, onPressed: () => context.go('/rate/${a.id}')),
                        if (mine != null) ratingBlock(mine, app.tr('Tu calificación', 'Your rating')),
                        if (theirs != null)
                          ratingBlock(theirs, app.tr('$otherName te calificó', '$otherName rated you'))
                        else if (a.status == 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(app.tr('Esperando la calificación de $otherName.', "Waiting for $otherName's rating."), style: p.muted(size: 13)),
                          ),
                      ]),
                    ),
                    if (a.conversationId != null) ...[
                      const SizedBox(height: 16),
                      Btn(app.tr('Abrir conversación', 'Open conversation'),
                          icon: Icons.chat_bubble_outline_rounded, kind: BtnKind.outline, block: true, onPressed: () => context.go('/chat/${a.conversationId}')),
                    ],
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
