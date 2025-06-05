import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/prediction_service.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';

class PredictionScreen extends StatefulWidget {
  final int? estudianteId;
  final int? cursoMateriaId;
  final String materiaName;

  const PredictionScreen({
    Key? key,
    this.estudianteId,
    this.cursoMateriaId,
    this.materiaName = 'Materia',
  }) : super(key: key);

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final PredictionService _predictionService = PredictionService();
  final ApiService _apiService = ApiService();
  
  PredictionResult? _prediction;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }
  
  Future<void> _loadPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Obtener ID del estudiante si no se proporcionó
      int estudianteId = widget.estudianteId ?? await _apiService.getCurrentEstudianteId() ?? 0;
      
      if (estudianteId <= 0) {
        // Si no hay ID de estudiante, usar datos de prueba con ID ficticio
        final prediction = _predictionService.getMockPrediction(1);
        setState(() {
          _prediction = prediction;
          _isLoading = false;
        });
        return;
      }
      
      // Obtener predicción
      final prediction = await _predictionService.getPrediction(estudianteId);
      
      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      print('Error en _loadPrediction: $e');
      
      // Usar datos de prueba en caso de error
      final estudianteId = widget.estudianteId ?? 1;
      final mockPrediction = _predictionService.getMockPrediction(estudianteId);
      
      setState(() {
        _prediction = mockPrediction;
        _isLoading = false;
        // Opcionalmente puedes mantener el mensaje de error para mostrar un snackbar
        // _errorMessage = 'Error al cargar predicciones: $e';
      });
      
      // Mostrar un mensaje de que se están usando datos de prueba
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usando datos de prueba por problemas de conexión'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Predicciones de ${widget.materiaName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Analizando datos...')
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildPredictionView(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar las predicciones',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPrediction,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionView() {
    if (_prediction == null) {
      return const Center(
        child: Text('No hay datos de predicción disponibles'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPrediction,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de predicción de notas
            _buildPredictionCard(
              title: 'Predicción de Notas',
              icon: Icons.grade,
              color: Colors.blue,
              child: _buildGradePrediction(),
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de predicción de asistencia
            _buildPredictionCard(
              title: 'Predicción de Asistencia',
              icon: Icons.calendar_today,
              color: Colors.green,
              child: _buildAttendancePrediction(),
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de predicción de participación
            _buildPredictionCard(
              title: 'Predicción de Participación',
              icon: Icons.record_voice_over,
              color: Colors.orange,
              child: _buildParticipationPrediction(),
            ),
            
            const SizedBox(height: 32),
            
            // Sección de datos recientes
            Text(
              'Historial Reciente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de notas recientes
            _buildHistoryCard(
              title: 'Últimas Notas',
              icon: Icons.grade,
              color: Colors.blue,
              child: _buildGradeHistory(),
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de asistencias recientes
            _buildHistoryCard(
              title: 'Últimas Asistencias',
              icon: Icons.calendar_today,
              color: Colors.green,
              child: _buildAttendanceHistory(),
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de participaciones recientes
            _buildHistoryCard(
              title: 'Últimas Participaciones',
              icon: Icons.record_voice_over,
              color: Colors.orange,
              child: _buildParticipationHistory(),
            ),
            
            const SizedBox(height: 24),
            
            // Nota sobre predicciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Acerca de las Predicciones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Las predicciones se basan en el historial académico utilizando algoritmos de Machine Learning (Random Forest). Estas predicciones son estimaciones y pueden variar según el desempeño futuro.',
                      style: TextStyle(fontSize: 14),
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
  
  Widget _buildPredictionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradePrediction() {
    final prediccionNota = _prediction!.prediccionNota;
    final confianza = (_prediction!.confianzaNota * 100).toStringAsFixed(0);
    
    Color getColor(int? nota) {
      if (nota == null) return Colors.grey;
      if (nota >= 80) return Colors.green;
      if (nota >= 60) return Colors.orange;
      return Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'La próxima nota será aproximadamente:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                prediccionNota != null ? '$prediccionNota' : 'No disponible',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: getColor(prediccionNota),
                ),
              ),
              Text(
                'Confianza: $confianza%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (prediccionNota != null)
          Text(
            prediccionNota >= 80
                ? 'Vas por muy buen camino. ¡Sigue así!'
                : prediccionNota >= 60
                    ? 'Tu rendimiento es aceptable, pero podrías mejorar.'
                    : 'Necesitas mejorar tu rendimiento para aprobar.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: getColor(prediccionNota),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAttendancePrediction() {
    final prediccion = _prediction!.prediccionAsistencia;
    final confianza = (_prediction!.confianzaAsistencia * 100).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basado en tu historial de asistencia, nuestra predicción es:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              prediccion ? Icons.check_circle : Icons.cancel,
              color: prediccion ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(width: 12),
            Text(
              prediccion ? 'Asistirás a la próxima clase' : 'Podrías faltar a la próxima clase',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: prediccion ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Confianza: $confianza%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          prediccion
              ? 'Tienes un buen patrón de asistencia. Mantener la asistencia regular contribuye significativamente a tu rendimiento académico.'
              : 'Según nuestro análisis, podrías faltar a la próxima clase. La asistencia regular es clave para el éxito académico.',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildParticipationPrediction() {
    final prediccion = _prediction!.prediccionParticipacion;
    final confianza = (_prediction!.confianzaParticipacion * 100).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En base a tu historial de participación, nuestra predicción es:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              prediccion ? Icons.record_voice_over : Icons.voice_over_off,
              color: prediccion ? Colors.green : Colors.orange,
              size: 40,
            ),
            const SizedBox(width: 12),
            Text(
              prediccion ? 'Participarás en la próxima clase' : 'Es posible que no participes\nen la próxima clase',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: prediccion ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Confianza: $confianza%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          prediccion
              ? 'Tienes un buen nivel de participación en clase. La participación activa contribuye a una mejor comprensión de los temas.'
              : 'Te recomendamos aumentar tu participación en clase, ya que es importante para reforzar el aprendizaje y aclarar dudas.',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGradeHistory() {
    final notas = _prediction!.ultimasNotas;
    
    if (notas.isEmpty) {
      return const Center(
        child: Text('No hay datos de notas recientes'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notas.length,
      itemBuilder: (context, index) {
        final nota = notas[index];
        final fecha = '${nota.date.day}/${nota.date.month}/${nota.date.year}';
        
        Color getColor(double valor) {
          if (valor >= 80) return Colors.green;
          if (valor >= 60) return Colors.orange;
          return Colors.red;
        }
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: getColor(nota.value.toDouble()),
            child: Text(
              nota.value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(nota.courseName),
          subtitle: Text(fecha),
          dense: true,
        );
      },
    );
  }
  
  Widget _buildAttendanceHistory() {
    final asistencias = _prediction!.ultimasAsistencias;
    
    if (asistencias.isEmpty) {
      return const Center(
        child: Text('No hay datos de asistencia recientes'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: asistencias.length,
      itemBuilder: (context, index) {
        final asistencia = asistencias[index];
        final fecha = '${asistencia.date.day}/${asistencia.date.month}/${asistencia.date.year}';
        
        return ListTile(
          leading: Icon(
            asistencia.present ? Icons.check_circle : Icons.cancel,
            color: asistencia.present ? Colors.green : Colors.red,
          ),
          title: Text(asistencia.present ? 'Presente' : 'Ausente'),
          subtitle: Text(fecha),
          dense: true,
        );
      },
    );
  }
  
  Widget _buildParticipationHistory() {
    final participaciones = _prediction!.ultimasParticipaciones;
    
    if (participaciones.isEmpty) {
      return const Center(
        child: Text('No hay datos de participación recientes'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participaciones.length,
      itemBuilder: (context, index) {
        final participacion = participaciones[index];
        final fecha = '${participacion.date.day}/${participacion.date.month}/${participacion.date.year}';
        
        return ListTile(
          leading: const Icon(
            Icons.record_voice_over,
            color: Colors.blue,
          ),
          title: Text(participacion.comment),
          subtitle: Text(fecha),
          dense: true,
        );
      },
    );
  }
} 