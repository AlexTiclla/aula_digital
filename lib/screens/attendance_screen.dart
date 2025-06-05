import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Asistencia> _asistencias = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener el ID de estudiante
      final estudianteId = await _authService.getEstudianteId();
      
      if (estudianteId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró ID de estudiante';
        });
        return;
      }
      
      print('Cargando asistencias para estudiante ID: $estudianteId');

      final asistencias = await _apiService.getAsistenciasEstudiante(estudianteId);
      
      setState(() {
        _asistencias = asistencias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar asistencias: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              onPressed: _loadAsistencias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_asistencias.isEmpty) {
      return const Center(
        child: Text(
          'No tienes registros de asistencia',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Agrupar asistencias por materia
    final Map<String, List<Asistencia>> asistenciasPorMateria = {};
    for (var asistencia in _asistencias) {
      if (!asistenciasPorMateria.containsKey(asistencia.nombreMateria)) {
        asistenciasPorMateria[asistencia.nombreMateria] = [];
      }
      asistenciasPorMateria[asistencia.nombreMateria]!.add(asistencia);
    }

    return RefreshIndicator(
      onRefresh: _loadAsistencias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: asistenciasPorMateria.length,
        itemBuilder: (context, index) {
          final materia = asistenciasPorMateria.keys.elementAt(index);
          final asistencias = asistenciasPorMateria[materia]!;
          
          // Calcular estadísticas de asistencia
          int presentes = 0;
          int ausentes = 0;
          int tardanzas = 0;
          int justificados = 0;
          
          for (var asistencia in asistencias) {
            switch (asistencia.estado.toLowerCase()) {
              case 'presente':
                presentes++;
                break;
              case 'ausente':
                ausentes++;
                break;
              case 'tardanza':
                tardanzas++;
                break;
              case 'justificado':
                justificados++;
                break;
            }
          }
          
          final total = asistencias.length;
          final porcentajeAsistencia = total > 0 ? (presentes / total * 100).toStringAsFixed(1) : '0.0';
          
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con nombre de materia
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: total > 0 ? presentes / total : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          porcentajeAsistencia.compareTo('75.0') >= 0 
                              ? Colors.green 
                              : Colors.orange
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Asistencia: $porcentajeAsistencia%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: porcentajeAsistencia.compareTo('75.0') >= 0 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Estadísticas de asistencia
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstadisticaItem(
                        'Presentes', 
                        presentes, 
                        Icons.check_circle, 
                        Colors.green
                      ),
                      _buildEstadisticaItem(
                        'Ausentes', 
                        ausentes, 
                        Icons.cancel, 
                        Colors.red
                      ),
                      _buildEstadisticaItem(
                        'Tardanzas', 
                        tardanzas, 
                        Icons.access_time, 
                        Colors.orange
                      ),
                      _buildEstadisticaItem(
                        'Justificados', 
                        justificados, 
                        Icons.assignment_late, 
                        Colors.blue
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Lista de asistencias
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: asistencias.length,
                  itemBuilder: (context, idx) {
                    final asistencia = asistencias[idx];
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    
                    return ListTile(
                      leading: Icon(
                        asistencia.getStatusIcon(),
                        color: asistencia.getStatusColor(),
                      ),
                      title: Text(
                        dateFormat.format(asistencia.fecha),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: asistencia.observacion != null && asistencia.observacion!.isNotEmpty
                          ? Text(asistencia.observacion!)
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: asistencia.getStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          asistencia.estado,
                          style: TextStyle(
                            color: asistencia.getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEstadisticaItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
} 