import '../entities/agreement.dart';

abstract class AgreementRepository {
  Future<List<Agreement>> list();
  Future<Agreement> get(int id);
  Future<Agreement> advance(int id);
  Future<Agreement> rate(int id, {required int stars, required List<String> tags, required String comment});
}
