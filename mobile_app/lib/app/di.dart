// Inyección de dependencias: aquí se arma toda la app de abajo hacia arriba
//   ApiClient → DataSources → Repositories → Providers
// Las pantallas solo conocen los repositorios (interfaces de dominio) y los providers.
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/network/api_client.dart';
import '../core/notifications/local_notifications.dart';
import '../data/datasources/local/appearance_local_datasource.dart';
import '../data/datasources/local/session_local_datasource.dart';
import '../data/datasources/remote/account_remote_datasource.dart';
import '../data/datasources/remote/agreement_remote_datasource.dart';
import '../data/datasources/remote/auction_remote_datasource.dart';
import '../data/datasources/remote/chat_remote_datasource.dart';
import '../data/datasources/remote/exchange_rate_remote_datasource.dart';
import '../data/datasources/remote/lot_remote_datasource.dart';
import '../data/datasources/remote/market_remote_datasource.dart';
import '../data/datasources/remote/media_remote_datasource.dart';
import '../data/datasources/remote/notification_remote_datasource.dart';
import '../data/repositories/agreement_repository_impl.dart';
import '../data/repositories/appearance_repository_impl.dart';
import '../data/repositories/auction_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../data/repositories/lot_repository_impl.dart';
import '../data/repositories/market_repository_impl.dart';
import '../data/repositories/media_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/agreement_repository.dart';
import '../domain/repositories/auction_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/lot_repository.dart';
import '../domain/repositories/market_repository.dart';
import '../domain/repositories/media_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../presentation/providers/appearance_provider.dart';
import '../presentation/providers/market_provider.dart';
import '../presentation/providers/notifications_provider.dart';
import '../presentation/providers/session_provider.dart';

class AppDependencies {
  final AuthRepository auth;
  final LotRepository lots;
  final ChatRepository chat;
  final AgreementRepository agreements;
  final AuctionRepository auctions;
  final NotificationRepository notifications;
  final MarketRepository market;
  final MediaRepository media;

  final SessionProvider session;
  final NotificationsProvider notificationsProvider;
  final MarketProvider marketProvider;
  final AppearanceProvider appearance;

  AppDependencies._({
    required this.auth,
    required this.lots,
    required this.chat,
    required this.agreements,
    required this.auctions,
    required this.notifications,
    required this.market,
    required this.media,
    required this.session,
    required this.notificationsProvider,
    required this.marketProvider,
    required this.appearance,
  });

  factory AppDependencies.create() {
    final api = ApiClient();
    final local = SessionLocalDataSource();

    final auth = AuthRepositoryImpl(api, AccountRemoteDataSource(api), local);
    final chat = ChatRepositoryImpl(ChatRemoteDataSource(api));
    final notifications = NotificationRepositoryImpl(NotificationRemoteDataSource(api), local);
    final market = MarketRepositoryImpl(MarketRemoteDataSource(api), ExchangeRateRemoteDataSource());

    return AppDependencies._(
      auth: auth,
      lots: LotRepositoryImpl(LotRemoteDataSource(api)),
      chat: chat,
      agreements: AgreementRepositoryImpl(AgreementRemoteDataSource(api)),
      auctions: AuctionRepositoryImpl(AuctionRemoteDataSource(api)),
      notifications: notifications,
      market: market,
      media: MediaRepositoryImpl(MediaRemoteDataSource(api)),
      session: SessionProvider(auth),
      notificationsProvider: NotificationsProvider(chat, notifications, LocalNotifications.instance),
      marketProvider: MarketProvider(market),
      appearance: AppearanceProvider(AppearanceRepositoryImpl(AppearanceLocalDataSource())),
    );
  }

  /// Lo que se pone en el árbol de widgets con MultiProvider.
  List<SingleChildWidget> get providers => [
        Provider<AuthRepository>.value(value: auth),
        Provider<LotRepository>.value(value: lots),
        Provider<ChatRepository>.value(value: chat),
        Provider<AgreementRepository>.value(value: agreements),
        Provider<AuctionRepository>.value(value: auctions),
        Provider<NotificationRepository>.value(value: notifications),
        Provider<MarketRepository>.value(value: market),
        Provider<MediaRepository>.value(value: media),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<NotificationsProvider>.value(value: notificationsProvider),
        ChangeNotifierProvider<MarketProvider>.value(value: marketProvider),
        ChangeNotifierProvider<AppearanceProvider>.value(value: appearance),
      ];

  /// Conecta la sesión con las notificaciones: al entrar empieza a consultar, al salir se detiene.
  void wireSession() {
    void sync() {
      final u = session.user;
      if (u == null) {
        if (notificationsProvider.active) notificationsProvider.stop();
      } else {
        notificationsProvider.start(u.id, u.lang);
      }
    }

    session.addListener(sync);
    sync();
  }
}
