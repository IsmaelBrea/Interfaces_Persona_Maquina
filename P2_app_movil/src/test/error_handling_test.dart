import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:src/models/medication.dart';
import 'package:src/models/posologyMed.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/treatment_screen.dart';
import 'package:src/screens/info_screen.dart';

class MockMedicationProvider extends MedicationProvider {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Medication> _medications = [];
  List<PosologyMed> _allPosologies = [];

  @override
  bool get isLoading => _isLoading;

  @override
  String get errorMessage => _errorMessage;

  @override
  List<Medication> get medications => _medications;

  @override
  List<PosologyMed> get allPosologies => _allPosologies;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setMedications(List<Medication> meds) {
    _medications = meds;
    notifyListeners();
  }

  void setAllPosologies(List<PosologyMed> posologies) {
    _allPosologies = posologies;
    notifyListeners();
  }

  @override
  Future<void> fetchMedications(int patientId) async {
    await Future.delayed(Duration(milliseconds: 500));
    notifyListeners();
  }

  @override
  Future<List<PosologyMed>> fetchAllPosologies(int patientId) async {
    await Future.delayed(Duration(milliseconds: 500));
    notifyListeners();
    return _allPosologies;
  }
}

void main() {
  group('Error Handling Tests', () {
    late MockMedicationProvider mockProvider;

    setUp(() {
      mockProvider = MockMedicationProvider();
    });

    Future<void> pumpTestWidget(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('Manejo de errores HTTP', () {
      final errorCases = {
        400: 'Error 400: Solicitud incorrecta',
        401: 'Error 401: No autorizado',
        403: 'Error 403: Prohibido',
        404: 'No hay datos disponibles.',
        408: 'La solicitud ha caducado. Por favor, inténtelo de nuevo.',
        500: 'Error del servidor. Código de estado: 500',
        502: 'Error 502: Puerta de enlace incorrecta',
        503: 'Error 503: Servicio no disponible',
        504: 'Error 504: Tiempo de espera de la puerta de enlace',
      };

      errorCases.forEach((statusCode, errorMessage) {
        // Verificamos que manejamos correctamente cada código de estado
        testWidgets('TreatmentScreen e InfoScreen manejan error $statusCode',
            (WidgetTester tester) async {
          mockProvider.setErrorMessage(errorMessage);

          for (final widget in [TreatmentScreen(), InfoScreen()]) {
            await pumpTestWidget(tester, widget);
            expect(find.text(errorMessage), findsOneWidget);
          }
        });
      });
    });

    // Verificar que manejamos correctamente los errores de red
    testWidgets('TreatmentScreen e InfoScreen manejan error de red',
        (WidgetTester tester) async {
      mockProvider.setErrorMessage(
          'Error de conexión. Compruebe su conexión a internet.');

      for (final widget in [TreatmentScreen(), InfoScreen()]) {
        await pumpTestWidget(tester, widget);
        expect(
            find.text('Error de conexión. Compruebe su conexión a internet.'),
            findsOneWidget);
      }
    });

    // Verificar que se muestra una lista vacía para un paciente sin posologías
    testWidgets(
        'TreatmentScreen muestra lista vacía sin error para paciente sin posologías',
        (WidgetTester tester) async {
      mockProvider.setAllPosologies([]);

      await pumpTestWidget(tester, TreatmentScreen());

      expect(find.byType(PosologyTile), findsNothing);
      expect(find.text('No hay posologías disponibles'), findsOneWidget);
    });

    // Verificar que se muestra una lista vacía para un paciente sin medicamentos
    testWidgets(
        'InfoScreen muestra lista vacía sin error para paciente sin medicamentos',
        (WidgetTester tester) async {
      mockProvider.setMedications([]);

      await pumpTestWidget(tester, InfoScreen());

      expect(find.byType(MedicationTile), findsNothing);
      expect(find.text('No hay medicamentos disponibles'), findsOneWidget);
    });

    testWidgets('TreatmentScreen e InfoScreen manejan error desconocido',
        (WidgetTester tester) async {
      mockProvider.setErrorMessage('Error desconocido. Código de estado: 418');

      for (final widget in [TreatmentScreen(), InfoScreen()]) {
        await pumpTestWidget(tester, widget);
        expect(find.text('Error desconocido. Código de estado: 418'),
            findsOneWidget);
      }
    });

    // Verificar que se muestra una lista de posologías correctamente
    testWidgets(
        'TreatmentScreen muestra posologías correctamente cuando hay datos',
        (WidgetTester tester) async {
      final posologies = [
        PosologyMed(
            id: 1,
            medicationName: 'Med1',
            medicationId: 1,
            hour: 8,
            minute: 0,
            dosage: 10),
        PosologyMed(
            id: 2,
            medicationName: 'Med2',
            medicationId: 2,
            hour: 14,
            minute: 30,
            dosage: 5),
      ];
      mockProvider.setAllPosologies(posologies);

      await pumpTestWidget(tester, TreatmentScreen());

      expect(find.byType(PosologyTile), findsNWidgets(2));
      expect(find.text('Med1'), findsOneWidget);
      expect(find.text('Med2'), findsOneWidget);
    });

    // Verificar que se muestra una lista de medicamentos correctamente
    testWidgets(
        'InfoScreen muestra medicamentos correctamente cuando hay datos',
        (WidgetTester tester) async {
      final medications = [
        Medication(
            id: 1,
            name: 'Med1',
            dosage: 10,
            startDate: '2023-01-01',
            treatmentDuration: 30,
            posologies: [],
            patientId: 1),
        Medication(
            id: 2,
            name: 'Med2',
            dosage: 5,
            startDate: '2023-02-01',
            treatmentDuration: 60,
            posologies: [],
            patientId: 2),
      ];
      mockProvider.setMedications(medications);

      await pumpTestWidget(tester, InfoScreen());

      expect(find.byType(MedicationTile), findsNWidgets(2));
      expect(find.text('Med1'), findsOneWidget);
      expect(find.text('Med2'), findsOneWidget);
    });

    // Verificar que se muestra un mensaje de error y luego se cargan los datos
    testWidgets(
        'TreatmentScreen maneja correctamente la transición de error a datos',
        (WidgetTester tester) async {
      mockProvider.setErrorMessage('Error inicial');
      await pumpTestWidget(tester, TreatmentScreen());
      expect(find.text('Error inicial'), findsOneWidget);

      mockProvider.setErrorMessage('');
      mockProvider.setAllPosologies([
        PosologyMed(
            id: 1,
            medicationName: 'Med1',
            medicationId: 1,
            hour: 8,
            minute: 0,
            dosage: 10),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Error inicial'), findsNothing);
      expect(find.byType(PosologyTile), findsOneWidget);
    });

    // Verificar que se muestra un mensaje de error y luego se cargan los datos
    testWidgets(
        'InfoScreen maneja correctamente la transición de error a datos',
        (WidgetTester tester) async {
      mockProvider.setErrorMessage('Error inicial');
      await pumpTestWidget(tester, InfoScreen());
      expect(find.text('Error inicial'), findsOneWidget);

      mockProvider.setErrorMessage('');
      mockProvider.setMedications([
        Medication(
            id: 1,
            name: 'Med1',
            dosage: 10,
            startDate: '2023-01-01',
            treatmentDuration: 30,
            posologies: [],
            patientId: 1),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Error inicial'), findsNothing);
      expect(find.byType(MedicationTile), findsOneWidget);
    });
  });
}
