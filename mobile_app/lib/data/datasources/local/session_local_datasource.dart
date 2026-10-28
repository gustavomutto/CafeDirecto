// Datos locales de la sesión.
//  · El token (JWT) va en almacenamiento cifrado (Android Keystore / iOS Keychain).
//  · El id del último aviso mostrado va en SharedPreferences (no es secreto).
// Si había un token de una versión anterior en SharedPreferences, se mueve al almacenamiento
// cifrado la primera vez, así nadie tiene que volver a iniciar sesión al actualizar la app.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';

class SessionLocalDataSource {
  SessionLocalDataSource({FlutterSecureStorage? secure}) : _secure = secure ?? const FlutterSecureStorage();

  static const _tokenKey = 'cafedirecto-token';
  static const _lastNotificationKey = 'cafedirecto-last-notification';

  final FlutterSecureStorage _secure;
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

  Future<String?> readToken() async {
    try {
      final token = await _secure.read(key: _tokenKey);
      if (token != null) return token;
    } catch (e) {
      AppLogger.w('No se pudo leer el almacenamiento cifrado: $e', tag: 'Session');
    }
    // Migración desde versiones anteriores (token sin cifrar).
    final legacy = (await _p())?.getString(_tokenKey);
    if (legacy != null) {
      await saveToken(legacy);
      await (await _p())?.remove(_tokenKey);
      AppLogger.i('Token movido al almacenamiento cifrado', tag: 'Session');
    }
    return legacy;
  }

  Future<void> saveToken(String token) async {
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (e) {
      AppLogger.e('No se pudo guardar el token cifrado', tag: 'Session', error: e);
    }
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {}
    final p = await _p();
    await p?.remove(_tokenKey);
    await p?.remove(_lastNotificationKey);
  }

  /// Última notificación por la que ya se mostró un aviso en el teléfono.
  Future<int> readLastNotifiedId() async => (await _p())?.getInt(_lastNotificationKey) ?? 0;
  Future<void> saveLastNotifiedId(int id) async => (await _p())?.setInt(_lastNotificationKey, id);
}
