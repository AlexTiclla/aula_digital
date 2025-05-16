import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';

class TeacherDashboard extends StatefulWidget {
  final String teacherId;

  const TeacherDashboard({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final DataService _dataService = DataService();
  late Teacher? _teacher;
  late List<Semester> _semesters;
  late String _selectedSemesterId;
  late List<Course> _teacherCourses;
  late String _selectedCourseId;
  List<Student> _students = [];
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
    _teacher = _dataService.getTeacherById(widget.teacherId);
    _semesters = _dataService.getSemesters();
    
    // Seleccionar el semestre más reciente por defecto
    _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
    
    // Obtener cursos del profesor en el semestre seleccionado
    _teacherCourses = _dataService.getCoursesByTeacher(widget.teacherId)
      .where((course) => course.semesterId == _selectedSemesterId)
      .toList();
    
    // Seleccionar el primer curso por defecto
    _selectedCourseId = _teacherCourses.isNotEmpty ? _teacherCourses.first.id : '';
    
    // Cargar estudiantes
    _loadStudents();

    setState(() {
      _isLoading = false;
    });
  }

  void _loadStudents() {
    if (_selectedCourseId.isEmpty) {
      _students = [];
      return;
    }
    
    // Obtener todos los estudiantes
    final allStudents = _dataService.getStudents();
    
    // Filtrar estudiantes que tienen notas en el curso seleccionado
    _students = allStudents.where((student) {
      return student.grades.any((grade) => 
        grade.courseId == _selectedCourseId && 
        grade.semesterId == _selectedSemesterId
      );
    }).toList();
  }

  void _onSemesterChanged(String? semesterId) {
    if (semesterId == null) return;
    
    setState(() {
      _selectedSemesterId = semesterId;
      
      // Actualizar cursos del profesor en el nuevo semestre
      _teacherCourses = _dataService.getCoursesByTeacher(widget.teacherId)
        .where((course) => course.semesterId == _selectedSemesterId)
        .toList();
      
      // Actualizar curso seleccionado
      _selectedCourseId = _teacherCourses.isNotEmpty ? _teacherCourses.first.id : '';
      
      // Recargar estudiantes
      _loadStudents();
    });
  }

  void _onCourseChanged(String? courseId) {
    if (courseId == null) return;
    
    setState(() {
      _selectedCourseId = courseId;
      _loadStudents();
    });
  }

  void _showAddGradeDialog(Student student) {
    final TextEditingController gradeController = TextEditingController();
    final TextEditingController commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar nota para ${student.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: 'Nota (0-100)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios (opcional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Validar nota
                final gradeText = gradeController.text.trim();
                if (gradeText.isEmpty) {
                  return;
                }
                
                final grade = double.tryParse(gradeText);
                if (grade == null || grade < 0 || grade > 100) {
                  return;
                }
                
                // Crear nueva nota
                final selectedCourse = _teacherCourses.firstWhere(
                  (course) => course.id == _selectedCourseId
                );
                
                final newGrade = Grade(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  studentId: student.id,
                  courseId: _selectedCourseId,
                  courseName: selectedCourse.name,
                  semesterId: _selectedSemesterId,
                  value: grade,
                  date: DateTime.now(),
                  comments: commentsController.text.trim().isNotEmpty 
                    ? commentsController.text.trim() 
                    : null,
                );
                
                // Agregar nota
                _dataService.addGrade(newGrade);
                
                // Cerrar diálogo y recargar datos
                Navigator.of(context).pop();
                _loadData();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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

    if (_teacher == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Profesor'),
        ),
        body: const Center(
          child: Text('Profesor no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Profesor'),
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
              // Información del profesor
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          _teacher!.name.substring(0, 1),
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
                              _teacher!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _teacher!.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Selectores de semestre y curso
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Notas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Semestre',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedSemesterId,
                              onChanged: _onSemesterChanged,
                              items: _semesters.map<DropdownMenuItem<String>>((Semester semester) {
                                return DropdownMenuItem<String>(
                                  value: semester.id,
                                  child: Text(semester.name),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Curso',
                                border: OutlineInputBorder(),
                              ),
                              value: _teacherCourses.isNotEmpty ? _selectedCourseId : null,
                              onChanged: _onCourseChanged,
                              items: _teacherCourses.map<DropdownMenuItem<String>>((Course course) {
                                return DropdownMenuItem<String>(
                                  value: course.id,
                                  child: Text(course.name),
                                );
                              }).toList(),
                              disabledHint: const Text('No hay cursos disponibles'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Lista de estudiantes
              if (_teacherCourses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No tienes cursos asignados en este semestre.'),
                  ),
                )
              else if (_students.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay estudiantes registrados en este curso.'),
                  ),
                )
              else
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estudiantes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Aquí se podría implementar la funcionalidad para agregar estudiantes
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Agregar Estudiante'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final courseGrades = student.grades.where((grade) => 
                              grade.courseId == _selectedCourseId && 
                              grade.semesterId == _selectedSemesterId
                            ).toList();
                            
                            double average = 0.0;
                            if (courseGrades.isNotEmpty) {
                              final sum = courseGrades.fold(0.0, (sum, grade) => sum + grade.value);
                              average = sum / courseGrades.length;
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ExpansionTile(
                                title: Text(student.name),
                                subtitle: Text('Promedio: ${average.toStringAsFixed(1)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _showAddGradeDialog(student),
                                  tooltip: 'Agregar nota',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Notas:',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        if (courseGrades.isEmpty)
                                          const Text('No hay notas registradas.')
                                        else
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: courseGrades.length,
                                            itemBuilder: (context, idx) {
                                              final grade = courseGrades[idx];
                                              return ListTile(
                                                dense: true,
                                                title: Text('Nota: ${grade.value.toStringAsFixed(1)}'),
                                                subtitle: Text('Fecha: ${_formatDate(grade.date)}${grade.comments != null ? '\nComentarios: ${grade.comments}' : ''}'),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
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
                            'Análisis de IA',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Próximamente: Análisis predictivo del rendimiento de los estudiantes y recomendaciones personalizadas para mejorar el desempeño del grupo.',
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
