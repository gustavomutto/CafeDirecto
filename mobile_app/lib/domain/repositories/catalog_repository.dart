/// Catálogos que vienen del servidor (por ejemplo, las regiones cafeteras), para poder
/// cambiarlos sin publicar una versión nueva de la app.
abstract class CatalogRepository {
  /// La última lista guardada en el teléfono (o null si nunca se descargó).
  Future<List<String>?> cachedRegions();

  /// Descarga la lista actual del servidor y la guarda en el teléfono.
  Future<List<String>> fetchRegions();
}
