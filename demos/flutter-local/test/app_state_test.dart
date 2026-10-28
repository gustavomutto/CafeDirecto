import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cafe_directo/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'persists newly published lots without duplicating sample lots',
    () async {
      final state = CafeState();
      await state.initialize();
      await state.addLot(
        name: 'Lote Nuevo',
        variety: 'Caturra',
        process: 'Lavado',
        sacks: 10,
        price: 5.5,
      );

      final restored = CafeState();
      await restored.initialize();

      expect(restored.lots, hasLength(9));
      expect(restored.lots.first.name, 'Lote Nuevo');
      expect(restored.lots.where((lot) => lot.id == 'l1'), hasLength(1));
      state.dispose();
      restored.dispose();
    },
  );
}
