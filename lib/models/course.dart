class Course {
  final String id;
  final String name;
  final String teacherId;
  final String semesterId;
  final String description;
  
  Course({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.semesterId,
    this.description = '',
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      teacherId: map['teacherId'],
      semesterId: map['semesterId'],
      description: map['description'] ?? '',
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'semesterId': semesterId,
      'description': description,
    };
  }
}
