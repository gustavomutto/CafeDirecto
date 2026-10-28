// Acuerdos.
import '../../../core/network/api_client.dart';
import '../../dtos/agreement_dto.dart';

class AgreementRemoteDataSource {
  final ApiClient _api;
  AgreementRemoteDataSource(this._api);

  Future<List<AgreementDto>> list() async => (await _api.getList('/agreements')).map(AgreementDto.fromJson).toList();

  Future<AgreementDto> get(int id) async => AgreementDto.fromJson(await _api.getMap('/agreements/$id'));

  Future<AgreementDto> advance(int id) async => AgreementDto.fromJson(await _api.postMap('/agreements/$id/advance'));

  Future<AgreementDto> rate(int id, Map<String, dynamic> body) async => AgreementDto.fromJson(await _api.postMap('/agreements/$id/rate', body));
}
