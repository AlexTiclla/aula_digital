import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/performance_chart.dart';
// import '../widgets/course_grades_card.dart';
import 'login_screen.dart';
import 'my_subjects_screen.dart';
import 'my_grades_screen.dart';
import 'grade_history_screen.dart';
import 'participation_screen.dart';
import 'attendance_screen.dart';
import 'my_teachers_screen.dart';
import 'my_tutor_screen.dart';
import 'prediction_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String? studentId;

  const StudentDashboard({
    Key? key,
    this.studentId,
  }) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DataService _dataService = DataService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  late Student? _student;
  late List<Semester> _semesters = [];
  late List<Course> _courses = [];
  late List<Grade> _grades = [];
  late String _selectedSemesterId = '';
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _selectedIndex = 0;
  int? _estudianteId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Intentar cargar datos del usuario autenticado
      _userData = await _userService.getEstudianteProfile();
      
      // Obtener ID del estudiante directamente del sharedpreferences
      if (_userData != null && _userData!.containsKey('id')) {
        // intentar obtenerlo de SharedPreferences
        _estudianteId = await _apiService.getCurrentEstudianteId();
        print('ID de estudiante obtenido de SharedPreferences: $_estudianteId');
      } else {

      }
      
      // Inicializar datos de prueba para asegurar que siempre haya algo que mostrar
      await _dataService.initialize();
      _semesters = _dataService.getSemesters();
      _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
      
      if (_userData != null) {
        // Cargar notas del estudiante desde la API
        if (_estudianteId != null) {
          try {
            // Cargar todas las notas del estudiante (para el gráfico de rendimiento)
            _grades = await _apiService.getNotasActualesEstudiante(_estudianteId!);
            print('Notas cargadas para el gráfico: ${_grades.length}');
          } catch (e) {
            print('Error al cargar notas: $e');
            _grades = [];
          }
          
          // Si no hay notas en la API, usar datos de prueba
          if (_grades.isEmpty) {
            final mockStudent = _dataService.getStudentById('1');
            _grades = mockStudent?.grades ?? [];
            print('Usando ${_grades.length} notas de prueba');
          }
          
          // Cargar materias de prueba si es necesario
          _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
        }
        
        // Crear estudiante con los datos cargados
        _student = Student(
          id: _estudianteId?.toString() ?? '0',
          name: "${_userData!['nombre'] ?? ''} ${_userData!['apellido'] ?? ''}",
          email: _userData!['email'] ?? '',
          grades: _grades,
        );
      } else {
        // Fallback a datos de prueba
        _student = _dataService.getStudentById(widget.studentId ?? '1');
        _grades = _student?.grades ?? [];
        _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
      }
      
    } catch (e) {
      print('Error cargando datos: $e');
      
      // Fallback a datos de prueba
      await _dataService.initialize();
      _student = _dataService.getStudentById(widget.studentId ?? '1');
      _semesters = _dataService.getSemesters();
      _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
      _grades = _student?.grades ?? [];
      _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
      
      // Mostrar diálogo de error solo si estamos montados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usando datos de prueba: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para cambiar el periodo seleccionado
  void _onSemesterChanged(String? newValue) async {
    if (newValue != null && newValue != _selectedSemesterId) {
      setState(() {
        _isLoading = true;
        _selectedSemesterId = newValue;
      });

      try {
        if (_estudianteId != null) {
          final periodoId = int.tryParse(_selectedSemesterId);
          if (periodoId != null) {

            
            // Actualizar el estudiante con las nuevas notas
            _student = Student(
              id: _student!.id,
              name: _student!.name,
              email: _student!.email,
              grades: _grades,
            );
          }
        } else {
          // Usar datos de prueba
          _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
          final mockStudent = _dataService.getStudentById('1');
          _grades = mockStudent?.grades.where((g) => g.semesterId == _selectedSemesterId).toList() ?? [];
          
          // Actualizar el estudiante con las nuevas notas
          _student = Student(
            id: _student!.id,
            name: _student!.name,
            email: _student!.email,
            grades: _grades,
          );
        }
      } catch (e) {
        print('Error al cambiar de periodo: $e');
        
        // Fallback a datos de prueba
        _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
        final mockStudent = _dataService.getStudentById('1');
        _grades = mockStudent?.grades.where((g) => g.semesterId == _selectedSemesterId).toList() ?? [];
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const MySubjectsScreen();
      case 2:
        return const MyGradesScreen();
      case 3:
        return const GradeHistoryScreen();
      case 4:
        return const ParticipationScreen();
      case 5:
        return const AttendanceScreen();
      case 6:
        return const MyTeachersScreen();
      case 7:
        return const MyTutorScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Theme.of(context).primaryColor, // puede ser el color
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Esta sección está en construcción',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_student == null) {
      return const Center(
        child: Text('Estudiante no encontrado'),
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

    return RefreshIndicator(
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
                    if (_userData != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.school, 'Estudiante', Theme.of(context).primaryColor),
                      if (_userData!.containsKey('direccion') && _userData!['direccion'] != null && _userData!['direccion'].toString().isNotEmpty)
                        _buildInfoRow(Icons.home, _userData!['direccion'], null),
                      if (_userData!.containsKey('tutor_nombre') && _userData!['tutor_nombre'] != null)
                        _buildInfoRow(Icons.person, 'Tutor: ${_userData!['tutor_nombre']}', null),
                    ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Historial de Rendimiento',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Promedio: ${currentAverage.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getColorForAverage(currentAverage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: historicalData.isEmpty
                          ? Center(child: Text('No hay datos de rendimiento disponibles'))
                          : PerformanceChart(
                              historicalData: historicalData,
                              currentAverage: currentAverage,
                              showDescription: true,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El gráfico muestra tu rendimiento basado en las notas obtenidas a lo largo del tiempo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_grades.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Resumen de Notas',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _buildNotasResumen(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección para predicciones de IA (ACTUALIZADA)
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
                          Icons.psychology,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Análisis de IA',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Descubre predicciones personalizadas sobre tu rendimiento académico basadas en tu historial de notas, asistencia y participación en clase.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PredictionScreen(
                              estudianteId: _estudianteId,
                              materiaName: 'Rendimiento General',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.insights),
                      label: const Text('Ver Predicciones'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Estudiante"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _student?.name.substring(0, 1) ?? 'E',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _student?.name ?? 'Estudiante',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _student?.email ?? 'estudiante@example.com',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(0, 'Mi Curso', Icons.school),
            _buildDrawerItem(1, 'Mis Materias', Icons.book),
            _buildDrawerItem(2, 'Mis Notas', Icons.grade),
            _buildDrawerItem(3, 'Historial de Notas', Icons.history),
            _buildDrawerItem(4, 'Participación', Icons.record_voice_over),
            _buildDrawerItem(5, 'Mi Asistencia', Icons.calendar_today),
            _buildDrawerItem(6, 'Mis Profesores', Icons.person),
            _buildDrawerItem(7, 'Mi Tutor', Icons.support_agent),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await _authService.logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _getSelectedScreen(),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        _onItemTapped(index);
      },
    );
  }

  Color _getColorForAverage(double average) {
    if (average >= 4.0) {
      return Colors.green;
    } else if (average >= 3.0) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  Widget _buildNotasResumen() {
    // Agrupar notas por materia
    final Map<String, List<Grade>> notasPorMateria = {};
    for (final nota in _grades) {
      if (!notasPorMateria.containsKey(nota.courseName)) {
        notasPorMateria[nota.courseName] = [];
      }
      notasPorMateria[nota.courseName]!.add(nota);
    }

    // Calcular promedios por materia
    final Map<String, double> promediosPorMateria = {};
    notasPorMateria.forEach((materia, notas) {
      final sum = notas.fold<double>(0, (sum, nota) => sum + nota.value);
      promediosPorMateria[materia] = sum / notas.length;
    });

    // Ordenar materias por promedio (de mayor a menor)
    final materias = promediosPorMateria.keys.toList()
      ..sort((a, b) => promediosPorMateria[b]!.compareTo(promediosPorMateria[a]!));

    // Limitar a 5 materias para no sobrecargar la UI
    final materiasAMostrar = materias.length > 5 ? materias.sublist(0, 5) : materias;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final materia in materiasAMostrar)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    materia,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: promediosPorMateria[materia]! / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForAverage(promediosPorMateria[materia]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  promediosPorMateria[materia]!.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getColorForAverage(promediosPorMateria[materia]!),
                  ),
                ),
              ],
            ),
          ),
        if (materias.length > 5)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navegar a la pantalla de notas completa
                _onItemTapped(2); // Índice de la pantalla de notas
              },
              child: const Text('Ver todas'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Color? color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
