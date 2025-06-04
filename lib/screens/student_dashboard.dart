import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/performance_chart.dart';
import '../widgets/course_grades_card.dart';
import 'login_screen.dart';
import 'my_subjects_screen.dart';
import 'my_grades_screen.dart';
import 'grade_history_screen.dart';

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
      
      // Obtener ID del estudiante directamente del perfil
      if (_userData != null && _userData!.containsKey('id')) {
        _estudianteId = _userData!['id'];
        print('ID de estudiante obtenido del perfil: $_estudianteId');
      } else {
        // Si no está en el perfil, intentar obtenerlo de SharedPreferences
        _estudianteId = await _apiService.getCurrentEstudianteId();
        print('ID de estudiante obtenido de SharedPreferences: $_estudianteId');
      }
      
      if (_userData != null) {
        // Cargar periodos desde la API
        final periodosData = await _apiService.getPeriodos();
        _semesters = periodosData.map((data) => Semester.fromMap(data)).toList();
        
        if (_semesters.isEmpty) {
          // Si no hay periodos en la API, usar datos de prueba
          await _dataService.initialize();
          _semesters = _dataService.getSemesters();
        }
        
        _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
        
        // Cargar notas y materias del estudiante desde la API
        if (_estudianteId != null) {
          final periodoId = int.tryParse(_selectedSemesterId);
          if (periodoId != null) {
            try {
              // Cargar materias inscritas del estudiante para este periodo
              _courses = await _apiService.getMateriasInscritasByEstudianteAndPeriodo(_estudianteId!, periodoId);
            } catch (e) {
              print('Error al cargar materias inscritas: $e');
              _courses = [];
            }
            
            try {
              // Cargar notas del estudiante para este periodo
              _grades = await _apiService.getNotasEstudianteByPeriodo(_estudianteId!, periodoId);
            } catch (e) {
              print('Error al cargar notas: $e');
              _grades = [];
            }
            
            // Si no hay materias o notas en la API, usar datos de prueba
            if (_courses.isEmpty || _grades.isEmpty) {
              await _dataService.initialize();
              if (_courses.isEmpty) {
                _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
              }
              if (_grades.isEmpty) {
                final mockStudent = _dataService.getStudentById('1');
                _grades = mockStudent?.grades.where((g) => g.semesterId == _selectedSemesterId).toList() ?? [];
              }
            }
          }
        }
        
        // Crear estudiante con los datos cargados
        _student = Student(
          id: _estudianteId?.toString() ?? '0',
          name: "${_userData!['nombre'] ?? ''} ${_userData!['apellido'] ?? ''}",
          email: _userData!['email'] ?? '',
          grades: _grades,
        );
      } else {
        // Fallback a datos de prueba solo si no hay datos de usuario
        await _dataService.initialize();
        _student = _dataService.getStudentById(widget.studentId ?? '1');
        _semesters = _dataService.getSemesters();
        _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
        _grades = _student?.grades ?? [];
        _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
      }
      
    } catch (e) {
      print('Error cargando datos: $e');
      
      // Mostrar diálogo de error solo si estamos montados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar la información del estudiante: $e'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
      
      // Fallback a datos de prueba
      await _dataService.initialize();
      _student = _dataService.getStudentById(widget.studentId ?? '1');
      _semesters = _dataService.getSemesters();
      _selectedSemesterId = _semesters.isNotEmpty ? _semesters.last.id : '';
      _grades = _student?.grades ?? [];
      _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
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
            // Cargar materias inscritas del estudiante para este periodo
            _courses = await _apiService.getMateriasInscritasByEstudianteAndPeriodo(_estudianteId!, periodoId);
            
            // Cargar notas del estudiante para este periodo
            _grades = await _apiService.getNotasEstudianteByPeriodo(_estudianteId!, periodoId);
            
            // Si no hay materias o notas en la API, usar datos de prueba
            if (_courses.isEmpty) {
              _courses = _dataService.getCoursesBySemester(_selectedSemesterId);
            }
            
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
        return _buildPlaceholderScreen('Participación');
      case 5:
        return _buildPlaceholderScreen('Mi Asistencia');
      case 6:
        return _buildPlaceholderScreen('Mis Profesores');
      case 7:
        return _buildPlaceholderScreen('Mi Tutor');
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
            color: Theme.of(context).primaryColor,
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
                    Text(
                      'Historial de Rendimiento',
                      style: Theme.of(context).textTheme.titleMedium,
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
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selector de semestre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: _selectedSemesterId,
                  onChanged: _onSemesterChanged,
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
                  child: Text('No hay cursos registrados para este bimestre.'),
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
        title: const Text('Dashboard Estudiante'),
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
}
