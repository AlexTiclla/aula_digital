import 'grade.dart';
import 'semester.dart';
import 'models.dart';

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
    if (grades.isEmpty) {
      return 70.0; // Valor por defecto para mostrar en la interfaz
    }
    final sum = grades.fold<double>(0, (sum, grade) => sum + grade.value);
    return sum / grades.length;
  }

  // Obtener datos históricos para gráficos
  List<HistoricalGradeData> getHistoricalData(List<Semester> semesters) {
    final List<HistoricalGradeData> result = [];
    
    if (grades.isEmpty) {
      // Generar datos de ejemplo si no hay notas reales
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 3, 1);
      
      for (int i = 0; i < 5; i++) {
        final date = startDate.add(Duration(days: i * 15));
        result.add(
          HistoricalGradeData(
            date: date,
            grade: 70.0 + (i * 5), // Notas que van mejorando
            description: 'Nota de ejemplo ${i + 1}',
          ),
        );
      }
      
      return result;
    }
    
    // Ordenar notas por fecha
    final sortedGrades = List<Grade>.from(grades);
    sortedGrades.sort((a, b) => a.date.compareTo(b.date));
    
    // Convertir cada nota a un punto de datos históricos
    for (var grade in sortedGrades) {
      // Encontrar el semestre correspondiente para contexto
      final semester = semesters.firstWhere(
        (s) => s.id == grade.semesterId,
        orElse: () => Semester(id: '', name: 'Desconocido', startDate: DateTime.now(), endDate: DateTime.now()),
      );
      
      // Crear descripción significativa
      String description = '${grade.description} - ${grade.courseName}';
      if (description.trim() == '-') {
        description = grade.courseName;
      }
      
      result.add(
        HistoricalGradeData(
          date: grade.date,
          grade: grade.value,
          description: description,
        ),
      );
    }
    
    // Si hay menos de 3 puntos de datos, agregar algunos puntos adicionales
    if (result.length < 3) {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      
      for (int i = result.length; i < 3; i++) {
        final date = startDate.add(Duration(days: i * 10));
        result.add(
          HistoricalGradeData(
            date: date,
            grade: 75.0 + (i * 5),
            description: 'Nota estimada ${i + 1}',
          ),
        );
      }
    }
    
    return result;
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
