import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateException implements Exception {
  final String message;
  const ExchangeRateException(this.message);

  @override
  String toString() => message;
}

class ExchangeRateSnapshot {
  final Map<String, double> rates;
  final DateTime updatedAt;

  const ExchangeRateSnapshot({required this.rates, required this.updatedAt});
}

class LatinAmericanCountry {
  final String code;
  final String currency;
  final String currencySpanish;
  final String currencyEnglish;
  final String spanish;
  final String english;

  const LatinAmericanCountry({
    required this.code,
    required this.currency,
    required this.currencySpanish,
    required this.currencyEnglish,
    required this.spanish,
    required this.english,
  });

  String name(String lang) => lang == 'es' ? spanish : english;
  String currencyName(String lang) =>
      lang == 'es' ? currencySpanish : currencyEnglish;
}

const latinAmericanCountries = [
  LatinAmericanCountry(
      code: 'AR',
      currency: 'ARS',
      currencySpanish: 'peso argentino',
      currencyEnglish: 'Argentine peso',
      spanish: 'Argentina',
      english: 'Argentina'),
  LatinAmericanCountry(
      code: 'BO',
      currency: 'BOB',
      currencySpanish: 'boliviano',
      currencyEnglish: 'Bolivian boliviano',
      spanish: 'Bolivia',
      english: 'Bolivia'),
  LatinAmericanCountry(
      code: 'BR',
      currency: 'BRL',
      currencySpanish: 'real brasileño',
      currencyEnglish: 'Brazilian real',
      spanish: 'Brasil',
      english: 'Brazil'),
  LatinAmericanCountry(
      code: 'CL',
      currency: 'CLP',
      currencySpanish: 'peso chileno',
      currencyEnglish: 'Chilean peso',
      spanish: 'Chile',
      english: 'Chile'),
  LatinAmericanCountry(
      code: 'CO',
      currency: 'COP',
      currencySpanish: 'peso colombiano',
      currencyEnglish: 'Colombian peso',
      spanish: 'Colombia',
      english: 'Colombia'),
  LatinAmericanCountry(
      code: 'CR',
      currency: 'CRC',
      currencySpanish: 'colón costarricense',
      currencyEnglish: 'Costa Rican colón',
      spanish: 'Costa Rica',
      english: 'Costa Rica'),
  LatinAmericanCountry(
      code: 'CU',
      currency: 'CUP',
      currencySpanish: 'peso cubano',
      currencyEnglish: 'Cuban peso',
      spanish: 'Cuba',
      english: 'Cuba'),
  LatinAmericanCountry(
      code: 'DO',
      currency: 'DOP',
      currencySpanish: 'peso dominicano',
      currencyEnglish: 'Dominican peso',
      spanish: 'República Dominicana',
      english: 'Dominican Republic'),
  LatinAmericanCountry(
      code: 'EC',
      currency: 'USD',
      currencySpanish: 'dólar estadounidense',
      currencyEnglish: 'United States dollar',
      spanish: 'Ecuador',
      english: 'Ecuador'),
  LatinAmericanCountry(
      code: 'SV',
      currency: 'USD',
      currencySpanish: 'dólar estadounidense',
      currencyEnglish: 'United States dollar',
      spanish: 'El Salvador',
      english: 'El Salvador'),
  LatinAmericanCountry(
      code: 'GT',
      currency: 'GTQ',
      currencySpanish: 'quetzal guatemalteco',
      currencyEnglish: 'Guatemalan quetzal',
      spanish: 'Guatemala',
      english: 'Guatemala'),
  LatinAmericanCountry(
      code: 'HT',
      currency: 'HTG',
      currencySpanish: 'gourde haitiano',
      currencyEnglish: 'Haitian gourde',
      spanish: 'Haití',
      english: 'Haiti'),
  LatinAmericanCountry(
      code: 'HN',
      currency: 'HNL',
      currencySpanish: 'lempira hondureño',
      currencyEnglish: 'Honduran lempira',
      spanish: 'Honduras',
      english: 'Honduras'),
  LatinAmericanCountry(
      code: 'MX',
      currency: 'MXN',
      currencySpanish: 'peso mexicano',
      currencyEnglish: 'Mexican peso',
      spanish: 'México',
      english: 'Mexico'),
  LatinAmericanCountry(
      code: 'NI',
      currency: 'NIO',
      currencySpanish: 'córdoba nicaragüense',
      currencyEnglish: 'Nicaraguan córdoba',
      spanish: 'Nicaragua',
      english: 'Nicaragua'),
  LatinAmericanCountry(
      code: 'PA',
      currency: 'PAB',
      currencySpanish: 'balboa panameño',
      currencyEnglish: 'Panamanian balboa',
      spanish: 'Panamá',
      english: 'Panama'),
  LatinAmericanCountry(
      code: 'PY',
      currency: 'PYG',
      currencySpanish: 'guaraní paraguayo',
      currencyEnglish: 'Paraguayan guaraní',
      spanish: 'Paraguay',
      english: 'Paraguay'),
  LatinAmericanCountry(
      code: 'PE',
      currency: 'PEN',
      currencySpanish: 'sol peruano',
      currencyEnglish: 'Peruvian sol',
      spanish: 'Perú',
      english: 'Peru'),
  LatinAmericanCountry(
      code: 'UY',
      currency: 'UYU',
      currencySpanish: 'peso uruguayo',
      currencyEnglish: 'Uruguayan peso',
      spanish: 'Uruguay',
      english: 'Uruguay'),
  LatinAmericanCountry(
      code: 'VE',
      currency: 'VES',
      currencySpanish: 'bolívar venezolano',
      currencyEnglish: 'Venezuelan bolívar',
      spanish: 'Venezuela',
      english: 'Venezuela'),
];

Future<ExchangeRateSnapshot>? _cachedRates;
DateTime? _cachedAt;

Future<ExchangeRateSnapshot> loadExchangeRates({bool refresh = false}) async {
  final fetchedAt = _cachedAt;
  if (!refresh &&
      _cachedRates != null &&
      fetchedAt != null &&
      DateTime.now().difference(fetchedAt) < const Duration(minutes: 5)) {
    return _cachedRates!;
  }

  final request = _fetchExchangeRates();
  _cachedRates = request;
  _cachedAt = DateTime.now();
  try {
    return await request;
  } catch (_) {
    if (identical(_cachedRates, request)) {
      _cachedRates = null;
      _cachedAt = null;
    }
    rethrow;
  }
}

Future<ExchangeRateSnapshot> _fetchExchangeRates() async {
  final uri = Uri.https('open.er-api.com', '/v6/latest/USD');
  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw ExchangeRateException(
        'El servicio de cambio respondió ${response.statusCode}.');
  }

  return parseExchangeRateResponse(response.body);
}

ExchangeRateSnapshot parseExchangeRateResponse(String body) {
  final payload = jsonDecode(body);
  if (payload is! Map || payload['result'] != 'success') {
    throw const FormatException(
        'La fuente de cambio no devolvió una respuesta válida.');
  }
  final rawRates = payload['rates'];
  if (rawRates is! Map) {
    throw const FormatException('La fuente no incluyó las tasas de cambio.');
  }
  final updatedUnix = payload['time_last_update_unix'];
  final updatedAt = updatedUnix is num
      ? DateTime.fromMillisecondsSinceEpoch(
          updatedUnix.toInt() * 1000,
          isUtc: true,
        )
      : DateTime.tryParse(payload['time_last_update_utc']?.toString() ?? '');
  if (updatedAt == null) {
    throw const FormatException(
        'La fuente no incluyó la fecha de actualización.');
  }

  final rates = <String, double>{};
  for (final country in latinAmericanCountries) {
    final value = rawRates[country.currency];
    if (value is num && value > 0) rates[country.currency] = value.toDouble();
  }
  if (rates.isEmpty || !rates.containsKey('COP')) {
    throw const FormatException(
        'La fuente no incluyó cotizaciones para América Latina.');
  }

  return ExchangeRateSnapshot(rates: rates, updatedAt: updatedAt);
}
