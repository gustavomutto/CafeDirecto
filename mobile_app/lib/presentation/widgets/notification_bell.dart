// Campanita con el número de avisos sin leer; abre la lista de notificaciones.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_context.dart';
import '../providers/notifications_provider.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final n = context.watch<NotificationsProvider>().unreadNotifications;
    return IconButton(
      tooltip: context.app.tr('Notificaciones', 'Notifications'),
      onPressed: () => context.go('/notifications'),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text(n > 9 ? '9+' : '$n'),
        child: Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: 28, color: p.ink),
      ),
    );
  }
}
