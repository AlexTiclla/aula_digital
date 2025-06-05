import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class ApiService {
  // URL base de la API
  static const String _baseUrl = 'https://backend-aula-digital.onrender.com/api/v1';
  
  // URL base pública para ser accedida por otros servicios
  static const String baseUrl = 'https://backend-aula-digital.onrender.com';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Método para obtener el token de autenticación
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Headers para las peticiones autenticadas
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para obtener el ID del estudiante actual (no el ID de usuario)
  Future<int?> getCurrentEstudianteId() async {
    final authService = AuthService();
    final estudianteId = await authService.getEstudianteId();
    
    if (estudianteId != null) {
      print('Usando ID de estudiante: $estudianteId');
      return estudianteId;
    } else {
      print('No se pudo obtener el ID de estudiante');
      return null;
    }
  }

  // Obtener notas por estudiante
  Future<List<Grade>> getNotasByEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Notas obtenidas del estudiante $estudianteId: ${data.length}');
        
        // Obtener información de materias para agregar nombres de cursos
        final materiasResponse = await http.get(
          Uri.parse('$_baseUrl/materias'),
          headers: headers,
        );
        
        Map<int, String> materiasMap = {};
        if (materiasResponse.statusCode == 200) {
          final List<dynamic> materias = jsonDecode(materiasResponse.body);
          for (var materia in materias) {
            materiasMap[materia['id']] = materia['nombre'] ?? 'Sin nombre';
          }
        }
        
        // Obtener curso_materias para relacionar con materias
        final cursoMateriasResponse = await http.get(
          Uri.parse('$_baseUrl/curso_materias'),
          headers: headers,
        );
        
        Map<int, int> cursoMateriaToMateria = {};
        if (cursoMateriasResponse.statusCode == 200) {
          final List<dynamic> cursoMaterias = jsonDecode(cursoMateriasResponse.body);
          for (var cm in cursoMaterias) {
            cursoMateriaToMateria[cm['id']] = cm['materia_id'];
          }
        }
        
        // Función auxiliar para convertir valor a double de manera segura
        double parseValue(dynamic val) {
          if (val == null) return 0.0;
          if (val is double) return val;
          if (val is int) return val.toDouble();
          if (val is String) {
            try {
              return double.parse(val);
            } catch (_) {
              return 0.0;
            }
          }
          return 0.0;
        }
        
        // Convertir a objetos Grade
        final List<Grade> notas = [];
        for (var notaData in data) {
          try {
            final cursoMateriaId = notaData['curso_materia_id'];
            final materiaId = cursoMateriaToMateria[cursoMateriaId];
            final nombreMateria = materiaId != null ? materiasMap[materiaId] ?? 'Materia desconocida' : 'Materia desconocida';
            
            notas.add(Grade.fromMap({
              'id': notaData['id'].toString(),
              'courseId': cursoMateriaId.toString(),
              'courseName': nombreMateria,
              'value': parseValue(notaData['valor']),
              'date': DateTime.parse(notaData['fecha']),
              'description': notaData['descripcion'] ?? '',
              'semesterId': '0', // Periodo actual
            }));
          } catch (e) {
            print('Error al procesar nota: $e');
            // Continuar con la siguiente nota
          }
        }
        
        return notas;
      } else {
        print('Error al cargar notas: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        throw Exception('Error al cargar notas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la petición de notas: $e');
      return [];
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
      
      // Usar la nueva ruta para obtener materias del estudiante
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (materiasResponse.statusCode != 200) {
        throw Exception('Error al obtener materias: ${materiasResponse.statusCode}');
      }
      
      final List<dynamic> materiasData = json.decode(materiasResponse.body);
      if (materiasData.isEmpty) {
        print('No se encontraron materias para el estudiante $estudianteId');
        return [];
      }
      
      // Convertir a objetos Course
      final List<Course> courses = [];
      for (var materia in materiasData) {
        courses.add(Course.fromJson({
          'id': materia['id'].toString(),
          'name': materia['nombre'] ?? 'Sin nombre',
          'teacher': materia['profesorFullName'] ?? 'Prof. Asignado',
          'credits': materia['horasSemanales'] ?? 0,
          'description': materia['descripcion'] ?? '',
          'semesterId': periodoId.toString(),
        }));
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
      
      // Usar la nueva ruta de la API
      final response = await http.get(
        Uri.parse('$_baseUrl/materias/estudiante/$estudianteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Imprimir la respuesta para depuración
        print('Respuesta de materias: ${response.body}');
        
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          print('No se encontraron materias para el estudiante $estudianteId');
          return _getDatosMateriasPrueba();
        }
        
        print('Materias obtenidas: ${data.length}');
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        print('Error al cargar materias del estudiante: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        throw Exception('Error al cargar materias del estudiante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo materias del estudiante: $e');
      return _getDatosMateriasPrueba();
    }
  }

  // Datos de prueba para materias
  List<Subject> _getDatosMateriasPrueba() {
    print('Usando datos de prueba para materias');
    return [
      Subject.fromJson({
        'id': 1,
        'nombre': 'Matemáticas',
        'descripcion': 'Curso de matemáticas básicas',
        'areaConocimiento': 'Ciencias Exactas',
        'horasSemanales': 5,
        'profesorFullName': 'Juan Pérez',
        'horario': 'Lunes y Miércoles 8:00 - 10:30',
        'aula': 'Aula 101',
        'modalidad': 'Presencial'
      }),
      Subject.fromJson({
        'id': 2,
        'nombre': 'Lenguaje',
        'descripcion': 'Comprensión y expresión lingüística',
        'areaConocimiento': 'Humanidades',
        'horasSemanales': 4,
        'profesorFullName': 'María González',
        'horario': 'Martes y Jueves 10:30 - 12:30',
        'aula': 'Aula 203',
        'modalidad': 'Presencial'
      }),
      Subject.fromJson({
        'id': 3,
        'nombre': 'Ciencias Naturales',
        'descripcion': 'Estudio de la naturaleza y sus fenómenos',
        'areaConocimiento': 'Ciencias Naturales',
        'horasSemanales': 3,
        'profesorFullName': 'Roberto Sánchez',
        'horario': 'Viernes 8:00 - 11:00',
        'aula': 'Laboratorio 2',
        'modalidad': 'Híbrido'
      }),
    ];
  }

  // 2. Obtener notas actuales del estudiante (materias activas) - OPTIMIZADO
  Future<List<Grade>> getNotasActualesEstudiante(int estudianteId) async { // usar este getNotasActualesEstudiante
    try {
      final headers = await _getAuthHeaders();
      
      // Obtener directamente las notas del estudiante usando la ruta simple
      final notasResponse = await http.get(
        Uri.parse('$_baseUrl/notas/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (notasResponse.statusCode != 200) {
        print('Error al obtener notas: ${notasResponse.statusCode}');
        print('Respuesta: ${notasResponse.body}');
        throw Exception('Error al obtener notas: ${notasResponse.statusCode}');
      }
      
      final List<dynamic> notasData = jsonDecode(notasResponse.body);
      if (notasData.isEmpty) {
        print('No se encontraron notas para el estudiante $estudianteId');
        return [];
      }
      
      print('Notas obtenidas: ${notasData.length}');
      
      // Obtener información de materias para agregar nombres de cursos
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      Map<int, String> materiasMap = {};
      if (materiasResponse.statusCode == 200) {
        final List<dynamic> materias = jsonDecode(materiasResponse.body);
        for (var materia in materias) {
          materiasMap[materia['id']] = materia['nombre'] ?? 'Sin nombre';
        }
      }
      
      // Obtener curso_materias para relacionar con materias
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias'),
        headers: headers,
      );
      
      Map<int, int> cursoMateriaToMateria = {};
      if (cursoMateriasResponse.statusCode == 200) {
        final List<dynamic> cursoMaterias = jsonDecode(cursoMateriasResponse.body);
        for (var cm in cursoMaterias) {
          cursoMateriaToMateria[cm['id']] = cm['materia_id'];
        }
      }
      
      // Convertir a objetos Grade
      final List<Grade> notas = [];
      for (var notaData in notasData) {
        final cursoMateriaId = notaData['curso_materia_id'];
        final materiaId = cursoMateriaToMateria[cursoMateriaId];
        final nombreMateria = materiaId != null ? materiasMap[materiaId] ?? 'Materia desconocida' : 'Materia desconocida';
        
        notas.add(Grade.fromMap({
          ...notaData,
          'courseName': nombreMateria,
          'semesterId': '0', // Periodo actual
        }));
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

  // Obtener participaciones del estudiante
  Future<List<Participacion>> getParticipacionesEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Obtener participaciones del estudiante
      final participacionesResponse = await http.get(
        Uri.parse('$_baseUrl/participaciones/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (participacionesResponse.statusCode != 200) {
        print('Error al obtener participaciones: ${participacionesResponse.statusCode}');
        print('Respuesta: ${participacionesResponse.body}');
        throw Exception('Error al obtener participaciones: ${participacionesResponse.statusCode}');
      }
      
      // Imprimir la respuesta completa para depuración
      print('Respuesta de participaciones: ${participacionesResponse.body}');
      
      final List<dynamic> participacionesData = jsonDecode(participacionesResponse.body);
      if (participacionesData.isEmpty) {
        print('No se encontraron participaciones para el estudiante $estudianteId');
        
        // Si no hay datos reales, devolver datos de prueba
        return _getDatosParticipacionesPrueba();
      }
      
      print('Participaciones obtenidas: ${participacionesData.length}');
      
      // Obtener información de materias para los nombres
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      Map<int, String> materiasMap = {};
      if (materiasResponse.statusCode == 200) {
        final List<dynamic> materias = jsonDecode(materiasResponse.body);
        for (var materia in materias) {
          materiasMap[materia['id']] = materia['nombre'] ?? 'Sin nombre';
        }
      }
      
      // Obtener curso_materias para relacionar con materias
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias'),
        headers: headers,
      );
      
      Map<int, int> cursoMateriaToMateria = {};
      if (cursoMateriasResponse.statusCode == 200) {
        final List<dynamic> cursoMaterias = jsonDecode(cursoMateriasResponse.body);
        for (var cm in cursoMaterias) {
          cursoMateriaToMateria[cm['id']] = cm['materia_id'];
        }
      }
      
      // Convertir a objetos Participacion
      final List<Participacion> participaciones = [];
      for (var participacionData in participacionesData) {
        try {
          final cursoMateriaId = participacionData['curso_materia_id'];
          final materiaId = cursoMateriaToMateria[cursoMateriaId];
          final nombreMateria = materiaId != null ? materiasMap[materiaId] ?? 'Materia desconocida' : 'Materia desconocida';
          
          // Usar los campos correctos según la estructura de la API
          final participacion = Participacion(
            id: participacionData['id'],
            estudianteId: participacionData['estudiante_id'],
            cursoMateriaId: participacionData['curso_materia_id'],
            nombreMateria: nombreMateria,
            descripcion: participacionData['participacion_clase'] ?? participacionData['descripcion'] ?? '',
            fecha: DateTime.parse(participacionData['fecha']),
            puntaje: participacionData['puntaje'] ?? 1,
            tipo: participacionData['tipo'] ?? 'Participación en clase',
          );
          
          participaciones.add(participacion);
          print('Participación procesada: ${participacion.descripcion}');
        } catch (e) {
          print('Error procesando participación: $e');
          print('Datos de participación: $participacionData');
        }
      }
      
      // Si no se pudo procesar ninguna participación, devolver datos de prueba
      if (participaciones.isEmpty) {
        return _getDatosParticipacionesPrueba();
      }
      
      return participaciones;
      
    } catch (e) {
      print('Error obteniendo participaciones: $e');
      
      // En caso de error, devolver datos de prueba
      return _getDatosParticipacionesPrueba();
    }
  }

  // Datos de prueba para participaciones
  List<Participacion> _getDatosParticipacionesPrueba() {
    print('Usando datos de prueba para participaciones');
    return [
      Participacion(
        id: 1,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        descripcion: 'Resolución de problema en pizarra',
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        puntaje: 2,
        tipo: 'Participación en clase',
      ),
      Participacion(
        id: 2,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        descripcion: 'Respuesta correcta a pregunta difícil',
        fecha: DateTime.now().subtract(const Duration(days: 3)),
        puntaje: 1,
        tipo: 'Respuesta oral',
      ),
      Participacion(
        id: 3,
        estudianteId: 1,
        cursoMateriaId: 2,
        nombreMateria: 'Lenguaje',
        descripcion: 'Exposición sobre literatura contemporánea',
        fecha: DateTime.now().subtract(const Duration(days: 7)),
        puntaje: 3,
        tipo: 'Exposición',
      ),
      Participacion(
        id: 4,
        estudianteId: 1,
        cursoMateriaId: 3,
        nombreMateria: 'Ciencias',
        descripcion: 'Aporte en trabajo grupal',
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        puntaje: 1,
        tipo: 'Trabajo en equipo',
      ),
    ];
  }

  // Obtener asistencias del estudiante
  Future<List<Asistencia>> getAsistenciasEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Obtener asistencias del estudiante
      final asistenciasResponse = await http.get(
        Uri.parse('$_baseUrl/asistencias/estudiante/$estudianteId'),
        headers: headers,
      );
      
      if (asistenciasResponse.statusCode != 200) {
        print('Error al obtener asistencias: ${asistenciasResponse.statusCode}');
        print('Respuesta: ${asistenciasResponse.body}');
        throw Exception('Error al obtener asistencias: ${asistenciasResponse.statusCode}');
      }
      
      // Imprimir la respuesta completa para depuración
      print('Respuesta de asistencias: ${asistenciasResponse.body}');
      
      final List<dynamic> asistenciasData = jsonDecode(asistenciasResponse.body);
      if (asistenciasData.isEmpty) {
        print('No se encontraron asistencias para el estudiante $estudianteId');
        
        // Si no hay datos reales, devolver datos de prueba
        return _getDatosAsistenciasPrueba();
      }
      
      print('Asistencias obtenidas: ${asistenciasData.length}');
      
      // Obtener información de materias para los nombres
      final materiasResponse = await http.get(
        Uri.parse('$_baseUrl/materias'),
        headers: headers,
      );
      
      Map<int, String> materiasMap = {};
      if (materiasResponse.statusCode == 200) {
        final List<dynamic> materias = jsonDecode(materiasResponse.body);
        for (var materia in materias) {
          materiasMap[materia['id']] = materia['nombre'] ?? 'Sin nombre';
        }
      }
      
      // Obtener curso_materias para relacionar con materias
      final cursoMateriasResponse = await http.get(
        Uri.parse('$_baseUrl/curso_materias'),
        headers: headers,
      );
      
      Map<int, int> cursoMateriaToMateria = {};
      if (cursoMateriasResponse.statusCode == 200) {
        final List<dynamic> cursoMaterias = jsonDecode(cursoMateriasResponse.body);
        for (var cm in cursoMaterias) {
          cursoMateriaToMateria[cm['id']] = cm['materia_id'];
        }
      }
      
      // Convertir a objetos Asistencia
      final List<Asistencia> asistencias = [];
      for (var asistenciaData in asistenciasData) {
        try {
          final cursoMateriaId = asistenciaData['curso_materia_id'];
          final materiaId = cursoMateriaToMateria[cursoMateriaId];
          final nombreMateria = materiaId != null ? materiasMap[materiaId] ?? 'Materia desconocida' : 'Materia desconocida';
          
          // Determinar el estado de asistencia basado en el campo 'valor'
          String estado = 'Desconocido';
          if (asistenciaData.containsKey('valor')) {
            final bool? valor = asistenciaData['valor'] is bool 
                ? asistenciaData['valor'] 
                : asistenciaData['valor'] == 'true' || asistenciaData['valor'] == '1' || asistenciaData['valor'] == 1;
            
            estado = valor == true ? 'Presente' : 'Ausente';
          } else if (asistenciaData.containsKey('estado')) {
            estado = asistenciaData['estado'];
          }
          
          final asistencia = Asistencia(
            id: asistenciaData['id'],
            estudianteId: asistenciaData['estudiante_id'],
            cursoMateriaId: asistenciaData['curso_materia_id'],
            nombreMateria: nombreMateria,
            fecha: DateTime.parse(asistenciaData['fecha']),
            estado: estado,
            observacion: asistenciaData['observacion'],
          );
          
          asistencias.add(asistencia);
          print('Asistencia procesada: ${asistencia.fecha} - ${asistencia.estado}');
        } catch (e) {
          print('Error procesando asistencia: $e');
          print('Datos de asistencia: $asistenciaData');
        }
      }
      
      // Si no se pudo procesar ninguna asistencia, devolver datos de prueba
      if (asistencias.isEmpty) {
        return _getDatosAsistenciasPrueba();
      }
      
      return asistencias;
      
    } catch (e) {
      print('Error obteniendo asistencias: $e');
      
      // En caso de error, devolver datos de prueba
      return _getDatosAsistenciasPrueba();
    }
  }

  // Datos de prueba para asistencias
  List<Asistencia> _getDatosAsistenciasPrueba() {
    print('Usando datos de prueba para asistencias');
    return [
      Asistencia(
        id: 1,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 2,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        fecha: DateTime.now().subtract(const Duration(days: 8)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 3,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        fecha: DateTime.now().subtract(const Duration(days: 6)),
        estado: 'Ausente',
        observacion: 'Enfermedad',
      ),
      Asistencia(
        id: 4,
        estudianteId: 1,
        cursoMateriaId: 1,
        nombreMateria: 'Matemáticas',
        fecha: DateTime.now().subtract(const Duration(days: 4)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 5,
        estudianteId: 1,
        cursoMateriaId: 2,
        nombreMateria: 'Lenguaje',
        fecha: DateTime.now().subtract(const Duration(days: 9)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 6,
        estudianteId: 1,
        cursoMateriaId: 2,
        nombreMateria: 'Lenguaje',
        fecha: DateTime.now().subtract(const Duration(days: 7)),
        estado: 'Tardanza',
        observacion: 'Llegó 10 minutos tarde',
      ),
      Asistencia(
        id: 7,
        estudianteId: 1,
        cursoMateriaId: 2,
        nombreMateria: 'Lenguaje',
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 8,
        estudianteId: 1,
        cursoMateriaId: 3,
        nombreMateria: 'Ciencias',
        fecha: DateTime.now().subtract(const Duration(days: 8)),
        estado: 'Justificado',
        observacion: 'Cita médica',
      ),
      Asistencia(
        id: 9,
        estudianteId: 1,
        cursoMateriaId: 3,
        nombreMateria: 'Ciencias',
        fecha: DateTime.now().subtract(const Duration(days: 6)),
        estado: 'Presente',
        observacion: null,
      ),
      Asistencia(
        id: 10,
        estudianteId: 1,
        cursoMateriaId: 3,
        nombreMateria: 'Ciencias',
        fecha: DateTime.now().subtract(const Duration(days: 4)),
        estado: 'Presente',
        observacion: null,
      ),
    ];
  }

  // Obtener profesores del estudiante
  Future<List<Profesor>> getProfesoresEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Usar la nueva ruta de la API
      final response = await http.get(
        Uri.parse('$_baseUrl/profesores/estudiante/$estudianteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Imprimir la respuesta para depuración
        print('Respuesta de profesores: ${response.body}');
        
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          print('No se encontraron profesores para el estudiante $estudianteId');
          return _getDatosProfesoresPrueba();
        }
        
        print('Profesores obtenidos: ${data.length}');
        return data.map((json) => Profesor.fromJson(json)).toList();
      } else {
        print('Error al cargar profesores del estudiante: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        throw Exception('Error al cargar profesores del estudiante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo profesores del estudiante: $e');
      return _getDatosProfesoresPrueba();
    }
  }

  // Datos de prueba para profesores
  List<Profesor> _getDatosProfesoresPrueba() {
    print('Usando datos de prueba para profesores');
    return [
      Profesor(
        id: 1,
        usuarioId: 101,
        nombre: 'Juan',
        apellido: 'Pérez',
        email: 'juan.perez@ejemplo.com',
        telefono: '555-1234',
        especialidad: 'Matemáticas',
        nivelAcademico: 'Licenciatura',
      ),
      Profesor(
        id: 2,
        usuarioId: 102,
        nombre: 'María',
        apellido: 'González',
        email: 'maria.gonzalez@ejemplo.com',
        telefono: '555-5678',
        especialidad: 'Lenguaje',
        nivelAcademico: 'Maestría',
      ),
      Profesor(
        id: 3,
        usuarioId: 103,
        nombre: 'Roberto',
        apellido: 'Sánchez',
        email: 'roberto.sanchez@ejemplo.com',
        telefono: '555-9012',
        especialidad: 'Ciencias Naturales',
        nivelAcademico: 'Doctorado',
      ),
    ];
  }

  // Obtener tutor del estudiante
  Future<Tutor?> getTutorEstudiante(int estudianteId) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Usar la nueva ruta de la API
      final response = await http.get(
        Uri.parse('$_baseUrl/tutores/estudiante/$estudianteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Imprimir la respuesta para depuración
        print('Respuesta de tutor: ${response.body}');
        
        final data = json.decode(response.body);
        return Tutor.fromJson(data);
      } else {
        print('Error al cargar tutor del estudiante: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        throw Exception('Error al cargar tutor del estudiante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo tutor del estudiante: $e');
      return _getDatoTutorPrueba();
    }
  }

  // Datos de prueba para tutor
  Tutor _getDatoTutorPrueba() {
    print('Usando datos de prueba para tutor');
    return Tutor(
      id: 1,
      nombre: 'Carlos',
      apellido: 'Rodríguez',
      relacionEstudiante: 'Padre',
      telefono: '555-4321',
      ocupacion: 'Ingeniero',
      lugarTrabajo: 'Empresa ABC',
      correo: 'carlos.rodriguez@ejemplo.com',
    );
  }
} 