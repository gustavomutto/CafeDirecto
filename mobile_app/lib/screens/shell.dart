// Pantalla principal con la barra de pestañas inferior.
import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'chat_list.dart';
import 'explore.dart';
import 'farmer_home.dart';
import 'learn.dart';
import 'my_profile.dart';
import 'orders.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.pal;
    final farmer = app.isFarmer;
    final unread = app.unread;
    final iconSize = farmer ? 28.0 : 24.0;

    NavigationDestination dest(IconData icon, IconData selected, String label, {int badge = 0}) => NavigationDestination(
          icon: Badge(isLabelVisible: badge > 0, label: Text(badge > 9 ? '9+' : '$badge'), child: Icon(icon, size: iconSize, color: p.ink2)),
          selectedIcon: Badge(isLabelVisible: badge > 0, label: Text(badge > 9 ? '9+' : '$badge'), child: Icon(selected, size: iconSize, color: p.primary)),
          label: label,
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: IndexedStack(
        index: app.tab,
        children: [
          farmer ? const FarmerHomeScreen(key: ValueKey('fh')) : const ExploreScreen(key: ValueKey('ex')),
          const ChatListScreen(),
          const OrdersScreen(),
          const LearnScreen(),
          const MyProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tab,
        onDestinationSelected: app.setTab,
        destinations: [
          dest(farmer ? Icons.home_outlined : Icons.explore_outlined, farmer ? Icons.home_rounded : Icons.explore_rounded,
              farmer ? app.tr('Inicio', 'Home') : app.tr('Explorar', 'Explore')),
          dest(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, app.tr('Mensajes', 'Messages'), badge: unread),
          dest(Icons.receipt_long_outlined, Icons.receipt_long_rounded, app.tr('Acuerdos', 'Orders')),
          dest(Icons.menu_book_outlined, Icons.menu_book_rounded, app.tr('Aprende', 'Learn')),
          dest(Icons.person_outline_rounded, Icons.person_rounded, farmer ? app.tr('Mi finca', 'My farm') : app.tr('Mi perfil', 'Profile')),
        ],
      ),
    );
  }
}
