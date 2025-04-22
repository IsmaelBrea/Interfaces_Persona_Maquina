import 'package:src/models/posologyMed.dart';

class PosologyMed {
  final int id;
  final String medicationName;
  final int medicationId;
  final int hour;
  final int minute;
  final double dosage;
  String takenHour;
  bool taken;

  PosologyMed({
    required this.id,
    required this.medicationName,
    required this.medicationId,
    required this.hour,
    required this.minute,
    required this.dosage,
    this.takenHour = "",
    this.taken = false,
  });

  factory PosologyMed.fromJson(Map<String, dynamic> json) {
    return PosologyMed(
      id: json['id'],
      medicationName: json['medication_name'],
      medicationId: json['medication_id'],
      hour: json['hour'],
      minute: json['minute'],
      dosage: json['dosage'].toDouble(),
      takenHour: json['taken_hour'],
      taken: json['taken'],
    );
  }
}