// Pestaña "Mi finca" / "Mi perfil": el perfil propio + editar, comisiones y cerrar sesión.
import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'user_profile.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;

    Widget link(IconData icon, String text, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CardBox(
            onTap: onTap,
            child: Row(children: [
              Icon(icon, color: color ?? p.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: p.text(weight: FontWeight.w800, color: color))),
              Icon(Icons.chevron_right_rounded, color: p.ink2),
            ]),
          ),
        );

    final links = Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(children: [
        link(Icons.edit_outlined, app.isFarmer ? app.tr('Editar mi finca y mis datos', 'Edit my farm & details') : app.tr('Editar mi perfil', 'Edit my profile'),
            () => context.go('/edit-profile')),
        if (app.isFarmer) link(Icons.add_rounded, app.tr('Publicar un lote nuevo', 'Publish a new lot'), () => context.go('/publish')),
        link(Icons.attach_money_rounded, app.tr('Comisiones y condiciones', 'Fees & terms'), () => context.go('/fees')),
        link(Icons.logout_rounded, app.tr('Cerrar sesión', 'Log out'), () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(app.tr('¿Cerrar sesión?', 'Log out?')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('Cancelar', 'Cancel'))),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('Salir', 'Log out'))),
              ],
            ),
          );
          if (ok == true) await app.logout();
        }, color: p.danger),
        const SizedBox(height: 6),
        Text(app.user!.email, style: p.muted(size: 12)),
      ]),
    );

    return UserProfileScreen(key: ValueKey('me-${app.user!.id}'), userId: app.user!.id, own: true, extra: links);
  }
}
