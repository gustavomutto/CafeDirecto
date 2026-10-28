// Rutas de la app: traduce una ruta como '/lot/12' en su pantalla.
import 'package:flutter/material.dart';

import '../presentation/screens/auctions/auction_detail_screen.dart';
import '../presentation/screens/auctions/auctions_screen.dart';
import '../presentation/screens/auctions/create_auction_screen.dart';
import '../presentation/screens/chat/chat_room_screen.dart';
import '../presentation/screens/home/root_gate.dart';
import '../presentation/screens/learn/fees_screen.dart';
import '../presentation/screens/learn/learn_screens.dart';
import '../presentation/screens/lot/interested_buyers_screen.dart';
import '../presentation/screens/lot/lot_detail_screen.dart';
import '../presentation/screens/lot/publish_lot_screen.dart';
import '../presentation/screens/market/market_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/orders/order_detail_screen.dart';
import '../presentation/screens/orders/rate_agreement_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/privacy_screen.dart';
import '../presentation/screens/profile/user_profile_screen.dart';

int _id(List<String> segs, [int i = 1]) => segs.length > i ? int.tryParse(segs[i]) ?? -1 : -1;

Route<dynamic> generateRoute(RouteSettings settings) {
  final segs = Uri.parse(settings.name ?? '/').pathSegments;
  final sub = segs.length > 2 ? segs[2] : '';
  final Widget page = switch (segs.isEmpty ? '' : segs[0]) {
    'lot' when sub == 'auction' => CreateAuctionScreen(lotId: _id(segs)),
    'lot' when sub == 'interest' => InterestedBuyersScreen(lotId: _id(segs)),
    'lot' => LotDetailScreen(lotId: _id(segs)),
    'farm' || 'buyer' || 'user' => UserProfileScreen(userId: _id(segs)),
    'publish' => PublishLotScreen(lotId: segs.length > 1 ? _id(segs) : null),
    'chat' => ChatRoomScreen(convId: _id(segs)),
    'orders' => OrderDetailScreen(agreementId: _id(segs)),
    'rate' => RateAgreementScreen(agreementId: _id(segs)),
    'learn' => LearnDetailScreen(itemId: segs.length > 1 ? segs[1] : ''),
    'fees' => const FeesScreen(),
    'market' => const MarketScreen(),
    'auctions' => const AuctionsScreen(),
    'auction' => AuctionDetailScreen(auctionId: _id(segs)),
    'notifications' => const NotificationsScreen(),
    'edit-profile' => const EditProfileScreen(),
    'privacy' => const PrivacyScreen(),
    _ => const RootGate(),
  };
  return MaterialPageRoute(settings: settings, builder: (_) => page);
}
