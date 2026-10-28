// Pruebas de apariencia (modos, colores, letra) e idioma de toda la app.
import 'package:cafedirecto/core/constants/catalog.dart';
import 'package:cafedirecto/core/theme/appearance.dart';
import 'package:cafedirecto/core/theme/palette.dart';
import 'package:cafedirecto/data/datasources/local/appearance_local_datasource.dart';
import 'package:cafedirecto/data/repositories/appearance_repository_impl.dart';
import 'package:cafedirecto/domain/repositories/appearance_repository.dart';
import 'package:cafedirecto/domain/repositories/catalog_repository.dart';
import 'package:cafedirecto/presentation/providers/appearance_provider.dart';
import 'package:cafedirecto/presentation/providers/catalog_provider.dart';
import 'package:cafedirecto/presentation/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

class _MemoryAppearance implements AppearanceRepository {
  AppearanceSettings stored;
  int saves = 0;
  _MemoryAppearance([this.stored = AppearanceSettings.defaults]);
  @override
  Future<AppearanceSettings> load() async => stored;
  @override
  Future<void> save(AppearanceSettings s) async {
    stored = s;
    saves++;
  }
}

class _FakeCatalog implements CatalogRepository {
  List<String>? cached;
  List<String>? server;
  _FakeCatalog({this.cached, this.server});
  @override
  Future<List<String>?> cachedRegions() async => cached;
  @override
  Future<List<String>> fetchRegions() async {
    if (server == null) throw Exception('sin internet');
    return server!;
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Paletas', () {
    final combos = [
      for (final role in ['farmer', 'buyer'])
        for (final mode in [ThemeChoice.light, ThemeChoice.neutral, ThemeChoice.dark])
          for (final accent in AccentChoice.values) (role, mode, accent),
    ];

    test('todas las combinaciones se leen bien (contraste WCAG)', () {
      for (final (role, mode, accent) in combos) {
        final p = resolvePalette(role, mode: mode, accent: accent);
        final where = '$role · ${mode.name} · ${accent.name}';
        expect(_contrast(p.ink, p.bg), greaterThanOrEqualTo(7), reason: 'texto sobre fondo en $where');
        expect(_contrast(p.ink2, p.surface), greaterThanOrEqualTo(4.5), reason: 'texto secundario en $where');
        expect(_contrast(p.primaryInk, p.primary), greaterThanOrEqualTo(4.5), reason: 'texto de botón en $where');
        expect(_contrast(p.primary, p.surface), greaterThanOrEqualTo(3), reason: 'color principal sobre tarjeta en $where');
        for (final c in [p.accent, p.warm, p.danger]) {
          expect(_contrast(Colors.white, c), greaterThanOrEqualTo(3), reason: 'ícono blanco sobre color en $where');
        }
      }
    });

    test('el modo oscuro es oscuro y el claro es claro', () {
      for (final role in ['farmer', 'buyer']) {
        expect(resolvePalette(role, mode: ThemeChoice.dark).dark, isTrue);
        expect(resolvePalette(role, mode: ThemeChoice.dark).bg.computeLuminance(), lessThan(0.05));
        expect(resolvePalette(role).bg.computeLuminance(), greaterThan(0.8));
        expect(resolvePalette(role, mode: ThemeChoice.neutral).dark, isFalse);
      }
    });

    test('el color principal cambia botones pero no el resto', () {
      final base = resolvePalette('farmer');
      final blue = resolvePalette('farmer', accent: AccentChoice.azul);
      expect(blue.primary, isNot(base.primary));
      expect(blue.bg, base.bg);
      expect(blue.accent, base.accent);
      expect(resolvePalette('farmer', accent: AccentChoice.cafe).primary, base.primary);
    });
  });

  group('AppearanceProvider', () {
    test('carga lo guardado, cambia al instante y guarda', () async {
      final repo = _MemoryAppearance(const AppearanceSettings(accent: AccentChoice.verde));
      final look = AppearanceProvider(repo, platformBrightness: () => Brightness.light);
      await look.load();
      expect(look.accent, AccentChoice.verde);

      var changes = 0;
      look.addListener(() => changes++);
      await look.setTheme(ThemeChoice.dark);
      expect(look.isDark, isTrue);
      expect(look.paletteFor('farmer').dark, isTrue);
      expect(repo.stored.theme, ThemeChoice.dark);
      expect(changes, 1);

      await look.setTheme(ThemeChoice.dark); // lo mismo: no guarda ni redibuja
      expect(repo.saves, 1);
      expect(changes, 1);

      await look.setTextSize(TextSizeChoice.xlarge);
      expect(look.textScale, 1.3);
      await look.reset();
      expect(look.settings, AppearanceSettings.defaults);
      look.dispose();
    });

    test('automático sigue el modo del teléfono', () async {
      var phone = Brightness.light;
      final look = AppearanceProvider(_MemoryAppearance(), platformBrightness: () => phone);
      await look.load();
      await look.setTheme(ThemeChoice.system);
      expect(look.effectiveTheme, ThemeChoice.light);

      var changes = 0;
      look.addListener(() => changes++);
      phone = Brightness.dark;
      look.didChangePlatformBrightness();
      expect(look.isDark, isTrue);
      expect(changes, 1);

      await look.setTheme(ThemeChoice.neutral);
      look.didChangePlatformBrightness(); // fuera de automático no le importa el teléfono
      expect(look.effectiveTheme, ThemeChoice.neutral);
      look.dispose();
    });

    test('se guarda en el teléfono y valores viejos o raros vuelven al original', () async {
      SharedPreferences.setMockInitialValues({'cafedirecto-theme': 'dark', 'cafedirecto-accent': 'morado'});
      final repo = AppearanceRepositoryImpl(AppearanceLocalDataSource());
      final s = await repo.load();
      expect(s.theme, ThemeChoice.dark);
      expect(s.accent, AccentChoice.cafe);
      expect(s.textSize, TextSizeChoice.normal);

      await repo.save(const AppearanceSettings(theme: ThemeChoice.neutral, accent: AccentChoice.vino, textSize: TextSizeChoice.large));
      expect(await repo.load(), const AppearanceSettings(theme: ThemeChoice.neutral, accent: AccentChoice.vino, textSize: TextSizeChoice.large));
    });
  });

  group('Idioma de toda la app', () {
    test('cambia al instante y lo guarda en el servidor', () async {
      final auth = FakeAuthRepository();
      final s = SessionProvider(auth);
      await s.login('carlos@x.co', 'cafe1234');
      expect(s.lang, 'es');
      expect(s.tr('Hola', 'Hello'), 'Hola');

      final v = s.dataVersion;
      await s.setLang('en');
      expect(s.lang, 'en');
      expect(s.tr('Hola', 'Hello'), 'Hello');
      expect(auth.stored!.user.lang, 'en');
      expect(s.dataVersion, greaterThan(v)); // las pantallas recargan
    });

    test('si el servidor falla, vuelve al idioma anterior y avisa', () async {
      final auth = FakeAuthRepository();
      final s = SessionProvider(auth);
      await s.login('carlos@x.co', 'cafe1234');
      auth.failLanguage = true;
      await s.setLang('en');
      expect(s.lang, 'es');
      expect(s.toast?.text, contains('Sin conexión'));
    });

    test('tipo de comprador traducido, también si se escribió a mano', () {
      expect(buyerTypeLabel('Planta de tostado', 'en'), 'Roasting plant');
      expect(buyerTypeLabel('planta de TOSTADO ', 'en'), 'Roasting plant');
      expect(buyerTypeLabel('Roaster', 'es'), 'Tostador');
      expect(buyerTypeLabel('cafeteria', 'en'), 'Coffee shop');
      expect(buyerTypeLabel('Hotel boutique', 'en'), 'Hotel boutique');
      expect(buyerTypeKey(''), isNull);
    });
  });

  group('Regiones del servidor', () {
    test('sin descargar todavía usa la lista de la app (incluye Cesar)', () {
      final c = CatalogProvider(_FakeCatalog());
      expect(c.regions, contains('Cesar'));
      expect(c.regions, regions);
    });

    test('una región nueva del servidor aparece al abrir la app', () async {
      final c = CatalogProvider(_FakeCatalog(server: [...regions, 'Antioquia']));
      var changes = 0;
      c.addListener(() => changes++);
      await c.load();
      expect(c.regions.last, 'Antioquia');
      expect(changes, 1);
    });

    test('sin internet usa la última lista guardada', () async {
      final c = CatalogProvider(_FakeCatalog(cached: ['Huila', 'Cesar', 'Caldas']));
      await c.load();
      expect(c.regions, ['Huila', 'Cesar', 'Caldas']);
    });
  });
}
