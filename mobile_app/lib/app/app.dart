// Widget principal: pone los providers en el árbol y configura MaterialApp.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/palette.dart';
import '../presentation/providers/app_context.dart';
import '../presentation/providers/appearance_provider.dart';
import '../presentation/providers/session_provider.dart';
import '../presentation/widgets/toast_overlay.dart';
import 'di.dart';
import 'router.dart';

class CafeDirectoApp extends StatelessWidget {
  final AppDependencies deps;
  const CafeDirectoApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: deps.providers,
      child: Builder(builder: (context) {
        final role = context.select<SessionProvider, String>((s) => s.role);
        final look = context.watch<AppearanceProvider>();
        final p = look.paletteFor(role);
        return MaterialApp(
          title: 'CaféDirecto',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(p),
          navigatorKey: navKey,
          initialRoute: '/',
          onGenerateRoute: generateRoute,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              // íconos de la barra de estado claros sobre fondo oscuro y al revés
              value: (p.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: const Color(0x00000000),
                systemNavigationBarColor: p.surface,
                systemNavigationBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
              ),
              child: MediaQuery(
                // tamaño de letra elegido (se suma al del sistema, con un tope para no romper pantallas)
                data: mq.copyWith(textScaler: TextScaler.linear((mq.textScaler.scale(1) * look.textScale).clamp(0.8, 1.6))),
                child: ToastOverlay(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
        );
      }),
    );
  }
}
