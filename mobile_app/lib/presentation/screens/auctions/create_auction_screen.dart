// Abrir una subasta para un lote: precio base, incremento mínimo, sacos, duración y entrega.
import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auction_repository.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';

class CreateAuctionScreen extends StatelessWidget {
  final int lotId;
  const CreateAuctionScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Loader<Lot>(
      load: () => context.repo<LotRepository>().get(lotId),
      frame: (c) => Scaffold(backgroundColor: p.bg, body: SafeArea(child: Column(children: [const TopBar(), Expanded(child: c)]))),
      builder: (context, lot, _) => _AuctionForm(lot: lot),
    );
  }
}

class _AuctionForm extends StatefulWidget {
  final Lot lot;
  const _AuctionForm({required this.lot});

  @override
  State<_AuctionForm> createState() => _AuctionFormState();
}

class _AuctionFormState extends State<_AuctionForm> {
  late double base = widget.lot.priceLb;
  double increment = 0.05;
  late double sacks = widget.lot.sacks.toDouble();
  int hours = 48;
  String incoterm = incoterms.keys.first;
  bool _busy = false;

  static const _durations = [24, 48, 72, 168];
  static const _increments = [0.05, 0.10, 0.25];

  Future<void> _submit() async {
    final app = context.session;
    final repo = context.repo<AuctionRepository>();
    setState(() => _busy = true);
    try {
      final a = await repo.open(
        widget.lot.id,
        AuctionInput(basePriceLb: round2(base), minIncrementLb: increment, sacks: sacks.round(), durationHours: hours, incoterm: incoterm),
      );
      app.showToast(app.tr('¡Subasta abierta! Avisamos a los compradores interesados.', 'Auction open! Interested buyers were notified.'), '🔨');
      app.touch();
      if (mounted) await context.replace('/auction/${a.id}');
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final lot = widget.lot;
    String dur(int h) => h % 24 == 0 ? (h == 24 ? app.tr('1 día', '1 day') : '${h ~/ 24} ${app.tr('días', 'days')}') : '$h h';

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Abrir subasta', 'Start auction'), subtitle: lot.name),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                CardBox(
                  color: p.warmSoft,
                  child: Text(
                    app.tr(
                      'Los compradores verán tu lote con el precio base y pujarán por libra. Cada oferta debe superar a la anterior por el incremento mínimo. Tú eliges la oferta que prefieras (no tiene que ser la más alta) y se registra el acuerdo.',
                      'Buyers will see your lot with the base price and bid per pound. Each offer must beat the previous one by the minimum increment. You choose the offer you prefer (not necessarily the highest) and the agreement is recorded.',
                    ),
                    style: p.text(size: 14),
                  ),
                ),
                SheetLabel(app.tr('1. Precio base (US\$ por libra)', '1. Base price (US\$ per pound)')),
                QtyStepper(value: base, step: 0.05, min: 0.5, max: 40, onChanged: (v) => setState(() => base = round2(v)), format: (v) => fmtUSD(v, lang), label: 'US\$/lb'),
                SheetLabel(app.tr('2. Incremento mínimo entre ofertas', '2. Minimum increment between offers')),
                Wrap(spacing: 8, children: [
                  for (final i in _increments) ChipBtn('+${fmtUSD(i, lang)}', active: increment == i, onTap: () => setState(() => increment = i)),
                ]),
                SheetLabel(app.tr('3. Sacos de 70 kg en subasta', '3. 70 kg bags in the auction')),
                QtyStepper(value: sacks, min: 1, max: lot.sacks.toDouble(), onChanged: (v) => setState(() => sacks = v), label: app.tr('sacos', 'bags')),
                SheetLabel(app.tr('4. ¿Cuánto dura?', '4. How long?')),
                Wrap(spacing: 8, children: [
                  for (final h in _durations) ChipBtn(dur(h), active: hours == h, onTap: () => setState(() => hours = h)),
                ]),
                SheetLabel(app.tr('5. Entrega', '5. Delivery terms')),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in incoterms.keys) ChipBtn(incoterms[k]!.of(lang), active: incoterm == k, onTap: () => setState(() => incoterm = k)),
                ]),
                TotalBox(app.tr('Valor mínimo del lote', 'Minimum lot value'), fmtUSD(quoteTotal(base, sacks.round()), lang, 0)),
                FinePrint(app.tr(
                  'Si alguien oferta en los últimos 2 minutos, el cierre se alarga 2 minutos para que los demás puedan responder. Tienes 7 días después del cierre para elegir ganador.',
                  'If someone bids in the last 2 minutes, closing is extended by 2 minutes so others can respond. You have 7 days after closing to choose a winner.',
                )),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: ScreenFooter(children: [
        Expanded(
          child: Btn(app.tr('Abrir subasta', 'Start auction'), icon: Icons.gavel_rounded, large: true, block: true, onPressed: _busy ? null : _submit),
        ),
      ]),
    );
  }
}
