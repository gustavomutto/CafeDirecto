import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/catalog_repository.dart';
import '../datasources/remote/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  static const _regionsKey = 'cafedirecto-regions';
  final CatalogRemoteDataSource _remote;
  CatalogRepositoryImpl(this._remote);

  @override
  Future<List<String>?> cachedRegions() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_regionsKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> fetchRegions() async {
    final list = await _remote.regions();
    if (list.isNotEmpty) {
      try {
        await (await SharedPreferences.getInstance()).setStringList(_regionsKey, list);
      } catch (_) {}
    }
    return list;
  }
}
