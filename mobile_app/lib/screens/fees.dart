// Comisiones y condiciones claras — RF-27.
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_scope.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  double sacks = 20;
  double price = 5.6;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final total = quoteTotal(price, sacks.round());
    final farmerFee = total * feeFarmer;
    final buyerFee = total * feeBuyer;
    final free = app.tr('Gratis', 'Free');

    final rows = [
      [app.tr('Crear cuenta y perfil', 'Account & profile'), free, free],
      [app.tr('Publicar lotes', 'Publish lots'), free, '—'],
      [app.tr('Mensajes y traducción', 'Messages & translation'), free, free],
      [app.tr('Verificación de comprador', 'Buyer verification'), '—', free],
      [app.tr('Acuerdo cerrado', 'Closed agreement'), '${(feeFarmer * 100).round()} %', '${(feeBuyer * 100).round()} %'],
    ];

    TableRow row(List<String> cells, {bool head = false, bool strong = false}) => TableRow(
          decoration: BoxDecoration(
            color: strong ? p.warmSoft : (head ? p.surface2 : p.surface),
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          children: [
            for (var i = 0; i < cells.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Text(
                  cells[i],
                  textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                  style: p.text(
                    size: p.fs - 3,
                    weight: (head || strong || i > 0) ? FontWeight.w800 : FontWeight.w600,
                    color: (i > 0 && cells[i] == free) ? p.accent : p.ink,
                  ),
                ),
              ),
          ],
        );

    Widget calc(String k, String v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(k, style: strong ? p.text(weight: FontWeight.w800) : p.muted())),
            Text(v, style: strong ? p.display(size: 20, color: p.accent) : p.text(weight: FontWeight.w700)),
          ]),
        );

    final terms = [
      app.tr('El precio lo acuerdan productor y comprador. CaféDirecto no lo fija.', 'Price is agreed between farmer and buyer. CaféDirecto does not set it.'),
      app.tr('El pago y el envío se hacen fuera de la app, con su exportador aliado.', 'Payment and shipping happen outside the app, via the partner exporter.'),
      app.tr('Cada acuerdo queda registrado y visible para ambas partes.', 'Every agreement is recorded and visible to both parties.'),
      app.tr('Solo se califica después de la entrega.', 'Ratings are only possible after delivery.'),
      app.tr('Sus datos y su historia son suyos. Puede borrarlos cuando quiera.', 'Your data and story are yours. Delete them any time.'),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Comisiones y condiciones', 'Fees & terms')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(p.radius)),
                  child: Column(children: [
                    const Text('🤝', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(app.tr('Solo cobramos cuando usted vende', 'We only charge when a deal closes'),
                        textAlign: TextAlign.center, style: p.display(size: 22, color: p.primaryInk)),
                    const SizedBox(height: 4),
                    Text(app.tr('Sin mensualidades. Sin costos ocultos.', 'No subscriptions. No hidden costs.'),
                        textAlign: TextAlign.center, style: p.text(color: p.primaryInk.withValues(alpha: 0.8))),
                  ]),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(p.radiusSm),
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                    children: [
                      row(['', app.tr('Caficultor', 'Farmer'), app.tr('Comprador', 'Buyer')], head: true),
                      for (var i = 0; i < rows.length; i++) row(rows[i], strong: i == rows.length - 1),
                    ],
                  ),
                ),
                SectionTitle(app.tr('Calcule un ejemplo', 'Try an example')),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(app.tr('Sacos de 70 kg', '70 kg bags'), style: p.muted(size: 13)),
                    const SizedBox(height: 6),
                    QtyStepper(value: sacks, min: 1, max: 100, onChanged: (v) => setState(() => sacks = v), label: app.tr('sacos', 'bags')),
                    const SizedBox(height: 12),
                    Text(app.tr('Precio por libra', 'Price per pound'), style: p.muted(size: 13)),
                    const SizedBox(height: 6),
                    QtyStepper(
                      value: price,
                      min: 2,
                      max: 20,
                      step: 0.1,
                      onChanged: (v) => setState(() => price = v),
                      format: (v) => fmtUSD(v, lang),
                      label: 'USD / lb',
                    ),
                    const SizedBox(height: 10),
                    calc(app.tr('Valor del negocio', 'Deal value'), fmtUSD(total, lang, 0)),
                    calc(app.tr('Comisión caficultor (2 %)', 'Farmer fee (2%)'), '− ${fmtUSD(farmerFee, lang, 0)}'),
                    calc(app.tr('El caficultor recibe', 'Farmer receives'), fmtUSD(total - farmerFee, lang, 0), strong: true),
                    calc(app.tr('Comisión comprador (4 %)', 'Buyer fee (4%)'), '+ ${fmtUSD(buyerFee, lang, 0)}'),
                  ]),
                ),
                SectionTitle(app.tr('Condiciones principales', 'Key terms')),
                for (final t in terms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.check_circle_outline_rounded, size: 20, color: p.accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: p.text(size: p.fs - 1))),
                    ]),
                  ),
                FinePrint(app.tr('Ejemplo ilustrativo. Te avisaremos antes de cualquier cambio en las comisiones.', 'Illustrative example. We will notify you before any change to the fees.')),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
