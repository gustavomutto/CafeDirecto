import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cafe_directo/app_state.dart';
import 'package:cafe_directo/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows onboarding and opens farmer home', (tester) async {
    final state = CafeState();
    await tester.pumpWidget(CafeDirectoApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('CaféDirecto'), findsOneWidget);
    expect(find.text('Soy caficultor'), findsOneWidget);

    await tester.tap(find.text('Soy caficultor'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Luz Marina 👋'), findsOneWidget);
    expect(find.text('Mis lotes publicados'), findsOneWidget);
  });

  testWidgets('buyer role opens searchable coffee catalogue', (tester) async {
    final state = CafeState();
    await tester.pumpWidget(CafeDirectoApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a coffee buyer"));
    await tester.pumpAndSettle();

    expect(find.text('Discover Colombian specialty origins'), findsOneWidget);
    expect(find.text('Lote Mandarina'), findsOneWidget);
  });
}
