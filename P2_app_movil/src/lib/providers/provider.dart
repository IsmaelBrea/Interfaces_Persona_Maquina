import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:src/models/posologyMed.dart';
import 'dart:convert';
import '../models/medication.dart';
import '../models/posology.dart';
import '../models/intake.dart';
import '../main.dart';

const String IP = '10.0.2.2';

class MedicationProvider with ChangeNotifier {
  final String baseUrl = 'http://$IP:8000';
  List<Medication> _medications = [];
  List<PosologyMed> _allPosologies = [];
  bool _isLoading = false;
  String _errorMessage = '';

  int patientId = 8;
  int get getPatientId => patientId;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  List<Medication> get medications => _medications;
  List<PosologyMed> get allPosologies => _allPosologies;

  Future<void> fetchMedications(int patientId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Medicamentos del paciente
      final response = await http
          .get(Uri.parse('$baseUrl/patients/$patientId/medications'))
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('Timeout fetching medications');
        return http.Response('Error', 408);
      });

      if (response.statusCode == 200) { // OK
        List<dynamic> body = jsonDecode(response.body);

        // Usamos Future.wait para asegurarnos de que todas las posologías sean cargadas
        _medications = await Future.wait(body.map((item) async {
          final medication = Medication.fromJson(item);

          try {
            // Asignamos las posologías obtenidas a cada medicamento
            medication.posologies =
                await fetchPosologies(patientId, medication.id);
          } catch (error) {
            debugPrint(
                'Error fetching posologies for medication ${medication.id}: $error');
            medication.posologies = []; // Si falla, asignamos una lista vacía
          }

          return medication;
        }).toList());
      } else if (response.statusCode == 404) {  // BAD REQUEST
        _errorMessage = 'No hay medicamentos disponibles.';
        _medications = [];
      } else if (response.statusCode == 408) {
        _errorMessage =
            'La solicitud ha caducado. Por favor, inténtelo de nuevo.';
        _medications = [];
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        _errorMessage =
            'Error del servidor. Código de estado: ${response.statusCode}';
        _medications = [];
      } else {
        _errorMessage =
            'Error desconocido. Código de estado: ${response.statusCode}';
        _medications = [];
      }
    } catch (error) {
      _errorMessage = 'Error al obtener los medicamentos: $error';
      _medications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Posologías de un medicamento
  Future<List<Posology>> fetchPosologies(
      int patientId, int medicationId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/patients/$patientId/medications/$medicationId/posologies'));

      if (response.statusCode == 200) { // OK
        List<dynamic> body = jsonDecode(response.body); // Decodifica el JSON
        List<Posology> posologies =
            body.map((item) => Posology.fromJson(item)).toList(); // Mapea los elementos a objetos Posology

        // Ordenamos las posologías por hora
        posologies.sort((a, b) => a.hour.compareTo(b.hour));
        return posologies;
      } else if (response.statusCode == 404) {  // BAD REQUEST
        _errorMessage = 'No hay tratamientos disponibles.';
        return [];
      } else if (response.statusCode == 408) {
        _errorMessage =
            'La solicitud ha caducado. Por favor, inténtelo de nuevo.';
        return [];
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        _errorMessage =
            'Error del servidor. Código de estado: ${response.statusCode}';
        return [];
      } else {
        _errorMessage =
            'Error desconocido. Código de estado: ${response.statusCode}';
        return [];
      }
    } catch (error) {
      debugPrint('Error fetching posologies: $error');
      return [];
    }
  }

  // Todas las posologías de un paciente
  Future<List<PosologyMed>> fetchAllPosologies(int patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Primero obtenemos los medicamentos
      await fetchMedications(patientId);

      // Generamos una lista de tareas concurrentes para obtener las posologías
      final allPosologiesTasks = _medications.map((medication) async {
        try {
          // Obtenemos las posologías concurrentemente para cada medicamento
          final posologies = await fetchPosologies(patientId, medication.id);
          return posologies.map((posology) {
            return PosologyMed(
              id: posology.id,
              medicationName: medication.name,
              medicationId: medication.id,
              hour: posology.hour,
              minute: posology.minute,
              dosage: medication.dosage,
            );
          }).toList();
        } catch (error) {
          debugPrint(
              'Error fetching posologies for medication ${medication.id}: $error');
          return <PosologyMed>[]; // Si falla, devolvemos una lista vacía
        }
      });

      // Esperamos a que todas las tareas finalicen
      final allPosologiesResults = await Future.wait(allPosologiesTasks);

      // Aplanamos la lista de listas
      _allPosologies =
          allPosologiesResults.expand((posology) => posology).toList();

      // Ordenamos por hora y minuto
      _allPosologies.sort((a, b) {
        final hourComparison = a.hour.compareTo(b.hour);
        return hourComparison != 0
            ? hourComparison
            : a.minute.compareTo(b.minute);
      });
    } catch (error) {
      debugPrint('Error fetching all posologies: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _allPosologies;
  }

  // Añadir una toma POST
  Future<void> addIntake(int patientId, int medicationId, String intakeTime) async {
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patients/$patientId/medications/$medicationId/intakes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'date': intakeTime,
          'medication_id': medicationId,
        }),
      );

      debugPrint('Código de respuesta: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        debugPrint('Toma añadida correctamente.');
      } else if (response.statusCode == 404) {
        _errorMessage = 'No se encontró el recurso solicitado.';
      } else if (response.statusCode == 422) {
        _errorMessage = 'Datos inválidos proporcionados.';
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        _errorMessage = 'Error del servidor. Código de estado: ${response.statusCode}';
      } else {
        _errorMessage = 'Error desconocido. Código de estado: ${response.statusCode}';
      }

    } catch (error) {
      debugPrint('Error al añadir la Toma: $error');
    } finally {
      notifyListeners();
    }
  }
}
