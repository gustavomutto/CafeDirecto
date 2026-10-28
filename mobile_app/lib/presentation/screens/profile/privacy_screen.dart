// Privacidad: qué datos guarda CaféDirecto y cómo eliminarlos. La versión completa está en la web
// del servidor (/privacy), que es la dirección que se registra en Google Play.
import 'package:flutter/material.dart';

import '../../../core/config/env.dart';
import '../../providers/app_context.dart';
import '../../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    Widget item(IconData icon, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: p.warm),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: p.text(weight: FontWeight.w800)),
                Text(text, style: p.text(size: p.fs - 1)),
              ]),
            ),
          ]),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          TopBar(title: app.tr('Privacidad', 'Privacy')),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
              item(Icons.person_outline_rounded, app.tr('Tu cuenta', 'Your account'),
                  app.tr('Nombre, correo, celular (opcional), idioma y foto. La contraseña se guarda cifrada.',
                      'Name, email, optional phone, language and photo. Your password is stored hashed.')),
              item(Icons.storefront_outlined, app.tr('Lo que publicas', 'What you publish'),
                  app.tr('Perfil, lotes, subastas, ofertas, acuerdos y calificaciones.', 'Profile, lots, auctions, bids, agreements and ratings.')),
              item(Icons.chat_bubble_outline_rounded, app.tr('Mensajes y fotos', 'Messages and photos'),
                  app.tr('Se guardan con su traducción. Las fotos solo se abren con la dirección que entrega la app.',
                      'Stored with their translation. Photos only open through the link the app provides.')),
              item(Icons.visibility_outlined, app.tr('Interés en lotes', 'Lot views'),
                  app.tr('Si eres comprador y abres un lote, el caficultor puede ver que lo viste.', 'If you are a buyer and open a lot, the farmer can see you viewed it.')),
              item(Icons.translate_rounded, app.tr('Servicios externos', 'Third parties'),
                  app.tr('Railway aloja el servidor; DeepL, Google o MyMemory traducen el texto de los mensajes; Resend envía el correo de recuperación. No vendemos tus datos.',
                      'Railway hosts the server; DeepL, Google or MyMemory translate message text; Resend sends the reset email. We never sell your data.')),
              item(Icons.delete_outline_rounded, app.tr('Eliminar tu cuenta', 'Delete your account'),
                  app.tr('Perfil → Eliminar mi cuenta. Se borra todo; los acuerdos ya registrados quedan para la otra parte sin tus datos personales.',
                      'Profile → Delete my account. Everything is removed; recorded agreements stay for the other party without your personal data.')),
              const SizedBox(height: 6),
              Text(app.tr('Política completa', 'Full policy'), style: p.muted(size: 12)),
              SelectableText('$apiUrl/privacy', style: p.text(size: 13, weight: FontWeight.w700, color: p.accent)),
            ]),
          ),
        ]),
      ),
    );
  }
}
