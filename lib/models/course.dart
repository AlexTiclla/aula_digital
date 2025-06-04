class Course {
  final String id;
  final String name;
  final String teacher;
  final int credits;
  final String? description;
  final String semesterId;
  
  Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.credits,
    this.description,
    this.semesterId = '',
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      name: json['nombre'] ?? json['name'] ?? 'Sin nombre',
      teacher: json['teacher'] ?? 'Sin profesor',
      credits: json['horas_semanales'] ?? json['credits'] ?? 0,
      description: json['descripcion'] ?? json['description'],
      semesterId: json['semesterId'] ?? '',
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'teacher': teacher,
      'horas_semanales': credits,
      'descripcion': description,
      'semesterId': semesterId,
    };
  }
}
