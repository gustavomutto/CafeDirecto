// Estado de la sesión: quién entró, su perfil, el idioma, la pestaña activa y los avisos breves (toasts).
// Habla con el servidor solo a través de AuthRepository (capa de dominio).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/bi.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class ToastData {
  final int id;
  final String text;
  final String icon;
  const ToastData(this.id, this.text, this.icon);
}

class SessionProvider extends ChangeNotifier {
  SessionProvider(this._auth) {
    _auth.onSessionExpired = _onExpired;
  }

  final AuthRepository _auth;

  Account? _account;
  int tab = 0;
  ToastData? toast;
  int _toastSeq = 0;

  /// Sube cuando cambian datos (lotes, perfil, acuerdos) para que las pantallas recarguen.
  int dataVersion = 0;

  AppUser? get user => _account?.user;
  FarmProfile? get farm => _account?.farm; // si el usuario es caficultor
  BuyerProfile? get buyer => _account?.buyer; // si es comprador
  bool get loggedIn => user != null;
  String get role => user?.role ?? 'farmer';
  bool get isFarmer => role == 'farmer';
  String get lang => user?.lang ?? 'es';
  String tr(String es, String en) => lang == 'es' ? es : en;
  String pick(Bi? b) => b == null ? '' : b.of(lang);

  void _set(Account? a, {bool resetTab = false}) {
    _account = a;
    if (resetTab) tab = 0;
    notifyListeners();
  }

  /// Al abrir la app: recupera la sesión guardada en el teléfono.
  Future<void> restore() async {
    try {
      final a = await _auth.restoreSession();
      if (a != null) _set(a);
    } catch (e, st) {
      AppLogger.e('No se pudo restaurar la sesión', tag: 'Sesión', error: e, stack: st);
    }
  }

  Future<void> refreshMe() async => _set(await _auth.me());

  Future<void> login(String email, String password) async {
    _set(await _auth.login(email, password), resetTab: true);
    AppLogger.i('Entró ${user?.email} (${user?.role})', tag: 'Sesión');
  }

  Future<void> register(Registration data) async {
    _set(await _auth.register(data), resetTab: true);
    AppLogger.i('Cuenta creada: ${user?.email} (${user?.role})', tag: 'Sesión');
  }

  Future<void> logout() async {
    await _auth.logout();
    _set(null, resetTab: true);
  }

  void _onExpired() {
    if (!loggedIn) return;
    AppLogger.w('El servidor cerró la sesión (401)', tag: 'Sesión');
    unawaited(logout());
  }

  /// Elimina la cuenta en el servidor (pide la contraseña). Después hay que llamar a [logout].
  Future<void> deleteAccountOnServer(String password) => _auth.deleteAccount(password);

  /// Pide un código de 6 dígitos por correo para cambiar la contraseña.
  Future<void> forgotPassword(String email) => _auth.forgotPassword(email);

  /// Cambia la contraseña con el código recibido y entra a la app.
  Future<void> resetPassword(String email, String code, String password) async =>
      _set(await _auth.resetPassword(email, code, password), resetTab: true);

  Future<void> updateAccount(AccountUpdate data) async {
    _account = await _auth.updateAccount(data);
    touch();
  }

  /// Cambia el idioma de TODA la app al instante; el servidor lo guarda en segundo plano
  /// (así los mensajes del chat y los errores llegan en ese idioma). Si falla, vuelve al anterior.
  Future<void> setLang(String l) async {
    final before = _account;
    if (before == null || before.user.lang == l || (l != 'es' && l != 'en')) return;
    _account = before.withLang(l);
    notifyListeners();
    try {
      _account = await _auth.setLanguage(l);
      touch(); // las pantallas recargan sus datos en el idioma nuevo
      AppLogger.i('Idioma de la app: $l', tag: 'Sesión');
    } catch (e) {
      _account = before;
      notifyListeners();
      showError(e);
    }
  }

  Future<void> updateFarmProfile(FarmProfileUpdate data) async {
    _account = await _auth.updateFarmProfile(data);
    touch();
  }

  Future<void> updateBuyerProfile(BuyerProfileUpdate data) async {
    _account = await _auth.updateBuyerProfile(data);
    touch();
  }

  /// Avisa a las pantallas que deben recargar (por ejemplo, tras publicar un lote).
  void touch() {
    dataVersion++;
    notifyListeners();
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
  void showError(Object e) {
    if (e is! ApiException) AppLogger.e('Error inesperado', tag: 'UI', error: e);
    showToast(e is ApiException ? e.message : tr('Algo salió mal', 'Something went wrong'), '⚠️');
  }
}
