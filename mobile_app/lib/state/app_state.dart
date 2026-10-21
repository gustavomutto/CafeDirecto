// Estado global: sesión del usuario, su perfil, pestaña activa, mensajes sin leer y avisos.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/models.dart';

class ToastData {
  final int id;
  final String text;
  final String icon;
  const ToastData(this.id, this.text, this.icon);
}

class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static const _tokenKey = 'cafedirecto-token';
  final SharedPreferences? _prefs;
  final Api api = Api();

  AppUser? user;
  FarmProfile? farm; // si el usuario es caficultor
  BuyerProfile? buyer; // si es comprador
  int tab = 0;
  int unread = 0;
  ToastData? toast;
  int _toastSeq = 0;
  Timer? _poll;

  /// Sube cuando cambian datos (lotes, perfil, acuerdos) para que las pantallas recarguen.
  int dataVersion = 0;

  bool get loggedIn => user != null;
  String get role => user?.role ?? 'farmer';
  bool get isFarmer => role == 'farmer';
  String get lang => user?.lang ?? 'es';
  String tr(String es, String en) => lang == 'es' ? es : en;
  String pick(Bi? b) => b == null ? '' : b.of(lang);

  static Future<AppState> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    final s = AppState._(prefs);
    final token = prefs?.getString(_tokenKey);
    if (token != null) {
      s.api.token = token;
      try {
        await s.refreshMe();
        s._startPolling();
      } on ApiException catch (e) {
        if (e.status == 401) {
          await s._clearSession();
        }
        // Si no hay internet al abrir, se queda sin usuario y la pantalla de inicio lo informa.
      }
    }
    return s;
  }

  void _applyMe(Map j) {
    user = AppUser.fromJson(j['user'] as Map);
    final p = j['profile'] as Map?;
    farm = user!.isFarmer && p != null ? FarmProfile.fromJson(p) : null;
    buyer = !user!.isFarmer && p != null ? BuyerProfile.fromJson(p) : null;
  }

  Future<void> refreshMe() async {
    final j = await api.get('/me') as Map;
    _applyMe(j);
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    api.token = token;
    await _prefs?.setString(_tokenKey, token);
  }

  Future<void> _clearSession() async {
    api.token = null;
    user = null;
    farm = null;
    buyer = null;
    unread = 0;
    tab = 0;
    _poll?.cancel();
    await _prefs?.remove(_tokenKey);
  }

  Future<void> login(String email, String password) async {
    final j = await api.post('/auth/login', {'email': email, 'password': password}) as Map;
    await _saveToken(j['token'] as String);
    await refreshMe();
    tab = 0;
    _startPolling();
  }

  Future<void> register(Map<String, dynamic> data) async {
    final j = await api.post('/auth/register', data) as Map;
    await _saveToken(j['token'] as String);
    await refreshMe();
    tab = 0;
    _startPolling();
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> updateAccount(Map<String, dynamic> data) async {
    _applyMe(await api.put('/me', data) as Map);
    dataVersion++;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _applyMe(await api.put('/me/profile', data) as Map);
    dataVersion++;
    notifyListeners();
  }

  /// Avisa a las pantallas que deben recargar (por ejemplo, tras publicar un lote).
  void touch() {
    dataVersion++;
    notifyListeners();
  }

  // ── Mensajes sin leer (se consulta cada 10 s) ───────────────────
  void _startPolling() {
    _poll?.cancel();
    refreshUnread();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => refreshUnread());
  }

  Future<void> refreshUnread() async {
    if (!loggedIn) return;
    try {
      final j = await api.get('/unread') as Map;
      final n = (j['unread'] as num).toInt();
      if (n != unread) {
        unread = n;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.status == 401) await logout();
    }
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void showToast(String text, [String icon = '✓']) {
    final id = ++_toastSeq;
    toast = ToastData(id, text, icon);
    notifyListeners();
    Timer(const Duration(milliseconds: 2800), () {
      if (toast?.id == id) {
        toast = null;
        notifyListeners();
      }
    });
  }

  /// Muestra el error de una llamada a la API como aviso.
  void showError(Object e) => showToast(e is ApiException ? e.message : tr('Algo salió mal', 'Something went wrong'), '⚠️');

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
