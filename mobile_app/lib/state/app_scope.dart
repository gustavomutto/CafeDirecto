// Pone el AppState al alcance de todos los widgets y define la navegación.
import 'package:flutter/material.dart';

import '../theme/palette.dart';
import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado');
    return scope!.notifier!;
  }
}

extension AppContextX on BuildContext {
  /// Estado global (y se reconstruye cuando cambia).
  AppState get app => AppScope.of(this);

  /// Paleta del rol activo (o la de un [PaletteOverride] si hay uno arriba).
  Palette get pal {
    final o = dependOnInheritedWidgetOfExactType<PaletteOverride>();
    return o?.palette ?? paletteFor(AppScope.of(this).role);
  }

  /// Abre una pantalla por su ruta, por ejemplo '/lot/l1'.
  Future<void> go(String path) => Navigator.of(this).pushNamed(path);

  /// Reemplaza la pantalla actual por otra.
  Future<void> replace(String path) => Navigator.of(this).pushReplacementNamed(path);
}

/// Fuerza una paleta para un subárbol (se usa en el onboarding, antes de elegir rol).
class PaletteOverride extends InheritedWidget {
  final Palette palette;
  const PaletteOverride({super.key, required this.palette, required super.child});

  @override
  bool updateShouldNotify(PaletteOverride oldWidget) => oldWidget.palette != palette;
}

/// Llave global del navegador (la usa el panel de demo, que vive fuera de las rutas).
final navKey = GlobalKey<NavigatorState>();

/// Lleva la cuenta de las pantallas abiertas para saber en cuál estamos.
class RouteTracker extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  String? get topPageName {
    for (final r in _stack.reversed) {
      if (r is PageRoute) return r.settings.name;
    }
    return null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
  }
}

final routeTracker = RouteTracker();

/// Vuelve a la pantalla principal (pestañas).
void goHome({int tab = 0}) {
  final nav = navKey.currentState;
  nav?.popUntil((r) => r.isFirst);
  final ctx = navKey.currentContext;
  if (ctx != null) AppScope.of(ctx).setTab(tab);
}
