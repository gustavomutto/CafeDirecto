import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/session_local_datasource.dart';
import '../datasources/remote/account_remote_datasource.dart';
import '../dtos/user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final AccountRemoteDataSource _remote;
  final SessionLocalDataSource _local;

  AuthRepositoryImpl(this._api, this._remote, this._local);

  @override
  set onSessionExpired(void Function()? callback) => _api.onUnauthorized = callback;

  Future<Account> _startSession(String token) async {
    _api.token = token;
    await _local.saveToken(token);
    return (await _remote.me()).toEntity();
  }

  @override
  Future<Account?> restoreSession() async {
    final token = await _local.readToken();
    if (token == null) return null;
    _api.token = token;
    try {
      final account = (await _remote.me()).toEntity();
      AppLogger.i('Sesión restaurada para ${account.user.email}', tag: 'Auth');
      return account;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        AppLogger.i('El token guardado ya no es válido', tag: 'Auth');
        await logout();
      }
      // Sin internet al abrir: se queda sin usuario y la pantalla de inicio lo informa.
      return null;
    }
  }

  @override
  Future<Account> login(String email, String password) async => _startSession((await _remote.login(email, password)).token);

  @override
  Future<Account> register(Registration data) async => _startSession((await _remote.register(RegistrationDto.toJson(data))).token);

  @override
  Future<void> forgotPassword(String email) => _remote.forgotPassword(email);

  @override
  Future<Account> resetPassword(String email, String code, String password) async =>
      _startSession((await _remote.resetPassword(email, code, password)).token);

  @override
  Future<void> logout() async {
    _api.token = null;
    await _local.clear();
  }

  @override
  Future<void> deleteAccount(String password) => _remote.deleteAccount(password);

  @override
  Future<Account> me() async => (await _remote.me()).toEntity();

  @override
  Future<Account> updateAccount(AccountUpdate data) async => (await _remote.updateAccount(AccountUpdateDto.toJson(data))).toEntity();

  @override
  Future<Account> updateFarmProfile(FarmProfileUpdate data) async => (await _remote.updateProfile(FarmProfileUpdateDto.toJson(data))).toEntity();

  @override
  Future<Account> updateBuyerProfile(BuyerProfileUpdate data) async => (await _remote.updateProfile(BuyerProfileUpdateDto.toJson(data))).toEntity();

  @override
  Future<PublicProfile> publicProfile(int userId) async {
    final r = await _remote.publicProfile(userId);
    final account = r.account.toEntity();
    return PublicProfile(account.user, farm: account.farm, buyer: account.buyer, lots: r.lots.map((l) => l.toEntity()).toList());
  }
}
