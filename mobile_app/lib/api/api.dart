// Cliente HTTP de la API de CaféDirecto.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class Api {
  String? token;
  final http.Client _http = http.Client();

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$apiUrl$path');
    return query == null ? u : u.replace(queryParameters: {...u.queryParameters, ...query});
  }

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map && body['error'] != null ? body['error'].toString() : 'Error ${r.statusCode}';
    throw ApiException(r.statusCode, msg);
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(const Duration(seconds: 25));
      return _decode(r);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(0, 'El servidor tardó mucho en responder. Revisa tu conexión.');
    } catch (_) {
      throw ApiException(0, 'Sin conexión con el servidor. Revisa tu internet.');
    }
  }

  Future<dynamic> get(String path, [Map<String, String>? query]) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => _http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) =>
      _send(() => _http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path), headers: _headers()));

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
    final req = http.MultipartRequest('POST', _uri('/images'))
      ..headers.addAll(_headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType('image', mime)));
    final body = await _send(() async => http.Response.fromStream(await _http.send(req)));
    return (body['id'] as num).toInt();
  }
}
