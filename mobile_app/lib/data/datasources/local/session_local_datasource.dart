// Guarda el token de sesión en el teléfono (SharedPreferences) para no pedir la contraseña cada vez.
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';

class SessionLocalDataSource {
  static const _tokenKey = 'cafedirecto-token';
  static const _lastNotificationKey = 'cafedirecto-last-notification';

  SharedPreferences? _prefs;

  Future<SharedPreferences?> _p() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      AppLogger.w('No se pudo abrir el almacenamiento local: $e', tag: 'Session');
    }
    return _prefs;
  }

  Future<String?> readToken() async => (await _p())?.getString(_tokenKey);
  Future<void> saveToken(String token) async => (await _p())?.setString(_tokenKey, token);
  Future<void> clear() async {
    final p = await _p();
    await p?.remove(_tokenKey);
    await p?.remove(_lastNotificationKey);
  }

  /// Última notificación por la que ya se mostró un aviso en el teléfono.
  Future<int> readLastNotifiedId() async => (await _p())?.getInt(_lastNotificationKey) ?? 0;
  Future<void> saveLastNotifiedId(int id) async => (await _p())?.setInt(_lastNotificationKey, id);
}
