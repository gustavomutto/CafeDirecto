// Pruebas de seguridad móvil (tarea OWASP Mobile Top 10).
import 'package:cafedirecto/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('H-06 · solo HTTPS', () {
    test('la versión publicada solo acepta https://', () {
      expect(insecureApiUrlReason('https://cafedirecto-production.up.railway.app', release: true), isNull);
      expect(insecureApiUrlReason('http://cafedirecto-production.up.railway.app', release: true), isNotNull);
      expect(insecureApiUrlReason('http://10.0.2.2:3000', release: true), isNotNull);
      expect(insecureApiUrlReason('no-es-una-url', release: true), isNotNull);
    });

    test('en depuración, http solo hacia el servidor local', () {
      expect(insecureApiUrlReason('http://10.0.2.2:3000', release: false), isNull);
      expect(insecureApiUrlReason('http://localhost:3000', release: false), isNull);
      expect(insecureApiUrlReason('http://192.168.1.20:3000', release: false), isNotNull);
      expect(insecureApiUrlReason('http://api.ejemplo.com', release: false), isNotNull);
    });

    test('la dirección configurada por defecto es segura', () {
      expect(insecureApiUrlReason(apiUrl, release: true), isNull);
    });
  });
}
