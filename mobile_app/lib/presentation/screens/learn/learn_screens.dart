// Sección Aprende — RF-25 a RF-27.
import 'package:flutter/material.dart';

import '../../../core/constants/learn.dart';
import '../../providers/app_context.dart';
import '../../widgets/common.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final sections = {
      'post': app.tr('Buenas prácticas de poscosecha', 'Post-harvest best practices'),
      'export': app.tr('Exportar y vender', 'Exporting & selling'),
    };

    Widget card(LearnItem l) => Material(
          color: l.color,
          borderRadius: BorderRadius.circular(p.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(p.radius),
            onTap: () => context.go('/learn/${l.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.icon, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 8),
                Text(app.pick(l.title), style: p.text(size: p.fs - 1, weight: FontWeight.w800, color: const Color(0xFF2B1D14))),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(app.pick(l.summary),
                      overflow: TextOverflow.fade, style: p.text(size: 13, color: const Color(0xFF5A4636))),
                ),
                Row(children: [
                  const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF5A4636)),
                  const SizedBox(width: 4),
                  Text('${l.minutes} min', style: p.text(size: 12, weight: FontWeight.w700, color: const Color(0xFF5A4636))),
                ]),
              ]),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Text(app.tr('Aprende', 'Learn'), style: p.display(size: 30)),
            Text(app.tr('Lecturas de 1 minuto', '1-minute reads'), style: p.muted(size: 14)),
            const SizedBox(height: 14),
            CardBox(
              color: p.accentSoft,
              onTap: () => context.go('/fees'),
              child: Row(children: [
                const Text('💰', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.tr('Comisiones y condiciones', 'Fees & terms'), style: p.text(weight: FontWeight.w800, color: p.accent)),
                    Text(app.tr('Claro y sin letra pequeña', 'Clear, no fine print'), style: p.text(size: 13)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: p.accent),
              ]),
            ),
            const SizedBox(height: 10),
            CardBox(
              color: p.warmSoft,
              onTap: () => context.go('/market'),
              child: Row(children: [
                Icon(Icons.trending_up_rounded, size: 30, color: p.warm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.tr('Precio del café y del dólar', 'Coffee & dollar prices'),
                        style: p.text(weight: FontWeight.w800, color: p.warm)),
                    Text(app.tr('Precio interno FNC, bolsa de Nueva York y TRM', 'FNC internal price, New York exchange and TRM'),
                        style: p.text(size: 13)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: p.warm),
              ]),
            ),
            for (final s in sections.entries) ...[
              SectionTitle(s.value),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
                children: learnItems.where((l) => l.section == s.key).map(card).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LearnDetailScreen extends StatelessWidget {
  final String itemId;
  const LearnDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final item = learnById(itemId);
    if (item == null) {
      return Scaffold(backgroundColor: p.bg, body: SafeArea(child: Column(children: const [TopBar(), EmptyState(title: '—')])));
    }
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Aprende', 'Learn')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(p.radius)),
                  child: Text(item.icon, style: const TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 16),
                Text(app.pick(item.title), style: p.display(size: 28)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 13, color: p.ink2),
                  const SizedBox(width: 4),
                  Expanded(child: Text('${item.minutes} min · ${app.pick(item.summary)}', style: p.muted(size: 14))),
                ]),
                const SizedBox(height: 16),
                for (var i = 0; i < item.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: p.text(size: 15, weight: FontWeight.w900, color: p.primaryInk)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(app.pick(item.steps[i]), style: p.text(height: 1.4)),
                        ),
                      ),
                    ]),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: p.warmSoft, borderRadius: BorderRadius.circular(p.radiusSm)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.auto_awesome, size: 20, color: p.warm),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${app.tr('Clave', 'Key point')}  ', style: const TextStyle(fontWeight: FontWeight.w900)),
                        TextSpan(text: app.pick(item.tip)),
                      ]), style: p.text(size: p.fs - 1)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
