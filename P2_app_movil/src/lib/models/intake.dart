class Intake {
  final int id;
  final String date;
  final int medicationId;

  Intake({
    required this.id,
    required this.date,
    required this.medicationId,
  });

  // Convertir un JSON a un objeto Intake
  factory Intake.fromJson(Map<String, dynamic> json) {
    return Intake(
      id: json['id'],
      date: json['date'],
      medicationId: json['medication_id'],
    );
  }

   // Convertir un objeto Intake a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'medication_id': medicationId,
    };
  }
}