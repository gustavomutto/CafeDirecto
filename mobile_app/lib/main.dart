// CaféDirecto · app Android conectada a la API en Railway.
//
// Estructura por capas:
//   core/          configuración, cliente HTTP, logs, avisos del teléfono, tema y utilidades
//   domain/        entidades y contratos de repositorios (no sabe nada de HTTP ni de Flutter)
//   data/          DTOs (JSON ⇄ entidades), fuentes de datos (API, teléfono) e implementación de repositorios
//   presentation/  providers (estado), pantallas y widgets
//   app/           inyección de dependencias, rutas y el widget principal
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/local_notifications.dart';
import 'presentation/providers/app_context.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  FlutterError.onError = (details) {
    AppLogger.e('Error de Flutter', tag: 'Flutter', error: details.exception, stack: details.stack);
    FlutterError.presentError(details);
  };

  // Al tocar un aviso del teléfono, abrir la pantalla correspondiente.
  LocalNotifications.instance.onTap = (route) => navKey.currentState?.pushNamed(route);
  await LocalNotifications.instance.init();

  final deps = AppDependencies.create();
  await deps.session.restore();
  deps.wireSession();
  AppLogger.i('App iniciada · sesión: ${deps.session.loggedIn ? deps.session.user!.email : 'ninguna'}');

  runApp(CafeDirectoApp(deps: deps));
}
