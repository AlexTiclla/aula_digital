import 'grade.dart';
import 'semester.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final List<Grade> grades;
  
  Student({
    required this.id,
    required this.name,
    required this.email,
    this.grades = const [],
  });

  // Obtener las notas de un semestre específico
  List<Grade> getGradesBySemester(String semesterId) {
    return grades.where((grade) => grade.semesterId == semesterId).toList();
  }

  // Calcular el promedio de notas por semestre
  double getAverageBySemester(String semesterId) {
    final semesterGrades = getGradesBySemester(semesterId);
    if (semesterGrades.isEmpty) return 0.0;
    
    final sum = semesterGrades.fold(0.0, (sum, grade) => sum + grade.value);
    return sum / semesterGrades.length;
  }

  // Calcular el promedio general de todas las notas
  double getOverallAverage() {
    if (grades.isEmpty) return 0.0;
    
    final sum = grades.fold(0.0, (sum, grade) => sum + grade.value);
    return sum / grades.length;
  }

  // Obtener datos históricos para gráficos
  Map<String, double> getHistoricalData(List<Semester> semesters) {
    final Map<String, double> historicalData = {};
    
    for (final semester in semesters) {
      historicalData[semester.name] = getAverageBySemester(semester.id);
    }
    
    return historicalData;
  }
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      grades: map['grades'] != null 
        ? List<Grade>.from(map['grades'].map((x) => Grade.fromMap(x)))
        : [],
    );
  }
  
  // Convertir a mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'grades': grades.map((x) => x.toMap()).toList(),
    };
  }
}
