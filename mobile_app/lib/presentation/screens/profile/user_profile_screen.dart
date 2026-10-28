// Perfil público de finca (RF-02, RF-04) o de comprador (RF-03, RF-05), con versión ES/EN.
import 'package:flutter/material.dart';

import '../../../core/constants/catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../providers/app_context.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import '../../widgets/lot_card.dart';
import '../lot/lot_detail_screen.dart';

typedef _ProfileData = PublicProfile;

class UserProfileScreen extends StatelessWidget {
  final int userId;
  final bool own;
  final Widget? extra;
  const UserProfileScreen({super.key, required this.userId, this.own = false, this.extra});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    return Loader<_ProfileData>(
      reloadKey: app.dataVersion,
      load: () => context.repo<AuthRepository>().publicProfile(userId),
      frame: (c) => Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(child: Column(children: [if (!own) const TopBar(), Expanded(child: c)])),
      ),
      builder: (context, d, reload) => d.farm != null
          ? _FarmView(data: d, own: own, extra: extra, reload: reload)
          : _BuyerView(data: d, own: own, extra: extra, reload: reload),
    );
  }
}

Future<void> _openChat(BuildContext context, int otherUserId, {int? lotId}) async {
  final app = context.session;
  try {
    final c = await context.repo<ChatRepository>().start(otherUserId, lotId: lotId);
    if (context.mounted) context.go('/chat/${c.id}');
  } catch (e) {
    app.showError(e);
  }
}

class _FarmView extends StatefulWidget {
  final _ProfileData data;
  final bool own;
  final Widget? extra;
  final Future<void> Function() reload;
  const _FarmView({required this.data, required this.own, this.extra, required this.reload});

  @override
  State<_FarmView> createState() => _FarmViewState();
}

class _FarmViewState extends State<_FarmView> {
  String? cLang;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final farm = widget.data.farm!;
    final lots = widget.data.lots;
    final l = cLang ?? app.lang;
    String t(String es, String en) => l == 'es' ? es : en;
    final rating = farm.rating;

    return Scaffold(
      backgroundColor: p.bg,
      body: RefreshIndicator(
        onRefresh: widget.reload,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverToBoxAdapter(
            child: ProfileCover(
              cover: farm.cover,
              showBack: !widget.own,
              avatar: Avatar(src: farm.producerPhoto, name: farm.producer, size: 88, ring: true),
              badge: farm.sca > 0 ? ScoreBadge(sca: farm.sca) : null,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(farm.displayName, style: p.display(size: 28)),
                const SizedBox(height: 2),
                Text([farm.producer, [farm.municipality, farm.region].where((s) => s.isNotEmpty).join(', ')].where((s) => s.isNotEmpty).join(' · '),
                    style: p.muted()),
                const SizedBox(height: 6),
                Stars(value: rating.avg, size: 16, showValue: rating.count > 0, count: rating.count),
                LangToggle(label: t('Ver perfil en', 'View profile in'), value: l, onChanged: (v) => setState(() => cLang = v)),
                if (!farm.quote.isEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: p.warm, width: 4))),
                    child: Text('“${farm.quote.of(l)}”', style: p.display(size: 20, weight: FontWeight.w500, color: p.primary)),
                  ),
                ],
                if (!farm.story.isEmpty) ...[
                  SectionTitle(t('Nuestra historia', 'Our story')),
                  Text(farm.story.of(l), style: p.text(height: 1.5)),
                ],
                if (farm.gallery.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: farm.gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => NetImg(farm.gallery[i], width: 150, height: 110, radius: BorderRadius.circular(p.radiusSm)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SpecGrid([
                  if (farm.altitude > 0) Spec(Icons.terrain_rounded, t('Altitud', 'Altitude'), '${fmtNum(farm.altitude, l)} m'),
                  if (farm.hectares > 0) Spec(Icons.eco_outlined, t('Tamaño', 'Size'), '${fmtNum(farm.hectares, l, farm.hectares % 1 == 0 ? 0 : 1)} ha'),
                  if (farm.since != null) Spec(Icons.schedule_rounded, t('Cultivando desde', 'Growing since'), '${farm.since}'),
                  if (farm.sca > 0) Spec(Icons.star_outline_rounded, t('Puntaje SCA', 'SCA score'), fmtSca(farm.sca)),
                  if (farm.varieties.isNotEmpty) Spec(Icons.grain_rounded, t('Variedades', 'Varieties'), farm.varieties.join(', '), wide: true),
                  if (farm.processes.isNotEmpty)
                    Spec(Icons.sync_rounded, t('Proceso poscosecha', 'Post-harvest process'),
                        farm.processes.map((x) => '${processes[x]?.icon ?? ''} ${processes[x]?.of(l) ?? x}').join(' · '),
                        wide: true),
                ]),
                if (farm.notes.isNotEmpty) ...[
                  SectionTitle(t('Notas de catación', 'Cupping notes')),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final n in farm.notes) NoteChip(notesCatalog[n]?.of(l) ?? n)]),
                ],
                if (farm.certifications.isNotEmpty) ...[
                  SectionTitle(t('Certificaciones (solo lectura)', 'Certifications (view only)')),
                  for (final c in farm.certifications) CertRow(name: c),
                ],
                SectionTitle(t('Lotes disponibles', 'Available lots')),
                if (lots.isEmpty) Text(t('Sin lotes publicados por ahora.', 'No lots published yet.'), style: p.muted()),
                for (final lot in lots) LotCard(lot: lot, compact: true),
                SectionTitle('${t('Reputación', 'Reputation')} · ${rating.count > 0 ? '${rating.avg.toStringAsFixed(1)} ★' : t('sin calificaciones', 'no ratings yet')}'),
                for (final r in farm.reviews) ReviewTile(review: r, lang: l),
                if (widget.extra != null) widget.extra!,
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: (!app.isFarmer && !widget.own)
          ? ScreenFooter(children: [
              Expanded(
                child: Btn('${app.tr('Escribir a', 'Message')} ${firstName(farm.producer)}',
                    icon: Icons.chat_bubble_outline_rounded, large: true, block: true,
                    onPressed: () => _openChat(context, farm.userId, lotId: lots.isNotEmpty ? lots.first.id : null)),
              ),
            ])
          : null,
    );
  }
}

class _BuyerView extends StatefulWidget {
  final _ProfileData data;
  final bool own;
  final Widget? extra;
  final Future<void> Function() reload;
  const _BuyerView({required this.data, required this.own, this.extra, required this.reload});

  @override
  State<_BuyerView> createState() => _BuyerViewState();
}

class _BuyerViewState extends State<_BuyerView> {
  String? cLang;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final b = widget.data.buyer!;
    final l = cLang ?? app.lang;
    String t(String es, String en) => l == 'es' ? es : en;
    final rating = b.rating;

    return Scaffold(
      backgroundColor: p.bg,
      body: RefreshIndicator(
        onRefresh: widget.reload,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverToBoxAdapter(
            child: ProfileCover(
              cover: b.cover,
              showBack: !widget.own,
              avatar: Avatar(src: b.contactPhoto, name: b.contact, size: 88, ring: true),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(b.displayName, style: p.display(size: 28)),
                const SizedBox(height: 2),
                Text([b.contact, b.type].where((s) => s.isNotEmpty).join(' · '), style: p.muted()),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  VerifiedBadge(label: t('Cuenta verificada por correo', 'Email-verified account')),
                  Stars(value: rating.avg, size: 15, showValue: rating.count > 0, count: rating.count),
                ]),
                LangToggle(label: t('Ver perfil en', 'View profile in'), value: l, onChanged: (v) => setState(() => cLang = v)),
                const SizedBox(height: 10),
                SpecGrid([
                  if (b.city.isNotEmpty || b.country.isNotEmpty)
                    Spec(Icons.place_outlined, t('Ciudad', 'City'), [b.city, b.country].where((s) => s.isNotEmpty).join(', ')),
                  if (b.type.isNotEmpty) Spec(Icons.person_outline_rounded, t('Tipo de comprador', 'Buyer type'), b.type),
                  if (b.volume.isNotEmpty) Spec(Icons.inventory_2_outlined, t('Volumen de compra', 'Purchase volume'), b.volume),
                  if (b.since != null) Spec(Icons.schedule_rounded, t('Comprando desde', 'Buying since'), '${b.since}'),
                ]),
                if (!b.about.isEmpty) ...[
                  SectionTitle(t('Sobre nosotros', 'About us')),
                  Text(b.about.of(l), style: p.text(height: 1.5)),
                ],
                if (!b.looking.isEmpty) ...[
                  SectionTitle(t('Qué buscamos', 'What we look for')),
                  Text(b.looking.of(l), style: p.text(height: 1.5)),
                ],
                SectionTitle('${t('Reputación', 'Reputation')} · ${rating.count > 0 ? '${rating.avg.toStringAsFixed(1)} ★' : t('sin calificaciones', 'no ratings yet')}'),
                for (final r in b.reviews) ReviewTile(review: r, lang: l),
                if (widget.extra != null) widget.extra!,
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: (app.isFarmer && !widget.own)
          ? ScreenFooter(children: [
              Expanded(
                child: Btn('${app.tr('Escribir a', 'Message')} ${firstName(b.contact)}',
                    icon: Icons.chat_bubble_outline_rounded, large: true, block: true, onPressed: () => _openChat(context, b.userId)),
              ),
            ])
          : null,
    );
  }
}

/// Portada con avatar superpuesto.
class ProfileCover extends StatelessWidget {
  final String? cover;
  final bool showBack;
  final Widget avatar;
  final Widget? badge;
  const ProfileCover({super.key, required this.cover, required this.showBack, required this.avatar, this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: 0, height: 200, child: NetImg(cover, fallback: '🌄')),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000), Color(0x55000000)],
              ),
            ),
          ),
        ),
        if (showBack) const SafeArea(child: TopBar(transparent: true)),
        Positioned(left: 18, bottom: 0, child: avatar),
        if (badge != null) Positioned(right: 18, bottom: 10, child: badge!),
      ]),
    );
  }
}

class LangToggle extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const LangToggle({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(children: [
        Icon(Icons.public_rounded, size: 18, color: p.ink2),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: p.muted(size: 14, weight: FontWeight.w700))),
        Segmented(small: true, value: value, onChanged: onChanged, options: const {'es': 'ES', 'en': 'EN'}),
      ]),
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;
  final String lang;
  const ReviewTile({super.key, required this.review, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardBox(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(review.by, style: p.text(size: p.fs - 2, weight: FontWeight.w800))),
            Stars(value: review.stars.toDouble(), size: 12),
          ]),
          if (review.text != null && !review.text!.isEmpty) ...[const SizedBox(height: 6), Text(review.text!.of(lang), style: p.text(size: p.fs - 2))],
          if (review.verified) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_rounded, size: 13, color: p.accent),
              const SizedBox(width: 4),
              Text(lang == 'es' ? 'Acuerdo verificado en CaféDirecto' : 'Verified CaféDirecto deal',
                  style: p.text(size: 12, weight: FontWeight.w700, color: p.accent)),
            ]),
          ],
        ]),
      ),
    );
  }
}
