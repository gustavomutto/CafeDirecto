// Contadores (mensajes sin leer y avisos de la campanita) y avisos en el teléfono.
// Mientras la app está abierta consulta el servidor cada 10 s; en segundo plano, cada 30 s
// (solo para mostrar el aviso del teléfono). Cuando no hay sesión, no consulta nada.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../core/notifications/local_notifications.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._chat, this._repo, this._local) {
    _life = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  final ChatRepository _chat;
  final NotificationRepository _repo;
  final LocalNotifications _local;
  AppLifecycleListener? _life;

  int unreadMessages = 0;
  int unreadNotifications = 0;
  List<AppNotification> items = const [];
  bool loadingList = false;

  /// true mientras la app está en pantalla.
  bool foreground = true;

  /// Idioma para el texto de los avisos del teléfono.
  String lang = 'es';

  int? _userId;
  int _lastAlerted = 0;
  Timer? _timer;
  bool _busy = false;

  bool get active => _userId != null;

  /// Empieza a consultar para este usuario (se llama al entrar).
  Future<void> start(int userId, String lang) async {
    this.lang = lang;
    if (_userId == userId) return;
    _userId = userId;
    _lastAlerted = await _repo.lastAlertedId();
    if (_lastAlerted == 0) {
      // Primera vez en este teléfono: no se muestran como aviso las notificaciones viejas.
      try {
        final page = await _repo.latest(limit: 1);
        if (page.items.isNotEmpty) {
          _lastAlerted = page.items.first.id;
          await _repo.saveLastAlertedId(_lastAlerted);
        }
      } catch (_) {}
    }
    await _local.requestPermission();
    _schedule();
    await refresh();
  }

  /// Deja de consultar (se llama al cerrar sesión).
  void stop() {
    _userId = null;
    _timer?.cancel();
    unreadMessages = 0;
    unreadNotifications = 0;
    items = const [];
    _lastAlerted = 0;
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    if (!active) return;
    _timer = Timer.periodic(Duration(seconds: foreground ? 10 : 30), (_) => refresh());
  }

  void _onLifecycle(AppLifecycleState s) {
    final visible = s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
    if (visible == foreground) return;
    foreground = visible;
    _schedule();
    if (visible) refresh(); // al volver, se pone al día de inmediato
    notifyListeners();
  }

  /// Actualiza los contadores y muestra en el teléfono los avisos nuevos.
  Future<void> refresh() async {
    if (!active || _busy) return;
    _busy = true;
    try {
      final counts = await _chat.unread();
      final changed = counts.messages != unreadMessages || counts.notifications != unreadNotifications;
      unreadMessages = counts.messages;
      unreadNotifications = counts.notifications;
      final fresh = await _repo.newerThan(_lastAlerted);
      if (fresh.isNotEmpty) {
        for (final n in fresh) {
          await _local.show(id: n.id, title: n.title.of(lang), body: n.body.of(lang), route: n.route);
        }
        _lastAlerted = fresh.map((n) => n.id).reduce((a, b) => a > b ? a : b);
        await _repo.saveLastAlertedId(_lastAlerted);
        AppLogger.i('${fresh.length} aviso(s) nuevo(s)', tag: 'Avisos');
        // si la lista está cargada, se agregan arriba
        if (items.isNotEmpty) items = [...fresh.reversed, ...items];
      }
      if (changed || fresh.isNotEmpty) notifyListeners();
    } on ApiException catch (e) {
      if (!e.isOffline) AppLogger.w('No se pudieron leer los avisos: ${e.message}', tag: 'Avisos');
    } catch (e) {
      AppLogger.w('No se pudieron leer los avisos: $e', tag: 'Avisos');
    } finally {
      _busy = false;
    }
  }

  /// Carga la lista de la campanita.
  Future<void> loadList() async {
    if (!active) return;
    loadingList = true;
    notifyListeners();
    try {
      final page = await _repo.latest();
      items = page.items;
      unreadNotifications = page.unread;
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    items = [for (final x in items) x.id == n.id ? _asRead(x) : x];
    unreadNotifications = unreadNotifications > 0 ? unreadNotifications - 1 : 0;
    notifyListeners();
    try {
      unreadNotifications = await _repo.markRead([n.id]);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    items = [for (final x in items) _asRead(x)];
    unreadNotifications = 0;
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  AppNotification _asRead(AppNotification n) =>
      AppNotification(id: n.id, type: n.type, title: n.title, body: n.body, data: n.data, read: true, createdAt: n.createdAt);

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    super.dispose();
  }
}
