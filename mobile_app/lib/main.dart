// CaféDirecto · app Android conectada a la API en Railway.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth.dart';
import 'screens/chat_room.dart';
import 'screens/edit_profile.dart';
import 'screens/fees.dart';
import 'screens/learn.dart';
import 'screens/lot_detail.dart';
import 'screens/order_detail.dart';
import 'screens/publish_lot.dart';
import 'screens/rate_agreement.dart';
import 'screens/shell.dart';
import 'screens/user_profile.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = await AppState.load();
  runApp(AppScope(state: state, child: const CafeDirectoApp()));
}

class CafeDirectoApp extends StatelessWidget {
  const CafeDirectoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return MaterialApp(
      title: 'CaféDirecto',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(paletteFor(app.role)),
      navigatorKey: navKey,
      navigatorObservers: [routeTracker],
      initialRoute: '/',
      onGenerateRoute: generateRoute,
      builder: (context, child) => AppOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}

int _id(List<String> segs, [int i = 1]) => segs.length > i ? int.tryParse(segs[i]) ?? -1 : -1;

/// Traduce una ruta como '/lot/12' a su pantalla.
Route<dynamic> generateRoute(RouteSettings settings) {
  final segs = Uri.parse(settings.name ?? '/').pathSegments;
  Widget page;
  switch (segs.isEmpty ? '' : segs[0]) {
    case 'lot':
      page = LotDetailScreen(lotId: _id(segs));
      break;
    case 'farm':
    case 'buyer':
    case 'user':
      page = UserProfileScreen(userId: _id(segs));
      break;
    case 'publish':
      page = PublishLotScreen(lotId: segs.length > 1 ? _id(segs) : null);
      break;
    case 'chat':
      page = ChatRoomScreen(convId: _id(segs));
      break;
    case 'orders':
      page = OrderDetailScreen(agreementId: _id(segs));
      break;
    case 'rate':
      page = RateAgreementScreen(agreementId: _id(segs));
      break;
    case 'learn':
      page = LearnDetailScreen(itemId: segs.length > 1 ? segs[1] : '');
      break;
    case 'fees':
      page = const FeesScreen();
      break;
    case 'edit-profile':
      page = const EditProfileScreen();
      break;
    default:
      page = const RootGate();
  }
  return MaterialPageRoute(settings: settings, builder: (_) => page);
}

/// Muestra la bienvenida (sin sesión) o la app con pestañas.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: app.loggedIn ? MainShell(key: ValueKey('shell-${app.user!.id}')) : const WelcomeScreen(key: ValueKey('welcome')),
    );
  }
}

/// Capa encima de todas las pantallas para los avisos breves.
class AppOverlay extends StatelessWidget {
  final Widget child;
  const AppOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 24,
          right: 24,
          bottom: mq.padding.bottom + 96,
          child: const Align(alignment: Alignment.bottomCenter, heightFactor: 1, child: ToastView()),
        ),
      ],
    );
  }
}

/// Aviso breve (toast).
class ToastView extends StatelessWidget {
  const ToastView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final t = app.toast;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: t == null
            ? const SizedBox.shrink()
            : Material(
                key: ValueKey(t.id),
                color: const Color(0xF21C1410),
                borderRadius: BorderRadius.circular(16),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Flexible(child: Text(t.text, style: p.text(size: 14, weight: FontWeight.w700, color: Colors.white))),
                  ]),
                ),
              ),
      ),
    );
  }
}
