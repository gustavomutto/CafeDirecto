// Apariencia de la app: modo (claro, neutro, oscuro o automático), color principal y tamaño de letra.
// Se aplica al instante y se guarda en el teléfono. En modo automático sigue al sistema
// (si la persona cambia el celular a oscuro, la app cambia sola).
import 'package:flutter/widgets.dart';

import '../../core/logging/app_logger.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/palette.dart';
import '../../domain/repositories/appearance_repository.dart';

class AppearanceProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppearanceProvider(this._repo, {Brightness Function()? platformBrightness})
      : _platformBrightness = platformBrightness ?? (() => WidgetsBinding.instance.platformDispatcher.platformBrightness);

  final AppearanceRepository _repo;
  final Brightness Function() _platformBrightness;
  AppearanceSettings _settings = AppearanceSettings.defaults;
  bool _observing = false;

  AppearanceSettings get settings => _settings;
  ThemeChoice get theme => _settings.theme;
  AccentChoice get accent => _settings.accent;
  TextSizeChoice get textSize => _settings.textSize;
  double get textScale => textScaleOf(_settings.textSize);

  /// El modo que realmente se ve (el automático se resuelve con el del teléfono).
  ThemeChoice get effectiveTheme {
    if (theme != ThemeChoice.system) return theme;
    return _platformBrightness() == Brightness.dark ? ThemeChoice.dark : ThemeChoice.light;
  }

  bool get isDark => effectiveTheme == ThemeChoice.dark;

  /// Paleta del rol con la apariencia actual.
  Palette paletteFor(String role) => resolvePalette(role, mode: effectiveTheme, accent: accent);

  /// Al abrir la app: lee lo guardado y empieza a escuchar el modo del teléfono.
  Future<void> load() async {
    try {
      _settings = await _repo.load();
    } catch (e) {
      AppLogger.w('No se pudo leer la apariencia guardada: $e', tag: 'Apariencia');
    }
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    notifyListeners();
  }

  Future<void> _update(AppearanceSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    try {
      await _repo.save(next);
    } catch (e) {
      AppLogger.w('No se pudo guardar la apariencia: $e', tag: 'Apariencia');
    }
  }

  Future<void> setTheme(ThemeChoice t) => _update(_settings.copyWith(theme: t));
  Future<void> setAccent(AccentChoice a) => _update(_settings.copyWith(accent: a));
  Future<void> setTextSize(TextSizeChoice s) => _update(_settings.copyWith(textSize: s));
  Future<void> reset() => _update(AppearanceSettings.defaults);

  @override
  void didChangePlatformBrightness() {
    if (theme == ThemeChoice.system) notifyListeners();
  }

  @override
  void dispose() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
