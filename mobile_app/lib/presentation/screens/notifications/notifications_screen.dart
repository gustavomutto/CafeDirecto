// Lista de notificaciones (campanita): interés en lotes, ofertas, subastas, cotizaciones y acuerdos.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/app_context.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsProvider>().loadList().catchError((Object e) {
          if (mounted) context.session.showError(e);
        }));
  }

  IconData _icon(String type) => switch (type) {
        'lot_interest' => Icons.visibility_rounded,
        'bid_new' => Icons.payments_outlined,
        'bid_outbid' => Icons.trending_up_rounded,
        'auction_opened' => Icons.gavel_rounded,
        'auction_won' => Icons.emoji_events_outlined,
        'auction_lost' || 'auction_cancelled' || 'auction_expired' => Icons.gavel_outlined,
        'auction_ended' => Icons.timer_outlined,
        'quote_new' || 'quote_counter' || 'quote_accepted' => Icons.request_quote_outlined,
        'agreement_new' || 'agreement_status' => Icons.handshake_outlined,
        'rating_new' => Icons.star_outline_rounded,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final lang = app.lang;
    final n = context.watch<NotificationsProvider>();
    final items = n.items;

    Future<void> open(AppNotification x) async {
      await n.markRead(x);
      final route = x.route;
      if (route != null && context.mounted) await context.go(route);
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(
            title: app.tr('Notificaciones', 'Notifications'),
            subtitle: n.unreadNotifications > 0 ? '${n.unreadNotifications} ${app.tr('sin leer', 'unread')}' : null,
            right: n.unreadNotifications > 0
                ? TextButton(onPressed: n.markAllRead, child: Text(app.tr('Leer todas', 'Mark all read')))
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: n.loadList,
              child: items.isEmpty
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                      if (n.loadingList)
                        const Padding(padding: EdgeInsets.all(40), child: LoadingView())
                      else
                        EmptyState(
                          icon: '🔔',
                          title: app.tr('Sin notificaciones', 'No notifications'),
                          text: app.isFarmer
                              ? app.tr('Te avisaremos cuando un comprador vea tu café, haga una oferta o te escriba.',
                                  'We will let you know when a buyer views your coffee, bids or messages you.')
                              : app.tr('Te avisaremos de subastas, ofertas superadas y acuerdos.', 'We will notify you about auctions, outbids and agreements.'),
                        ),
                    ])
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final x = items[i];
                        return Material(
                          color: x.read ? p.surface : p.warmSoft,
                          borderRadius: BorderRadius.circular(p.radiusSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(p.radiusSm),
                            onTap: () => open(x),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: x.read ? p.surface2 : p.surface, shape: BoxShape.circle),
                                  child: Icon(_icon(x.type), color: p.warm, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(x.title.of(lang), style: p.text(weight: x.read ? FontWeight.w600 : FontWeight.w800)),
                                    if (!x.body.isEmpty) Text(x.body.of(lang), style: p.text(size: 13)),
                                    const SizedBox(height: 2),
                                    Text(fmtAgo(x.createdAt, lang), style: p.muted(size: 11)),
                                  ]),
                                ),
                                if (!x.read) Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: p.warm, shape: BoxShape.circle)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
