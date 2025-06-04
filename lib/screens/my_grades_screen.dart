import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyGradesScreen extends StatefulWidget {
  const MyGradesScreen({Key? key}) : super(key: key);

  @override
  _MyGradesScreenState createState() => _MyGradesScreenState();
}

class _MyGradesScreenState extends State<MyGradesScreen> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Grade> _grades = [];
  String _errorMessage = '';
  
  // Agrupar notas por materia
  Map<String, List<Grade>> _gradesBySubject = {};

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener el ID de estudiante directamente del AuthService
      final estudianteId = await _authService.getEstudianteId();
      
      if (estudianteId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró ID de estudiante';
        });
        return;
      }
      
      print('Cargando notas para estudiante ID: $estudianteId');

      final grades = await _apiService.getNotasActualesEstudiante(estudianteId);
      
      // Agrupar por nombre de materia
      final Map<String, List<Grade>> gradesBySubject = {};
      for (var grade in grades) {
        if (!gradesBySubject.containsKey(grade.courseName)) {
          gradesBySubject[grade.courseName] = [];
        }
        gradesBySubject[grade.courseName]!.add(grade);
      }
      
      setState(() {
        _grades = grades;
        _gradesBySubject = gradesBySubject;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar notas: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas'),
        backgroundColor: Colors.indigo,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGrades,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_grades.isEmpty) {
      return const Center(
        child: Text(
          'No tienes notas registradas en este periodo',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gradesBySubject.length,
        itemBuilder: (context, index) {
          final subject = _gradesBySubject.keys.elementAt(index);
          final grades = _gradesBySubject[subject]!;
          return SubjectGradesCard(
            subject: subject,
            grades: grades,
          );
        },
      ),
    );
  }
}

class SubjectGradesCard extends StatelessWidget {
  final String subject;
  final List<Grade> grades;

  const SubjectGradesCard({
    Key? key,
    required this.subject,
    required this.grades,
  }) : super(key: key);

  // Calcular promedio de notas
  double get average {
    if (grades.isEmpty) return 0;
    final sum = grades.fold(0.0, (sum, grade) => sum + grade.value);
    return sum / grades.length;
  }

  // Determinar color según el promedio
  Color get averageColor {
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con nombre de materia y promedio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: averageColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Prom: ${average.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: averageColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de notas
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return ListTile(
                title: Text(
                  grade.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Fecha: ${dateFormat.format(grade.date)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade.value).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    grade.value.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getGradeColor(grade.value),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Determinar color según la nota
  Color _getGradeColor(double grade) {
    if (grade >= 80) return Colors.green;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }
} 