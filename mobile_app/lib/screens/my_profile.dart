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
        link(Icons.currency_exchange_rounded, app.tr('Dólar USD/COP y precios', 'USD/COP rate & prices'), () => context.go('/market')),
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
          if (ok == true) {
            await _dialogClosed();
            await app.logout();
          }
        }, color: p.danger),
        link(Icons.delete_forever_outlined, app.tr('Eliminar mi cuenta', 'Delete my account'), () => _confirmDelete(context), color: p.danger),
        const SizedBox(height: 6),
        Text(app.user!.email, style: p.muted(size: 12)),
      ]),
    );

    return UserProfileScreen(key: ValueKey('me-${app.user!.id}'), userId: app.user!.id, own: true, extra: links);
  }

  /// Confirma con la contraseña antes de eliminar la cuenta (no se puede deshacer).
  Future<void> _confirmDelete(BuildContext context) async {
    final app = context.app;
    final p = context.pal;
    final pass = TextEditingController();
    String? error;
    bool busy = false;
    // El idioma se lee antes: después de eliminar ya no hay usuario.
    final done = app.tr('Tu cuenta fue eliminada', 'Your account was deleted');
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Future<void> submit() async {
            setD(() {
              busy = true;
              error = null;
            });
            try {
              // Solo se borra en el servidor; la sesión se cierra después de cerrar este diálogo,
              // porque al cerrarla desaparece la pantalla que lo abrió.
              await app.deleteAccountOnServer(pass.text);
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              setD(() {
                busy = false;
                error = e.toString();
              });
            }
          }

          return AlertDialog(
            title: Text(app.tr('¿Eliminar tu cuenta?', 'Delete your account?')),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  app.tr(
                    'Se borran tu perfil, tus lotes, tus conversaciones y tus fotos. No se puede deshacer.\n\n'
                        'Si tienes acuerdos registrados, la otra parte conserva el registro del acuerdo, pero sin tus datos personales.',
                    'Your profile, lots, conversations and photos will be deleted. This cannot be undone.\n\n'
                        'If you have recorded agreements, the other party keeps the agreement record, without your personal data.',
                  ),
                  style: p.text(size: 15),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pass,
                  obscureText: true,
                  enabled: !busy,
                  style: p.text(),
                  decoration: InputDecoration(
                    labelText: app.tr('Tu contraseña', 'Your password'),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: p.ink2),
                  ),
                  onSubmitted: (_) => submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: p.text(size: 14, weight: FontWeight.w700, color: p.danger)),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: Text(app.tr('Cancelar', 'Cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: p.danger),
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(app.tr('Eliminar', 'Delete')),
              ),
            ],
          );
        },
      ),
    );
    pass.dispose();
    if (deleted == true) {
      await _dialogClosed();
      await app.logout();
      app.showToast(done);
    }
  }

  /// Espera a que termine la animación de cierre del diálogo. Cerrar la sesión antes
  /// quita de golpe la pantalla que lo abrió mientras el diálogo aún se dibuja (error de Flutter).
  static Future<void> _dialogClosed() => Future<void>.delayed(const Duration(milliseconds: 350));
}
