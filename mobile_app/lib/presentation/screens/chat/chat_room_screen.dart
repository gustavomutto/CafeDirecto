// Chat directo entre caficultor y comprador reales, con traducción automática (servidor),
// dictado por voz, fotos, frases rápidas y cotizaciones — RF-09 a RF-17.
// Los mensajes nuevos se consultan cada 3 segundos.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/catalog.dart';
import '../../../core/constants/phrases.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/agreement_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/lot_repository.dart';
import '../../providers/app_context.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/session_provider.dart';
import '../../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/quote_card.dart';

class ChatRoomScreen extends StatefulWidget {
  final int convId;
  const ChatRoomScreen({super.key, required this.convId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _text = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _viaVoice = false;

  Conversation? _conv;
  List<ChatMessage> _messages = [];
  final Map<int, Agreement> _agreements = {};
  Object? _error;
  Timer? _timer;
  bool _sending = false;
  bool _polling = false;
  int _tempId = -1;

  late SessionProvider app;
  late ChatRepository _chat;
  late AgreementRepository _agreementsRepo;
  late LotRepository _lots;
  late NotificationsProvider _counters;

  int get _lastId => _messages.where((m) => m.id > 0).fold(0, (a, m) => m.id > a ? m.id : a);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    app = context.session;
    _chat = context.repo<ChatRepository>();
    _agreementsRepo = context.repo<AgreementRepository>();
    _lots = context.repo<LotRepository>();
    _counters = context.read<NotificationsProvider>();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final c = await _chat.conversation(widget.convId);
      if (!mounted) return;
      setState(() => _conv = c);
      await _reloadAll();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Vuelve a traer todos los mensajes (cuando cambian cotizaciones o estados).
  Future<void> _reloadAll() async {
    final list = await _chat.messages(widget.convId);
    if (!mounted) return;
    setState(() => _messages = [...list, ..._messages.where((m) => m.pending)]);
    await _loadAgreements(refresh: true);
    _markRead();
  }

  Future<void> _poll() async {
    // Con la app en segundo plano no se consulta; al volver, el siguiente ciclo se pone al día.
    if (_polling || !mounted || !_counters.foreground) return;
    _polling = true;
    try {
      final list = await _chat.messages(widget.convId, after: _lastId);
      if (list.isEmpty || !mounted) return;
      // Si llegó algo que cambia cotizaciones o acuerdos, se recarga todo para ver los estados nuevos.
      if (list.any((m) => m.type != 'text' && m.type != 'photo')) {
        await _reloadAll();
      } else {
        setState(() => _messages = [..._messages.where((m) => !m.pending), ...list, ..._messages.where((m) => m.pending)]);
        _markRead();
      }
    } catch (_) {
      // sin conexión momentánea: se reintenta en el siguiente ciclo
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadAgreements({bool refresh = false}) async {
    final ids = _messages.where((m) => m.type == 'agreement' && m.agreementId != null).map((m) => m.agreementId!).toSet();
    for (final id in ids) {
      if (!refresh && _agreements.containsKey(id)) continue;
      try {
        final a = await _agreementsRepo.get(id);
        if (mounted) setState(() => _agreements[id] = a);
      } catch (_) {}
    }
  }

  Future<void> _markRead() async {
    try {
      await _chat.markRead(widget.convId, _lastId);
      _counters.refresh();
    } catch (_) {}
  }

  // ── Envíos ────────────────────────────────────────────────────
  Future<void> _sendText([String? override]) async {
    final t = (override ?? _text.text).trim();
    if (t.isEmpty || _sending) return;
    final voice = override == null && _viaVoice;
    if (_listening) await _speech.stop();
    final temp = ChatMessage(
      id: _tempId--,
      conversationId: widget.convId,
      senderId: app.user!.id,
      from: app.role,
      type: 'text',
      text: t,
      lang: app.lang,
      viaVoice: voice,
      createdAt: nowMs(),
      pending: true,
    );
    if (override == null) _text.clear();
    setState(() {
      _viaVoice = false;
      _messages = [..._messages, temp];
    });
    try {
      final m = await _chat.sendText(widget.convId, t, lang: app.lang, viaVoice: voice);
      if (!mounted) return;
      setState(() => _messages = [..._messages.where((x) => x.id != temp.id && x.id != m.id), m]..sort((a, b) => _order(a, b)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages = _messages.where((x) => x.id != temp.id).toList());
      if (override == null) _text.text = t;
      app.showError(e);
    }
  }

  int _order(ChatMessage a, ChatMessage b) {
    if (a.pending != b.pending) return a.pending ? 1 : -1;
    return a.id.compareTo(b.id);
  }

  Future<void> _sendPhoto() async {
    final file = await chooseImage(context);
    if (file == null) return;
    setState(() => _sending = true);
    try {
      if (!mounted) return;
      final id = await uploadImage(context, file);
      if (id == null) return;
      await _chat.sendPhoto(widget.convId, id, text: _text.text.trim(), lang: app.lang);
      _text.clear();
      await _poll();
    } catch (e) {
      app.showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Dictado por voz (reconocimiento de voz del teléfono) ──────
  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) setState(() => _listening = false);
      },
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok) {
      app.showToast(app.tr('El reconocimiento de voz no está disponible o no diste permiso al micrófono', 'Speech recognition unavailable or microphone permission denied'), '🎙️');
      return;
    }
    setState(() {
      _listening = true;
      _viaVoice = true;
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: app.lang == 'es' ? 'es_CO' : 'en_US',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (r) {
        _text.text = r.recognizedWords;
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
      },
    );
  }

  // ── Cotizaciones ──────────────────────────────────────────────
  Future<void> _quoteAction(ChatMessage m, String action, {double? priceLb, int? sacks}) async {
    try {
      await _chat.quoteAction(m.id, action, priceLb: priceLb, sacks: sacks);
      await _reloadAll();
      if (action == 'confirm') app.showToast(app.tr('¡Acuerdo registrado!', 'Agreement registered!'), '🤝');
      app.touch();
    } catch (e) {
      app.showError(e);
      _reloadAll();
    }
  }

  Future<void> _openQuote() async {
    final c = _conv!;
    List<Lot> lots;
    try {
      lots = (await _lots.byFarmer(c.farmerId)).where((l) => l.sacks > 0).toList();
    } catch (e) {
      app.showError(e);
      return;
    }
    if (!mounted) return;
    if (lots.isEmpty) {
      app.showToast(app.tr('Primero publica un lote con sacos disponibles', 'Publish a lot with available bags first'), '📦');
      return;
    }
    final start = lots.firstWhere((l) => l.id == c.lot?.id, orElse: () => lots.first);
    var lotId = start.id;
    var price = start.priceLb;
    var sacks = start.sacks < 20 ? start.sacks : 20;
    var incoterm = 'FOB Buenaventura';
    final lang = app.lang;

    await showAppSheet(
      context,
      title: app.tr('Enviar precio', 'Send price'),
      body: (ctx, setSheet) {
        final p = ctx.pal;
        final maxSacks = lots.firstWhere((l) => l.id == lotId).sacks;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetLabel(app.tr('1. ¿Qué lote?', '1. Which lot?')),
          for (final l in lots)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: lotId == l.id ? p.warmSoft : p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(p.radiusSm),
                  side: BorderSide(color: lotId == l.id ? p.warm : p.line, width: lotId == l.id ? 2 : 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(p.radiusSm),
                  onTap: () => setSheet(() {
                    lotId = l.id;
                    price = l.priceLb;
                    if (sacks > l.sacks) sacks = l.sacks;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      NetImg(l.photo, width: 48, height: 48, radius: BorderRadius.circular(10)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.name, style: p.text(weight: FontWeight.w800)),
                          Text('${l.variety} · ${processes[l.process]?.of(lang) ?? l.process} · ${l.sacks} ${app.tr('sacos', 'bags')}', style: p.muted(size: 13)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          SheetLabel(app.tr('2. Precio por libra (USD)', '2. Price per pound (USD)')),
          QtyStepper(value: price, step: 0.05, min: 1, max: 40, onChanged: (v) => setSheet(() => price = v), format: (v) => fmtUSD(v, lang), label: 'USD / lb'),
          SheetLabel(app.tr('3. ¿Cuántos sacos de 70 kg?', '3. How many 70 kg bags?')),
          QtyStepper(value: sacks.toDouble(), min: 1, max: maxSacks.toDouble(), onChanged: (v) => setSheet(() => sacks = v.round()), label: app.tr('sacos', 'bags')),
          SheetLabel(app.tr('4. ¿Dónde se entrega?', '4. Delivery terms')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in incoterms.keys) ChipBtn(incoterms[k]!.of(lang), active: incoterm == k, onTap: () => setSheet(() => incoterm = k)),
          ]),
          TotalBox(app.tr('Total del negocio', 'Deal total'), fmtUSD(quoteTotal(price, sacks), lang, 0)),
        ]);
      },
      footer: (ctx, _) => Btn(app.tr('Enviar cotización', 'Send quote'), icon: Icons.send_rounded, large: true, block: true, onPressed: () async {
        Navigator.of(ctx).pop();
        try {
          await _chat.sendQuote(widget.convId, lotId: lotId, priceLb: price, sacks: sacks, incoterm: incoterm);
          await _reloadAll();
        } catch (e) {
          app.showError(e);
        }
      }),
    );
  }

  void _openCounter(ChatMessage m) {
    final q = m.quote!;
    final lang = app.lang;
    final delta = app.isFarmer ? 0.2 : -0.25;
    var price = round2(q.priceLb + delta);
    var sacks = q.sacks;
    showAppSheet(
      context,
      title: app.tr('Contraoferta', 'Counter-offer'),
      body: (ctx, setSheet) {
        final p = ctx.pal;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${app.tr('Oferta actual', 'Current offer')}: '),
              TextSpan(text: '${fmtUSD(q.priceLb, lang)}/lb', style: const TextStyle(fontWeight: FontWeight.w900)),
              TextSpan(text: ' · ${q.sacks} ${app.tr('sacos', 'bags')}'),
            ]),
            style: p.muted(size: 14),
          ),
          SheetLabel(app.tr('Tu precio por libra', 'Your price per pound')),
          QtyStepper(value: price, step: 0.05, min: 1, max: 40, onChanged: (v) => setSheet(() => price = v), format: (v) => fmtUSD(v, lang), label: 'USD / lb'),
          SheetLabel(app.tr('Sacos de 70 kg', '70 kg bags')),
          QtyStepper(value: sacks.toDouble(), min: 1, max: 200, onChanged: (v) => setSheet(() => sacks = v.round()), label: app.tr('sacos', 'bags')),
          TotalBox(app.tr('Total', 'Total'), fmtUSD(quoteTotal(price, sacks), lang, 0)),
        ]);
      },
      footer: (ctx, _) => Btn(app.tr('Enviar contraoferta', 'Send counter-offer'), icon: Icons.send_rounded, large: true, block: true, onPressed: () {
        Navigator.of(ctx).pop();
        _quoteAction(m, 'counter', priceLb: price, sacks: sacks);
      }),
    );
  }

  void _openTemplates() {
    final lang = app.lang;
    showAppSheet(
      context,
      title: app.tr('Frases listas', 'Quick messages'),
      body: (ctx, _) {
        final p = ctx.pal;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final t in templates[app.role]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardBox(
                padding: const EdgeInsets.all(12),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _sendText(t.of(lang));
                },
                child: Row(children: [
                  Text(t.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.of(lang), style: p.text(weight: FontWeight.w800))),
                ]),
              ),
            ),
        ]);
      },
    );
  }

  void _openPhoto(String? url) {
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(child: InteractiveViewer(child: NetImg(url, fit: BoxFit.contain))),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final conv = _conv;

    if (conv == null) {
      return Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(children: [
            TopBar(title: app.tr('Chat', 'Chat')),
            Expanded(child: _error != null ? ErrorRetry(error: _error!, onRetry: () { setState(() => _error = null); _init(); }) : const LoadingView()),
          ]),
        ),
      );
    }

    final isFarmer = app.isFarmer;
    final other = conv.other;
    final lot = conv.lot;
    final otherPath = '/user/${other.id}';

    final handlers = QuoteHandlers(
      onAccept: (m) => _quoteAction(m, 'accept'),
      onConfirm: (m) => _quoteAction(m, 'confirm'),
      onCounter: _openCounter,
    );

    final items = [
      for (final m in _messages.reversed)
        MessageBubble(
          key: ValueKey(m.id),
          msg: m,
          handlers: handlers,
          agreement: m.agreementId == null ? null : _agreements[m.agreementId],
          onOpenPhoto: () => _openPhoto(m.photo),
        ),
    ];
    final quickTemplates = templates[app.role]!.take(4).toList();
    final empty = _text.text.trim().isEmpty;

    Widget quickBtn(IconData icon, String label, VoidCallback? onTap, {bool price = false}) => Expanded(
          child: Material(
            color: price ? p.accent : p.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.radiusSm), side: price ? BorderSide.none : BorderSide(color: p.line)),
            child: InkWell(
              borderRadius: BorderRadius.circular(p.radiusSm),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 20, color: price ? Colors.white : p.primary),
                  const SizedBox(width: 6),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: p.text(size: 15, weight: FontWeight.w800, color: price ? Colors.white : p.primary))),
                ]),
              ),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(
            right: IconButton(
              tooltip: app.tr('Ver perfil', 'View profile'),
              icon: Icon(Icons.info_outline_rounded, color: p.ink),
              onPressed: () => context.go(otherPath),
            ),
            child: InkWell(
              onTap: () => context.go(otherPath),
              child: Row(children: [
                Avatar(src: other.photo, name: other.name, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(other.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(weight: FontWeight.w800)),
                    if (other.sub.isNotEmpty) Text(other.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.muted(size: 12)),
                  ]),
                ),
              ]),
            ),
          ),
          Container(
            color: p.accentSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(children: [
              Icon(Icons.translate_rounded, size: 15, color: p.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(app.tr('Traducción automática ES ⇄ EN', 'Auto-translation EN ⇄ ES'),
                    style: p.text(size: 12, weight: FontWeight.w700, color: p.accent)),
              ),
              if (lot != null)
                GestureDetector(
                  onTap: () => context.go('/lot/${lot.id}'),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                    decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ClipOval(child: NetImg(lot.photo, width: 22, height: 22)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(lot.name, overflow: TextOverflow.ellipsis, style: p.text(size: 12, weight: FontWeight.w800)),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: ListView(reverse: true, padding: const EdgeInsets.all(12), children: items),
          ),
          Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: isFarmer
                ? Row(children: [
                    quickBtn(Icons.attach_money_rounded, app.tr('Enviar precio', 'Send price'), _openQuote, price: true),
                    const SizedBox(width: 8),
                    quickBtn(Icons.notes_rounded, app.tr('Frases', 'Phrases'), _openTemplates),
                    const SizedBox(width: 8),
                    quickBtn(Icons.photo_camera_outlined, app.tr('Foto', 'Photo'), _sending ? null : _sendPhoto),
                  ])
                : SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickTemplates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Center(
                        child: ChipBtn('${quickTemplates[i].icon} ${quickTemplates[i].of(app.lang)}', onTap: () => _sendText(quickTemplates[i].of(app.lang))),
                      ),
                    ),
                  ),
          ),
          if (_listening)
            Container(
              width: double.infinity,
              color: p.danger.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                Icon(Icons.mic_rounded, color: p.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(app.tr('Escuchando… habla con tranquilidad. Revisa el texto y toca enviar.', 'Listening… then check the text and tap send.'),
                      style: p.text(size: 13, weight: FontWeight.w700, color: p.danger)),
                ),
              ]),
            ),
          Container(
            decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
            padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
            child: Row(children: [
              if (!isFarmer) ...[
                IconButton(onPressed: _sending ? null : _sendPhoto, icon: Icon(Icons.image_outlined, color: p.ink2)),
                IconButton(onPressed: _openTemplates, icon: Icon(Icons.notes_rounded, color: p.ink2)),
              ] else
                const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _text,
                  style: p.text(),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                  onChanged: (_) {
                    if (!_listening) _viaVoice = false;
                  },
                  decoration: InputDecoration(
                    hintText: app.tr('Escribe un mensaje…', 'Write a message…'),
                    isDense: true,
                    fillColor: p.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: p.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: p.line)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: _listening ? p.danger : p.warm,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggleMic,
                  child: SizedBox(
                    width: isFarmer ? 52 : 44,
                    height: isFarmer ? 52 : 44,
                    child: Icon(_listening ? Icons.stop_rounded : Icons.mic_none_rounded, size: 26, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: empty ? p.surface2 : p.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: empty ? null : () => _sendText(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.send_rounded, size: 20, color: empty ? p.ink2 : p.primaryInk),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
