/// Avisos en el teléfono. La app usa [LocalNotifications]; las pruebas usan una versión falsa.
abstract class AlertService {
  Future<void> requestPermission();
  Future<void> show({required int id, required String title, required String body, String? route});
}
