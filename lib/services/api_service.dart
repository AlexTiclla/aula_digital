import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class ApiService {
  // URL base de la API
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Método para obtener el token de autenticación
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Headers para las peticiones autenticadas
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para obtener el ID del estudiante actual
  Future<int?> getCurrentEstudianteId() async {
    final authService = AuthService();
    return authService.getEstudianteId();
  }

  // Obtener notas por estudiante
  Future<List<Map<String, dynamic>>> getNotasByEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar notas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de notas: $e');
    }
  }

  // Obtener materias
  Future<List<Map<String, dynamic>>> getMaterias() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar materias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de materias: $e');
    }
  }

  // Obtener cursos por periodo
  Future<List<Map<String, dynamic>>> getCursosByPeriodo(int periodoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/curso_periodos?periodo_id=$periodoId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar cursos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de cursos: $e');
    }
  }

  // Obtener curso_materias por curso_periodo
  Future<List<Map<String, dynamic>>> getCursoMateriasByCursoPeriodo(int cursoPeriodoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/curso_materias?curso_periodo_id=$cursoPeriodoId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar curso_materias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de curso_materias: $e');
    }
  }

  // Obtener notas por estudiante y curso_materia
  Future<List<Map<String, dynamic>>> getNotasByEstudianteAndCursoMateria(
    int estudianteId,
    int cursoMateriaId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId/curso_materia/$cursoMateriaId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar notas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de notas: $e');
    }
  }

  // Obtener periodos académicos
  Future<List<Map<String, dynamic>>> getPeriodos() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/periodos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar periodos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de periodos: $e');
    }
  }

  // Obtener materias inscritas por estudiante y periodo (OPTIMIZADO)
  Future<List<Course>> getMateriasInscritasByEstudianteAndPeriodo(int estudianteId, int periodoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 1. Obtener el curso_periodo del estudiante directamente
      final estudiante = await http.get(
        Uri.parse('$_baseUrl/usuarios/$estudianteId'),
        headers: headers,
      );
      
      if (estudiante.statusCode != 200) {
        throw Exception('Error al obtener estudiante: ${estudiante.statusCode}');
      }
      
      final estudianteData = json.decode(estudiante.body);
      final cursoPeriodoId = estudianteData['curso_periodo_id'];
      
      if (cursoPeriodoId == null) {
        print('El estudiante no tiene un curso_periodo asignado');
        return [];
      }
      
      // 2. Obtener todas las materias del curso_periodo en una sola petición
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias?curso_periodo_id=$cursoPeriodoId'),
        headers: headers,
      );
      
      if (cursoMateriasResponse.statusCode != 200) {
        throw Exception('Error al obtener curso_materias: ${cursoMateriasResponse.statusCode}');
      }
      
      final List<dynamic> cursoMaterias = json.decode(cursoMateriasResponse.body);
      if (cursoMaterias.isEmpty) {
        return [];
      }
      
      // 3. Obtener todas las materias en una sola petición
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      if (materiasResponse.statusCode != 200) {
        throw Exception('Error al obtener materias: ${materiasResponse.statusCode}');
      }
      
      final List<dynamic> materias = json.decode(materiasResponse.body);
      final Map<int, Map<String, dynamic>> materiasMap = {};
      for (var materia in materias) {
        materiasMap[materia['id']] = materia;
      }
      
      // 4. Convertir a objetos Course
      final List<Course> courses = [];
      for (var cursoMateria in cursoMaterias) {
        final int materiaId = cursoMateria['materia_id'];
        final materia = materiasMap[materiaId];
        
        if (materia != null) {
          courses.add(Course.fromJson({
            'id': cursoMateria['id'].toString(),
            'name': materia['nombre'] ?? 'Sin nombre',
            'teacher': 'Prof. Asignado', // Simplificado para evitar más peticiones
            'credits': materia['horas_semanales'] ?? 0,
            'description': materia['descripcion'] ?? '',
            'semesterId': periodoId.toString(),
          }));
        }
      }
      
      return courses;
      
    } catch (e) {
      print('Error obteniendo materias inscritas: $e');
      return [];
    }
  }

  // Obtener todas las notas del estudiante por periodo (OPTIMIZADO)
  Future<List<Grade>> getNotasEstudianteByPeriodo(int estudianteId, int periodoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 1. Obtener todas las notas del estudiante en una sola petición
      final notasResponse = await http.get(
        Uri.parse('$_baseUrl/notas/$estudianteId'),
        headers: headers,
      );
      
      if (notasResponse.statusCode != 200) {
        throw Exception('Error al obtener notas: ${notasResponse.statusCode}');
      }
      
      final List<dynamic> notasData = json.decode(notasResponse.body);
      if (notasData.isEmpty) {
        return [];
      }
      
      // 2. Obtener todos los curso_materias para filtrar por periodo
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias'),
        headers: headers,
      );
      
      if (cursoMateriasResponse.statusCode != 200) {
        throw Exception('Error al obtener curso_materias: ${cursoMateriasResponse.statusCode}');
      }
      
      // 3. Obtener todos los curso_periodos en una sola petición
      final cursoPeriodosResponse = await http.get(
        Uri.parse('$_baseUrl/curso_periodos'),
        headers: headers,
      );
      
      if (cursoPeriodosResponse.statusCode != 200) {
        throw Exception('Error al obtener curso_periodos: ${cursoPeriodosResponse.statusCode}');
      }
      
      final List<dynamic> cursoPeriodos = json.decode(cursoPeriodosResponse.body);
      
      // Crear un mapa de curso_periodo_id -> periodo_id para búsqueda rápida
      final Map<int, int> cursoPeriodoToPeriodo = {};
      for (var cursoPeriodo in cursoPeriodos) {
        cursoPeriodoToPeriodo[cursoPeriodo['id']] = cursoPeriodo['periodo_id'];
      }
      
      final List<dynamic> cursoMaterias = json.decode(cursoMateriasResponse.body);
      final Map<int, Map<String, dynamic>> cursoMateriasMap = {};
      final Set<int> materiasIds = {};
      
      // Filtrar curso_materias por periodo usando el mapa en lugar de peticiones individuales
      for (var cursoMateria in cursoMaterias) {
        final cursoPeriodoId = cursoMateria['curso_periodo_id'];
        final periodoIdDelCurso = cursoPeriodoToPeriodo[cursoPeriodoId];
        
        if (periodoIdDelCurso == periodoId) {
          cursoMateriasMap[cursoMateria['id']] = cursoMateria;
          materiasIds.add(cursoMateria['materia_id']);
        }
      }
      
      // 4. Obtener todas las materias necesarias en una sola petición
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      if (materiasResponse.statusCode != 200) {
        throw Exception('Error al obtener materias: ${materiasResponse.statusCode}');
      }
      
      final List<dynamic> materias = json.decode(materiasResponse.body);
      final Map<int, String> materiasNombres = {};
      for (var materia in materias) {
        if (materiasIds.contains(materia['id'])) {
          materiasNombres[materia['id']] = materia['nombre'] ?? 'Sin nombre';
        }
      }
      
      // 5. Filtrar notas por curso_materias del periodo y convertir a objetos Grade
      final List<Grade> notas = [];
      for (var notaData in notasData) {
        final cursoMateriaId = notaData['curso_materia_id'];
        final cursoMateria = cursoMateriasMap[cursoMateriaId];
        
        if (cursoMateria != null) {
          final materiaId = cursoMateria['materia_id'];
          final nombreMateria = materiasNombres[materiaId] ?? 'Sin nombre';
          
          notas.add(Grade.fromMap({
            ...notaData,
            'courseName': nombreMateria,
            'semesterId': periodoId.toString(),
          }));
        }
      }
      
      return notas;
      
    } catch (e) {
      print('Error obteniendo notas del estudiante: $e');
      return [];
    }
  }

  // NUEVOS MÉTODOS PARA LAS PANTALLAS SOLICITADAS

  // 1. Obtener materias del estudiante actual (usando el endpoint obtener_materias_estudiante)
  Future<List<Subject>> getMateriasEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      // Mis materias o Mis notas
      // Forbidden, no se puede acceder a las notas
      final response = await http.get(
        Uri.parse('$_baseUrl/estudiantes/$estudianteId/materias'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar materias del estudiante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo materias del estudiante: $e');
      return [];
    }
  }

  // 2. Obtener notas actuales del estudiante (materias activas) - OPTIMIZADO
  Future<List<Grade>> getNotasActualesEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 1. Obtener materias del estudiante en una sola petición
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/estudiantes/$estudianteId/materias'),
        headers: headers,
      );
      
      if (materiasResponse.statusCode != 200) {
        throw Exception('Error al obtener materias: ${materiasResponse.statusCode}');
      }
      
      final List<dynamic> materias = json.decode(materiasResponse.body);
      if (materias.isEmpty) {
        return [];
      }
      
      // 2. Obtener todas las notas del estudiante en una sola petición
      final notasResponse = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (notasResponse.statusCode != 200) {
        throw Exception('Error al obtener notas: ${notasResponse.statusCode}');
      }
      
      final List<dynamic> notasData = json.decode(notasResponse.body);
      if (notasData.isEmpty) {
        return [];
      }
      
      // 3. Crear mapa de materias para acceso rápido
      final Map<int, Map<String, dynamic>> materiasMap = {};
      for (var materia in materias) {
        final id = materia['id'];
        materiasMap[id] = materia;
      }
      
      // 4. Filtrar notas por materias del estudiante y convertir a objetos Grade
      final List<Grade> notas = [];
      for (var notaData in notasData) {
        final cursoMateriaId = notaData['curso_materia_id'];
        
        // Verificar si esta nota corresponde a una de las materias actuales
        if (materiasMap.containsKey(cursoMateriaId)) {
          final materia = materiasMap[cursoMateriaId]!;
          final nombreMateria = materia['materia']['nombre'] ?? 'Sin nombre';
          
          notas.add(Grade.fromMap({
            ...notaData,
            'courseName': nombreMateria,
            'semesterId': '0', // Periodo actual
          }));
        }
      }
      
      return notas;
      
    } catch (e) {
      print('Error obteniendo notas actuales: $e');
      return [];
    }
  }

  // 3. Obtener historial de notas (materias de periodos inactivos) - OPTIMIZADO
  Future<List<Grade>> getHistorialNotasEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 1. Obtener periodos inactivos en una sola petición
      final periodosResponse = await http.get(
        Uri.parse('$_baseUrl/periodos'),
        headers: headers,
      );
      
      if (periodosResponse.statusCode != 200) {
        throw Exception('Error al obtener periodos: ${periodosResponse.statusCode}');
      }
      
      final List<dynamic> periodos = json.decode(periodosResponse.body);
      final List<dynamic> periodosInactivos = periodos.where((p) => p['is_active'] == false).toList();
      
      if (periodosInactivos.isEmpty) {
        return []; // No hay periodos inactivos
      }
      
      // 2. Obtener todas las notas del estudiante en una sola petición
      final notasResponse = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (notasResponse.statusCode != 200) {
        throw Exception('Error al obtener notas: ${notasResponse.statusCode}');
      }
      
      final List<dynamic> notasData = json.decode(notasResponse.body);
      if (notasData.isEmpty) {
        return [];
      }
      
      // 3. Obtener todos los curso_materias en una sola petición
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias'),
        headers: headers,
      );
      
      if (cursoMateriasResponse.statusCode != 200) {
        throw Exception('Error al obtener curso_materias: ${cursoMateriasResponse.statusCode}');
      }
      
      // 4. Obtener todos los curso_periodos en una sola petición
      final cursoPeriodosResponse = await http.get(
        Uri.parse('$_baseUrl/curso_periodos'),
        headers: headers,
      );
      
      if (cursoPeriodosResponse.statusCode != 200) {
        throw Exception('Error al obtener curso_periodos: ${cursoPeriodosResponse.statusCode}');
      }
      
      final List<dynamic> cursoPeriodos = json.decode(cursoPeriodosResponse.body);
      final Map<int, int> cursoPeriodoToPeriodo = {}; // Mapeo de curso_periodo_id a periodo_id
      
      // Crear mapa de curso_periodo a periodo
      for (var cursoPeriodo in cursoPeriodos) {
        cursoPeriodoToPeriodo[cursoPeriodo['id']] = cursoPeriodo['periodo_id'];
      }
      
      final List<dynamic> cursoMaterias = json.decode(cursoMateriasResponse.body);
      final Map<int, Map<String, dynamic>> cursoMateriasMap = {};
      final Set<int> materiasIds = {};
      final Map<int, int> cursoMateriaToPeriodo = {}; // Mapeo de curso_materia_id a periodo_id
      
      // Filtrar curso_materias por periodos inactivos y crear mapa
      final Set<int> periodosInactivosIds = periodosInactivos.map<int>((p) => p['id']).toSet();
      
      for (var cursoMateria in cursoMaterias) {
        final cursoPeriodoId = cursoMateria['curso_periodo_id'];
        final periodoId = cursoPeriodoToPeriodo[cursoPeriodoId];
        
        if (periodoId != null && periodosInactivosIds.contains(periodoId)) {
          cursoMateriasMap[cursoMateria['id']] = cursoMateria;
          materiasIds.add(cursoMateria['materia_id']);
          cursoMateriaToPeriodo[cursoMateria['id']] = periodoId;
        }
      }
      
      // 5. Obtener todas las materias necesarias en una sola petición
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      if (materiasResponse.statusCode != 200) {
        throw Exception('Error al obtener materias: ${materiasResponse.statusCode}');
      }
      
      final List<dynamic> materias = json.decode(materiasResponse.body);
      final Map<int, String> materiasNombres = {};
      for (var materia in materias) {
        if (materiasIds.contains(materia['id'])) {
          materiasNombres[materia['id']] = materia['nombre'] ?? 'Sin nombre';
        }
      }
      
      // 6. Filtrar notas por curso_materias de periodos inactivos y convertir a objetos Grade
      final List<Grade> notas = [];
      for (var notaData in notasData) {
        final cursoMateriaId = notaData['curso_materia_id'];
        final cursoMateria = cursoMateriasMap[cursoMateriaId];
        
        if (cursoMateria != null) {
          final materiaId = cursoMateria['materia_id'];
          final nombreMateria = materiasNombres[materiaId] ?? 'Sin nombre';
          final periodoId = cursoMateriaToPeriodo[cursoMateriaId];
          
          notas.add(Grade.fromMap({
            ...notaData,
            'courseName': nombreMateria,
            'semesterId': periodoId.toString(),
          }));
        }
      }
      
      return notas;
      
    } catch (e) {
      print('Error obteniendo historial de notas: $e');
      return [];
    }
  }
} 