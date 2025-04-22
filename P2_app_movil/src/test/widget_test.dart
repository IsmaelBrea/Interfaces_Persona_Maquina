import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:src/main.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/main_screen.dart';

void main() {
  //Verificar que la aplicación se inicia con MainScreen, que el título de la App Bar es correcto y que los botones de navegación están presentes
  testWidgets('La app se inicia correctamente', (WidgetTester tester) async {
    // Construimos nuestra app y provocamos un frame
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>(
        create: (_) => MedicationProvider(),
        child: const MyApp(),
      ),
    );

    // Verificamos que la app se inicia con MainScreen
    expect(find.byType(MainScreen), findsOneWidget);

    // Verificamos que el título de la AppBar es correcto
    expect(find.text('MEDICATION APP'), findsOneWidget);

    // Verificamos que los botones de navegación están presentes
    expect(find.text('Tratamiento'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
  });

  // Verifica que la barra de navegación inferior tiene los iconos correctos
  testWidgets('La barra de navegación inferior tiene los iconos correctos',
      (WidgetTester tester) async {
    // Configuramos el ChangeNotifierProvider para que MainScreen pueda acceder a MedicationProvider
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>(
        create: (_) => MedicationProvider(),
        child: const MyApp(),
      ),
    );

    // Verificamos que los iconos correctos están presentes
    expect(find.byIcon(Icons.medical_services), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
  });

  // Verificar que el título de la AppBar está centrado
  testWidgets('El título App bar title esta centrado',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>(
        create: (_) => MedicationProvider(),
        child: const MyApp(),
      ),
    );

    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isTrue);
  });

// Verifica que la AppBar tiene el color de fondo correcto
  testWidgets('App bar tiene el color de fondo correcto',
      (WidgetTester tester) async {
    // Configuramos el ChangeNotifierProvider para que MainScreen pueda acceder a MedicationProvider.
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>(
        create: (_) => MedicationProvider(),
        child: const MyApp(),
      ),
    );

    // Buscamos la AppBar y verificamos que tiene el color de fondo correcto.
    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.green);
  });
}
