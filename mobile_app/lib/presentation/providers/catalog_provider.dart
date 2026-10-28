// Regiones cafeteras que muestran el registro, "Editar mi finca" y los filtros de Explorar.
// Vienen del servidor (así una región nueva aparece al abrir la app, sin reinstalar).
// Mientras tanto, o sin internet, se usa la última lista guardada o la que trae la app.
import 'package:flutter/foundation.dart';

import '../../core/constants/catalog.dart' as fallback;
import '../../core/logging/app_logger.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repo);
  final CatalogRepository _repo;

  List<String> _regions = fallback.regions;
  List<String> get regions => _regions;

  void _set(List<String>? list) {
    if (list == null || list.isEmpty || listEquals(list, _regions)) return;
    _regions = List.unmodifiable(list);
    notifyListeners();
  }

  /// Al abrir la app: primero lo guardado (instantáneo), luego lo del servidor.
  Future<void> load() async {
    _set(await _repo.cachedRegions());
    try {
      _set(await _repo.fetchRegions());
    } catch (e) {
      AppLogger.w('No se pudieron descargar las regiones; se usa la lista guardada: $e', tag: 'Catálogo');
    }
  }
}
