import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'package:http/http.dart' as http;

// Este servicio simula la obtención de datos desde una API o base de datos
class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  bool _initialized = false;
  final List<Student> _students = [];
  final List<Teacher> _teachers = [];
  final List<Course> _courses = [];
  final List<Semester> _semesters = [];
  final List<Grade> _grades = [];

  Future<void> initialize() async {
    if (_initialized) return;

    // En un caso real, aquí cargaríamos datos del API
    // Por ahora usamos datos de ejemplo
    _loadMockData();
    _initialized = true;
  }

  void _loadMockData() {
    // Crear semestres (bimestres)
    _semesters.addAll([
      Semester(
        id: '1',
        name: 'Primer Bimestre 2023',
        startDate: DateTime(2023, 2, 1),
        endDate: DateTime(2023, 4, 15),
      ),
      Semester(
        id: '2',
        name: 'Segundo Bimestre 2023',
        startDate: DateTime(2023, 4, 16),
        endDate: DateTime(2023, 6, 30),
      ),
      Semester(
        id: '3',
        name: 'Tercer Bimestre 2023',
        startDate: DateTime(2023, 7, 1),
        endDate: DateTime(2023, 9, 15),
      ),
      Semester(
        id: '4',
        name: 'Cuarto Bimestre 2023',
        startDate: DateTime(2023, 9, 16),
        endDate: DateTime(2023, 12, 15),
      ),
    ]);

    // Crear cursos
    _courses.addAll([
      Course(
        id: '1',
        name: 'Matemáticas',
        teacher: 'Prof. García',
        credits: 4,
        semesterId: '1',
      ),
      Course(
        id: '2',
        name: 'Literatura',
        teacher: 'Prof. Rodríguez',
        credits: 3,
        semesterId: '1',
      ),
      Course(
        id: '3',
        name: 'Ciencias Naturales',
        teacher: 'Prof. López',
        credits: 4,
        semesterId: '1',
      ),
      Course(
        id: '4',
        name: 'Historia',
        teacher: 'Prof. Martínez',
        credits: 3,
        semesterId: '2',
      ),
      Course(
        id: '5',
        name: 'Inglés',
        teacher: 'Prof. Wilson',
        credits: 2,
        semesterId: '2',
      ),
    ]);

    // Crear notas con descripciones
    final List<Grade> grades = [
      // Primer bimestre
      Grade(
        id: '1',
        studentId: '1',
        courseId: '1',
        courseName: 'Matemáticas',
        semesterId: '1',
        value: 85,
        date: DateTime(2023, 2, 15),
        description: 'Examen parcial',
      ),
      Grade(
        id: '2',
        studentId: '1',
        courseId: '1',
        courseName: 'Matemáticas',
        semesterId: '1',
        value: 90,
        date: DateTime(2023, 3, 30),
        description: 'Examen final',
      ),
      Grade(
        id: '3',
        studentId: '1',
        courseId: '2',
        courseName: 'Literatura',
        semesterId: '1',
        value: 78,
        date: DateTime(2023, 2, 20),
        description: 'Ensayo literario',
      ),
      Grade(
        id: '4',
        studentId: '1',
        courseId: '2',
        courseName: 'Literatura',
        semesterId: '1',
        value: 82,
        date: DateTime(2023, 4, 5),
        description: 'Examen final',
      ),
      Grade(
        id: '5',
        studentId: '1',
        courseId: '3',
        courseName: 'Ciencias Naturales',
        semesterId: '1',
        value: 88,
        date: DateTime(2023, 3, 10),
        description: 'Proyecto de laboratorio',
      ),
      Grade(
        id: '6',
        studentId: '1',
        courseId: '3',
        courseName: 'Ciencias Naturales',
        semesterId: '1',
        value: 92,
        date: DateTime(2023, 4, 10),
        description: 'Examen final',
      ),
      
      // Segundo bimestre
      Grade(
        id: '7',
        studentId: '1',
        courseId: '1',
        courseName: 'Matemáticas',
        semesterId: '2',
        value: 87,
        date: DateTime(2023, 5, 15),
        description: 'Examen parcial',
      ),
      Grade(
        id: '8',
        studentId: '1',
        courseId: '1',
        courseName: 'Matemáticas',
        semesterId: '2',
        value: 91,
        date: DateTime(2023, 6, 25),
        description: 'Examen final',
      ),
      Grade(
        id: '9',
        studentId: '1',
        courseId: '4',
        courseName: 'Historia',
        semesterId: '2',
        value: 76,
        date: DateTime(2023, 5, 20),
        description: 'Ensayo histórico',
      ),
      Grade(
        id: '10',
        studentId: '1',
        courseId: '4',
        courseName: 'Historia',
        semesterId: '2',
        value: 80,
        date: DateTime(2023, 6, 20),
        description: 'Examen final',
      ),
      Grade(
        id: '11',
        studentId: '1',
        courseId: '5',
        courseName: 'Inglés',
        semesterId: '2',
        value: 85,
        date: DateTime(2023, 5, 10),
        description: 'Presentación oral',
      ),
      Grade(
        id: '12',
        studentId: '1',
        courseId: '5',
        courseName: 'Inglés',
        semesterId: '2',
        value: 88,
        date: DateTime(2023, 6, 15),
        description: 'Examen final',
      ),
      
      // Tercer bimestre
      Grade(
        id: '13',
        studentId: '1',
        courseId: '2',
        courseName: 'Literatura',
        semesterId: '3',
        value: 83,
        date: DateTime(2023, 7, 20),
        description: 'Análisis literario',
      ),
      Grade(
        id: '14',
        studentId: '1',
        courseId: '2',
        courseName: 'Literatura',
        semesterId: '3',
        value: 89,
        date: DateTime(2023, 9, 5),
        description: 'Examen final',
      ),
      Grade(
        id: '15',
        studentId: '1',
        courseId: '3',
        courseName: 'Ciencias Naturales',
        semesterId: '3',
        value: 90,
        date: DateTime(2023, 8, 10),
        description: 'Proyecto de investigación',
      ),
      Grade(
        id: '16',
        studentId: '1',
        courseId: '3',
        courseName: 'Ciencias Naturales',
        semesterId: '3',
        value: 94,
        date: DateTime(2023, 9, 10),
        description: 'Examen final',
      ),
      
      // Cuarto bimestre
      Grade(
        id: '17',
        studentId: '1',
        courseId: '4',
        courseName: 'Historia',
        semesterId: '4',
        value: 79,
        date: DateTime(2023, 10, 15),
        description: 'Proyecto histórico',
      ),
      Grade(
        id: '18',
        studentId: '1',
        courseId: '4',
        courseName: 'Historia',
        semesterId: '4',
        value: 84,
        date: DateTime(2023, 12, 5),
        description: 'Examen final',
      ),
      Grade(
        id: '19',
        studentId: '1',
        courseId: '5',
        courseName: 'Inglés',
        semesterId: '4',
        value: 87,
        date: DateTime(2023, 10, 20),
        description: 'Composición escrita',
      ),
      Grade(
        id: '20',
        studentId: '1',
        courseId: '5',
        courseName: 'Inglés',
        semesterId: '4',
        value: 90,
        date: DateTime(2023, 12, 1),
        description: 'Examen final',
      ),
    ];
    
    _grades.addAll(grades);

    // Crear estudiante
    _students.add(
      Student(
        id: '1',
        name: 'Juan Pérez',
        email: 'juan.perez@example.com',
        grades: _grades,
      ),
    );
  }

  // Métodos para obtener datos
  List<Student> getStudents() => _students;
  List<Teacher> getTeachers() => _teachers;
  List<Course> getCourses() => _courses;
  List<Semester> getSemesters() => _semesters;

  // Obtener un estudiante por ID
  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener un profesor por ID
  Teacher? getTeacherById(String id) {
    try {
      return _teachers.firstWhere((teacher) => teacher.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener cursos por semestre
  List<Course> getCoursesBySemester(String semesterId) {
    // Obtener IDs de cursos que tienen notas en este semestre
    final courseIds = _grades
        .where((grade) => grade.semesterId == semesterId)
        .map((grade) => grade.courseId)
        .toSet()
        .toList();

    // Obtener los cursos correspondientes
    return _courses
        .where((course) => courseIds.contains(course.id))
        .toList();
  }

  // Obtener cursos por profesor
  List<Course> getCoursesByTeacher(String teacherName) {
    return _courses.where((course) => course.teacher == teacherName).toList();
  }

  // Agregar una nueva nota
  void addGrade(Grade grade) {
    final student = getStudentById(grade.studentId);
    if (student != null) {
      final index = _students.indexOf(student);
      final updatedGrades = List<Grade>.from(student.grades)..add(grade);
      final updatedStudent = Student(
        id: student.id,
        name: student.name,
        email: student.email,
        grades: updatedGrades,
      );
      _students[index] = updatedStudent;
    }
  }
}
