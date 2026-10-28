// Compradores que vieron un lote (solo lo ve el caficultor dueño del lote).
import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';

class InterestedBuyersScreen extends StatelessWidget {
  final int lotId;
  const InterestedBuyersScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;

    Future<void> write(InterestedBuyer b) async {
      final session = context.session;
      try {
        final c = await context.repo<ChatRepository>().start(b.user.id, lotId: lotId);
        if (context.mounted) await context.go('/chat/${c.id}');
      } catch (e) {
        session.showError(e);
      }
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Compradores interesados', 'Interested buyers')),
          Expanded(
            child: Loader<List<InterestedBuyer>>(
              load: () => context.repo<LotRepository>().interestedBuyers(lotId),
              builder: (context, list, reload) => RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      app.tr('Estos compradores abrieron tu lote. Escríbeles: el chat traduce solo.',
                          'These buyers opened your lot. Message them: the chat translates automatically.'),
                      style: p.muted(),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      EmptyState(icon: '👀', title: app.tr('Todavía nadie lo ha visto', 'No views yet'), text: app.tr('Te avisaremos cuando alguien lo abra.', 'We will notify you when someone opens it.')),
                    for (final b in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CardBox(
                          onTap: () => context.go('/user/${b.user.id}'),
                          child: Row(children: [
                            Avatar(src: b.user.photo, name: b.user.name, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(b.display, style: p.text(weight: FontWeight.w800)),
                                Text([b.user.name, b.city, b.country].where((s) => s.isNotEmpty).toSet().join(' · '), style: p.muted(size: 12)),
                                Text(
                                  '${b.views} ${b.views == 1 ? app.tr('vista', 'view') : app.tr('vistas', 'views')} · ${fmtAgo(b.lastAt, lang)}',
                                  style: p.text(size: 12, weight: FontWeight.w700, color: p.warm),
                                ),
                              ]),
                            ),
                            Btn(app.tr('Escribir', 'Message'), small: true, icon: Icons.chat_bubble_outline_rounded, onPressed: () => write(b)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
