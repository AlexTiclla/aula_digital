import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ParticipationScreen extends StatefulWidget {
  const ParticipationScreen({Key? key}) : super(key: key);

  @override
  _ParticipationScreenState createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Participacion> _participaciones = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadParticipaciones();
  }

  Future<void> _loadParticipaciones() async {
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
      
      print('Cargando participaciones para estudiante ID: $estudianteId');

      final participaciones = await _apiService.getParticipacionesEstudiante(estudianteId);
      
      setState(() {
        _participaciones = participaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar participaciones: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Participaciones'),
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
              onPressed: _loadParticipaciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_participaciones.isEmpty) {
      return const Center(
        child: Text(
          'No tienes participaciones registradas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Agrupar participaciones por materia
    final Map<String, List<Participacion>> participacionesPorMateria = {};
    for (var participacion in _participaciones) {
      if (!participacionesPorMateria.containsKey(participacion.nombreMateria)) {
        participacionesPorMateria[participacion.nombreMateria] = [];
      }
      participacionesPorMateria[participacion.nombreMateria]!.add(participacion);
    }

    return RefreshIndicator(
      onRefresh: _loadParticipaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: participacionesPorMateria.length,
        itemBuilder: (context, index) {
          final materia = participacionesPorMateria.keys.elementAt(index);
          final participaciones = participacionesPorMateria[materia]!;
          
          // Calcular puntaje total de la materia
          final puntajeTotal = participaciones.fold<int>(
            0, (sum, item) => sum + item.puntaje);
          
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con nombre de materia y puntos totales
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
                          materia,
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
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Total: $puntajeTotal pts',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de participaciones
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: participaciones.length,
                  itemBuilder: (context, idx) {
                    final participacion = participaciones[idx];
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    
                    return ListTile(
                      title: Text(
                        participacion.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha: ${dateFormat.format(participacion.fecha)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            'Tipo: ${participacion.tipo}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${participacion.puntaje} pts',
                          style: TextStyle(
                            color: Colors.green.shade800,
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
        },
      ),
    );
  }
} 