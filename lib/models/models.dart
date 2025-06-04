import 'package:flutter/material.dart';
import 'dart:convert';

export 'student.dart';
export 'teacher.dart';
export 'grade.dart';
export 'semester.dart';
export 'course.dart';
export 'subject.dart';
export 'profesor.dart';
export 'tutor.dart';

// Añadir la clase HistoricalGradeData para representar los datos históricos de notas
class HistoricalGradeData {
  final DateTime date;
  final double grade;
  final String description;

  HistoricalGradeData({
    required this.date,
    required this.grade,
    required this.description,
  });
}

// Modelo para Participación
class Participacion {
  final int id;
  final int estudianteId;
  final int cursoMateriaId;
  final String nombreMateria;
  final String descripcion;
  final DateTime fecha;
  final int puntaje;
  final String tipo;

  Participacion({
    required this.id,
    required this.estudianteId,
    required this.cursoMateriaId,
    required this.nombreMateria,
    required this.descripcion,
    required this.fecha,
    required this.puntaje,
    required this.tipo,
  });

  factory Participacion.fromJson(Map<String, dynamic> json, {String? nombreMateria}) {
    return Participacion(
      id: json['id'],
      estudianteId: json['estudiante_id'],
      cursoMateriaId: json['curso_materia_id'],
      nombreMateria: nombreMateria ?? 'Materia no especificada',
      descripcion: json['participacion_clase'] ?? json['descripcion'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      puntaje: json['puntaje'] ?? 1,
      tipo: json['tipo'] ?? 'Participación en clase',
    );
  }
}

// Modelo para Asistencia
class Asistencia {
  final int id;
  final int estudianteId;
  final int cursoMateriaId;
  final String nombreMateria;
  final DateTime fecha;
  final String estado;
  final String? observacion;

  Asistencia({
    required this.id,
    required this.estudianteId,
    required this.cursoMateriaId,
    required this.nombreMateria,
    required this.fecha,
    required this.estado,
    this.observacion,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json, {String? nombreMateria}) {
    // Determinar el estado de asistencia basado en el campo 'valor'
    String estado = 'Desconocido';
    if (json.containsKey('valor')) {
      final bool? valor = json['valor'] is bool 
          ? json['valor'] 
          : json['valor'] == 'true' || json['valor'] == '1' || json['valor'] == 1;
      
      estado = valor == true ? 'Presente' : 'Ausente';
    } else if (json.containsKey('estado')) {
      estado = json['estado'];
    }
    
    return Asistencia(
      id: json['id'],
      estudianteId: json['estudiante_id'],
      cursoMateriaId: json['curso_materia_id'],
      nombreMateria: nombreMateria ?? 'Materia no especificada',
      fecha: DateTime.parse(json['fecha']),
      estado: estado,
      observacion: json['observacion'],
    );
  }

  // Método para obtener el color según el estado de asistencia
  Color getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Colors.green;
      case 'ausente':
        return Colors.red;
      case 'tardanza':
        return Colors.orange;
      case 'justificado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Método para obtener el ícono según el estado de asistencia
  IconData getStatusIcon() {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check_circle;
      case 'ausente':
        return Icons.cancel;
      case 'tardanza':
        return Icons.access_time;
      case 'justificado':
        return Icons.assignment_late;
      default:
        return Icons.help;
    }
  }
}
