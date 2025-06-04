export 'student.dart';
export 'teacher.dart';
export 'grade.dart';
export 'semester.dart';
export 'course.dart';
export 'subject.dart';

// Añadir la clase HistoricalGradeData para representar los datos históricos de notas
class HistoricalGradeData {
  final DateTime date;
  final double grade;
  final String description;

  HistoricalGradeData({
    required this.date,
    required this.grade,
    required this.description,
  });
}
