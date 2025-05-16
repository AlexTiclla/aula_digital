import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../widgets/performance_chart.dart';
import '../widgets/course_grades_card.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;

  const StudentDashboard({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DataService _dataService = DataService();
  late Student? _student;
  late List<Semester> _semesters;
  late String _selectedSemesterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _dataService.initialize();
    _student = _dataService.getStudentById(widget.studentId);
    _semesters = _dataService.getSemesters();
    
    // Seleccionar el semestre más reciente por defecto
    _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Estudiante'),
        ),
        body: const Center(
          child: Text('Estudiante no encontrado'),
        ),
      );
    }

    final historicalData = _student!.getHistoricalData(_semesters);
    final currentAverage = _student!.getOverallAverage();
    final semesterGrades = _student!.getGradesBySemester(_selectedSemesterId);
    
    // Agrupar notas por curso
    final Map<String, List<Grade>> gradesByCourse = {};
    for (final grade in semesterGrades) {
      if (!gradesByCourse.containsKey(grade.courseId)) {
        gradesByCourse[grade.courseId] = [];
      }
      gradesByCourse[grade.courseId]!.add(grade);
    }
    
    // Obtener cursos del semestre seleccionado
    final semesterCourses = _dataService.getCoursesBySemester(_selectedSemesterId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Estudiante'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del estudiante
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              _student!.name.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _student!.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _student!.email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Gráfico de rendimiento
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PerformanceChart(
                    historicalData: historicalData,
                    currentAverage: currentAverage,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Selector de semestre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notas del semestre',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DropdownButton<String>(
                    value: _selectedSemesterId,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSemesterId = newValue;
                        });
                      }
                    },
                    items: _semesters.map<DropdownMenuItem<String>>((Semester semester) {
                      return DropdownMenuItem<String>(
                        value: semester.id,
                        child: Text(semester.name),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Notas por curso
              ...semesterCourses.map((course) {
                final courseGrades = gradesByCourse[course.id] ?? [];
                return CourseGradesCard(
                  course: course,
                  grades: courseGrades,
                );
              }).toList(),
              
              // Mensaje si no hay cursos
              if (semesterCourses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay cursos registrados para este semestre.'),
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Sección para futuras predicciones de IA
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Predicciones de IA',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Próximamente: Predicciones de notas basadas en tu rendimiento histórico y recomendaciones personalizadas para mejorar tu desempeño académico.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
