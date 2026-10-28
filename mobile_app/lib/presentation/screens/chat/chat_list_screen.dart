// Lista de conversaciones con personas reales (se actualiza sola).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../providers/app_context.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/session_provider.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';

/// Texto corto del último mensaje, en el idioma de quien mira.
String messagePreview(SessionProvider app, ChatMessage? m) {
  if (m == null) return '';
  final lang = app.lang;
  switch (m.type) {
    case 'text':
      final t = (m.lang != lang && (m.translation ?? '').isNotEmpty) ? m.translation! : (m.text ?? '');
      return m.viaVoice ? '🎙️ $t' : t;
    case 'photo':
      return '📷 ${app.tr('Foto', 'Photo')}';
    case 'quote':
      return '💲 ${app.tr('Cotización', 'Quote')}: ${fmtUSD(m.quote?.priceLb ?? 0, lang)}/lb';
    case 'agreement':
      return '🤝 ${app.tr('Acuerdo registrado', 'Agreement registered')}';
    case 'system':
      return app.pick(m.sys);
    default:
      return '';
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation>? _convs;
  Object? _error;
  Timer? _timer;
  int _lastUnread = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Se refresca solo cuando esta pestaña está visible y la app está en pantalla.
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final visible = context.read<NotificationsProvider>().foreground;
      if (visible && context.session.tab == 1) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final app = context.session;
    if (!app.loggedIn) return;
    try {
      final list = await context.repo<ChatRepository>().conversations();
      if (mounted) {
        setState(() {
          _convs = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _convs == null) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    // si el contador global cambió (llegó un mensaje), recarga la lista
    final unread = context.watch<NotificationsProvider>().unreadMessages;
    if (_lastUnread != unread) {
      _lastUnread = unread;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    final convs = _convs;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Text(app.tr('Mensajes', 'Messages'), style: p.display(size: 30)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.translate_rounded, size: 15, color: p.ink2),
                const SizedBox(width: 6),
                Expanded(child: Text(app.tr('Todo se traduce automáticamente', 'Everything is translated automatically'), style: p.muted(size: 14))),
              ]),
              const SizedBox(height: 14),
              if (convs == null && _error == null) const LoadingView(),
              if (convs == null && _error != null) ErrorRetry(error: _error!, onRetry: _load),
              if (convs != null && convs.isEmpty)
                EmptyState(
                  icon: '💬',
                  title: app.tr('Aún no tienes mensajes', 'No conversations yet'),
                  text: app.isFarmer
                      ? app.tr('Cuando un comprador te escriba, aparecerá aquí.', 'When a buyer writes to you, it will show up here.')
                      : app.tr('Abre un lote en Explorar y escribe al caficultor.', 'Open a lot in Explore and message the farmer.'),
                ),
              if (convs != null) for (final c in convs) _row(context, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Conversation c) {
    final app = context.app;
    final p = context.pal;
    final unread = c.unread;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardBox(
        padding: const EdgeInsets.all(12),
        color: unread > 0 ? p.surface : p.bg,
        onTap: () async {
          final counters = context.read<NotificationsProvider>();
          await context.go('/chat/${c.id}');
          _load();
          counters.refresh();
        },
        child: Row(children: [
          Avatar(src: c.other.photo, name: c.other.name, size: app.isFarmer ? 56 : 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(c.other.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(weight: unread > 0 ? FontWeight.w900 : FontWeight.w700)),
                ),
                Text(fmtTime(c.updatedAt, app.lang), style: p.muted(size: 12)),
              ]),
              if (c.other.sub.isNotEmpty) Text(c.other.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.muted(size: 12)),
              const SizedBox(height: 2),
              Text(
                messagePreview(app, c.last),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: p.text(size: p.fs - 2, color: unread > 0 ? p.ink : p.ink2, weight: unread > 0 ? FontWeight.w700 : FontWeight.w500),
              ),
            ]),
          ),
          if (unread > 0) ...[const SizedBox(width: 6), CountBadge(unread, big: true)],
        ]),
      ),
    );
  }
}
