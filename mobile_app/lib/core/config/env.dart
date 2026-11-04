// Configuración de la app.
//
// Dirección del servidor en Railway. Se puede cambiar al compilar, sin editar este archivo:
//     flutter run --dart-define=API_URL=http://10.0.2.2:3000     (servidor local desde el emulador)
// En un teléfono por USB: `adb reverse tcp:3000 tcp:3000` y API_URL=http://localhost:3000.
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://cafedirecto-production.up.railway.app',
);

/// Equipos locales a los que la versión de depuración puede hablar por http (igual que en
/// android/app/src/debug/res/xml/network_security_config.xml).
const _localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

/// Revisa que la dirección del servidor sea segura (hallazgo H-06). Devuelve el problema, o null si está bien.
/// En la versión publicada solo se acepta https://; http:// solo en depuración y hacia el equipo local.
String? insecureApiUrlReason(String url, {required bool release}) {
  final u = Uri.tryParse(url);
  if (u == null || !u.hasScheme || u.host.isEmpty) return 'API_URL no es una dirección válida: $url';
  if (u.scheme == 'https') return null;
  if (!release && u.scheme == 'http' && _localHosts.contains(u.host)) return null;
  return release
      ? 'La versión publicada solo se conecta por https:// (API_URL=$url)'
      : 'Por http:// solo se permite el servidor local (localhost, 127.0.0.1 o 10.0.2.2), no $url';
}

/// Convierte rutas como '/images/12' en una URL completa.
String? mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiUrl$path';
}
