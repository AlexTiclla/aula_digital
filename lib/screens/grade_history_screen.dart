import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Grade History esta por eliminarse
class GradeHistoryScreen extends StatefulWidget {
  const GradeHistoryScreen({Key? key}) : super(key: key);

  @override
  _GradeHistoryScreenState createState() => _GradeHistoryScreenState();
}

class _GradeHistoryScreenState extends State<GradeHistoryScreen> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Grade> _grades = [];
  String _errorMessage = '';
  
  // Agrupar notas por periodo y materia
  Map<String, Map<String, List<Grade>>> _gradesByPeriodAndSubject = {};
  List<String> _periods = [];

  @override
  void initState() {
    super.initState();
    _loadGradeHistory();
  }

  Future<void> _loadGradeHistory() async {
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
      
      print('Cargando historial de notas para estudiante ID: $estudianteId');

      final grades = await _apiService.getHistorialNotasEstudiante(estudianteId);
      
      // Agrupar por periodo y materia
      final Map<String, Map<String, List<Grade>>> gradesByPeriodAndSubject = {};
      final Set<String> periods = {};
      
      for (var grade in grades) {
        final periodId = grade.semesterId;
        periods.add(periodId);
        
        if (!gradesByPeriodAndSubject.containsKey(periodId)) {
          gradesByPeriodAndSubject[periodId] = {};
        }
        
        if (!gradesByPeriodAndSubject[periodId]!.containsKey(grade.courseName)) {
          gradesByPeriodAndSubject[periodId]![grade.courseName] = [];
        }
        
        gradesByPeriodAndSubject[periodId]![grade.courseName]!.add(grade);
      }
      
      setState(() {
        _grades = grades;
        _gradesByPeriodAndSubject = gradesByPeriodAndSubject;
        _periods = periods.toList()..sort(); // Ordenar periodos
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar historial de notas: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Notas'),
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
              onPressed: _loadGradeHistory,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_grades.isEmpty) {
      return const Center(
        child: Text(
          'No hay historial de notas disponible',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGradeHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final periodId = _periods[index];
          final subjectsInPeriod = _gradesByPeriodAndSubject[periodId]!;
          
          return PeriodCard(
            periodId: periodId,
            subjectsGrades: subjectsInPeriod,
          );
        },
      ),
    );
  }
}

class PeriodCard extends StatelessWidget {
  final String periodId;
  final Map<String, List<Grade>> subjectsGrades;

  const PeriodCard({
    Key? key,
    required this.periodId,
    required this.subjectsGrades,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del periodo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Periodo $periodId',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Lista de materias en este periodo
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjectsGrades.length,
            itemBuilder: (context, index) {
              final subject = subjectsGrades.keys.elementAt(index);
              final grades = subjectsGrades[subject]!;
              
              return ExpansionTile(
                title: Text(
                  subject,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Promedio: ${_calculateAverage(grades).toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _getAverageColor(_calculateAverage(grades)),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  _buildGradesList(grades),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradesList(List<Grade> grades) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: grades.map((grade) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.description,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Fecha: ${dateFormat.format(grade.date)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
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
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Calcular promedio de notas
  double _calculateAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0;
    final sum = grades.fold(0.0, (sum, grade) => sum + grade.value);
    return sum / grades.length;
  }
  
  // Determinar color según el promedio
  Color _getAverageColor(double average) {
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }
  
  // Determinar color según la nota
  Color _getGradeColor(double grade) {
    if (grade >= 80) return Colors.green;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }
} 