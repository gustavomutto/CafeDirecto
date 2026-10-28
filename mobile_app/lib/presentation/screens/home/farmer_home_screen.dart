// Inicio del caficultor: botones grandes y sus lotes publicados.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/learn.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import '../../widgets/lot_card.dart';
import '../market/market_widgets.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final me = app.user!;
    final farm = app.farm;
    final unread = context.watch<NotificationsProvider>().unreadMessages;
    final tip = learnItems[DateTime.now().day % learnItems.length];
    final incomplete = farm == null || farm.story.isEmpty || farm.altitude == 0 || farm.cover == null;

    Widget tile(IconData icon, String label, VoidCallback onTap, {bool primary = false, int badge = 0}) => Material(
          color: primary ? p.primary : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(p.radius),
            side: primary ? BorderSide.none : BorderSide(color: p.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(p.radius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(color: primary ? Colors.white.withValues(alpha: 0.15) : p.warmSoft, shape: BoxShape.circle),
                    child: Icon(icon, size: 34, color: primary ? p.primaryInk : p.primary),
                  ),
                  if (badge > 0) Positioned(right: -6, top: -4, child: CountBadge(badge, big: true)),
                ]),
                const SizedBox(height: 10),
                Text(label, textAlign: TextAlign.center, style: p.text(size: 17, weight: FontWeight.w800, color: primary ? p.primaryInk : p.ink)),
              ]),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final notifications = context.read<NotificationsProvider>();
            await app.refreshMe();
            app.touch();
            await notifications.refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              Row(children: [
                Avatar(src: me.photo, name: me.name, size: 58),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${app.tr('Hola', 'Hi')}, ${firstName(me.name)} 👋', style: p.display(size: 26)),
                    if (farm != null && farm.name.isNotEmpty) Text([farm.name, farm.region].where((s) => s.isNotEmpty).join(' · '), style: p.muted()),
                    if (farm != null) Stars(value: farm.rating.avg, size: 15, showValue: farm.rating.count > 0, count: farm.rating.count),
                  ]),
                ),
                const NotificationBell(),
              ]),
              const SizedBox(height: 14),
              const MarketShortcut(),
              if (incomplete) ...[
                const SizedBox(height: 14),
                CardBox(
                  color: p.warmSoft,
                  onTap: () => context.go('/edit-profile'),
                  child: Row(children: [
                    const Text('✍️', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(app.tr('Completa el perfil de tu finca', 'Complete your farm profile'), style: p.text(weight: FontWeight.w800)),
                        Text(app.tr('Historia, fotos, altitud y certificaciones', 'Story, photos, altitude and certifications'), style: p.muted()),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.ink),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  tile(Icons.add_rounded, app.tr('Publicar lote', 'Publish lot'), () => context.go('/publish'), primary: true),
                  tile(Icons.chat_bubble_outline_rounded, app.tr('Mensajes', 'Messages'), () => app.setTab(1), badge: unread),
                  tile(Icons.handshake_outlined, app.tr('Mis acuerdos', 'My deals'), () => app.setTab(2)),
                  tile(Icons.menu_book_outlined, app.tr('Aprende', 'Learn'), () => app.setTab(3)),
                ],
              ),
              if (unread > 0) ...[
                const SizedBox(height: 14),
                CardBox(
                  color: p.warmSoft,
                  onTap: () => app.setTab(1),
                  child: Row(children: [
                    const Text('💬', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(app.tr('Tienes $unread mensaje(s) nuevo(s)', 'You have $unread new message(s)'), style: p.text(weight: FontWeight.w800)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.ink),
                  ]),
                ),
              ],
              SectionTitle(app.tr('Mis lotes publicados', 'My published lots')),
              Loader<List<Lot>>(
                reloadKey: app.dataVersion,
                load: () => context.repo<LotRepository>().byFarmer(me.id),
                builder: (context, lots, _) => lots.isEmpty
                    ? EmptyState(
                        icon: '🌱',
                        title: app.tr('Aún no has publicado lotes', 'No lots yet'),
                        text: app.tr('Publica tu primer lote para que los compradores lo vean.', 'Publish your first lot so buyers can find it.'),
                      )
                    : Column(children: [for (final l in lots) LotCard(lot: l, compact: true)]),
              ),
              const SizedBox(height: 10),
              CardBox(
                color: tip.color,
                onTap: () => context.go('/learn/${tip.id}'),
                child: Row(children: [
                  Text(tip.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.tr('CONSEJO DEL DÍA', 'TIP OF THE DAY'), style: p.text(size: 11, weight: FontWeight.w900, color: const Color(0xFF5A4636))),
                      Text(app.pick(tip.title), style: p.text(weight: FontWeight.w800, color: const Color(0xFF2B1D14))),
                      Text(app.pick(tip.summary), style: p.text(size: p.fs - 2, color: const Color(0xFF2B1D14))),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
