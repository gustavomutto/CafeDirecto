// Pruebas rápidas de la lógica (formato, conversiones y traducción simulada).
// Ejecutar con:  flutter test
import 'package:cafedirecto/models/models.dart';
import 'package:cafedirecto/utils/format.dart';
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
}
