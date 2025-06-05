import 'models.dart';

class PredictionResult {
  final int? prediccionNota;
  final bool prediccionAsistencia;
  final bool prediccionParticipacion;
  final double confianzaNota;
  final double confianzaAsistencia;
  final double confianzaParticipacion;
  final List<Grade> ultimasNotas;
  final List<Attendance> ultimasAsistencias;
  final List<Participation> ultimasParticipaciones;

  PredictionResult({
    this.prediccionNota,
    required this.prediccionAsistencia,
    required this.prediccionParticipacion,
    required this.confianzaNota,
    required this.confianzaAsistencia,
    required this.confianzaParticipacion,
    required this.ultimasNotas,
    required this.ultimasAsistencias,
    required this.ultimasParticipaciones,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    try {
      // Convertir notas
      List<Grade> notas = [];
      if (json['ultimas_notas'] != null) {
        for (var nota in json['ultimas_notas']) {
          try {
            notas.add(Grade.fromJson(nota));
          } catch (e) {
            print('Error al convertir nota: $e');
          }
        }
      }

      // Convertir asistencias
      List<Attendance> asistencias = [];
      if (json['ultimas_asistencias'] != null) {
        for (var asistencia in json['ultimas_asistencias']) {
          try {
            asistencias.add(Attendance.fromJson(asistencia));
          } catch (e) {
            print('Error al convertir asistencia: $e');
          }
        }
      }

      // Convertir participaciones
      List<Participation> participaciones = [];
      if (json['ultimas_participaciones'] != null) {
        for (var participacion in json['ultimas_participaciones']) {
          try {
            participaciones.add(Participation.fromJson(participacion));
          } catch (e) {
            print('Error al convertir participación: $e');
          }
        }
      }

      return PredictionResult(
        prediccionNota: json['prediccion_nota'],
        prediccionAsistencia: json['prediccion_asistencia'] ?? false,
        prediccionParticipacion: json['prediccion_participacion'] ?? false,
        confianzaNota: _parseDouble(json['confianza_nota']),
        confianzaAsistencia: _parseDouble(json['confianza_asistencia']),
        confianzaParticipacion: _parseDouble(json['confianza_participacion']),
        ultimasNotas: notas,
        ultimasAsistencias: asistencias,
        ultimasParticipaciones: participaciones,
      );
    } catch (e) {
      print('Error general en fromJson: $e');
      // Devolver un objeto con valores predeterminados en caso de error
      return PredictionResult(
        prediccionNota: 0,
        prediccionAsistencia: false,
        prediccionParticipacion: false,
        confianzaNota: 0.0,
        confianzaAsistencia: 0.0,
        confianzaParticipacion: 0.0,
        ultimasNotas: [],
        ultimasAsistencias: [],
        ultimasParticipaciones: [],
      );
    }
  }
  
  // Función auxiliar para convertir cualquier valor a double
  static double _parseDouble(dynamic value) {
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
} 