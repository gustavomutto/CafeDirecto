// Cliente HTTP de la API de CaféDirecto: arma las peticiones, agrega el token, decodifica el JSON
// y convierte cualquier falla en un ApiException con un mensaje claro para la persona.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/env.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';

export 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = apiUrl}) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  /// Token de sesión (JWT). Lo pone el repositorio de autenticación.
  String? token;

  /// Se llama cuando el servidor responde 401 (sesión vencida o cerrada en otro teléfono).
  void Function()? onUnauthorized;

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$baseUrl$path');
    return query == null || query.isEmpty ? u : u.replace(queryParameters: {...u.queryParameters, ...query});
  }

  dynamic _decode(String method, Uri uri, http.Response r, Stopwatch sw) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }
    AppLogger.d('$method ${uri.path} → ${r.statusCode} (${sw.elapsedMilliseconds} ms)', tag: 'API');
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map && body['error'] != null ? body['error'].toString() : 'Error ${r.statusCode}';
    if (r.statusCode == 401 && token != null) onUnauthorized?.call();
    if (r.statusCode >= 500) AppLogger.e('$method ${uri.path} falló', tag: 'API', error: msg);
    throw ApiException(r.statusCode, msg);
  }

  Future<dynamic> _send(String method, Uri uri, Future<http.Response> Function() call) async {
    final sw = Stopwatch()..start();
    try {
      final r = await call().timeout(const Duration(seconds: 25));
      return _decode(method, uri, r, sw);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      AppLogger.w('$method ${uri.path} tardó demasiado', tag: 'API');
      throw const ApiException(0, 'El servidor tardó mucho en responder. Revisa tu conexión.');
    } catch (e) {
      AppLogger.w('$method ${uri.path} sin conexión: $e', tag: 'API');
      throw const ApiException(0, 'Sin conexión con el servidor. Revisa tu internet.');
    }
  }

  Future<dynamic> get(String path, [Map<String, String>? query]) {
    final uri = _uri(path, query);
    return _send('GET', uri, () => _http.get(uri, headers: _headers()));
  }

  Future<dynamic> post(String path, [Object? body]) {
    final uri = _uri(path);
    return _send('POST', uri, () => _http.post(uri, headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> put(String path, [Object? body]) {
    final uri = _uri(path);
    return _send('PUT', uri, () => _http.put(uri, headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> delete(String path, [Object? body]) {
    final uri = _uri(path);
    return _send('DELETE', uri, () => _http.delete(uri, headers: _headers(), body: body == null ? null : jsonEncode(body)));
  }

  /// Respuesta que debe ser un objeto JSON.
  Future<Map<String, dynamic>> getMap(String path, [Map<String, String>? query]) async => _asMap(await get(path, query));
  Future<Map<String, dynamic>> postMap(String path, [Object? body]) async => _asMap(await post(path, body));
  Future<Map<String, dynamic>> putMap(String path, [Object? body]) async => _asMap(await put(path, body));

  /// Respuesta que debe ser una lista de objetos JSON.
  Future<List<Map<String, dynamic>>> getList(String path, [Map<String, String>? query]) async {
    final v = await get(path, query);
    if (v is! List) throw const ApiException(500, 'Respuesta inesperada del servidor');
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is! Map) throw const ApiException(500, 'Respuesta inesperada del servidor');
    return Map<String, dynamic>.from(v);
  }

  /// Sube una imagen y devuelve su id.
  Future<int> uploadImage(Uint8List bytes, String filename) async {
    final lower = filename.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.webp')
            ? 'webp'
            : lower.endsWith('.gif')
                ? 'gif'
                : 'jpeg';
    final uri = _uri('/images');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType('image', mime)));
    final body = await _send('POST', uri, () async => http.Response.fromStream(await _http.send(req)));
    return ((body as Map)['id'] as num).toInt();
  }
}
