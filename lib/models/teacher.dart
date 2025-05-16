class Teacher {
  final String id;
  final String name;
  final String email;
  final List<String> courseIds;
  
  Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.courseIds = const [],
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      courseIds: List<String>.from(map['courseIds'] ?? []),
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'courseIds': courseIds,
    };
  }
}
