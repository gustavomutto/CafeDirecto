import 'lot.dart';
import 'user.dart';

/// Perfil público de otra persona (y sus lotes, si es caficultor).
class PublicProfile {
  final AppUser user;
  final FarmProfile? farm;
  final BuyerProfile? buyer;
  final List<Lot> lots;
  const PublicProfile(this.user, {this.farm, this.buyer, this.lots = const []});
}
