import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_service.dart';

class PredictionService {
  final ApiService _apiService = ApiService();
  
  // Solo requiere el ID del estudiante ahora
  Future<PredictionResult> getPrediction(int estudianteId) async {
    try {
      final token = await _apiService.getToken();
      
      if (token == null) {
        print('Token no encontrado, usando datos de prueba');
        return getMockPrediction(estudianteId);
      }
      
      final url = '${ApiService.baseUrl}/api/v1/predicciones/predict';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'estudiante_id': estudianteId,
        }),
      );
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          // Imprimir datos para depuración
          print('Datos recibidos de la API:');
          print('prediccion_nota: ${data['prediccion_nota']}, tipo: ${data['prediccion_nota']?.runtimeType}');
          print('confianza_nota: ${data['confianza_nota']}, tipo: ${data['confianza_nota']?.runtimeType}');
          print('confianza_asistencia: ${data['confianza_asistencia']}, tipo: ${data['confianza_asistencia']?.runtimeType}');
          print('confianza_participacion: ${data['confianza_participacion']}, tipo: ${data['confianza_participacion']?.runtimeType}');
          
          // Preparar datos manualmente para evitar errores de tipo
          Map<String, dynamic> cleanData = {
            'prediccion_nota': data['prediccion_nota'],
            'prediccion_asistencia': data['prediccion_asistencia'] ?? false,
            'prediccion_participacion': data['prediccion_participacion'] ?? false,
            'confianza_nota': _ensureDouble(data['confianza_nota']),
            'confianza_asistencia': _ensureDouble(data['confianza_asistencia']),
            'confianza_participacion': _ensureDouble(data['confianza_participacion']),
            'ultimas_notas': data['ultimas_notas'] ?? [],
            'ultimas_asistencias': data['ultimas_asistencias'] ?? [],
            'ultimas_participaciones': data['ultimas_participaciones'] ?? [],
          };
          
          return PredictionResult.fromJson(cleanData);
        } catch (e) {
          print('Error procesando respuesta JSON: $e');
          return getMockPrediction(estudianteId);
        }
      } else {
        print('Error en la API: ${response.statusCode}, ${response.body}');
        // Si hay error en la API, usar datos de prueba
        return getMockPrediction(estudianteId);
      }
    } catch (e) {
      print('Error en getPrediction: $e');
      // Para cualquier error, devolver datos de prueba
      return getMockPrediction(estudianteId);
    }
  }
  
  // Función auxiliar para asegurar que un valor sea double
  double _ensureDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
  
  // Método público para datos ficticios - ahora solo usa el estudianteId
  PredictionResult getMockPrediction(int estudianteId) {
    print('Generando datos de prueba para estudiante $estudianteId');
    
    final ultimasNotas = [
      // studentId, courseId, semesterId. con valor 1 puesto
      Grade(id: '1', studentId: estudianteId.toString(), courseId: '1', value: 85, courseName: 'Matemáticas', semesterId: '1', date: DateTime.now().subtract(const Duration(days: 30))),
      Grade(id: '2', studentId: estudianteId.toString(), courseId: '1', value: 78, courseName: 'Matemáticas', semesterId: '1', date: DateTime.now().subtract(const Duration(days: 25))),
      Grade(id: '3', studentId: estudianteId.toString(), courseId: '1', value: 82, courseName: 'Matemáticas', semesterId: '1', date: DateTime.now().subtract(const Duration(days: 15))),
      Grade(id: '4', studentId: estudianteId.toString(), courseId: '1', value: 88, courseName: 'Matemáticas', semesterId: '1', date: DateTime.now().subtract(const Duration(days: 10))),
      Grade(id: '5', studentId: estudianteId.toString(), courseId: '1', value: 90, courseName: 'Matemáticas', semesterId: '1', date: DateTime.now().subtract(const Duration(days: 5))),
    ];
    
    final ultimasAsistencias = [
      Attendance(id: '1', date: DateTime.now().subtract(const Duration(days: 25)), present: true),
      Attendance(id: '2', date: DateTime.now().subtract(const Duration(days: 20)), present: true),
      Attendance(id: '3', date: DateTime.now().subtract(const Duration(days: 15)), present: false),
      Attendance(id: '4', date: DateTime.now().subtract(const Duration(days: 10)), present: true),
      Attendance(id: '5', date: DateTime.now().subtract(const Duration(days: 5)), present: true),
    ];
    
    final ultimasParticipaciones = [
      Participation(id: '1', date: DateTime.now().subtract(const Duration(days: 25)), comment: 'Participación activa'),
      Participation(id: '2', date: DateTime.now().subtract(const Duration(days: 15)), comment: 'Intervención en clase'),
      Participation(id: '3', date: DateTime.now().subtract(const Duration(days: 5)), comment: 'Responde preguntas'),
    ];
    
    return PredictionResult(
      prediccionNota: 92, 
      prediccionAsistencia: true, 
      prediccionParticipacion: true,
      confianzaNota: 0.85,
      confianzaAsistencia: 0.78,
      confianzaParticipacion: 0.65,
      ultimasNotas: ultimasNotas,
      ultimasAsistencias: ultimasAsistencias,
      ultimasParticipaciones: ultimasParticipaciones,
    );
  }
} 