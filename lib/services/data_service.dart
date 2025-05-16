import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

// Este servicio simula la obtención de datos desde una API o base de datos
class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Datos de ejemplo
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  List<Course> _courses = [];
  List<Semester> _semesters = [];

  // Inicializar datos de ejemplo
  Future<void> initialize() async {
    await _loadSemesters();
    await _loadCourses();
    await _loadTeachers();
    await _loadStudents();
  }

  // Cargar datos de semestres
  Future<void> _loadSemesters() async {
    _semesters = [
      Semester(
        id: '1',
        name: '2024-1',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 6, 30),
      ),
      Semester(
        id: '2',
        name: '2024-2',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 12, 31),
      ),
      Semester(
        id: '3',
        name: '2025-1',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 6, 30),
      ),
    ];
  }

  // Cargar datos de cursos
  Future<void> _loadCourses() async {
    _courses = [
      Course(
        id: '1',
        name: 'Matemáticas',
        teacherId: '1',
        semesterId: '1',
        description: 'Curso de matemáticas básicas',
      ),
      Course(
        id: '2',
        name: 'Física',
        teacherId: '2',
        semesterId: '1',
        description: 'Curso de física básica',
      ),
      Course(
        id: '3',
        name: 'Programación',
        teacherId: '1',
        semesterId: '2',
        description: 'Introducción a la programación',
      ),
      Course(
        id: '4',
        name: 'Bases de Datos',
        teacherId: '2',
        semesterId: '2',
        description: 'Diseño y gestión de bases de datos',
      ),
    ];
  }

  // Cargar datos de profesores
  Future<void> _loadTeachers() async {
    _teachers = [
      Teacher(
        id: '1',
        name: 'Juan Pérez',
        email: 'juan.perez@universidad.edu',
        courseIds: ['1', '3'],
      ),
      Teacher(
        id: '2',
        name: 'María López',
        email: 'maria.lopez@universidad.edu',
        courseIds: ['2', '4'],
      ),
    ];
  }

  // Cargar datos de estudiantes con sus notas
  Future<void> _loadStudents() async {
    _students = [
      Student(
        id: '1',
        name: 'Carlos Rodríguez',
        email: 'carlos.rodriguez@universidad.edu',
        grades: [
          Grade(
            id: '1',
            studentId: '1',
            courseId: '1',
            courseName: 'Matemáticas',
            semesterId: '1',
            value: 85.0,
            date: DateTime(2024, 3, 15),
          ),
          Grade(
            id: '2',
            studentId: '1',
            courseId: '2',
            courseName: 'Física',
            semesterId: '1',
            value: 78.0,
            date: DateTime(2024, 3, 20),
          ),
          Grade(
            id: '3',
            studentId: '1',
            courseId: '3',
            courseName: 'Programación',
            semesterId: '2',
            value: 92.0,
            date: DateTime(2024, 8, 10),
          ),
        ],
      ),
      Student(
        id: '2',
        name: 'Ana Martínez',
        email: 'ana.martinez@universidad.edu',
        grades: [
          Grade(
            id: '4',
            studentId: '2',
            courseId: '1',
            courseName: 'Matemáticas',
            semesterId: '1',
            value: 90.0,
            date: DateTime(2024, 3, 15),
          ),
          Grade(
            id: '5',
            studentId: '2',
            courseId: '2',
            courseName: 'Física',
            semesterId: '1',
            value: 88.0,
            date: DateTime(2024, 3, 20),
          ),
          Grade(
            id: '6',
            studentId: '2',
            courseId: '4',
            courseName: 'Bases de Datos',
            semesterId: '2',
            value: 95.0,
            date: DateTime(2024, 8, 15),
          ),
        ],
      ),
    ];
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
    return _courses.where((course) => course.semesterId == semesterId).toList();
  }

  // Obtener cursos por profesor
  List<Course> getCoursesByTeacher(String teacherId) {
    return _courses.where((course) => course.teacherId == teacherId).toList();
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
