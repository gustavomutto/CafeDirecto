// Avisos en la barra de notificaciones del teléfono (flutter_local_notifications).
// La app los muestra cuando el servidor tiene una notificación nueva (interés en un lote,
// una oferta, un acuerdo…). Al tocar el aviso, se abre la pantalla correspondiente.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_logger.dart';
import 'alert_service.dart';

class LocalNotifications implements AlertService {
  LocalNotifications._();
  static final LocalNotifications instance = LocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Se llama con la ruta guardada en el aviso cuando la persona lo toca (por ejemplo '/lot/12').
  void Function(String route)? onTap;

  static const _channel = AndroidNotificationDetails(
    'cafedirecto_avisos',
    'Avisos de CaféDirecto',
    channelDescription: 'Interés en tus lotes, ofertas de subastas, cotizaciones y acuerdos',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    color: Color(0xFF6D4C41),
  );

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (r) {
          final route = r.payload;
          if (route != null && route.isNotEmpty) onTap?.call(route);
        },
      );
      _ready = true;
      // Si la app se abrió tocando un aviso, ir a esa pantalla.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final route = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && route != null && route.isNotEmpty) {
        Future.microtask(() => onTap?.call(route));
      }
    } catch (e) {
      AppLogger.w('No se pudieron iniciar los avisos del teléfono: $e', tag: 'Avisos');
    }
  }

  /// En Android 13 o más el sistema pide permiso la primera vez.
  @override
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (e) {
      AppLogger.w('Permiso de avisos no disponible: $e', tag: 'Avisos');
    }
  }

  @override
  Future<void> show({required int id, required String title, required String body, String? route}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
        payload: route,
      );
    } catch (e) {
      AppLogger.w('No se pudo mostrar el aviso: $e', tag: 'Avisos');
    }
  }
}
