// Cotización en el chat.
// - 'open': quien NO hizo la última oferta puede Aceptar o Contraofertar.
// - 'accepted': la otra parte debe Confirmar → se registra el acuerdo.
// - 'agreed': muestra que el acuerdo quedó registrado.
// - 'superseded': versión anterior, se muestra compacta.
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import 'common.dart';

class QuoteHandlers {
  final void Function(ChatMessage) onAccept;
  final void Function(ChatMessage) onCounter;
  final void Function(ChatMessage) onConfirm;
  const QuoteHandlers({required this.onAccept, required this.onCounter, required this.onConfirm});
}

class QuoteCard extends StatelessWidget {
  final ChatMessage msg;
  final QuoteHandlers handlers;
  const QuoteCard({super.key, required this.msg, required this.handlers});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final q = msg.quote!;
    final lang = app.lang;
    final role = app.role;
    final total = quoteTotal(q.priceLb, q.sacks);
    String who(String r) => r == 'farmer' ? app.tr('Caficultor', 'Farmer') : app.tr('Comprador', 'Buyer');
    final isCounter = q.history.length > 1;

    if (q.status == 'superseded') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(p.radiusSm),
          border: Border.all(color: p.line),
        ),
        child: Row(children: [
          Icon(Icons.sell_outlined, size: 16, color: p.ink2),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${isCounter ? app.tr('Contraoferta', 'Counter-offer') : app.tr('Cotización', 'Quote')}: '),
                TextSpan(
                  text: '${fmtUSD(q.priceLb, lang)}/lb · ${q.sacks} ${app.tr('sacos', 'bags')}',
                  style: const TextStyle(decoration: TextDecoration.lineThrough),
                ),
              ]),
              style: p.muted(size: 13),
            ),
          ),
          Text(app.tr('reemplazada', 'replaced'), style: p.muted(size: 11)),
        ]),
      );
    }

    final myTurn = q.status == 'open' && q.lastBy != role;
    final mustConfirm = q.status == 'accepted' && q.acceptedBy != role;

    final statusLabel = {
          'open': app.tr('Abierta', 'Open'),
          'accepted': app.tr('Aceptada', 'Accepted'),
          'agreed': app.tr('Cerrada', 'Closed'),
        }[q.status] ??
        '';
    final statusColor = q.status == 'open' ? p.warm : p.accent;

    Widget term(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 82, child: Text(k, style: p.muted(size: p.fs - 3))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: v)),
          ]),
        );
    TextStyle tv = p.text(size: p.fs - 2, weight: FontWeight.w700);

    Widget waitLine(String text) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Icon(Icons.schedule_rounded, size: 15, color: p.ink2),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: p.muted(size: 13))),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(p.radius),
        border: Border.all(color: q.status == 'open' ? p.warm : p.accent, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: p.warmSoft, shape: BoxShape.circle),
              child: Icon(Icons.sell_outlined, size: 18, color: p.warm),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isCounter ? app.tr('Contraoferta', 'Counter-offer') : app.tr('Cotización', 'Price quote'),
                    style: p.text(weight: FontWeight.w800)),
                Text('${app.tr('de', 'from')} ${who(q.lastBy)}', style: p.muted(size: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
              child: Text(statusLabel, style: p.text(size: 12, weight: FontWeight.w800, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtUSD(q.priceLb, lang), style: p.display(size: 30)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('/ lb', style: p.muted())),
          ]),
          const SizedBox(height: 6),
          term(app.tr('Lote', 'Lot'),
              Text('${q.lotName} · ${q.variety} ${processes[q.process]?.of(lang) ?? ''}',
                  textAlign: TextAlign.right, style: tv)),
          term(app.tr('Cantidad', 'Quantity'),
              Text('${q.sacks} × $kgPerSack kg (${fmtNum(q.sacks * kgPerSack, lang)} kg)', textAlign: TextAlign.right, style: tv)),
          term(app.tr('Condición', 'Terms'), Text(incoterms[q.incoterm]?.of(lang) ?? q.incoterm, textAlign: TextAlign.right, style: tv)),
          term(app.tr('Total', 'Total'), Text(fmtUSD(total, lang, 0), style: p.text(size: p.fs, weight: FontWeight.w900, color: p.accent))),
          if (q.history.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (var i = 0; i < q.history.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: i == q.history.length - 1 ? p.warmSoft : p.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${who(q.history[i].by)}: ${fmtUSD(q.history[i].priceLb, lang)}',
                      style: p.text(
                        size: 12,
                        weight: i == q.history.length - 1 ? FontWeight.w800 : FontWeight.w600,
                        color: i == q.history.length - 1 ? p.primary : p.ink2,
                      ),
                    ),
                  ),
              ]),
            ),
          if (myTurn)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Expanded(child: Btn(app.tr('Contraofertar', 'Counter'), kind: BtnKind.outline, onPressed: () => handlers.onCounter(msg))),
                const SizedBox(width: 8),
                Expanded(child: Btn(app.tr('Aceptar', 'Accept'), icon: Icons.check_rounded, onPressed: () => handlers.onAccept(msg))),
              ]),
            ),
          if (q.status == 'open' && !myTurn) waitLine(app.tr('Esperando respuesta…', 'Waiting for a reply…')),
          if (mustConfirm)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Btn(app.tr('Confirmar acuerdo', 'Confirm agreement'),
                  icon: Icons.handshake_outlined, block: true, onPressed: () => handlers.onConfirm(msg)),
            ),
          if (q.status == 'accepted' && !mustConfirm)
            waitLine(app.tr('Aceptaste · esperando confirmación de la otra parte', 'You accepted · waiting for the other party to confirm')),
          if (q.status == 'agreed')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Icon(Icons.done_all_rounded, size: 17, color: p.accent),
                const SizedBox(width: 6),
                Text(app.tr('Ambas partes confirmaron', 'Both parties confirmed'),
                    style: p.text(size: 13, weight: FontWeight.w800, color: p.accent)),
              ]),
            ),
        ],
      ),
    );
  }
}
