// Publicar lote (caficultor) — RF-06. Formulario de pasos grandes y numerados.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/catalog.dart';
import '../../providers/app_context.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/market_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_picker.dart';

const _noteOptions = ['panela', 'chocolate', 'caramelo', 'frutosrojos', 'citrico', 'floral', 'miel', 'mandarina'];

class PublishLotScreen extends StatefulWidget {
  /// Si se da, se edita ese lote; si no, se crea uno nuevo.
  final int? lotId;
  const PublishLotScreen({super.key, this.lotId});

  @override
  State<PublishLotScreen> createState() => _PublishLotScreenState();
}

class _PublishLotScreenState extends State<PublishLotScreen> {
  String variety = 'Pink Bourbon';
  String process = 'honey';
  double sacks = 10;
  double sca = 86;
  String unit = 'lb';
  double priceLb = 5.5;
  double priceCarga = 3200000;
  List<String> notes = ['panela', 'chocolate'];
  int? photoId;
  final _name = TextEditingController();
  final _harvest = TextEditingController();
  int? doneId;
  bool _busy = false;
  bool _loading = false;

  bool get editing => widget.lotId != null;

  @override
  void initState() {
    super.initState();
    _harvest.text = context.session.tr('Cosecha ${DateTime.now().year}', '${DateTime.now().year} harvest');
    // La TRM del día para convertir el precio por carga a dólares.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MarketProvider>().ensureLoaded());
    if (editing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLot());
    }
  }

  Future<void> _loadLot() async {
    final app = context.session;
    try {
      final l = await context.repo<LotRepository>().get(widget.lotId!);
      setState(() {
        _name.text = l.name;
        variety = l.variety;
        process = l.process;
        sacks = l.sacks.toDouble();
        sca = l.sca;
        priceLb = l.priceLb;
        if (l.priceCarga != null) {
          unit = 'carga';
          priceCarga = l.priceCarga!.toDouble();
        }
        notes = List<String>.from(l.notes);
        _harvest.text = l.harvest;
        photoId = l.photoId;
      });
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _harvest.dispose();
    super.dispose();
  }

  /// TRM del día (la entrega el servidor); si no se pudo consultar, una tasa de respaldo.
  double get _copPerUsd => context.read<MarketProvider>().copPerUsd ?? fallbackCopPerUsd;

  double get _effectivePriceLb => unit == 'lb' ? priceLb : round2(copCargaToUsdLb(priceCarga, _copPerUsd));

  Future<void> _publish() async {
    final app = context.session;
    if (photoId == null) {
      app.showToast(app.tr('Agrega una foto del lote', 'Add a photo of the lot'), '📷');
      return;
    }
    setState(() => _busy = true);
    final input = LotInput(
      name: _name.text.trim(),
      variety: variety,
      process: process,
      sacks: sacks.round(),
      sca: sca,
      priceLb: _effectivePriceLb,
      priceCarga: unit == 'carga' ? priceCarga.round() : null,
      notes: notes,
      harvest: _harvest.text.trim(),
      photoId: photoId,
    );
    final lots = context.repo<LotRepository>();
    try {
      final saved = editing ? await lots.update(widget.lotId!, input) : await lots.create(input);
      app.touch();
      if (!mounted) return;
      if (editing) {
        app.showToast(app.tr('Lote actualizado', 'Lot updated'));
        Navigator.of(context).pop();
      } else {
        setState(() => doneId = saved.id);
      }
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final lang = app.lang;
    String t(String es, String en) => app.tr(es, en);
    context.watch<MarketProvider>(); // redibuja cuando llega la TRM

    if (_loading) {
      return Scaffold(backgroundColor: p.bg, body: const SafeArea(child: Column(children: [TopBar(), Expanded(child: LoadingView())])));
    }

    if (doneId != null) {
      return Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 70, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text(t('¡Lote publicado!', 'Lot published!'), style: p.display(size: 30)),
              const SizedBox(height: 8),
              Text(t('Ya lo pueden ver los compradores registrados en CaféDirecto.', 'Buyers registered on CaféDirecto can see it now.'),
                  textAlign: TextAlign.center, style: p.muted(size: p.fs)),
              const SizedBox(height: 28),
              Btn(t('Ver mi lote', 'View my lot'), icon: Icons.visibility_outlined, large: true, block: true, onPressed: () => context.replace('/lot/$doneId')),
              const SizedBox(height: 10),
              Btn(t('Ir al inicio', 'Go home'), kind: BtnKind.ghost, large: true, block: true, onPressed: () => goHome()),
            ]),
          ),
        ),
      );
    }

    Widget stepTitle(String n, String text, {String? small}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
              child: Text(n, style: p.text(size: 16, weight: FontWeight.w900, color: p.primaryInk)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: text, style: p.text(size: p.fs + 1, weight: FontWeight.w800)),
                if (small != null) TextSpan(text: '  $small', style: p.muted(size: 13)),
              ])),
            ),
          ]),
        );

    Widget section(List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
        );

    final lb = _effectivePriceLb;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: editing ? t('Editar lote', 'Edit lot') : t('Publicar lote', 'Publish lot'), subtitle: t('5 pasos sencillos', '5 simple steps')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                section([
                  stepTitle('1', t('¿Qué variedad?', 'Which variety?')),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final v in varieties) ChipBtn(v, big: true, active: variety == v, onTap: () => setState(() => variety = v)),
                  ]),
                ]),
                section([
                  stepTitle('2', t('¿Qué proceso?', 'Which process?')),
                  Row(children: [
                    for (final e in processes.entries) ...[
                      if (e.key != processes.keys.first) const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: process == e.key ? p.primary : p.surface2,
                          borderRadius: BorderRadius.circular(p.radiusSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(p.radiusSm),
                            onTap: () => setState(() => process = e.key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Column(children: [
                                Text(e.value.icon, style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(e.value.of(lang),
                                    style: p.text(weight: FontWeight.w800, color: process == e.key ? p.primaryInk : p.ink)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ]),
                section([
                  stepTitle('3', t('¿Cuántos sacos de 70 kg?', 'How many 70 kg bags?')),
                  QtyStepper(
                    value: sacks,
                    min: 1,
                    max: 200,
                    onChanged: (v) => setState(() => sacks = v),
                    label: '${t('sacos', 'bags')} · ${fmtNum(sacks * 70, lang)} kg',
                  ),
                ]),
                section([
                  stepTitle('4', t('Puntaje SCA', 'SCA score')),
                  QtyStepper(value: sca, min: 78, max: 95, step: 0.5, onChanged: (v) => setState(() => sca = v), label: t('puntos', 'points')),
                  if (sca < 80)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: p.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(t('CaféDirecto recibe cafés de 80 puntos o más.', 'CaféDirecto accepts coffees of 80 points or more.'),
                              style: p.text(size: 14, weight: FontWeight.w700, color: p.danger)),
                        ),
                      ]),
                    ),
                ]),
                section([
                  stepTitle('5', t('Su precio', 'Your price')),
                  Segmented(
                    value: unit,
                    onChanged: (v) => setState(() => unit = v),
                    options: {'lb': t('Por libra (USD)', 'Per pound (USD)'), 'carga': t('Por carga (COP)', 'Per carga (COP)')},
                  ),
                  const SizedBox(height: 12),
                  if (unit == 'lb')
                    QtyStepper(
                      value: priceLb,
                      min: 1,
                      max: 40,
                      step: 0.1,
                      onChanged: (v) => setState(() => priceLb = v),
                      format: (v) => fmtUSD(v, lang),
                      label: t('por libra', 'per pound'),
                    )
                  else ...[
                    QtyStepper(
                      value: priceCarga,
                      min: 1000000,
                      max: 20000000,
                      step: 50000,
                      onChanged: (v) => setState(() => priceCarga = v),
                      format: fmtCOP,
                      label: t('por carga (125 kg pergamino)', 'per carga (125 kg parchment)'),
                    ),
                    const SizedBox(height: 8),
                    Text(t('≈ ${fmtUSD(lb, lang)} por libra de café verde', '≈ ${fmtUSD(lb, lang)} per pound of green coffee'), textAlign: TextAlign.center, style: p.muted(size: 14)),
                  ],
                  _RateHint(priceLb: lb),
                  TotalBox(t('Si vende todo el lote', 'If you sell the whole lot'), fmtUSD(quoteTotal(lb, sacks.round()), lang, 0)),
                ]),
                section([
                  stepTitle('+', t('Sabores en la taza', 'Cup flavors'), small: t('(opcional)', '(optional)')),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final n in _noteOptions)
                      ChipBtn(
                        notesCatalog[n]!.of(lang),
                        active: notes.contains(n),
                        onTap: () => setState(() {
                          if (notes.contains(n)) {
                            notes.remove(n);
                          } else {
                            notes = [...notes, n];
                            if (notes.length > 4) notes = notes.sublist(notes.length - 4);
                          }
                        }),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  stepTitle('+', t('Foto del lote', 'Lot photo')),
                  PhotoSlot(
                    url: photoId == null ? null : '/images/$photoId',
                    height: 190,
                    label: t('Toca para tomar o elegir una foto', 'Tap to take or choose a photo'),
                    preview: (u) => NetImg(u),
                    onTap: () async {
                      final id = await pickAndUpload(context);
                      if (id != null) setState(() => photoId = id);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(t('Cosecha', 'Harvest'), style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(controller: _harvest, style: p.text()),
                  const SizedBox(height: 18),
                  Text(t('Nombre del lote (opcional)', 'Lot name (optional)'), style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    style: p.text(),
                    decoration: InputDecoration(hintText: t('Lote $variety', '$variety lot')),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: ScreenFooter(children: [
        Expanded(child: Btn(_busy ? t('Guardando…', 'Saving…') : (editing ? t('Guardar cambios', 'Save changes') : t('Publicar lote', 'Publish lot')), icon: Icons.send_rounded, large: true, block: true, onPressed: (sca < 80 || _busy) ? null : _publish)),
      ]),
    );
  }
}

/// Referencia del mercado debajo del precio: TRM usada y comparación con el precio interno FNC.
class _RateHint extends StatelessWidget {
  final double priceLb;
  const _RateHint({required this.priceLb});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    String t(String es, String en) => app.tr(es, en);
    final m = context.watch<MarketProvider>();
    final rate = m.copPerUsd;
    final fnc = m.coffee?.internal?.copPerCarga;
    final mine = usdLbToCopCarga(priceLb, rate ?? fallbackCopPerUsd);
    final lines = <String>[
      rate == null
          ? t('Dólar de referencia: ${fmtCOP(fallbackCopPerUsd)} (no se pudo consultar la TRM de hoy)',
              'Reference dollar: ${fmtCOP(fallbackCopPerUsd)} (today\'s official rate could not be loaded)')
          : t('TRM de hoy: ${fmtCOP(rate)} por dólar', "Today's official rate (TRM): ${fmtCOP(rate)} per dollar"),
      t('Equivale a ${fmtCOP(mine)} por carga', 'Equals ${fmtCOP(mine)} per carga'),
      if (fnc != null)
        '${t('Precio interno FNC hoy: ${fmtCOP(fnc)} por carga', "Today's FNC internal price: ${fmtCOP(fnc)} per carga")}'
            ' (${mine >= fnc ? '+' : '−'}${fmtNum(((mine - fnc).abs() / fnc * 100), app.lang, 0)} %)',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(children: [for (final l in lines) Text(l, textAlign: TextAlign.center, style: p.muted(size: 13))]),
    );
  }
}
