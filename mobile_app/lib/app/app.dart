// Widget principal: pone los providers en el árbol y configura MaterialApp.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/palette.dart';
import '../presentation/providers/app_context.dart';
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
        return MaterialApp(
          title: 'CaféDirecto',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(paletteFor(role)),
          navigatorKey: navKey,
          navigatorObservers: [routeTracker],
          initialRoute: '/',
          onGenerateRoute: generateRoute,
          builder: (context, child) => ToastOverlay(child: child ?? const SizedBox.shrink()),
        );
      }),
    );
  }
}
