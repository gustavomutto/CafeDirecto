// Explorar y filtrar lotes publicados por caficultores reales (comprador) — RF-07.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../widgets/notification_bell.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import '../../widgets/lot_card.dart';
import '../market/market_widgets.dart';

class _Filters {
  Set<String> regions;
  Set<String> processes;
  Set<String> varieties;
  double minScore;
  double minAlt;
  _Filters({Set<String>? regions, Set<String>? processes, Set<String>? varieties, this.minScore = 80, this.minAlt = 0})
      : regions = regions ?? {},
        processes = processes ?? {},
        varieties = varieties ?? {};

  _Filters copy() => _Filters(regions: {...regions}, processes: {...processes}, varieties: {...varieties}, minScore: minScore, minAlt: minAlt);

  int get activeCount => processes.length + varieties.length + (minScore > 80 ? 1 : 0) + (minAlt > 0 ? 1 : 0);

  LotQuery query(String q, {bool onlyAuctions = false}) => LotQuery(
        regions: regions,
        processes: processes,
        varieties: varieties,
        minSca: minScore > 80 ? minScore : null,
        minAlt: minAlt > 0 ? minAlt : null,
        text: q,
        onlyAuctions: onlyAuctions,
      );

  String key(String q, bool onlyAuctions) =>
      '${regions.join(',')}|${processes.join(',')}|${varieties.join(',')}|$minScore|$minAlt|$q|$onlyAuctions';
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _q = '';
  Timer? _debounce;
  _Filters f = _Filters();
  bool _onlyAuctions = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 450), () {
        if (mounted && _search.text != _q) setState(() => _q = _search.text);
      });
      setState(() {}); // para el botón de borrar
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _toggle(Set<String> set, String v) => set.contains(v) ? set.remove(v) : set.add(v);

  void _openFilters() {
    final app = context.session;
    final draft = f.copy();
    showAppSheet(
      context,
      title: app.tr('Filtros', 'Filters'),
      body: (ctx, setSheet) {
        final p = ctx.pal;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SheetLabel(app.tr('Proceso', 'Process')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in processes.entries)
              ChipBtn('${e.value.icon} ${e.value.of(app.lang)}',
                  active: draft.processes.contains(e.key), onTap: () => setSheet(() => _toggle(draft.processes, e.key))),
          ]),
          SheetLabel(app.tr('Variedad', 'Variety')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final v in varieties) ChipBtn(v, active: draft.varieties.contains(v), onTap: () => setSheet(() => _toggle(draft.varieties, v))),
          ]),
          SheetLabel(app.tr('Puntaje SCA mínimo', 'Minimum SCA score'), trailing: '${draft.minScore.round()}+'),
          Slider(min: 80, max: 90, divisions: 10, value: draft.minScore, onChanged: (v) => setSheet(() => draft.minScore = v)),
          SheetLabel(app.tr('Altitud mínima', 'Minimum altitude'), trailing: draft.minAlt == 0 ? app.tr('Cualquiera', 'Any') : '${fmtNum(draft.minAlt, app.lang)} m'),
          Slider(min: 0, max: 2200, divisions: 22, value: draft.minAlt, onChanged: (v) => setSheet(() => draft.minAlt = v)),
          Row(children: [Text('0 m', style: p.muted(size: 12)), const Spacer(), Text('2.200 m', style: p.muted(size: 12))]),
        ]);
      },
      footer: (ctx, setSheet) => Row(children: [
        Btn(app.tr('Limpiar', 'Reset'),
            kind: BtnKind.ghost,
            onPressed: () => setSheet(() {
                  draft.processes.clear();
                  draft.varieties.clear();
                  draft.minScore = 80;
                  draft.minAlt = 0;
                })),
        const SizedBox(width: 10),
        Expanded(
          child: Btn(app.tr('Ver resultados', 'Show results'), block: true, onPressed: () {
            setState(() => f = draft);
            Navigator.of(ctx).pop();
          }),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final query = f.query(_q, onlyAuctions: _onlyAuctions);
    final active = f.activeCount;
    final key = '${app.dataVersion}|${f.key(_q, _onlyAuctions)}';
    final lots = context.repo<LotRepository>();

    Future<List<Lot>> load() => lots.search(query);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Loader<List<Lot>>(
          reloadKey: key,
          load: load,
          builder: (context, results, reload) => RefreshIndicator(
            onRefresh: reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${app.tr('Hola', 'Hello')}, ${firstName(app.user!.name)} ☀️', style: p.muted(size: 14, weight: FontWeight.w700))),
                        const NotificationBell(),
                      ]),
                      const SizedBox(height: 4),
                      Text(app.tr('Descubre orígenes\nde especialidad', 'Discover Colombian\nspecialty origins'), style: p.display(size: 30)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _search,
                        style: p.text(),
                        decoration: InputDecoration(
                          hintText: app.tr('Buscar finca, variedad, sabor…', 'Search farm, variety, flavor…'),
                          prefixIcon: Icon(Icons.search_rounded, color: p.ink2),
                          suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => _search.clear()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const MarketShortcut(),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      children: [
                        ChipBtn('🔨 ${app.tr('En subasta', 'Auctions')}', active: _onlyAuctions, onTap: () => setState(() => _onlyAuctions = !_onlyAuctions)),
                        const SizedBox(width: 8),
                        ChipBtn(app.tr('Todas', 'All regions'), active: f.regions.isEmpty, onTap: () => setState(() => f = f.copy()..regions.clear())),
                        for (final r in regions) ...[
                          const SizedBox(width: 8),
                          ChipBtn(r, active: f.regions.contains(r), onTap: () => setState(() => f = f.copy().._toggleRegion(r))),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: Row(children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${results.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            TextSpan(text: app.tr(' lotes · directo de la finca', ' lots · direct from farm')),
                          ]),
                          style: p.text(size: 14),
                        ),
                      ),
                      Btn(
                        active > 0 ? '${app.tr('Filtros', 'Filters')} · $active' : app.tr('Filtros', 'Filters'),
                        icon: Icons.tune_rounded,
                        small: true,
                        kind: active > 0 ? BtnKind.primary : BtnKind.outline,
                        onPressed: _openFilters,
                      ),
                    ]),
                  ),
                ),
                if (results.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: '🔎',
                      title: app.tr('No hay lotes con esos filtros', 'No lots match these filters'),
                      text: app.tr('Cuando los caficultores publiquen lotes, aparecerán aquí.', 'Lots published by farmers will show up here.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => LotCard(lot: results[i]), childCount: results.length)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on _Filters {
  void _toggleRegion(String r) => regions.contains(r) ? regions.remove(r) : regions.add(r);
}
