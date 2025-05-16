class Semester {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  
  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });
  
  // Verificar si un semestre está activo
  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
