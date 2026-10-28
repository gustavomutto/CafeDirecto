// Muestra la bienvenida (sin sesión) o la app con pestañas.
import 'package:flutter/material.dart';

import '../../providers/app_context.dart';
import '../auth/auth_screens.dart';
import 'main_shell.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    // Sin sesión se cambia de inmediato: si la pantalla principal se quedara animando su salida,
    // se volvería a dibujar sin usuario (app.user == null) y fallaría.
    if (!app.loggedIn) return const WelcomeScreen(key: ValueKey('welcome'));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: MainShell(key: ValueKey('shell-${app.user!.id}')),
    );
  }
}
