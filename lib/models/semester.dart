class Semester {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? description;
  
  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.description,
  });
  
  // Verificar si un semestre está activo actualmente
  bool isCurrentlyActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'].toString(),
      name: map['descripcion'] ?? 'Bimestre ${map['bimestre']} - ${map['anio']}',
      startDate: DateTime.parse(map['fecha_inicio']),
      endDate: DateTime.parse(map['fecha_fin']),
      isActive: map['is_active'] ?? true,
      description: map['descripcion'],
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate.toIso8601String(),
      'is_active': isActive,
      'descripcion': description,
    };
  }
}
