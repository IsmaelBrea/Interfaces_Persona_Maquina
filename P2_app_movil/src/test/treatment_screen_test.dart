import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:src/models/intake.dart';
import 'package:src/models/posologyMed.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/treatment_screen.dart';
import 'package:clock/clock.dart';

class MockMedicationProvider extends MedicationProvider {
  bool _isLoading = true;
  List<PosologyMed> _mockPosologies = [];
  String _errorMessage = '';
  List<Intake> intakes = []; // Almacenar intakes simulados, inicializado aquí

  @override
  bool get isLoading => _isLoading;

  @override
  List<PosologyMed> get allPosologies => _mockPosologies;

  @override
  String get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setMockPosologies(List<PosologyMed> posologies) {
    _mockPosologies = posologies;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

// Simulación del método addIntake
  @override
  Future<void> addIntake(
      int patientId, int medicationId, String intakeTime) async {
    // Usa clock.now() para respetar el mock del tiempo
    final now = clock.now().toIso8601String();
    intakes.add(Intake(
      id: intakes.length + 1,
      date: now, // Aquí usamos clock.now()
      medicationId: medicationId,
    ));

    notifyListeners();
  }
}

void main() {
  group('TreatmentScreen Tests', () {
    late MockMedicationProvider mockProvider;

    setUp(() {
      mockProvider = MockMedicationProvider();
    });

    // Verificar que se muestra un indicador de carga mientras se están obteniendo los datos
    testWidgets('Muestra indicador de carga mientras se obtienen los datos',
        (WidgetTester tester) async {
      mockProvider.setLoading(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<MedicationProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: TreatmentScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Verificar que se muestran los PosologyTiles una vez que los datos se han cargado
    testWidgets('Muestra PosologyTiles cuando los datos se han cargado',
        (WidgetTester tester) async {
      mockProvider.setLoading(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: TreatmentScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      mockProvider.setLoading(false);
      mockProvider.setMockPosologies([
        PosologyMed(
          id: 1,
          medicationName: 'Medicamento 1',
          medicationId: 1,
          hour: 8,
          minute: 0,
          dosage: 10,
        ),
        PosologyMed(
          id: 2,
          medicationName: 'Medicamento 2',
          medicationId: 2,
          hour: 14,
          minute: 30,
          dosage: 5,
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(PosologyTile), findsNWidgets(2));

      expect(find.text('Medicamento 1'), findsOneWidget);
      expect(find.text('Medicamento 2'), findsOneWidget);

      expect(find.text('10.0 mg'), findsOneWidget);
      expect(find.text('5.0 mg'), findsOneWidget);

      expect(find.text('Hora de la Toma: 08:00'), findsOneWidget);
      expect(find.text('Hora de la Toma: 14:30'), findsOneWidget);

      print('Todos los widgets de texto encontrados:');
      tester.widgetList<Text>(find.byType(Text)).forEach((widget) {
        print('Text widget: "${widget.data}"');
      });
    });

    // Verificar que se marca de rojo una posología cuando ya pasó la hora de la toma
    testWidgets(
      'Marca de color rojo una posología cuando ya pasó la hora de la toma',
      (WidgetTester tester) async {
        // Set a fixed time for the test
        final fixedTime = DateTime(2023, 1, 1, 10, 0); // 10:00 AM

        withClock(Clock.fixed(fixedTime), () async {
          mockProvider.setLoading(false);
          mockProvider.setMockPosologies([
            PosologyMed(
              id: 1,
              medicationName: 'Medicamento Pasado',
              medicationId: 1,
              hour: 9,
              minute: 0,
              dosage: 10,
            ),
            PosologyMed(
              id: 2,
              medicationName: 'Medicamento Futuro',
              medicationId: 2,
              hour: 11,
              minute: 0,
              dosage: 5,
            ),
          ]);

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<MedicationProvider>.value(
                value: mockProvider,
                child: TreatmentScreen(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Find the PosologyTile widgets
          final posologyTiles = tester
              .widgetList<PosologyTile>(find.byType(PosologyTile))
              .toList();

          // Check the color of the first PosologyTile (should be red)
          final firstPosologyContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byWidget(posologyTiles[0]),
              matching: find.byType(AnimatedContainer),
            ),
          );
          expect(firstPosologyContainer.decoration, isA<BoxDecoration>());
          final firstBoxDecoration =
              firstPosologyContainer.decoration as BoxDecoration;
          expect(firstBoxDecoration.color, equals(Colors.red));

          // Check the color of the second PosologyTile (should be white)
          final secondPosologyContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byWidget(posologyTiles[1]),
              matching: find.byType(AnimatedContainer),
            ),
          );
        });
      },
    );

    // Verificar que se marca de verde una posología cuando es tomada
    testWidgets(
      'Permite marcar una posología como tomada y cambia el color a verde',
      (WidgetTester tester) async {
        // Set a fixed time for the test
        final fixedTime = DateTime(2023, 1, 1, 10, 0); // 10:00 AM

        withClock(Clock.fixed(fixedTime), () async {
          mockProvider.setLoading(false);
          mockProvider.setMockPosologies([
            PosologyMed(
              id: 1,
              medicationName: 'Medicamento Pendiente',
              medicationId: 1,
              hour: 9,
              minute: 0,
              dosage: 10,
            ),
          ]);

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<MedicationProvider>.value(
                value: mockProvider,
                child: TreatmentScreen(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verifica que el color inicial de la posología es rojo (hora ya pasó)
          final initialContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(PosologyTile),
              matching: find.byType(AnimatedContainer),
            ),
          );
          expect(initialContainer.decoration, isA<BoxDecoration>());
          final initialBoxDecoration =
              initialContainer.decoration as BoxDecoration;
          expect(initialBoxDecoration.color, equals(Colors.red));

          // Simula el tap para marcar la posología como tomada
          await tester.tap(find.byType(PosologyTile));
          await tester.pumpAndSettle();

          // Verifica que el color de la posología cambió a verde
          final updatedContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(PosologyTile),
              matching: find.byType(AnimatedContainer),
            ),
          );
          expect(updatedContainer.decoration, isA<BoxDecoration>());
          final updatedBoxDecoration =
              updatedContainer.decoration as BoxDecoration;
          expect(updatedBoxDecoration.color, equals(Colors.green));
        });
      },
    );

    // Verificar que se muestra la hora de toma después de marcar una posología como tomada
    testWidgets(
      'Muestra la hora de toma después de marcar una posología como tomada',
      (WidgetTester tester) async {
        // Usamos la hora actual
        final now = DateTime.now();
        final currentHour = now.hour.toString().padLeft(2, '0');
        final currentMinute = now.minute.toString().padLeft(2, '0');
        final currentTime = '$currentHour:$currentMinute';

        mockProvider.setLoading(false);
        mockProvider.setMockPosologies([
          PosologyMed(
            id: 1,
            medicationName: 'Medicamento Pendiente',
            medicationId: 1,
            hour: 9,
            minute: 0,
            dosage: 10,
            taken: false,
            takenHour: '',
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<MedicationProvider>.value(
              value: mockProvider,
              child: TreatmentScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verifica que inicialmente no haya el RichText con "Tomada a las:"
        expect(
            find.byWidgetPredicate((widget) =>
                widget is RichText &&
                (widget.text as TextSpan)
                    .toPlainText()
                    .contains('Tomada a las:')),
            findsNothing);

        // Simula el tap para marcar la posología como tomada
        await tester.tap(find.byType(InkWell));

        // Forzar la actualización del estado y la reconstrucción del widget
        mockProvider.notifyListeners();
        await tester.pump();
        await tester.pumpAndSettle();

        // Verifica que el RichText con "Tomada a las:" esté visible ahora
        expect(
            find.byWidgetPredicate((widget) =>
                widget is RichText &&
                (widget.text as TextSpan)
                    .toPlainText()
                    .contains('Tomada a las:')),
            findsOneWidget);

        // Verifica el contenido del RichText
        final richTextWidget = tester.widget<RichText>(find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                (widget.text as TextSpan)
                    .toPlainText()
                    .contains('Tomada a las:')));
        final textSpan = richTextWidget.text as TextSpan;
        expect(textSpan.toPlainText(), contains('Tomada a las: $currentTime'));

        // Imprime todos los widgets de texto para depuración
        print('Todos los widgets de texto encontrados:');
        tester.widgetList<RichText>(find.byType(RichText)).forEach((widget) {
          print(
              'RichText widget: "${(widget.text as TextSpan).toPlainText()}"');
        });
      },
    );

    // Verificar que se realizó un addIntake cuando marcamos una posología como tomada con los datos correctos
    testWidgets(
      'Se realiza un addIntake cuando marcamos una posología como tomada, con los datos correctos',
      (WidgetTester tester) async {
        // Fija la hora para el test
        final fixedTime = DateTime(2023, 1, 1, 10, 15); // 10:15 AM

        withClock(Clock.fixed(fixedTime), () async {
          mockProvider.setLoading(false);
          mockProvider.setMockPosologies([
            PosologyMed(
              id: 1,
              medicationName: 'Medicamento Pendiente',
              medicationId: 1,
              hour: 9,
              minute: 0,
              dosage: 10,
            ),
          ]);

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<MedicationProvider>.value(
                value: mockProvider,
                child: TreatmentScreen(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verifica que inicialmente no hay intakes en el mockProvider
          expect(mockProvider.intakes, isEmpty);

          // Simula el tap para marcar la posología como tomada
          await tester.tap(find.byType(PosologyTile));
          await tester.pumpAndSettle();

          // Verifica que se añadió un intake al mockProvider
          expect(mockProvider.intakes.length, 1);

          // Verifica que los datos del intake son correctos
          final addedIntake = mockProvider.intakes.first;
          expect(addedIntake.medicationId, 1); // ID del medicamento
          expect(addedIntake.date,
              fixedTime.toIso8601String()); // Hora exacta tomada
        });
      },
    );
  });
}
