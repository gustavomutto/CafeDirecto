import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens.dart';

const coffeeBrown = Color(0xFF5B3A29);
const coffeeGreen = Color(0xFF3E7B4F);
const coffeeCream = Color(0xFFF7F3EC);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CafeDirectoApp(state: CafeState()));
}

class CafeDirectoApp extends StatefulWidget {
  const CafeDirectoApp({required this.state, super.key});

  final CafeState state;

  @override
  State<CafeDirectoApp> createState() => _CafeDirectoAppState();
}

class _CafeDirectoAppState extends State<CafeDirectoApp> {
  @override
  void initState() {
    super.initState();
    widget.state.initialize();
  }

  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) => MaterialApp(
      title: 'CaféDirecto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: coffeeCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: coffeeBrown,
          primary: coffeeBrown,
          secondary: coffeeGreen,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: coffeeCream,
          foregroundColor: Color(0xFF2B1D14),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: !widget.state.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : widget.state.onboarded
          ? AppShell(state: widget.state)
          : OnboardingScreen(state: widget.state),
    ),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({required this.state, super.key});

  final CafeState state;

  @override
  Widget build(BuildContext context) {
    final pages = [
      state.isFarmer
          ? FarmerHomeScreen(state: state)
          : ExploreScreen(state: state),
      ChatListScreen(state: state),
      OrdersScreen(state: state),
      LearnScreen(state: state),
      ProfileScreen(state: state),
    ];
    final labels = state.isFarmer
        ? const ['Inicio', 'Mensajes', 'Acuerdos', 'Aprende', 'Mi finca']
        : const ['Explorar', 'Mensajes', 'Pedidos', 'Aprende', 'Perfil'];
    final icons = state.isFarmer
        ? const [
            Icons.home_rounded,
            Icons.chat_bubble_outline_rounded,
            Icons.handshake_outlined,
            Icons.menu_book_rounded,
            Icons.person_outline_rounded,
          ]
        : const [
            Icons.explore_outlined,
            Icons.chat_bubble_outline_rounded,
            Icons.receipt_long_outlined,
            Icons.menu_book_rounded,
            Icons.person_outline_rounded,
          ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (state.offline)
              Material(
                color: const Color(0xFFFFE6C6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sin conexión · tus cambios se guardan en el dispositivo',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar aviso',
                        visualDensity: VisualDensity.compact,
                        onPressed: state.toggleOffline,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(index: state.tabIndex, children: pages),
            ),
          ],
        ),
      ),
      floatingActionButton: state.isFarmer && state.tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublishLotScreen(state: state),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Publicar lote'),
              backgroundColor: coffeeBrown,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.selectTab,
        destinations: List.generate(
          labels.length,
          (index) => NavigationDestination(
            icon: Icon(icons[index]),
            label: labels[index],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({required this.state, super.key});

  final CafeState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1D14), Color(0xFF5B3A29), Color(0xFF315740)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'CaféDirecto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Del cafetal a la taza,\nsin intermediarios.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .85),
                  fontSize: 20,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'From farm to cup, direct.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Text(
                '¿Cómo quieres usar CaféDirecto?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _RoleChoice(
                icon: '👩🏽‍🌾',
                title: 'Soy caficultor',
                subtitle: 'Quiero vender mi café',
                onTap: () => state.completeOnboarding(true),
              ),
              const SizedBox(height: 10),
              _RoleChoice(
                icon: '☕',
                title: "I'm a coffee buyer",
                subtitle: 'Roaster, café or importer',
                onTap: () => state.completeOnboarding(false),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Demo · datos de ejemplo',
                  style: TextStyle(color: Colors.white.withValues(alpha: .7)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
