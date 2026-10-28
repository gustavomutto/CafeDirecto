// Pruebas de la capa de presentación (providers) con repositorios falsos.
import 'package:cafedirecto/presentation/providers/chat_room_controller.dart';
import 'package:cafedirecto/presentation/providers/notifications_provider.dart';
import 'package:cafedirecto/presentation/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatRoomController', () {
    late FakeChatRepository chat;
    late FakeAgreementRepository agreements;
    late ChatRoomController ctrl;
    var reads = 0;

    setUp(() {
      chat = FakeChatRepository();
      agreements = FakeAgreementRepository();
      reads = 0;
      ctrl = ChatRoomController(
        chat: chat,
        agreements: agreements,
        lots: FakeLotRepository(),
        convId: 7,
        myUserId: 1,
        myRole: 'farmer',
        lang: 'es',
        onRead: () => reads++,
        pollEvery: const Duration(hours: 1), // en las pruebas se consulta a mano
      );
    });
    tearDown(() => ctrl.dispose());

    test('al abrir carga la conversación, los mensajes y marca leído', () async {
      await ctrl.start();
      expect(ctrl.conversation?.id, 7);
      expect(ctrl.messages.map((m) => m.id), [1, 2]);
      expect(chat.readMarks.last, 2);
      expect(reads, 1);
    });

    test('enviar texto: queda el mensaje confirmado por el servidor', () async {
      await ctrl.start();
      await ctrl.sendText('  ¿Tiene muestra?  ');
      expect(ctrl.messages.last.text, '¿Tiene muestra?');
      expect(ctrl.messages.last.pending, isFalse);
      expect(ctrl.messages.last.id, 100);
    });

    test('si el envío falla se quita el pendiente y se avisa', () async {
      await ctrl.start();
      chat.failSend = true;
      await expectLater(ctrl.sendText('hola'), throwsA(anything));
      expect(ctrl.messages.where((m) => m.pending), isEmpty);
      expect(ctrl.messages.length, 2);
    });

    test('consultar trae solo lo nuevo, sin duplicar', () async {
      await ctrl.start();
      chat.server.add(msg(3));
      await ctrl.poll();
      await ctrl.poll();
      expect(ctrl.messages.map((m) => m.id), [1, 2, 3]);
    });

    test('un acuerdo nuevo recarga todo y trae el acuerdo', () async {
      await ctrl.start();
      chat.server.add(msg(4, type: 'agreement', sender: null, agreementId: 9));
      await ctrl.poll();
      expect(ctrl.agreements[9]?.code, 'CD-2026-0009');
    });

    test('para cotizar solo ofrece lotes con sacos', () async {
      await ctrl.start();
      final lots = await ctrl.lotsWithStock();
      expect(lots.map((l) => l.id), [3]);
    });

    test('en segundo plano no consulta', () async {
      final bg = ChatRoomController(
        chat: chat, agreements: agreements, lots: FakeLotRepository(), convId: 7, myUserId: 1, myRole: 'farmer', lang: 'es',
        isForeground: () => false, pollEvery: const Duration(hours: 1),
      );
      await bg.start();
      chat.server.add(msg(3));
      await bg.poll();
      expect(bg.messages.length, 2);
      bg.dispose();
    });
  });

  group('SessionProvider', () {
    test('entrar, cerrar sesión y sesión vencida', () async {
      final auth = FakeAuthRepository();
      final s = SessionProvider(auth);
      expect(s.loggedIn, isFalse);
      s.setTab(3);
      await s.login('lena@nordlicht.de', 'cafe1234');
      expect(s.loggedIn, isTrue);
      expect(s.isFarmer, isFalse);
      expect(s.lang, 'en');
      expect(s.tab, 0);
      expect(s.tr('Hola', 'Hi'), 'Hi');
      auth.expired!(); // el servidor respondió 401
      await Future<void>.delayed(Duration.zero);
      expect(s.loggedIn, isFalse);
      expect(auth.logouts, 1);
    });

    test('contraseña incorrecta: no entra y muestra el mensaje del servidor', () async {
      final s = SessionProvider(FakeAuthRepository());
      Object? error;
      try {
        await s.login('luz@finca.co', 'mala');
      } catch (e) {
        error = e;
        s.showError(e);
      }
      expect(s.loggedIn, isFalse);
      expect(error, isNotNull);
      expect(s.toast?.text, 'Correo o contraseña incorrectos');
    });
  });

  group('NotificationsProvider', () {
    test('la primera vez no muestra avisos viejos; luego avisa solo los nuevos', () async {
      final chat = FakeChatRepository();
      final repo = FakeNotificationRepository()..all = [notice(5), notice(6)];
      final alerts = FakeAlerts();
      final n = NotificationsProvider(chat, repo, alerts);

      chat.counts = const UnreadCounts(1, 2, 6);
      await n.start(1, 'es');
      expect(alerts.shown, isEmpty);
      expect(repo.lastAlerted, 6);
      expect(n.unreadMessages, 1);
      expect(n.unreadNotifications, 2);

      // nada nuevo: ni siquiera pide la lista
      final before = repo.newerCalls;
      await n.refresh();
      expect(repo.newerCalls, before);

      // llega uno nuevo
      repo.all.add(notice(7, type: 'bid_new'));
      chat.counts = const UnreadCounts(1, 3, 7);
      await n.refresh();
      expect(alerts.shown, ['Aviso 7 → /lot/3']);
      expect(repo.lastAlerted, 7);

      n.stop();
      expect(n.active, isFalse);
      expect(n.unreadNotifications, 0);
      n.dispose();
    });
  });
}
