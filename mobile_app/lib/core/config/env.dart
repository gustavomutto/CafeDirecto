// Configuración de la app.
//
// Dirección del servidor en Railway. Se puede cambiar al compilar, sin editar este archivo:
//     flutter run --dart-define=API_URL=http://10.0.2.2:3000     (servidor local desde el emulador)
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://cafedirecto-production.up.railway.app',
);

/// Convierte rutas como '/images/12' en una URL completa.
String? mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiUrl$path';
}
