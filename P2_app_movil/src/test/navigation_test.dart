import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:src/main.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/treatment_screen.dart';
import 'package:src/screens/info_screen.dart';

void main() {
  // Verificar que la navegación entre pantallas funciona correctamente
  testWidgets('La navegación entre las dos pantallas funciona correctamente',
      (WidgetTester tester) async {
    // Construimos nuestra app
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>(
        create: (_) => MedicationProvider(),
        child: const MyApp(),
      ),
    );

    // Verificamos que inicialmente estamos en TreatmentScreen
    expect(find.byType(TreatmentScreen), findsOneWidget);
    expect(find.byType(InfoScreen), findsNothing);

    // Navegamos a InfoScreen
    await tester.tap(find.text('Información'));
    await tester.pumpAndSettle();

    // Verificamos que ahora estamos en InfoScreen
    expect(find.byType(InfoScreen), findsOneWidget);
    expect(find.byType(TreatmentScreen), findsNothing);

    // Navegamos de vuelta a TreatmentScreen
    await tester.tap(find.text('Tratamiento'));
    await tester.pumpAndSettle();

    // Verificamos que hemos vuelto a TreatmentScreen
    expect(find.byType(TreatmentScreen), findsOneWidget);
    expect(find.byType(InfoScreen), findsNothing);
  });
}
