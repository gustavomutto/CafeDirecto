// Apariencia guardada en SharedPreferences (no es dato sensible).
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';

class AppearanceLocalDataSource {
  static const _themeKey = 'cafedirecto-theme';
  static const _accentKey = 'cafedirecto-accent';
  static const _textSizeKey = 'cafedirecto-text-size';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      AppLogger.w('No se pudo abrir el almacenamiento local: $e', tag: 'Apariencia');
      return null;
    }
  }

  Future<Map<String, String?>> read() async {
    final p = await _prefs();
    return {
      'theme': p?.getString(_themeKey),
      'accent': p?.getString(_accentKey),
      'textSize': p?.getString(_textSizeKey),
    };
  }

  Future<void> write({required String theme, required String accent, required String textSize}) async {
    final p = await _prefs();
    await p?.setString(_themeKey, theme);
    await p?.setString(_accentKey, accent);
    await p?.setString(_textSizeKey, textSize);
  }
}
