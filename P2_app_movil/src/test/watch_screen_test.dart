import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:src/models/intake.dart';
import 'package:src/models/posologyMed.dart';
import 'package:src/models/posology.dart';
import 'package:src/models/medication.dart';
import 'package:src/providers/provider.dart';
import 'package:src/screens/watch_screen.dart';
import 'package:clock/clock.dart';

class MockMedicationProvider extends MedicationProvider {
  bool _isLoading = true;
  List<PosologyMed> _mockPosologies = [];
  String _errorMessage = '';
  List<Intake> intakes = [];

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

  void setMockMedications(List<Medication> medications) {
    _mockPosologies = medications
        .expand((med) => med.posologies.map((pos) => PosologyMed(
              id: pos.id,
              medicationName: med.name,
              medicationId: med.id,
              hour: pos.hour,
              minute: pos.minute,
              dosage: med.dosage,
            )))
        .toList();
    notifyListeners();
  }

  @override
  Future<void> addIntake(
      int patientId, int medicationId, String intakeTime) async {
    final now = clock.now().toIso8601String();
    intakes.add(Intake(
      id: intakes.length + 1,
      date: now,
      medicationId: medicationId,
    ));
    notifyListeners();
  }
}

void main() {
  //Los casos del watch_screen son los mismos que los de treatment_screen. Simpemente añadimos un widget que muestra la hora actual en el AppBar
  group('WatchScreen Tests', () {
    late MockMedicationProvider mockProvider;

    setUp(() {
      mockProvider = MockMedicationProvider();
    });

    // Verificamos que se muestre la hora actual en el AppBar
    testWidgets('Muestra la hora actual en el AppBar',
        (WidgetTester tester) async {
      final currentTime = DateTime.now();

      mockProvider.setLoading(false);
      mockProvider.setMockPosologies([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: WatchScreen(),
          ),
        ),
      );

      await tester.pump();

      final expectedTimeString = DateFormat('HH:mm').format(currentTime);
      expect(find.text(expectedTimeString), findsOneWidget);
    });

    // Tests para mostrar los posibles errores en la pantalla del reloj
    testWidgets('Muestra el mensaje de carga cuando isLoading es true',
        (WidgetTester tester) async {
      mockProvider.setLoading(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: WatchScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Muestra el mensaje de error cuando hay un error',
        (WidgetTester tester) async {
      mockProvider.setLoading(false);
      mockProvider.setErrorMessage('Error al cargar los datos');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: WatchScreen(),
          ),
        ),
      );

      expect(find.text('Error al cargar los datos'), findsOneWidget);
    });

    testWidgets('Muestra el mensaje cuando no hay posologías disponibles',
        (WidgetTester tester) async {
      mockProvider.setLoading(false);
      mockProvider.setMockPosologies([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MedicationProvider>.value(
            value: mockProvider,
            child: WatchScreen(),
          ),
        ),
      );

      expect(find.text('No hay posologías disponibles'), findsOneWidget);
    });
  });
}
