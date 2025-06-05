// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserService {
  static const String baseUrl = 'https://backend-aula-digital.onrender.com/api/v1';
  final AuthService _authService = AuthService();
  
  // Obtener datos del perfil de estudiante
  Future<Map<String, dynamic>> getEstudianteProfile() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    
    if (userId == null || token == null) {
      throw Exception('No hay sesión activa');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Perfil de estudiante no encontrado. Puede que necesites completar tu registro como estudiante.');
    } else {
      print('Error API: ${response.statusCode} - ${response.body}');
      throw Exception('Error al obtener datos del estudiante. Código: ${response.statusCode}');
    }
  }
  
  // Obtener datos del perfil de profesor
  Future<Map<String, dynamic>> getProfesorProfile() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    
    if (userId == null || token == null) {
      throw Exception('No hay sesión activa');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/profesores/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Perfil de profesor no encontrado. Puede que necesites completar tu registro como profesor.');
    } else {
      print('Error API: ${response.statusCode} - ${response.body}');
      throw Exception('Error al obtener datos del profesor. Código: ${response.statusCode}');
    }
  }
}