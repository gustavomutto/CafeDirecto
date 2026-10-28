import '../entities/public_profile.dart';
import '../entities/user.dart';

/// Sesión y cuenta del usuario.
abstract class AuthRepository {
  /// Intenta recuperar la sesión guardada en el teléfono. Devuelve null si no hay.
  Future<Account?> restoreSession();
  Future<Account> login(String email, String password);
  Future<Account> register(Registration data);
  Future<void> forgotPassword(String email);
  Future<Account> resetPassword(String email, String code, String password);
  Future<void> logout();
  Future<void> deleteAccount(String password);

  Future<Account> me();
  Future<Account> updateAccount(AccountUpdate data);
  Future<Account> updateFarmProfile(FarmProfileUpdate data);
  Future<Account> updateBuyerProfile(BuyerProfileUpdate data);

  Future<PublicProfile> publicProfile(int userId);

  /// Se llama cuando el servidor rechaza el token (sesión cerrada en otro lado).
  set onSessionExpired(void Function()? callback);
}
