import '../../domain/entities/agreement.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../datasources/remote/agreement_remote_datasource.dart';

class AgreementRepositoryImpl implements AgreementRepository {
  final AgreementRemoteDataSource _remote;
  AgreementRepositoryImpl(this._remote);

  @override
  Future<List<Agreement>> list() async => (await _remote.list()).map((d) => d.toEntity()).toList();

  @override
  Future<Agreement> get(int id) async => (await _remote.get(id)).toEntity();

  @override
  Future<Agreement> advance(int id) async => (await _remote.advance(id)).toEntity();

  @override
  Future<Agreement> rate(int id, {required int stars, required List<String> tags, required String comment}) async =>
      (await _remote.rate(id, {'stars': stars, 'tags': tags, 'comment': comment})).toEntity();
}
