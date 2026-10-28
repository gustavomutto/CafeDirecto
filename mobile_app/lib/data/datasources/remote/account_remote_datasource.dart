// Autenticación, mi cuenta y perfiles públicos.
import '../../../core/network/api_client.dart';
import '../../dtos/lot_dto.dart';
import '../../dtos/user_dto.dart';

class AccountRemoteDataSource {
  final ApiClient _api;
  AccountRemoteDataSource(this._api);

  Future<AuthResponseDto> login(String email, String password) async =>
      AuthResponseDto.fromJson(await _api.postMap('/auth/login', {'email': email, 'password': password}));

  Future<AuthResponseDto> register(Map<String, dynamic> body) async => AuthResponseDto.fromJson(await _api.postMap('/auth/register', body));

  Future<void> forgotPassword(String email) => _api.post('/auth/forgot', {'email': email});

  Future<AuthResponseDto> resetPassword(String email, String code, String password) async =>
      AuthResponseDto.fromJson(await _api.postMap('/auth/reset', {'email': email, 'code': code, 'password': password}));

  Future<AccountDto> me() async => AccountDto.fromJson(await _api.getMap('/me'));

  Future<AccountDto> updateAccount(Map<String, dynamic> body) async => AccountDto.fromJson(await _api.putMap('/me', body));

  Future<AccountDto> updateProfile(Map<String, dynamic> body) async => AccountDto.fromJson(await _api.putMap('/me/profile', body));

  Future<void> deleteAccount(String password) => _api.delete('/me', {'password': password});

  /// Perfil público: { user, profile, lots? }
  Future<({AccountDto account, List<LotDto> lots})> publicProfile(int userId) async {
    final j = await _api.getMap('/users/$userId');
    final lots = (j['lots'] is List ? j['lots'] as List : const []).whereType<Map>().map((e) => LotDto.fromJson(Map<String, dynamic>.from(e))).toList();
    return (account: AccountDto.fromJson(j), lots: lots);
  }

}
