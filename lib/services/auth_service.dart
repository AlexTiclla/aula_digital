// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Cambia esta URL por la de tu servidor
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1/auth';
  
  // Para almacenar el token JWT
  Future<void> _saveToken(String token, int userId, String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('userId', userId);
    await prefs.setString('rol', rol);
    
    // Si el rol es estudiante, obtener y guardar el ID del estudiante
    if (rol == 'estudiante') {
      await _fetchAndSaveEstudianteId(userId, token);
    }
  }
  
  // Método para obtener y guardar el ID del estudiante
  Future<void> _fetchAndSaveEstudianteId(int userId, String token) async {
    try {
      // Obtener todos los estudiantes y filtrar por usuario_id
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/v1/estudiantes/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> estudiantes = jsonDecode(response.body);
        
        // Buscar el estudiante con el usuario_id correspondiente
        for (var estudiante in estudiantes) {
          if (estudiante['usuario_id'] == userId) {
            final estudianteId = estudiante['id'];
            if (estudianteId != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('estudiante_id', estudianteId);
              print('ID de estudiante guardado: $estudianteId');
              return;
            }
          }
        }
        
        print('No se encontró un estudiante con usuario_id: $userId');
      } else {
        print('Error al obtener estudiantes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener ID de estudiante: $e');
    }
  }
  
  // Para verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }
  
  // Para obtener el rol del usuario
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }
  
  // Para obtener el ID del usuario
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
  
  // Para obtener el ID del estudiante
  Future<int?> getEstudianteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('estudiante_id');
  }
  
  // Para cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Iniciar sesión
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(
        data['access_token'], 
        data['user_id'], 
        data['rol']
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al iniciar sesión');
    }
  }
  
  // Registrar usuario (solo estudiantes)
  Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    String nombre, 
    String apellido
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
        'rol': 'ESTUDIANTE',  // Siempre registramos como estudiante
      }),
    );
    
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      
      // Iniciar sesión automáticamente después del registro exitoso
      try {
        await login(email, password);
        return userData;
      } catch (e) {
        print('Error al iniciar sesión automáticamente después del registro: $e');
        return userData;
      }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al registrar usuario');
    }
  }

  // Añadir a lib/services/auth_service.dart
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}