// Fuente remota de tasas de cambio: ExchangeRate-API (gratuita, se actualiza una vez al día).
import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../dtos/exchange_rate_dto.dart';

class ExchangeRateRemoteDataSource {
  final http.Client _http;
  ExchangeRateRemoteDataSource([http.Client? client]) : _http = client ?? http.Client();

  Future<ExchangeRateSnapshot> fetchLatest() async {
    final uri = Uri.https('open.er-api.com', '/v6/latest/USD');
    AppLogger.d('GET $uri', tag: 'FX');
    final response = await _http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ExchangeRateException('El servicio de cambio respondió ${response.statusCode}.');
    }
    return parseExchangeRateResponse(response.body);
  }
}
