/// Error de una llamada a la API. `status` es 0 cuando no hubo conexión.
class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);

  bool get isUnauthorized => status == 401;
  bool get isOffline => status == 0;

  @override
  String toString() => message;
}
