import 'package:src/models/posology.dart';

class Medication {
  final int id;
  final String name;
  final double dosage;
  final String startDate;
  final int treatmentDuration;
  final int patientId;
  List<Posology> posologies; // Nueva propiedad para las posologías

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.startDate,
    required this.treatmentDuration,
    required this.patientId,
    this.posologies = const [], // Inicializamos la lista vacía
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'].toDouble(),
      startDate: json['start_date'],
      treatmentDuration: json['treatment_duration'],
      patientId: json['patient_id'],
      posologies: [], // Las posologías se cargan después
    );
  }
}
