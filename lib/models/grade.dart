class Grade {
  final String id;
  final String studentId;
  final String courseId;
  final String courseName;
  final String semesterId;
  final double value;
  final DateTime date;
  final String? comments;
  
  Grade({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseName,
    required this.semesterId,
    required this.value,
    required this.date,
    this.comments,
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      studentId: map['studentId'],
      courseId: map['courseId'],
      courseName: map['courseName'],
      semesterId: map['semesterId'],
      value: map['value'].toDouble(),
      date: DateTime.parse(map['date']),
      comments: map['comments'],
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'courseName': courseName,
      'semesterId': semesterId,
      'value': value,
      'date': date.toIso8601String(),
      'comments': comments,
    };
  }
}
