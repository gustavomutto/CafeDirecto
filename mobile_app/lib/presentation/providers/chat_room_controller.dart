// Estado de una conversación abierta: carga mensajes y acuerdos, consulta los nuevos cada 3 s,
// envía texto y fotos (mostrando el mensaje al instante mientras llega la confirmación)
// y responde cotizaciones. La pantalla solo dibuja y maneja el teclado y el micrófono.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/utils/format.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/lot_repository.dart';

class ChatRoomController extends ChangeNotifier {
  ChatRoomController({
    required ChatRepository chat,
    required AgreementRepository agreements,
    required LotRepository lots,
    required this.convId,
    required this.myUserId,
    required this.myRole,
    required this.lang,
    bool Function()? isForeground,
    void Function()? onRead,
    this.pollEvery = const Duration(seconds: 3),
  })  : _chat = chat,
        _agreementsRepo = agreements,
        _lots = lots,
        _isForeground = isForeground ?? (() => true),
        _onRead = onRead;

  final ChatRepository _chat;
  final AgreementRepository _agreementsRepo;
  final LotRepository _lots;
  final int convId;
  final int myUserId;
  final String myRole;
  final String lang;
  final Duration pollEvery;
  final bool Function() _isForeground;
  final void Function()? _onRead;

  Conversation? conversation;
  List<ChatMessage> messages = const [];
  final Map<int, Agreement> agreements = {};
  Object? error;
  bool sendingPhoto = false;

  Timer? _timer;
  bool _polling = false;
  bool _disposed = false;
  int _tempId = -1;

  /// Id del último mensaje confirmado por el servidor (los pendientes tienen id negativo).
  int get lastId => messages.where((m) => m.id > 0).fold(0, (a, m) => m.id > a ? m.id : a);

  Future<void> start() async {
    error = null;
    _notify();
    try {
      conversation = await _chat.conversation(convId);
      _notify();
      await reloadAll();
      _timer?.cancel();
      _timer = Timer.periodic(pollEvery, (_) => poll());
    } catch (e) {
      error = e;
      _notify();
    }
  }

  /// Vuelve a traer todos los mensajes (cuando cambian cotizaciones o estados).
  Future<void> reloadAll() async {
    final list = await _chat.messages(convId);
    messages = [...list, ...messages.where((m) => m.pending)];
    _notify();
    await _loadAgreements(refresh: true);
    await _markRead();
  }

  /// Trae solo lo nuevo. Con la app en segundo plano no consulta.
  Future<void> poll() async {
    if (_polling || _disposed || !_isForeground()) return;
    _polling = true;
    try {
      final list = await _chat.messages(convId, after: lastId);
      if (list.isEmpty || _disposed) return;
      // Si llegó algo que cambia cotizaciones o acuerdos, se recarga todo para ver los estados nuevos.
      if (list.any((m) => m.type != 'text' && m.type != 'photo')) {
        await reloadAll();
      } else {
        final known = {for (final m in messages) m.id};
        messages = [...messages.where((m) => !m.pending), ...list.where((m) => !known.contains(m.id)), ...messages.where((m) => m.pending)];
        _notify();
        await _markRead();
      }
    } catch (e) {
      AppLogger.d('Sin conexión al consultar mensajes: $e', tag: 'Chat');
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadAgreements({bool refresh = false}) async {
    final ids = messages.where((m) => m.type == 'agreement' && m.agreementId != null).map((m) => m.agreementId!).toSet();
    for (final id in ids) {
      if (!refresh && agreements.containsKey(id)) continue;
      try {
        agreements[id] = await _agreementsRepo.get(id);
        _notify();
      } catch (_) {}
    }
  }

  Future<void> _markRead() async {
    try {
      await _chat.markRead(convId, lastId);
      _onRead?.call();
    } catch (_) {}
  }

  static int _order(ChatMessage a, ChatMessage b) {
    if (a.pending != b.pending) return a.pending ? 1 : -1;
    return a.id.compareTo(b.id);
  }

  /// Envía un texto. Se ve al instante como "pendiente"; si falla, se quita y se relanza el error
  /// para que la pantalla devuelva el texto a la caja.
  Future<void> sendText(String text, {bool viaVoice = false}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final temp = ChatMessage(
      id: _tempId--,
      conversationId: convId,
      senderId: myUserId,
      from: myRole,
      type: 'text',
      text: t,
      lang: lang,
      viaVoice: viaVoice,
      createdAt: nowMs(),
      pending: true,
    );
    messages = [...messages, temp];
    _notify();
    try {
      final m = await _chat.sendText(convId, t, lang: lang, viaVoice: viaVoice);
      messages = [...messages.where((x) => x.id != temp.id && x.id != m.id), m]..sort(_order);
      _notify();
    } catch (e) {
      messages = messages.where((x) => x.id != temp.id).toList();
      _notify();
      rethrow;
    }
  }

  Future<void> sendPhoto(int photoId, {String text = ''}) async {
    sendingPhoto = true;
    _notify();
    try {
      await _chat.sendPhoto(convId, photoId, text: text, lang: lang);
      await poll();
    } finally {
      sendingPhoto = false;
      _notify();
    }
  }

  /// action: 'accept' | 'confirm' | 'counter'. Siempre recarga para ver el estado real.
  Future<void> quoteAction(ChatMessage m, String action, {double? priceLb, int? sacks}) async {
    try {
      await _chat.quoteAction(m.id, action, priceLb: priceLb, sacks: sacks);
    } finally {
      await reloadAll();
    }
  }

  /// Lotes del caficultor de esta conversación que todavía tienen sacos (para cotizar).
  Future<List<Lot>> lotsWithStock() async {
    final c = conversation;
    if (c == null) return const [];
    return (await _lots.byFarmer(c.farmerId)).where((l) => l.sacks > 0).toList();
  }

  Future<void> sendQuote({required int lotId, required double priceLb, required int sacks, required String incoterm}) async {
    await _chat.sendQuote(convId, lotId: lotId, priceLb: priceLb, sacks: sacks, incoterm: incoterm);
    await reloadAll();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
