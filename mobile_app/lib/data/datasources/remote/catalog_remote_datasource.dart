// Catálogos del servidor (GET /catalog).
import '../../../core/network/api_client.dart';

class CatalogRemoteDataSource {
  final ApiClient _api;
  CatalogRemoteDataSource(this._api);

  Future<List<String>> regions() async {
    final m = await _api.getMap('/catalog');
    final list = m['regions'];
    return list is List ? list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList() : <String>[];
  }
}
