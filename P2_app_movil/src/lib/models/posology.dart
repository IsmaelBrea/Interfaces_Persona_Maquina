class Posology {
  final int id;
  final int hour;
  final int minute;
  final int medicationId;

  Posology({
    required this.id,
    required this.hour,
    required this.minute,
    required this.medicationId,
  });

  factory Posology.fromJson(Map<String, dynamic> json) {
    return Posology(
      id: json['id'],
      hour: json['hour'],
      minute: json['minute'],
      medicationId: json['medication_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'medication_id': medicationId,
    };
  }

  String get formattedTime {
    String hourString = hour.toString().padLeft(2, '0');
    String minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }

  @override
  String toString() {
    return 'Posology(id: $id, time: $formattedTime, medicationId: $medicationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Posology &&
        other.id == id &&
        other.hour == hour &&
        other.minute == minute &&
        other.medicationId == medicationId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        hour.hashCode ^
        minute.hashCode ^
        medicationId.hashCode;
  }
}
