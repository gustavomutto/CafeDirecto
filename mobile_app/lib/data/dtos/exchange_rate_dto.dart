// DTO de la respuesta de ExchangeRate-API (open.er-api.com/v6/latest/USD).
import 'dart:convert';

import '../../core/constants/countries.dart';
import '../../domain/entities/exchange_rate.dart';

class ExchangeRateException implements Exception {
  final String message;
  const ExchangeRateException(this.message);

  @override
  String toString() => message;
}

/// Lee el JSON de la fuente y deja solo las monedas de América Latina.
ExchangeRateSnapshot parseExchangeRateResponse(String body) {
  final payload = jsonDecode(body);
  if (payload is! Map || payload['result'] != 'success') {
    throw const FormatException('La fuente de cambio no devolvió una respuesta válida.');
  }
  final rawRates = payload['rates'];
  if (rawRates is! Map) {
    throw const FormatException('La fuente no incluyó las tasas de cambio.');
  }
  final updatedUnix = payload['time_last_update_unix'];
  final updatedAt = updatedUnix is num
      ? DateTime.fromMillisecondsSinceEpoch(updatedUnix.toInt() * 1000, isUtc: true)
      : DateTime.tryParse(payload['time_last_update_utc']?.toString() ?? '');
  if (updatedAt == null) {
    throw const FormatException('La fuente no incluyó la fecha de actualización.');
  }

  final rates = <String, double>{};
  for (final country in latinAmericanCountries) {
    final value = rawRates[country.currency];
    if (value is num && value > 0) rates[country.currency] = value.toDouble();
  }
  if (rates.isEmpty || !rates.containsKey('COP')) {
    throw const FormatException('La fuente no incluyó cotizaciones para América Latina.');
  }

  return ExchangeRateSnapshot(rates: rates, updatedAt: updatedAt);
}
