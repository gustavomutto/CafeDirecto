// Tarjeta "Acuerdo registrado": visible para ambas partes en el chat y en Acuerdos.
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import 'common.dart';
import 'status_timeline.dart';

class AgreementCard extends StatelessWidget {
  final Agreement agreement;
  final bool inChat;
  const AgreementCard({super.key, required this.agreement, this.inChat = false});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final a = agreement;
    final lang = app.lang;
    final total = quoteTotal(a.priceLb, a.sacks);

    Widget term(String k, String v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(k, style: p.muted(size: p.fs - 3))),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: strong ? p.display(size: 20, color: p.accent) : p.text(size: p.fs - 2, weight: FontWeight.w700)),
              ),
            ],
          ),
        );

    Widget party(String label, String name, String sub, bool right) => Expanded(
          child: Column(
            crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(label, style: p.muted(size: 11)),
              Text(name, textAlign: right ? TextAlign.right : TextAlign.left, style: p.text(size: p.fs - 2, weight: FontWeight.w800)),
              if (sub.isNotEmpty) Text(sub, textAlign: right ? TextAlign.right : TextAlign.left, style: p.muted(size: 12)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(p.radius),
        border: Border.all(color: p.accent, width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
              child: const Text('🤝', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.tr('Acuerdo registrado', 'Agreement registered'), style: p.text(weight: FontWeight.w800, color: p.accent)),
                Text('${a.code} · ${fmtDate(a.createdAt, lang)}', style: p.muted(size: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(p.radiusSm)),
            child: Row(children: [
              party(app.tr('Productor', 'Producer'), a.farmerName, [a.farmName, a.farmRegion].where((s) => s.isNotEmpty).join(' · '), false),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.handshake_outlined, size: 20, color: p.ink2)),
              party(app.tr('Comprador', 'Buyer'), a.buyerDisplay, [a.buyerCity, a.buyerCountry].where((s) => s.isNotEmpty).join(', '), true),
            ]),
          ),
          const SizedBox(height: 8),
          term(app.tr('Lote', 'Lot'), '${a.lotName} · ${a.variety} ${processes[a.process]?.of(lang) ?? ''}'),
          term(app.tr('Cantidad', 'Quantity'), '${a.sacks} ${app.tr('sacos', 'bags')} × $kgPerSack kg = ${fmtNum(a.sacks * kgPerSack, lang)} kg'),
          term(app.tr('Precio', 'Price'), '${fmtUSD(a.priceLb, lang)} / lb'),
          term(app.tr('Condición', 'Terms'), incoterms[a.incoterm]?.of(lang) ?? a.incoterm),
          Divider(color: p.line),
          term(app.tr('Valor total', 'Total value'), fmtUSD(total, lang, 0), strong: true),
          StatusTimeline(status: a.status, history: a.history),
          if (inChat) ...[
            const SizedBox(height: 6),
            Btn(app.tr('Ver acuerdo', 'View agreement'),
                trailing: Icons.chevron_right_rounded, kind: BtnKind.ghost, small: true, block: true, onPressed: () => context.go('/orders/${a.id}')),
          ],
        ],
      ),
    );
  }
}
