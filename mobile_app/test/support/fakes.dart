// Repositorios falsos para probar la capa de presentación sin servidor.
import 'dart:typed_data';

import 'package:cafedirecto/core/network/api_exception.dart';
import 'package:cafedirecto/core/notifications/alert_service.dart';
import 'package:cafedirecto/domain/entities/entities.dart';
import 'package:cafedirecto/domain/repositories/agreement_repository.dart';
import 'package:cafedirecto/domain/repositories/auth_repository.dart';
import 'package:cafedirecto/domain/repositories/chat_repository.dart';
import 'package:cafedirecto/domain/repositories/lot_repository.dart';
import 'package:cafedirecto/domain/repositories/media_repository.dart';
import 'package:cafedirecto/domain/repositories/notification_repository.dart';

const farmer = AppUser(id: 1, role: 'farmer', name: 'Luz Marina', lang: 'es', email: 'luz@finca.co');
const buyer = AppUser(id: 2, role: 'buyer', name: 'Lena', lang: 'en', email: 'lena@nordlicht.de');

ChatMessage msg(int id, {String type = 'text', int? sender = 2, String text = 'hola', int? agreementId}) =>
    ChatMessage(id: id, conversationId: 7, senderId: sender, from: sender == 1 ? 'farmer' : 'buyer', type: type, text: text, agreementId: agreementId, createdAt: id);

Lot lot(int id, {int sacks = 10, int farmerId = 1}) => Lot(
      id: id,
      farmerId: farmerId,
      name: 'Lote $id',
      variety: 'Caturra',
      process: 'lavado',
      harvest: '',
      sacks: sacks,
      sca: 86,
      priceLb: 5,
      notes: const [],
      createdAt: 0,
      isNew: false,
      farm: const LotFarm(name: 'La Esperanza', region: 'Huila', municipality: '', producer: 'Luz', altitude: 1700, hectares: 3, rating: RatingSummary.none),
      certifications: const [],
    );

const sampleConversation = Conversation(
  id: 7,
  farmerId: 1,
  buyerId: 2,
  unread: 0,
  updatedAt: 0,
  other: ChatPeer(id: 2, role: 'buyer', name: 'Lena', sub: 'Nordlicht', lang: 'en'),
);

class FakeChatRepository implements ChatRepository {
  final List<ChatMessage> server = [msg(1), msg(2, sender: 1)];
  final List<int> readMarks = [];
  int nextId = 100;
  bool failSend = false;
  UnreadCounts counts = const UnreadCounts(0, 0, 0);
  int unreadCalls = 0;

  @override
  Future<Conversation> conversation(int id) async => conversation_;
  Conversation conversation_ = sampleConversation;

  @override
  Future<List<ChatMessage>> messages(int convId, {int after = 0}) async => server.where((m) => m.id > after).toList();

  @override
  Future<ChatMessage> sendText(int convId, String text, {required String lang, bool viaVoice = false}) async {
    if (failSend) throw const ApiException(0, 'Sin conexión con el servidor. Revisa tu internet.');
    final m = ChatMessage(id: nextId++, conversationId: convId, senderId: 1, from: 'farmer', type: 'text', text: text, lang: lang, createdAt: 0);
    server.add(m);
    return m;
  }

  @override
  Future<void> markRead(int convId, int lastId) async => readMarks.add(lastId);

  @override
  Future<UnreadCounts> unread() async {
    unreadCalls++;
    return counts;
  }

  @override
  Future<ChatMessage> sendPhoto(int convId, int photoId, {String text = '', required String lang}) async {
    final m = ChatMessage(id: nextId++, conversationId: convId, senderId: 1, type: 'photo', photo: '/images/$photoId?s=x', createdAt: 0);
    server.add(m);
    return m;
  }

  @override
  Future<void> quoteAction(int messageId, String action, {double? priceLb, int? sacks}) async {}

  @override
  Future<ChatMessage> sendQuote(int convId, {required int lotId, required double priceLb, required int sacks, required String incoterm}) async =>
      msg(nextId++, type: 'quote');

  @override
  Future<List<Conversation>> conversations() async => [conversation_];

  @override
  Future<Conversation> start(int userId, {int? lotId}) async => conversation_;
}

class FakeAgreementRepository implements AgreementRepository {
  int gets = 0;
  @override
  Future<Agreement> get(int id) async {
    gets++;
    return Agreement(
      id: id, code: 'CD-2026-000$id', farmerId: 1, buyerId: 2, lotName: 'Lote', variety: 'Caturra', process: 'lavado', incoterm: 'FOB',
      sca: 86, priceLb: 5, sacks: 10, status: 1, createdAt: 0, history: const [], farmerName: 'Luz', farmName: 'La Esperanza',
      farmRegion: 'Huila', buyerName: 'Lena', buyerCompany: 'Nordlicht', buyerCity: '', buyerCountry: 'DE',
    );
  }

  @override
  Future<List<Agreement>> list() async => [];
  @override
  Future<Agreement> advance(int id) => get(id);
  @override
  Future<Agreement> rate(int id, {required int stars, required List<String> tags, required String comment}) => get(id);
}

class FakeLotRepository implements LotRepository {
  List<Lot> lots = [lot(3), lot(4, sacks: 0)];
  @override
  Future<List<Lot>> byFarmer(int farmerId) async => lots.where((l) => l.farmerId == farmerId).toList();
  @override
  Future<List<Lot>> search(LotQuery query) async => lots;
  @override
  Future<Lot> get(int id) async => lots.firstWhere((l) => l.id == id);
  @override
  Future<Lot> create(LotInput input) async => lots.first;
  @override
  Future<Lot> update(int id, LotInput input) async => lots.first;
  @override
  Future<void> remove(int id) async {}
  @override
  Future<List<InterestedBuyer>> interestedBuyers(int lotId) async => [];
}

class FakeAuthRepository implements AuthRepository {
  Account? stored;
  void Function()? expired;
  int logouts = 0;

  @override
  set onSessionExpired(void Function()? callback) => expired = callback;

  @override
  Future<Account?> restoreSession() async => stored;

  @override
  Future<Account> login(String email, String password) async {
    if (password != 'cafe1234') throw const ApiException(401, 'Correo o contraseña incorrectos');
    return stored = Account(email.startsWith('lena') ? buyer : farmer);
  }

  @override
  Future<void> logout() async {
    logouts++;
    stored = null;
  }

  @override
  Future<Account> me() async => stored!;
  @override
  Future<Account> register(Registration data) async => stored = Account(data.role == 'buyer' ? buyer : farmer);
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<Account> resetPassword(String email, String code, String password) async => stored = const Account(farmer);
  @override
  Future<void> deleteAccount(String password) async {}
  @override
  Future<Account> updateAccount(AccountUpdate data) async => stored!;
  bool failLanguage = false;
  @override
  Future<Account> setLanguage(String lang) async {
    if (failLanguage) throw const ApiException(0, 'Sin conexión con el servidor. Revisa tu internet.');
    return stored = stored!.withLang(lang);
  }
  @override
  Future<Account> updateFarmProfile(FarmProfileUpdate data) async => stored!;
  @override
  Future<Account> updateBuyerProfile(BuyerProfileUpdate data) async => stored!;
  @override
  Future<PublicProfile> publicProfile(int userId) async => const PublicProfile(farmer);
}

AppNotification notice(int id, {String type = 'lot_interest'}) => AppNotification(
      id: id,
      type: type,
      title: Bi('Aviso $id', 'Notice $id'),
      body: const Bi('cuerpo', 'body'),
      data: const {'lotId': 3, 'userId': 2},
      read: false,
      createdAt: id,
    );

class FakeNotificationRepository implements NotificationRepository {
  List<AppNotification> all = [];
  int lastAlerted = 0;
  int newerCalls = 0;

  @override
  Future<NotificationPage> latest({int limit = 50}) async {
    final sorted = [...all]..sort((a, b) => b.id.compareTo(a.id));
    return NotificationPage(sorted.take(limit).toList(), all.where((n) => !n.read).length);
  }

  @override
  Future<List<AppNotification>> newerThan(int afterId) async {
    newerCalls++;
    return all.where((n) => n.id > afterId).toList();
  }

  @override
  Future<int> markRead(List<int> ids) async => all.where((n) => !n.read && !ids.contains(n.id)).length;
  @override
  Future<int> markAllRead() async => 0;
  @override
  Future<int> lastAlertedId() async => lastAlerted;
  @override
  Future<void> saveLastAlertedId(int id) async => lastAlerted = id;
}

class FakeAlerts implements AlertService {
  final List<String> shown = [];
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> show({required int id, required String title, required String body, String? route}) async => shown.add('$title → $route');
}

class FakeMediaRepository implements MediaRepository {
  @override
  Future<int> upload(Uint8List bytes, String filename) async => 1;
}
