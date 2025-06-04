class Grade {
  final String id;
  final String studentId;
  final String courseId;
  final String courseName;
  final String semesterId;
  final double value;
  final DateTime date;
  final String? comments;
  final String description;
  
  Grade({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseName,
    required this.semesterId,
    required this.value,
    required this.date,
    this.comments,
    this.description = '',
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'].toString(),
      studentId: map['estudiante_id'].toString(),
      courseId: map['curso_materia_id'].toString(),
      courseName: map['courseName'] ?? 'Sin nombre',
      semesterId: map['semesterId'] ?? '1',
      value: (map['valor'] is int) ? (map['valor'] as int).toDouble() : map['valor'].toDouble(),
      date: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      comments: map['comments'],
      description: map['descripcion'] ?? '',
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estudiante_id': studentId,
      'curso_materia_id': courseId,
      'courseName': courseName,
      'semesterId': semesterId,
      'valor': value,
      'fecha': date.toIso8601String(),
      'comments': comments,
      'descripcion': description,
    };
  }
}
