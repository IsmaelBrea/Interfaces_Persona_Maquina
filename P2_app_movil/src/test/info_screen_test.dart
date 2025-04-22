import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:src/models/medication.dart';
import 'package:src/models/posology.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/info_screen.dart';

class MockMedicationProvider extends MedicationProvider {
  bool _isLoading = true;
  List<Medication> _mockMedications = [];
  String _errorMessage = '';

  @override
  bool get isLoading => _isLoading;

  @override
  List<Medication> get medications => _mockMedications;

  @override
  String get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setMockMedications(List<Medication> medications) {
    _mockMedications = medications;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}

void main() {
  group('InfoScreen Tests', () {
    late MockMedicationProvider mockProvider;

    setUp(() {
      mockProvider = MockMedicationProvider();
    });

    // Verificar que se muestra un indicador de carga mientras se están obteniendo los datos
    testWidgets(
        'Se muestra un indicador de carga mientras se están obteniendo los datos',
        (WidgetTester tester) async {
      mockProvider.setLoading(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<MedicationProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: InfoScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MedicationTile), findsNothing);
    });

    // Verificar que se muestra un mensaje de error si no se pueden obtener los datos
    testWidgets(
        'Se muestran las MedicationTiles una vez que los datos se han cargado',
        (WidgetTester tester) async {
      mockProvider.setLoading(false);
      mockProvider.setMockMedications([
        Medication(
          id: 1,
          name: 'CEFOTAXIMA Polvo para Solución Inyectable',
          dosage: 2.0,
          startDate: '2024-10-10',
          treatmentDuration: 93,
          patientId: 1,
          posologies: [
            Posology(id: 1, hour: 7, minute: 0, medicationId: 1),
            Posology(id: 2, hour: 15, minute: 0, medicationId: 1),
            Posology(id: 3, hour: 23, minute: 0, medicationId: 1),
          ],
        ),
        Medication(
          id: 2,
          name: 'SULCRAN',
          dosage: 2.0,
          startDate: '2024-10-28',
          treatmentDuration: 73,
          patientId: 1,
          posologies: [
            Posology(id: 4, hour: 22, minute: 0, medicationId: 2),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: InfoScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(MedicationTile), findsNWidgets(2));
      expect(find.text('CEFOTAXIMA Polvo para Solución Inyectable'),
          findsOneWidget);
      expect(find.text('SULCRAN'), findsOneWidget);
    });

    // Verificar que se muestra un mensaje de error si no se pueden obtener los datos
    testWidgets(
        'Se puede expandir una MedicationTile para mostrar información detallada',
        (WidgetTester tester) async {
      mockProvider.setLoading(false);
      mockProvider.setMockMedications([
        Medication(
          id: 1,
          name: 'CEFOTAXIMA Polvo para Solución Inyectable',
          dosage: 2.0,
          startDate: '2024-10-10',
          treatmentDuration: 93,
          patientId: 1,
          posologies: [
            Posology(id: 1, hour: 7, minute: 0, medicationId: 1),
            Posology(id: 2, hour: 15, minute: 0, medicationId: 1),
            Posology(id: 3, hour: 23, minute: 0, medicationId: 1),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: InfoScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dosis: 2.0mg'), findsNothing);

      await tester.tap(find.text('CEFOTAXIMA Polvo para Solución Inyectable'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dosis'), findsOneWidget);
    });

    // Verificar que la información detallada (dosis, fecha de inicio, duración del tratamiento, posologías) se muestra correctamente
    testWidgets('La información detallada se muestra correctamente',
        (WidgetTester tester) async {
      mockProvider.setLoading(false);
      mockProvider.setMockMedications([
        Medication(
          id: 1,
          name: 'CEFOTAXIMA Polvo para Solución Inyectable',
          dosage: 2.0,
          startDate: '2024-10-10',
          treatmentDuration: 93,
          patientId: 1,
          posologies: [
            Posology(id: 1, hour: 7, minute: 0, medicationId: 1),
            Posology(id: 2, hour: 15, minute: 0, medicationId: 1),
            Posology(id: 3, hour: 23, minute: 0, medicationId: 1),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: InfoScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(MedicationTile));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dosis'), findsOneWidget);
      expect(find.textContaining('Fecha de inicio'), findsOneWidget);
      expect(find.textContaining('Duración del tratamiento'), findsOneWidget);
      expect(find.textContaining('Posologías'), findsOneWidget);
    });
  });
}
