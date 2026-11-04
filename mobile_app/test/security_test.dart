// Pruebas de seguridad móvil (tarea OWASP Mobile Top 10).
import 'package:cafedirecto/core/config/env.dart';
import 'package:cafedirecto/core/logging/app_logger.dart';
import 'package:cafedirecto/presentation/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

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

  group('H-05 · registros sin datos personales', () {
    test('entrar y crear cuenta no deja el correo en los registros', () async {
      final s = SessionProvider(FakeAuthRepository());
      await s.login('lena@nordlicht.de', 'cafe1234');
      final email = s.user!.email;
      final leaked = AppLogger.recent.where((e) => e.message.contains(email) || e.message.contains('@')).toList();
      expect(leaked, isEmpty, reason: 'Registros con el correo: ${leaked.join(' | ')}');
    });
  });
}
