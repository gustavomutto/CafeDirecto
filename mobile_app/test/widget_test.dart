// Pruebas de la lógica: formato, conversiones y DTOs (JSON del servidor → entidades).
// Ejecutar con:  flutter test
import 'package:cafedirecto/core/constants/countries.dart';
import 'package:cafedirecto/core/utils/format.dart';
import 'package:cafedirecto/core/utils/media.dart';
import 'package:cafedirecto/core/utils/validators.dart';
import 'package:cafedirecto/data/dtos/auction_dto.dart';
import 'package:cafedirecto/data/dtos/chat_dto.dart';
import 'package:cafedirecto/data/dtos/exchange_rate_dto.dart';
import 'package:cafedirecto/data/dtos/lot_dto.dart';
import 'package:cafedirecto/data/dtos/market_dto.dart';
import 'package:cafedirecto/data/dtos/notification_dto.dart';
import 'package:cafedirecto/domain/entities/entities.dart';
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

  test('conversión de precio por carga a USD/lb con la TRM del día', () {
    // 1 carga (125 kg pergamino, factor 94) ≈ 205,2 lb de café verde
    expect(lbGreenPerCarga, closeTo(205.24, 0.01));
    // con la TRM real (3.147,40) y con la tasa de respaldo (3.900)
    expect(copCargaToUsdLb(2065000, 3147.4), closeTo(3.197, 0.001));
    expect(copCargaToUsdLb(3200000), closeTo(4.0, 0.01));
    expect(usdLbToCopCarga(copCargaToUsdLb(2065000, 3147.4), 3147.4), closeTo(2065000, 1));
  });

  test('id de una foto a partir de su dirección firmada', () {
    expect(imageIdFromUrl('/images/42?s=AbCdEfGh12345678'), 42);
    expect(imageIdFromUrl('https://api.example.com/images/7?s=x'), 7);
    expect(imageIdFromUrl('/otra/cosa'), isNull);
    expect(imageIdFromUrl(null), isNull);
  });

  test('contraseña: 8 caracteres con letras y números', () {
    expect(passwordProblem('123456'), isNotNull);
    expect(passwordProblem('abcdefgh'), isNotNull);
    expect(passwordProblem('cafe1234'), isNull);
  });

  test('lectura de un mensaje de la API', () {
    final m = ChatMessageDto.fromJson({
      'id': 5,
      'conversationId': 1,
      'senderId': 2,
      'from': 'buyer',
      'type': 'text',
      'text': 'Hello',
      'lang': 'en',
      'translation': 'Hola',
      'createdAt': 1700000000000,
    }).toEntity();
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

  test('lote con subasta abierta', () {
    final lot = LotDto.fromJson({
      'id': 3,
      'farmerId': 1,
      'name': 'Mandarina',
      'variety': 'Pink Bourbon',
      'process': 'honey',
      'sacks': '30',
      'sca': 88,
      'priceLb': '5.5',
      'farm': {'name': 'La Esperanza', 'rating': {'avg': 4.5, 'count': 2}},
      'auction': {'id': 9, 'endsAt': 1793145751000, 'basePriceLb': 5.5, 'minIncrementLb': 0.1, 'sacks': 20, 'phase': 'live', 'highest': 5.8, 'bids': 2, 'bidders': 2},
      'interest': 4,
    }).toEntity();
    expect(lot.sacks, 30);
    expect(lot.priceLb, 5.5);
    expect(lot.farm.rating.count, 2);
    expect(lot.auction?.isLive, isTrue);
    expect(lot.auction?.highest, 5.8);
    expect(lot.interest, 4);
  });

  test('subasta: ofertas anónimas y la mía', () {
    final a = AuctionDto.fromJson({
      'id': 9,
      'lotId': 3,
      'farmerId': 1,
      'basePriceLb': 5.5,
      'minIncrementLb': 0.1,
      'minNext': 5.9,
      'sacks': 20,
      'endsAt': 1793145751000,
      'phase': 'live',
      'highest': 5.8,
      'myBest': 5.5,
      'leading': false,
      'bidders': 2,
      'bids': [
        {'id': 2, 'priceLb': 5.8, 'status': 'active', 'mine': false, 'alias': 2, 'bidder': null},
        {'id': 1, 'priceLb': 5.5, 'status': 'active', 'mine': true, 'alias': 1, 'bidder': {'id': 7, 'name': 'Lena', 'company': 'Nordlicht'}},
      ],
    }).toEntity();
    expect(a.isLive, isTrue);
    expect(a.bids.first.bidder, isNull);
    expect(a.bids.last.bidder?.display, 'Nordlicht');
    expect(a.minNext, 5.9);
  });

  test('notificación lleva a la pantalla correcta', () {
    final n = NotificationDto.fromJson({
      'id': 1,
      'type': 'lot_interest',
      'title': {'es': '👀 Lena está interesada', 'en': '👀 Lena is interested'},
      'body': {'es': 'vio tu lote', 'en': 'viewed your lot'},
      'data': {'lotId': 3, 'userId': 7},
      'read': false,
      'createdAt': 1700000000000,
    }).toEntity();
    expect(n.route, '/user/7');
    expect(n.title.of('en'), '👀 Lena is interested');
    final bid = NotificationDto.fromJson({'id': 2, 'type': 'bid_new', 'data': {'auctionId': 9, 'lotId': 3}}).toEntity();
    expect(bid.route, '/auction/9');
  });

  test('mercado del café: conversiones', () {
    final m = CoffeeMarketDto.fromJson({
      'updatedAt': 1793145751000,
      'internal': {'copPerCarga': 2065000, 'date': '2026-10-27', 'source': 'FNC', 'estimated': false},
      'ny': {'usdCentsPerLb': 293.75, 'date': '2026-10-27', 'source': 'ICE', 'history': [{'t': 1, 'v': 290}, {'t': 2, 'v': 293.75}]},
      'trm': {'copPerUsd': 3147.4, 'date': '2026-10-27', 'source': 'SFC'},
      'derived': {'copPerKg': 16520, 'copPerArroba': 206500, 'internalUsdPerLbGreen': 3.197, 'differentialUsdLb': 0.26},
      'constants': {'lbGreenPerCarga': 205.24},
    }).toEntity();
    expect(m.internal?.copPerCarga, 2065000);
    expect(m.ny?.usdPerLb, closeTo(2.9375, 1e-9));
    expect(m.ny?.history.length, 2);
    // 3,197 US$/lb × 205,24 lb × 3.147,4 COP ≈ 2.065.000 por carga
    expect(m.usdLbToCopCarga(3.197)!, closeTo(2065000, 3000));
    expect(fmtRemaining(nowMs() - 1000, 'es'), 'Terminó');
  });
}
