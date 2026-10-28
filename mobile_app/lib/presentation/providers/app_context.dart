// Atajos para que los widgets lleguen al estado (Provider) y a la navegación.
//
//   context.app      → SessionProvider y se redibuja cuando cambia (usar dentro de build)
//   context.session  → SessionProvider sin escuchar (usar en botones, callbacks, initState)
//   context.repo<T>()→ un repositorio (LotRepository, ChatRepository, …)
//   context.pal      → paleta de colores del rol activo, con la apariencia elegida (claro, neutro, oscuro…)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import 'appearance_provider.dart';
import 'session_provider.dart';

extension AppContextX on BuildContext {
  /// Dentro de build escucha los cambios; dentro de un callback solo lee
  /// (Provider no permite escuchar fuera de build y lo marca como error en modo depuración).
  bool get _listen => !kDebugMode || (owner?.debugBuilding ?? false);

  /// Estado de la sesión: dentro de build el widget se redibuja cuando cambia.
  SessionProvider get app => Provider.of<SessionProvider>(this, listen: _listen);

  /// Estado de la sesión sin escuchar cambios (para callbacks).
  SessionProvider get session => read<SessionProvider>();

  /// Repositorio de la capa de dominio.
  T repo<T>() => read<T>();

  /// Paleta del rol activo (o la de un [PaletteOverride] si hay uno arriba).
  Palette get pal {
    final o = dependOnInheritedWidgetOfExactType<PaletteOverride>();
    return o?.palette ?? palFor(Provider.of<SessionProvider>(this, listen: _listen).role);
  }

  /// Paleta de un rol con la apariencia elegida (sirve antes de entrar, cuando aún no hay rol).
  Palette palFor(String role) {
    final a = Provider.of<AppearanceProvider?>(this, listen: _listen);
    return a?.paletteFor(role) ?? paletteFor(role);
  }

  /// Preferencias de apariencia: dentro de build escucha, en callbacks solo lee.
  AppearanceProvider get appearance => Provider.of<AppearanceProvider>(this, listen: _listen);

  /// Abre una pantalla por su ruta, por ejemplo '/lot/12'.
  Future<void> go(String path) => Navigator.of(this).pushNamed(path);

  /// Reemplaza la pantalla actual por otra.
  Future<void> replace(String path) => Navigator.of(this).pushReplacementNamed(path);
}

/// Fuerza una paleta para un subárbol (se usa en la bienvenida, antes de elegir rol).
class PaletteOverride extends InheritedWidget {
  final Palette palette;
  const PaletteOverride({super.key, required this.palette, required super.child});

  @override
  bool updateShouldNotify(PaletteOverride oldWidget) => oldWidget.palette != palette;
}

/// Llave global del navegador (para navegar desde fuera de un widget, por ejemplo al tocar un aviso).
final navKey = GlobalKey<NavigatorState>();

/// Vuelve a la pantalla principal (pestañas).
void goHome({int tab = 0}) {
  final nav = navKey.currentState;
  nav?.popUntil((r) => r.isFirst);
  final ctx = navKey.currentContext;
  if (ctx != null) ctx.read<SessionProvider>().setTab(tab);
}
