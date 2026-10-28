// Pruebas rápidas de la lógica (formato, conversiones y traducción simulada).
// Ejecutar con:  flutter test
import 'package:cafedirecto/models/models.dart';
import 'package:cafedirecto/utils/format.dart';
import 'package:cafedirecto/api/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formato de números y monedas', () {
    expect(fmtNum(1750, 'en'), '1,750');
    expect(fmtNum(1750, 'es'), '1.750');
    expect(fmtUSD(5.9, 'es'), 'US\$ 5,90');
    expect(fmtUSD(5.9, 'en'), 'US\$ 5.90');
    expect(fmtCOP(3200000), '\$ 3.200.000');
  });

  test('sacos a libras y total de una cotización', () {
    // 20 sacos × 70 kg × 2,20462 lb/kg × US$ 5,45
    expect(quoteTotal(5.45, 20).round(), 16821);
  });

  test('conversión de precio por carga a USD/lb', () {
    expect(copCargaToUsdLb(3200000), closeTo(3.95, 0.05));
  });

  test('lectura de un mensaje de la API', () {
    final m = ChatMessage.fromJson({
      'id': 5,
      'conversationId': 1,
      'senderId': 2,
      'from': 'buyer',
      'type': 'text',
      'text': 'Hello',
      'lang': 'en',
      'translation': 'Hola',
      'createdAt': 1700000000000,
    });
    expect(m.translation, 'Hola');
    expect(m.from, 'buyer');
  });

  test('texto bilingüe usa el otro idioma si falta uno', () {
    expect(const Bi('', 'Hi').of('es'), 'Hi');
  });

  test('el selector incluye los países latinoamericanos y sus monedas', () {
    final countriesByCode = {
      for (final country in latinAmericanCountries) country.code: country
    };
    expect(countriesByCode.length, 20);
    expect(countriesByCode['CO']?.currency, 'COP');
    expect(countriesByCode['MX']?.currency, 'MXN');
    expect(countriesByCode['BR']?.currency, 'BRL');
    expect(countriesByCode['EC']?.currency, 'USD');
    expect(countriesByCode['CO']?.currencyName('es'), 'peso colombiano');
    expect(countriesByCode['CO']?.currencyName('en'), 'Colombian peso');
    expect(
      latinAmericanCountries.every(
          (country) => country.currencyName('es').isNotEmpty && country.currencyName('en').isNotEmpty),
      isTrue,
    );
  });

  test('lee tasas de cambio y fecha del formato real de la API', () {
    final snapshot = parseExchangeRateResponse('''
      {
        "result": "success",
        "time_last_update_unix": 1793145751,
        "time_last_update_utc": "Wed, 28 Oct 2026 00:02:31 +0000",
        "rates": {"COP": 3143.42897, "MXN": 18.673405, "BRL": 5.348375}
      }
    ''');

    expect(snapshot.rates['COP'], 3143.42897);
    expect(snapshot.rates['MXN'], 18.673405);
    expect(snapshot.rates['BRL'], 5.348375);
    expect(snapshot.updatedAt.toUtc().millisecondsSinceEpoch, 1793145751000);
  });
}
