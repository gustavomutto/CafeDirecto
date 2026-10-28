// Utilidades para las direcciones de las fotos que entrega el servidor ('/images/12?s=FIRMA').

final _imageId = RegExp(r'/images/(\d+)');

/// Id numérico de una foto a partir de su dirección (o null si no es una foto del servidor).
int? imageIdFromUrl(String? url) {
  if (url == null) return null;
  final m = _imageId.firstMatch(url);
  return m == null ? null : int.tryParse(m.group(1)!);
}
