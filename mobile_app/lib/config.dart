// ─────────────────────────────────────────────────────────────────
//  DIRECCIÓN DE TU SERVIDOR EN RAILWAY
//  Cámbiala por el dominio que te da Railway (Settings → Networking →
//  Generate Domain), SIN la barra final. Ejemplo:
//      https://cafedirecto-api-production.up.railway.app
//
//  También puedes pasarla al compilar sin editar este archivo:
//      flutter run --dart-define=API_URL=https://...up.railway.app
// ─────────────────────────────────────────────────────────────────
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
